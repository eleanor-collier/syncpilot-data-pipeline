#########################################################################################
# Script to create verbal-nonverbal convergence scores
# Eleanor Collier
# 1/27/22
#########################################################################################

# Set up workspace
library(tidyverse)
library(roll)
library(DescTools)

get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"

# Load data
accoustic_data <- read_csv(paste0(get_data_here, "accoustic_features_by_time.csv")) %>% 
  # Code for speech and silence
  mutate(sound = case_when(pitch > 0 ~ 'speaking', pitch == 0 ~ 'silence')) #%>% 
  # "Smudge" accoustic features across the same window used for VADER scores using a moving average
  # First set values for moments of silence to NA
  # mutate_at(vars(pitch:f4), ~case_when(sound=='silence' ~ NA, sound=='speaking' ~ .)) %>% 
  # group_by(ID, disclosure) %>%
  # mutate_at(vars(pitch:f4), ~roll_mean(., width = 15, min_obs = 1, complete_obs = T)) %>%
  # ungroup()

VADER_data     <- read_csv(paste0(get_data_here, 'transcripts_by_window_5s_vader.csv')) %>% distinct()

# Count median number of words per window
# median(lengths(strsplit(VADER_data$text, "\\s+")), na.rm=T)

# 2s: 5
# 3s: 8
# 4s: 8
# 5s: 13
# 6s: 15
# 7s: 18
# 8s: 21
# 9s: 23
# 10s: 26

#########################################################################################
## Mean by disclosure ----

#NOTE: Actually, we may want to do this with moving average accoustic features, since
# the linguistic scores are calculated based on the past 15 seconds rather than on the
# one-second timespan of the accoustic features. If we do this, then we'll want to also
# do that for the moment-to-moment convergence scores as well, and we won't need to set
# nonspeech moments to NA because the whole thing will be sort of smeared across time

verbal_nonverbal_convergence <-
  inner_join(VADER_data, accoustic_data, by=c('ID', 'disclosure', 'time')) %>% 
  # Filter for moments of speech only
  filter(sound=="speaking") %>%
  # Get correlation between verbal and nonverbal features
  group_by(ID, disclosure) %>% 
  summarize(
    arousal_pitch_conv = cor(vader_arousal, pitch, use="pairwise.complete.obs"),
    arousal_f1_conv = cor(vader_arousal, f1, use="pairwise.complete.obs"),
    valence_f2_conv = cor(vader_valence, f2, use="pairwise.complete.obs"),
    posemo_f2_conv = cor(vader_posemo, f2, use="pairwise.complete.obs"),
    negemo_f2_conv = cor(vader_negemo, f2, use="pairwise.complete.obs")
  ) %>% 
  ungroup() %>% 
  # Apply Fisher R to Z transformation
  mutate_at(vars(matches("conv")), ~FisherZ(.)) %>%
  # Get rid of Inf values (really only one recording that got cut short)
  filter(valence_f2_conv!=Inf)

# Save data
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"
write_csv(verbal_nonverbal_convergence, paste0(save_data_here, "verbal_nonverbal_convergence.csv"))

#########################################################################################
## Moment to moment ----
verbal_nonverbal_convergence_by_window <-
  inner_join(VADER_data, accoustic_data, by=c('ID', 'disclosure', 'time')) %>% 
  # Set values of disclosure features to NA for moments of silence
  mutate_at(
    vars(vader_arousal, vader_valence, pitch, f1, f2),
    ~case_when(
      sound=='speaking' ~ .
      )
  ) %>% 
  mutate(
    arousal_pitch_conv = roll_cor(vader_arousal, pitch, width=15, min_obs=3, na_restore=T),
    arousal_f1_conv = roll_cor(vader_arousal, f1, width=15, min_obs=3, na_restore=T),
    valence_f2_conv = roll_cor(vader_valence, f2, width=15, min_obs=3, na_restore=T)
  )


# Save data
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
write_csv(verbal_nonverbal_convergence_by_window, paste0(save_data_here, "verbal_nonverbal_convergence_by_window.csv"))

