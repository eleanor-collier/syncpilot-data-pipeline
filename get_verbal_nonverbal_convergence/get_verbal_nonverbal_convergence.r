#########################################################################################
# Script to create verbal-nonverbal convergence scores
# Eleanor Collier
# 1/27/22
#########################################################################################

# Set up workspace
library(tidyverse)
library(roll)
library(DescTools)
library(lmerTest)
library(ggpubr)

get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

# Load speaking labels data
speaking_labels <- read_csv(paste0(get_data_here, "speaking_labels.csv")) %>% 
  mutate(ID = as.double(ID))

# Load acoustic features data ----
acoustic_data <- read_csv(paste0(get_data_here, "acoustic_features_by_window_1s.csv")) %>%
  mutate(ID = as.double(ID)) %>% 
  # Code for speech and silence using transcript-based labels
  left_join(speaking_labels, by=c('ID', 'disclosure', 'time')) %>% 
  # Set values for moments of silence to NA
  mutate_at(vars(pitch:f4), ~case_when(
    is_speaking!=TRUE ~ NA_real_, 
    is_speaking==TRUE ~ .
  )) %>%
  # Set pitch to NA when pitch = 0
  mutate_at(vars(pitch), ~na_if(., 0)) %>% 
  # Get pitch sd across 5s window for each second
  group_by(ID, disclosure) %>%
  mutate(
    pitch_sd = roll_sd(pitch, width = 5, min_obs = 1, complete_obs = T),
    intensity_sd = roll_sd(intensity, width = 5, min_obs = 1, complete_obs = T)
  ) %>% 
  ungroup() %>% 
  # "Smudge" acoustic features across the same window used for VADER scores using a moving average
  group_by(ID, disclosure) %>%
  mutate_at(vars(pitch:f4), ~roll_mean(., width = 5, min_obs = 1, complete_obs = T)) %>%
  ungroup()

# Load vocal arousal data ----
vocal_data <- read_csv(paste0(get_data_here, "vocal_arousal_by_window_1s_global_modeling.csv")) %>% 
  # Code for speech and silence using transcript-based labels
  left_join(speaking_labels, by=c('ID', 'disclosure', 'time')) %>% 
  # Code for speech and silence using pitch-based labels
  # left_join(acoustic_data %>% select(ID, disclosure, time, sound), by=c(c('ID', 'disclosure', 'time'))) %>% 
  # Set values for moments of silence to NA
  mutate_at(vars(arousal_score), ~case_when(
    is_speaking!=TRUE ~ NA_real_, 
    is_speaking==TRUE ~ .
    )) %>%
  # "Smudge" vocal arousal across the same window used for VADER scores using a moving average
  group_by(ID, disclosure) %>%
  mutate_at(vars(arousal_score), ~roll_mean(., width = 5, min_obs = 1, complete_obs = T)) %>%
  ungroup()

# Load VADER scores ----
VADER_data <- read_csv(paste0(get_data_here, 'transcripts_by_window_5s_vader.csv')) %>% 
  distinct() %>% 
  # Get number of words per window
  mutate(nwords = lengths(strsplit(text, "\\s+")), na.rm=T)

# Count median number of words per window ----
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
## Compute mean convergence by disclosure ----
# RAW ACOUSTIC FEATURES ----
verbal_nonverbal_convergence <- VADER_data %>% 
  left_join(vocal_data, by=c('ID', 'disclosure', 'time')) %>% select(-is_speaking) %>% 
  left_join(acoustic_data, by=c('ID', 'disclosure', 'time')) %>% 
  # Filter for moments of speech only
  filter(is_speaking==TRUE) %>%
  # Get correlation between verbal and nonverbal features
  group_by(ID, disclosure) %>% 
  summarize(
    arousal_conv = cor(vader_arousal, arousal_score, use="pairwise.complete.obs"),
    arousal_pitchSD_conv = cor(vader_arousal, pitch_sd, use="pairwise.complete.obs"),
    arousal_jitter_conv = cor(vader_arousal, jitter, use="pairwise.complete.obs"),
    arousal_speechrate_conv = cor(vader_arousal, nwords, use="pairwise.complete.obs"),
    valence_jitter_conv = cor(vader_valence, jitter, use="pairwise.complete.obs"),
    negemo_jitter_conv = cor(vader_negemo, jitter, use="pairwise.complete.obs"),
    posemo_jitter_conv = cor(vader_posemo, jitter, use="pairwise.complete.obs"),
    valence_speechrate_conv = cor(vader_valence, nwords, use="pairwise.complete.obs"),
    posemo_speechrate_conv = cor(vader_posemo, nwords, use="pairwise.complete.obs"),
    negemo_speechrate_conv = cor(vader_negemo, nwords, use="pairwise.complete.obs")
  ) %>% 
  ungroup() %>% 
  # Apply Fisher R to Z transformation
  mutate_at(vars(matches("conv")), ~FisherZ(.))
  
# Look at distribution of convergence scores
# ggdensity(verbal_nonverbal_convergence$arousal_conv, na.rm=T)

# Save data
write_csv(verbal_nonverbal_convergence, paste0(save_data_here, "verbal_nonverbal_convergence.csv"))

# Check if linguistic & vocal arousal scores correlate on average ----
test_data <- inner_join(VADER_data, vocal_data, by=c('ID', 'disclosure', 'time')) %>% 
  # Filter for moments of speech only
  filter(is_speaking==TRUE) %>% 
  # Center vars within stories
  group_by(ID, disclosure) %>% 
  mutate_at(
    vars(arousal_score), 
    ~scale(., center=T, scale=F)
  ) %>% 
  ungroup()

mdl <- lmer(
  vader_arousal ~ arousal_score + (1|ID/disclosure),
  data = test_data
)
summary(mdl)

#########################################################################################
## Moment to moment ----
# Note: This code is old/not in use, but it's an example of how to compute moment-to-moment convergence
verbal_nonverbal_convergence_by_window <-
  inner_join(VADER_data, acoustic_data, by=c('ID', 'disclosure', 'time')) %>% 
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

