#########################################################################################
# Script to average disclosure acoustic features across each disclosure
# Eleanor Collier
# 11/01/21
#########################################################################################

# Set up workspace
library(tidyverse)
library(psych)
library(factoextra)

get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

#########################################################################################
## Average acoustic features across each disclosure ----
# Load data
acoustic_features_by_time <- read_csv(paste0(get_data_here, "acoustic_features_by_window_1s.csv"))
speaking_labels <- read_csv(paste0(get_data_here, "speaking_labels.csv"))

# Filter out moments when participants were not speaking
acoustic_features_by_time <- acoustic_features_by_time %>% 
  mutate(ID = as.double(ID)) %>% 
  # Set values for moments of silence to NA
  left_join(speaking_labels, by=c('ID', 'disclosure', 'time')) %>% 
  mutate_at(vars(pitch:f4), ~case_when(
    is_speaking!=TRUE ~ NA_real_, 
    is_speaking==TRUE ~ .
  )) %>% 
  # Set pitch to NA when pitch = 0
  mutate_at(vars(pitch), ~na_if(., 0))
  
# Get mean values of features across disclosures (only including instances of speech)
mean_acoustic_features <- acoustic_features_by_time %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:f4),
    ~ mean(., na.rm=T)
  ) %>% 
  ungroup()

# Get standard deviations of acoustic features (only including instances of speech)
sd_acoustic_features <- acoustic_features_by_time %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:f4),
    ~ sd(., na.rm=T)
  ) %>% 
  ungroup() %>% 
  rename_at(vars(pitch:f4), ~paste0(., "_sd"))

# Get max acoustic features (only including instances of speech)
max_acoustic_features <- acoustic_features_by_time %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:shimmer),
    ~ max(., na.rm=T)
  ) %>% 
  mutate_at(vars(pitch:shimmer), ~na_if(., -Inf)) %>% 
  rename_at(vars(pitch:shimmer), ~paste0(., "_max")) %>% 
  ungroup()

# Get span of acoustic features (only including instances of speech)
span_acoustic_features <- acoustic_features_by_time %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(
    vars(pitch:shimmer),
    ~ max(., na.rm=T) - min(., na.rm=T)
  ) %>% 
  mutate_at(vars(pitch:shimmer), ~na_if(., -Inf)) %>% 
  rename_at(vars(pitch:shimmer), ~paste0(., "_span")) %>% 
  ungroup()

# Combine all features into one dataset
acoustic_features <- mean_acoustic_features %>% 
  left_join(sd_acoustic_features, by=c("ID", "disclosure")) %>% 
  left_join(max_acoustic_features, by=c("ID", "disclosure")) %>% 
  left_join(span_acoustic_features, by=c("ID", "disclosure"))

## Save data ----
write_csv(acoustic_features, paste0(save_data_here, "acoustic_features.csv"))



