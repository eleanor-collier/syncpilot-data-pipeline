#########################################################################################
# Script to average vocal arousal ratings across disclosures
# Eleanor Collier
# 2/14/23
#########################################################################################

# Set up workspace
library(tidyverse)

get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

#########################################################################################
### Load data ----
valence_ratings_neumdl <- read_csv(paste0(get_data_here, 'vocal_arousal_by_window_1s_neutral_modeling.csv'))

### Average arousal scores across disclosures ----
mean_arousal_ratings <- valence_ratings_neumdl %>% 
  group_by(ID, disclosure) %>% 
  summarize(
    vocal_arousal = mean(arousal_score, na.rm=T),
    vocal_arousal_max = max(arousal_score, na.rm=T),
    vocal_arousal_sd = sd(arousal_score, na.rm=T),
    vocal_arousal_span = max(arousal_score, na.rm=T) - min(arousal_score, na.rm=T),
  ) %>% 
  ungroup() %>% 
  mutate_all(~na_if(., -Inf))

# Get rid of Inf issue

# Save
write_csv(mean_arousal_ratings, paste0(save_data_here, 'vocal_arousal.csv'))
