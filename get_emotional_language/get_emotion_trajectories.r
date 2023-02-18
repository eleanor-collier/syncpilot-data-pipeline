#########################################################################################
# Analyze valence and arousal in disclosers' language using VADER
# Eleanor Collier
# 1/28/22
#########################################################################################
## Set up workspace ----
library(tidyverse)
library(knitr) 
library(vader)
library(factoextra)
library(NbClust)
library(ggplot2)
library(lmerTest)

# Load custom functions
setwd("/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/")
source("helper_functions/stdCoef.R")

# Load data
get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

transcripts <- read_csv(paste0(get_data_here, "transcripts.csv")) %>% distinct() %>% arrange(ID, disclosure)
# transcripts <- read_csv(paste0(get_data_here, "out_of_use/transcripts.csv")) %>% distinct() %>% arrange(ID, disclosure)

# problem_IDs <- c(1, 2, 9, 29, 30, 33, 34, 39, 40, 93, 94, 129, 147, 148, 149, 150, 179, 180)
problem_IDs <- c(9, 34, 39, 40, 129)

#########################################################################################
## Chunk disclosures into an equal number of windows ----
# Clean up use of the word "like" as it throws off valence scores
transcripts$text <- gsub("like", "", transcripts$text, ignore.case=T)

window_number = 100
window_size = 25

transcripts_prep <- transcripts %>% 
  # Get number of words
  mutate(n_words = sapply(strsplit(text, " "), length)) %>% 
  # Get rid of any stories with less than 250 words (mean is 500)
  filter(n_words >= 250) %>% 
  # Calculate the window gap for each story (round down)
  mutate(
    window_gap = floor((n_words - (window_size + 1))/window_number)
  )

# Initialize outer lists to store info for each transcript as a whole
IDs_list <- list()
disclosure_labels_list <- list()
transcripts_list <- list()
for (row in 1:nrow(transcripts_prep)) {
  # Initialize inner lists to store info for each text window
  IDs <- list()
  disclosure_labels <- list()
  text_chunks <- list()
  
  # Get ID, disclosure label, and text split into individual words
  ID <- transcripts_prep$ID[row]
  disclosure_label <- transcripts_prep$disclosure[row]
  text_by_word <- unlist(strsplit(transcripts_prep$text[row], " "))
  
  # Split transcripts into rolling windows
  for (window in 1:window_number) {
    window_gap <- transcripts_prep$window_gap[row]
    first_word_index <- 1 + ((window - 1)*window_gap)
    last_word_index  <- first_word_index + window_size
    words_to_combine <- text_by_word[first_word_index:last_word_index]
    text_chunk <- combine_words(words_to_combine[!is.na(words_to_combine)], sep=" ", and="")
    text_chunks[[window]] <- text_chunk
    IDs[[window]] <- ID
    disclosure_labels[[window]] <- disclosure_label
  }
  transcripts_list[[row]] <- text_chunks
  IDs_list[[row]] <- IDs
  disclosure_labels_list[[row]] <- disclosure_labels
}

# Covert transcript windows into dataframe & add IDs back in
transcripts_by_window <- data.frame(
  'ID' = unlist(IDs_list, use.names = F),
  'disclosure' = unlist(disclosure_labels_list, use.names = F),
  'window' = rep(1:window_number, times = length(transcripts_list)),
  'text' = unlist(transcripts_list, use.names = F)
  )

#########################################################################################
## Create emotion trajectories from VADER scores ----
vader_scores <- transcripts_by_window$text %>% 
  vader_df(text) %>% 
  rename(vader_valence = compound) %>% 
  # Get overall arousal (valence agnostic) by summing vader's valence score for each word (abs value)
  mutate(
    n_words = sapply(strsplit(gsub("\\{|\\}", "", word_scores), ","), function(x) length(x)),
    vader_arousal = sapply(strsplit(gsub("\\{|\\}", "", word_scores), ","), function(x) sum(abs(as.numeric(x))))/n_words
  ) %>% 
  select(-c(pos, neu, neg, but_count, word_scores, n_words, text))

# Bind with original data cols
transcripts_by_window_vader <- bind_cols(transcripts_by_window, vader_scores)

# Mean center trajectories
vader_scores_centered <- transcripts_by_window_vader %>% 
  group_by(ID, disclosure) %>% 
  mutate(
    valence_centered = scale(vader_valence, center=T, scale=F),
    arousal_centered = scale(vader_arousal, center=T, scale=F)
  ) %>% 
  ungroup()

#########################################################################################
## Format VADER scores for analysis ----
# Transform data to wide format
valence_centered_wide <- vader_scores_centered %>% 
  select(ID, disclosure, window, valence_centered) %>% 
  # Make each text window its own column
  pivot_wider(
    names_from = window,
    values_from = valence_centered
  ) %>% 
  mutate(storyID = 1:nrow(.)) %>% 
  select(ID, disclosure, storyID, everything())

arousal_centered_wide <- vader_scores_centered %>% 
  select(ID, disclosure, window, arousal_centered) %>% 
  # Make each text window its own column
  pivot_wider(
    names_from = window,
    values_from = arousal_centered
  ) %>% 
  mutate(storyID = 1:nrow(.)) %>% 
  select(ID, disclosure, storyID, everything())

# Save data
# write.csv(valence_centered_wide, paste0(save_data_here, "valence_trajectories_prep.csv"), row.names = F)
# write.csv(arousal_centered_wide, paste0(save_data_here, "arousal_trajectories_prep.csv"), row.names = F)

# Load data (instead of running the above code again, simply load the data to save time)
# old_valence_centered_wide <- read_csv(paste0(save_data_here, "out_of_use/valence_trajectories_prep.csv"))
valence_centered_wide <- read_csv(paste0(save_data_here, "valence_trajectories_prep.csv")) %>% arrange(ID, disclosure)
arousal_centered_wide <- read_csv(paste0(save_data_here, "arousal_trajectories_prep.csv"))

# # Compare new data to old for troubleshooting purposes
# old_stories <- read_csv(paste0(save_data_here, "out_of_use/valence_trajectories_prep.csv")) %>% 
#   select(ID, disclosure) %>% unique()
# new_stories <- read_csv(paste0(save_data_here, "valence_trajectories_prep.csv")) %>% 
#   select(ID, disclosure) %>% unique()
# test <- setdiff(new_stories, old_stories)

# Filter out problem participants
valence_centered_wide <- valence_centered_wide %>% filter(!(ID %in% problem_IDs))
# valence_centered_wide <- valence_centered_wide %>% filter(ID <= 152)
# valence_centered_wide <- valence_centered_wide %>%
#   mutate(ID_x=ID) %>%
#   group_by(ID_x) %>%
#   filter(disclosure %in% filter(old_stories, ID==unique(ID_x))$disclosure) %>%
#   ungroup() %>%
#   select(-ID_x)

# # Check difference between old data and new subset of selected stories
# setdiff(valence_centered_wide %>% select(ID, disclosure), old_stories)
# setdiff(old_stories, valence_centered_wide %>% select(ID, disclosure))

# Make dataframe with emotion scores x window only
valence_by_window <- select(valence_centered_wide, -c(ID:disclosure, storyID))
arousal_by_window <- select(arousal_centered_wide, -c(ID:disclosure, storyID))

#########################################################################################
## Run Hierarchical Cluster Analysis on Valence ----
# dist_mat <- dist(valence_by_window, method = 'euclidean')
dist_mat <- dist(valence_by_window, method = 'manhattan')
polarity_hclust <- hclust(dist_mat, method = 'ward.D')
# plot(polarity_hclust) # dendrogram

# Determine ideal number of clusters
# fviz_nbclust(valence_by_window, FUN = hcut, method = "wss", diss = dist_mat) # Elbow plot
# fviz_nbclust(valence_by_window, FUN = hcut, method = "silhouette", diss = dist_mat) # Silhouette plot

# Cut tree
clusters <- cutree(polarity_hclust, k = 2)
table(clusters) # Count number in each cluster

# Compute average trajectory for each cluster
mean_valence_trajectories <- valence_by_window %>% 
  # Add cluster id to dataset
  mutate(cluster = as.factor(clusters)) %>% 
  # Get mean trajectory for each cluster by computing mean value at each window
  group_by(cluster) %>% 
  summarize_at(
    vars("1":"100"),
    list(~mean(., na.rm=T))
  ) %>% 
  ungroup() %>% 
  # Change data to long form
  pivot_longer(
    cols = "1":"100",
    names_to = "window",
    values_to = "valence"
  ) %>% 
  mutate_at(
    vars(window, valence),
    list(~as.numeric(as.character(.)))
  )

# Plot mean cluster trajectories
ggplot(
  mean_valence_trajectories,
  aes(x=window, y=valence, color=cluster)
  ) +
  geom_point() +
  geom_smooth()

# Compute each story's distance from cluster mean
valence_clusters <- data.frame(rbind(
  c("cluster1", NA, NA, filter(mean_valence_trajectories, cluster==1)$valence, NA),
  c("cluster2", NA, NA, filter(mean_valence_trajectories, cluster==2)$valence, NA)
  )) %>% 
  mutate_at(vars(X3:X103), ~as.numeric(as.character(.))) %>% 
  mutate_at(vars(X1), ~as.character(.))

valence_diffs <- valence_centered_wide %>% 
  mutate(ID = as.character(ID)) %>% 
  # Add cluster id to dataset
  mutate(cluster = as.factor(clusters)) %>% 
  # Add mean trajectory values for each cluster
  bind_rows(setNames(valence_clusters, names(.))) %>% 
  # Subtract mean trajectory scores from each story
  mutate_at(
    vars("1":"100"),
    ~case_when(
      cluster==1 ~ abs(. - .[ID=="cluster1"]), 
      cluster==2 ~ abs(. - .[ID=="cluster2"]),
      TRUE ~ .
      )
  ) %>% 
  # Get mean distance from cluster center score for each story
  filter(!ID %in% c("cluster1", "cluster2")) %>% 
  mutate(distance_from_cluster = rowMeans(select(., "1":"100"), na.rm = T)) %>% 
  # Clean up
  mutate("valence_trajectory" = paste0("cluster", clusters)) %>% 
  select(ID, disclosure, storyID, valence_trajectory, distance_from_cluster)

# Model trajectories with a cubic polynomial function
library(lmerTest)

valence_by_window_clustered <- valence_centered_wide %>% 
  mutate(storyID = as.factor(1:nrow(.))) %>% 
  mutate("valence_trajectory" = paste0("cluster", clusters)) %>% 
  pivot_longer(cols="1":"100", names_to="window") %>% 
  mutate(window = as.numeric(as.character(window))) %>% 
  rename(valence = value)

valence_cluster1_mdl <- lmer(
  valence ~ (poly(window, 3, raw=F)||storyID) + poly(window, 3, raw=F),
  data = filter(valence_by_window_clustered, valence_trajectory=="cluster1"),
  control = lmerControl(optimizer = "Nelder_Mead", optCtrl = list(maxfun=2e5))
)
summary(valence_cluster1_mdl)
cbind(stdCoef.merMod(valence_cluster1_mdl), round(coef(summary(valence_cluster1_mdl)), 3))
#sjPlot::tab_model(valence_cluster1_mdl)

valence_cluster2_mdl <- lmer(
  valence ~ (poly(window, 3, raw=F)||storyID) + poly(window, 3, raw=F),
  data = filter(valence_by_window_clustered, valence_trajectory=="cluster2"),
  control = lmerControl(optimizer = "Nelder_Mead", optCtrl = list(maxfun=2e5))
)
summary(valence_cluster2_mdl)
cbind(stdCoef.merMod(valence_cluster2_mdl), round(coef(summary(valence_cluster2_mdl)), 3))
# sjPlot::tab_model(valence_cluster2_mdl)

# Extract each story's deviation from the average cubic coefficient
valence_trajectories <- bind_rows(
  coef(valence_cluster1_mdl)[[1]], 
  coef(valence_cluster2_mdl)[[1]]*(-1) # Flip signs because cluster 2 is inverse cubic
  ) %>% 
  mutate(storyID = as.numeric(as.character(row.names(.)))) %>% 
  arrange(storyID) %>% 
  rename(deviation_from_cubic = "poly(window, 3, raw = F)3") %>% 
  select(storyID, deviation_from_cubic) %>% 
  left_join(valence_diffs, by="storyID") %>% 
  select(ID, disclosure, storyID, valence_trajectory, everything())

# Save data
write_csv(valence_trajectories, paste0(save_data_here, "valence_trajectories_manhattan.csv"))

#########################################################################################
## Run Hierarchical Cluster Analysis on Arousal ----
dist_mat <- dist(arousal_by_window, method = 'manhattan')
polarity_hclust <- hclust(dist_mat, method = 'ward.D')

# Determine ideal number of clusters
plot(polarity_hclust) # dendrogram
fviz_nbclust(arousal_by_window, FUN = hcut, method = "wss") # Elbow plot
fviz_nbclust(arousal_by_window, FUN = hcut, method = "silhouette") # Silhouette plot

# Cut tree
clusters <- cutree(polarity_hclust, k = 2)
table(clusters) # Count number in each cluster

# Add cluster id to dataset
arousal_by_window_clustered <- arousal_centered_wide %>% 
  mutate("arousal_trajectory" = paste0("cluster", clusters)) %>% 
  select(ID, disclosure, arousal_trajectory)

# Save data
write_csv(arousal_by_window_clustered, paste0(save_data_here, "arousal_trajectories.csv"))

# Compute average trajectory for each cluster
arousal_trajectories <- arousal_by_window %>% 
  # Add cluster id to dataset
  mutate(cluster = as.factor(clusters)) %>% 
  # Get mean trajectory for each cluster by computing mean value at each window
  group_by(cluster) %>% 
  summarize_at(
    vars("1":"100"),
    list(~mean(.))
  ) %>% 
  ungroup() %>% 
  # Change data to long form
  pivot_longer(
    cols = "1":"100",
    names_to = "window",
    values_to = "arousal"
  ) %>% 
  mutate_at(
    vars(window, arousal),
    list(~as.numeric(as.character(.)))
  )

# Plot clusters
ggplot(
  arousal_trajectories,
  aes(x=window, y=arousal, color=cluster)
  ) +
  geom_point() +
  geom_smooth()

#########################################################################################