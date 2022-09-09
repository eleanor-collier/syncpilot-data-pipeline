#########################################################################################
# Script to average disclosure acoustic features across each disclosure
# Eleanor Collier
# 11/01/21
#########################################################################################

# Set up workspace
library(tidyverse)
library(psych)
library(factoextra)

get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

#########################################################################################
## Average acoustic features across each disclosure ----
# Load data
acoustic_features_by_time <- read_csv(paste0(get_data_here, "acoustic_features_by_time.csv"))

# Average across disclosures (only including instances of speech)
mean_acoustic_features <- acoustic_features_by_time %>% 
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) %>% 
  filter(sound=='speaking') %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:f4),
    ~ mean(., na.rm=T)
  ) %>% 
  ungroup()

# Get max acoustic features (only including instances of speech)
max_acoustic_features <- acoustic_features_by_time %>% 
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) %>% 
  filter(sound=='speaking') %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:shimmer),
    ~ max(., na.rm=T)
  ) %>% 
  rename_at(vars(pitch:shimmer), ~paste0(., "_max")) %>% 
  ungroup()

# Get span of acoustic features (only including instances of speech)
span_acoustic_features <- acoustic_features_by_time %>% 
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) %>% 
  filter(sound=='speaking') %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:intensity),
    ~ max(., na.rm=T) - min(., na.rm=T)
  ) %>% 
  rename_at(vars(pitch:intensity), ~paste0(., "_span")) %>% 
  ungroup()

acoustic_features <- mean_acoustic_features %>% 
  left_join(max_acoustic_features, by=c("ID", "disclosure")) %>% 
  left_join(span_acoustic_features, by=c("ID", "disclosure"))

# Run PCA on vocal markers of arousal
gender_data <- read_csv('/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/baseline_data.csv') %>% 
  select(ID, gender) %>% 
  mutate(ID = as.numeric(as.character(ID)))

acoustic_features_for_pca_female <- acoustic_features %>% 
  select(ID, disclosure, pitch_max, pitch_span, intensity_max, f1) %>% 
  left_join(gender_data, by="ID") %>% 
  filter(gender=="Female") %>% 
  drop_na()

acoustic_features_for_pca_male <- acoustic_features %>% 
  select(ID, disclosure, pitch_max, pitch_span, intensity_max, f1) %>% 
  left_join(gender_data, by="ID") %>% 
  filter(gender=="Male") %>% 
  drop_na()

arousal_markers_pca_female <- prcomp(
  acoustic_features_for_pca_female %>% select(-c(ID, disclosure, gender)),
  scale=T, center=T
)

arousal_markers_pca_male <- prcomp(
  acoustic_features_for_pca_male %>% select(-c(ID, disclosure, gender)),
  scale=T, center=T
)

# Explore PCA results
summary(arousal_markers_pca_female)
arousal_markers_pca_female$rotation
summary(arousal_markers_pca_male)
arousal_markers_pca_male$rotation
# fviz_screeplot(arousal_markers_pca, addlabels = TRUE)
# biplot(arousal_markers_pca)
# fviz_contrib(arousal_markers_pca, choice="var", axes=1)

# Add first principal component to the data
arousal_markers_female <- bind_cols(
  "ID"=acoustic_features_for_pca_female$ID, 
  "disclosure"=acoustic_features_for_pca_female$disclosure, 
  "vocal_arousal"=-arousal_markers_pca_female$x[,1]
  )

arousal_markers_male <- bind_cols(
  "ID"=acoustic_features_for_pca_male$ID, 
  "disclosure"=acoustic_features_for_pca_male$disclosure, 
  "vocal_arousal"=arousal_markers_pca_male$x[,1]
)

arousal_markers <- bind_rows(arousal_markers_female, arousal_markers_male)

acoustic_features <- acoustic_features %>% 
  # PCA composite score
  # left_join(arousal_markers, by=c("ID", "disclosure"))
  # Simple average composite score
  mutate(vocal_arousal = rowMeans(select(., pitch_max, pitch_span, intensity_max, f1) %>% scale(.), na.rm=T))

# Save data
write_csv(acoustic_features, paste0(save_data_here, "acoustic_features.csv"))



