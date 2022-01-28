#########################################################################################
# Script to create verbal-nonverbal convergence scores
# Eleanor Collier
# 1/27/22
#########################################################################################

# Set up workspace
library(tidyverse)

get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"

# Load data
VADER_data     <- read_csv(paste0(get_data_here, 'transcripts_by_window_vader.csv')) %>% distinct()
accoustic_data <- read_csv(paste0(get_data_here, "accoustic_features_by_time.csv")) %>% 
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) 

#########################################################################################
## Mean by disclosure ----
verbal_nonverbal_convergence <-
  inner_join(VADER_data, accoustic_data, by=c('ID', 'disclosure', 'time')) %>% 
  # Filter for moments of speech only
  filter(sound=="speaking") %>% 
  group_by(ID, disclosure) %>% 
  summarize(
    arousal_pitch_conv = cor(vader_arousal, pitch),
    arousal_f1_conv = cor(vader_arousal, f1),
    valence_f2_conv = cor(vader_valence, f2)
  ) %>% 
  ungroup()

# Save data
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"
write_csv(verbal_nonverbal_convergence, paste0(save_data_here, "verbal_nonverbal_convergence.csv"))

#########################################################################################
## Moment to moment ----
verbal_nonverbal_convergence_by_window <-
  inner_join(VADER_data, accoustic_data, by=c('ID', 'disclosure', 'time')) %>% 
  # Filter for moments of speech only
  filter(sound=="speaking") %>% 
  group_by(ID, disclosure) %>% 
  summarize(
    arousal_pitch_conv = cor(vader_arousal, pitch),
    valence_f2_conv = cor(vader_valence, f2)
  ) %>% 
  ungroup()

# Save data
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
write_csv(verbal_nonverbal_convergence_by_window, paste0(save_data_here, "verbal_nonverbal_convergence_by_window.csv"))

