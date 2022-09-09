#########################################################################################
# Annotate acoustic features with when speaker is speaking based on transcript timestamps
# Eleanor Collier
# 9/2/22
#########################################################################################

# Set up workspace
library(tidyverse)
library(vroom)

# Load data
get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/data/processed/moment_to_moment/"
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/processing_pipeline/get_prosody/data_for_ML/"

transcripts_by_word <- vroom(paste0(get_data_here, 'transcripts_by_word.csv'))
acoustic_features_by_time <- vroom(paste0(get_data_here, 'acoustic_features_by_time.csv'))

#########################################################################################
## Make transcript data joinable to acoustic features data
transcripts_by_time <- transcripts_by_word[1:1000,] %>% 
  # Make a column called 'time' that includes start and stoptime for every word
  pivot_longer(
    cols = c(start_time, end_time),
    names_to = "word_timelabel",
    values_to = "time"
  ) %>% 
  select(-word_timelabel) %>% 
  
  # Expand 'time' to include every 0.01 second between start and stop
  group_by(ID, disclosure, text) %>% 
  complete(time = seq.int(
    from=time[1],
    to=time[2],
    by=0.01
  )) %>% 
  ungroup() %>% 
  select(-text) %>% 
  
  # Create is_speaking column and label all rows as TRUE
  mutate(is_speaking = TRUE) %>% 

  # Delete duplicate time rows
  group_by(ID, disclosure) %>% 
  distinct(time, .keep_all=T) %>% 
  ungroup() 


## Join transcript data to acoustic features data, and set NAs in is_speaking to FALSE


