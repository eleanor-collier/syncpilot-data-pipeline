#########################################################################################
# Analyze valence and arousal in disclosers' language using VADER
# Eleanor Collier
# 1/5/22
#########################################################################################

# Set up workspace
library(tidyverse)
library(vader)

#########################################################################################
## MOMENT TO MOMENT ----
# Load data
get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"

transcripts_by_window <- read_csv(paste0(get_data_here, "transcripts_by_window.csv"))

# Clean up use of the word "like" as it throws off valence scores
transcripts_by_window$text <- gsub("like", "", transcripts_by_window$text, ignore.case=T)

# Get valence using vader's normalized, weighted compound score for valence
vader_scores <- transcripts_by_window$text %>% 
  vader_df(text) %>% 
  rename(vader_valence = compound) %>% 
  # Get overall arousal (valence agnostic) by summing vader's valence score for each word (abs value)
  mutate(
    vader_arousal = sapply(strsplit(gsub("\\{|\\}", "", word_scores), ","), function(x) sum(abs(as.numeric(x))))
  ) %>% 
  select(-c(pos, neu, neg, but_count, text))

# Bind with original data cols
transcripts_by_window_vader <- bind_cols(transcripts_by_window, vader_scores)

# Save data
transcripts_by_window_vader <- transcripts_by_window_vader %>% select(-word_scores)
write_csv(transcripts_by_window_vader, paste0(save_data_here, "transcripts_by_window_vader.csv"))

## MEAN BY DISCLOSURE ----
# Load data
get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

transcripts <- read_csv(paste0(get_data_here, "transcripts.csv"))

# Clean up use of the word "like" as it throws off valence scores
transcripts$text <- gsub("like", "", transcripts$text, ignore.case=T)

# Get valence using vader's normalized, weighted compound score for valence
vader_scores <- transcripts$text %>% 
  vader_df(text) %>% 
  rename(
    vader_valence = compound,
    vader_posemo = pos,
    vader_negemo = neg
    ) %>% 
  # Get overall arousal (valence agnostic) by summing vader's valence score for each word (abs value)
  # and dividing by total number of words
  mutate(
    n_words = sapply(strsplit(gsub("\\{|\\}", "", word_scores), ","), function(x) length(x)),
    vader_arousal = sapply(strsplit(gsub("\\{|\\}", "", word_scores), ","), function(x) sum(abs(as.numeric(x))))/n_words
  ) %>% 
  select(-c(neu, but_count, text))

# Bind with original data cols
transcripts_vader <- bind_cols(transcripts, vader_scores)

# Save data
transcripts_vader <- transcripts_vader %>% select(-word_scores)
write_csv(transcripts_vader, paste0(save_data_here, "transcripts_vader.csv"))

