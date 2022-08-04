#########################################################################################
# Script to average human prosody ratings across raters
# Eleanor Collier
# 7/29/22
#########################################################################################

# Set up workspace
library(tidyverse)

get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/processing_pipeline/get_prosody/Inquisit_rate_training_data_RAs"
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/processing_pipeline/get_prosody/training_data/"

#########################################################################################
### Load data ----
# Get file names
raw_files <- list.files(path = get_data_here, full.names = T, recursive = T)
raw_files_valence <- raw_files[str_detect(test, 'prosody_v')]
raw_files_arousal <- raw_files[str_detect(test, 'prosody_a')]

# Append data files to each other
valence_ratings_raw <- data.frame()
for(file in raw_files_valence){
  valence_ratings_raw <- bind_rows(valence_ratings_raw, read_csv(file))
}
arousal_ratings_raw <- data.frame()
for(file in raw_files_arousal){
  arousal_ratings_raw <- bind_rows(arousal_ratings_raw, read_csv(file))
}

### Process data ----
# VALENCE
valence_ratings_processed <- valence_ratings_raw %>%
  ## Clean data
  select(subject, timeofrating, valence_rating, videoname) %>% 
  # Change column names
  rename(rater=subject, time=timeofrating, disclosure=videoname) %>% 
  # Change time of rating from milliseconds to seconds & round to nearest second
  mutate_at(vars(time), ~round(./1000)) %>% 
  # Make valence column numeric & scale to 0-100
  mutate_at(vars(valence_rating), ~as.numeric(gsub("pct", "", .))*2) %>% 
  
  ## Standardize timeseries
  # For seconds with multiple ratings, average to get one rating per second
  group_by(rater, disclosure, time) %>%
  summarize_at(vars(valence_rating), ~mean(., na.rm = T)) %>% 
  # Make sure all timeseries start with 0 and end with 180
  group_by(rater, disclosure) %>%
  complete(time = full_seq(0:180, 1)) %>%
  ungroup() %>%
  # Create rows for all missing time points with explicit NAs
  complete(rater, disclosure, time, fill = list(valence_rating = NA)) %>%
  # Fill in missing values based on previous values
  group_by(rater, disclosure) %>%
  fill(valence_rating) %>%
  replace_na(list(valence_rating = 50)) #For NAs at early time points, use valence rating of 50

# AROUSAL
arousal_ratings_processed <- arousal_ratings_raw %>%
  ## Clean data
  select(subject, timeofrating, valence_rating, videoname) %>% 
  # Change column names
  rename(rater=subject, time=timeofrating, disclosure=videoname, arousal_rating=valence_rating) %>% 
  # Change time of rating from milliseconds to seconds & round to nearest second
  mutate_at(vars(time), ~round(./1000)) %>% 
  # Make valence column numeric & scale to 0-100
  mutate_at(vars(arousal_rating), ~as.numeric(gsub("pct", "", .))*2) %>% 
  
  ## Standardize timeseries
  # For seconds with multiple ratings, average to get one rating per second
  group_by(rater, disclosure, time) %>%
  summarize_at(vars(arousal_rating), ~mean(., na.rm = T)) %>% 
  # Make sure all timeseries start with 0 and end with 180
  group_by(rater, disclosure) %>%
  complete(time = full_seq(0:180, 1)) %>%
  ungroup() %>%
  # Create rows for all missing time points with explicit NAs
  complete(rater, disclosure, time, fill = list(arousal_rating = NA)) %>%
  # Fill in missing values based on previous values
  group_by(rater, disclosure) %>%
  fill(arousal_rating) %>%
  replace_na(list(arousal_rating = 50)) #For NAs at early time points, use arousal rating of 50
  

### Average prosody ratings across disclosures ----
# VALENCE
mean_valence_ratings <- valence_ratings_processed %>% 
  group_by(disclosure, time) %>% 
  summarize(
    valence = mean(valence_rating, na.rm=T)
  ) %>% 
  ungroup()

# AROUSAL
mean_arousal_ratings <- arousal_ratings_processed %>% 
  group_by(disclosure, time) %>% 
  summarize(
    arousal = mean(arousal_rating, na.rm=T)
  ) %>% 
  ungroup()

# Combine into a single data file and save
prosody_human_rated <- left_join(mean_valence_ratings, mean_arousal_ratings, by=c('disclosure', 'time'))
write_csv(prosody_human_rated, paste0(save_data_here, 'prosody_human_rated.csv'))

### Inspect prosody ratings ----
## Plot prosody ratings
ggplot(data=prosody_human_rated, aes(x=time, y=valence, color=disclosure)) +
  geom_smooth()

ggplot(data=prosody_human_rated, aes(x=time, y=arousal, color=disclosure)) +
  geom_smooth()

## Calculate interrater reliability
library(psych)
library(broom)
library(ggpubr)

# VALENCE
valence_ratings_wide <- pivot_wider(
  valence_ratings_processed,
  names_from = rater,
  values_from = valence_rating
)
valence_alphas <- valence_ratings_wide %>% 
  select(-time) %>% 
  nest(data = c(Katelynn, NivaM, Yuritza)) %>% 
  mutate(alpha_info = map(data, ~alpha(.x, check.keys=F))) %>% 
  mutate(alpha = map_dbl(alpha_info, ~.x[[1]][[1]]))
ggdensity(valence_alphas$alpha)
# There are no alphas above 0.80

# AROUSAL
arousal_ratings_wide <- pivot_wider(
  arousal_ratings_processed,
  names_from = rater,
  values_from = arousal_rating
)
arousal_alphas <- arousal_ratings_wide %>% 
  select(-time) %>% 
  nest(data = c(Katelynn, Niva, Yuritza)) %>% 
  mutate(alpha_info = map(data, ~alpha(.x, check.keys=F))) %>% 
  mutate(alpha = map_dbl(alpha_info, ~.x[[1]][[1]]))
ggdensity(arousal_alphas$alpha)
# Only 1 alpha is above 0.80

# In conclusion...the interrater reliability is pretty horrific. We may need to
# get a bunch of raters to rate this data
