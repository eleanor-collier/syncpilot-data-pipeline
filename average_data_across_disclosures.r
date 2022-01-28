#########################################################################################
# Script to average disclosure features across each disclosure
# Eleanor Collier
# 11/01/21
#########################################################################################

# Set up workspace
library(tidyverse)

get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

#########################################################################################
## Collapse transcripts by word across each disclosure ----
# Load data
transcripts_by_word <- read_csv(paste0(get_data_here, "transcripts_by_word.csv"))

# Collapse transcripts across disclosures
transcripts <- transcripts_by_word %>% 
  group_by(ID, disclosure) %>% 
  summarise(text = paste(text, collapse=" ")) %>% 
  ungroup()

# Save data
write_csv(transcripts, paste0(save_data_here, "transcripts.csv"))

#########################################################################################
## Average accoustic features across each disclosure ----
# Load data
accoustic_features_by_time <- read_csv(paste0(get_data_here, "accoustic_features_by_time.csv"))

# Average across disclosures (only including instances of speech)
mean_accoustic_features <- accoustic_features_by_time %>% 
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) %>% 
  filter(sound=='speaking') %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:f4),
    ~ mean(., na.rm=T)
  ) %>% 
  ungroup()

# Get max accoustic features (only including instances of speech)
max_accoustic_features <- accoustic_features_by_time %>% 
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) %>% 
  filter(sound=='speaking') %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:shimmer),
    ~ max(., na.rm=T)
  ) %>% 
  rename_at(vars(pitch:shimmer), ~paste0(., "_max")) %>% 
  ungroup()

# Get span of accoustic features (only including instances of speech)
span_accoustic_features <- accoustic_features_by_time %>% 
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) %>% 
  filter(sound=='speaking') %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:intensity),
    ~ max(., na.rm=T) - min(., na.rm=T)
  ) %>% 
  rename_at(vars(pitch:intensity), ~paste0(., "_span")) %>% 
  ungroup()

accoustic_features <- mean_accoustic_features %>% 
  left_join(max_accoustic_features, by=c("ID", "disclosure")) %>% 
  left_join(span_accoustic_features, by=c("ID", "disclosure"))

# Save data
write_csv(accoustic_features, paste0(save_data_here, "accoustic_features.csv"))

#########################################################################################
## Average prosody across each disclosure ----



