#########################################################################################
# Annotate acoustic features with when speaker is speaking based on transcript timestamps
# Eleanor Collier
# 9/2/22
#########################################################################################

# Set up workspace
library(tidyverse)
library(vroom)

# Load data
get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"

transcripts_by_word <- vroom(paste0(get_data_here, 'transcripts_by_word.csv'))

#########################################################################################
## Generate speaking labels for every second based on transcript
transcripts_by_time <- transcripts_by_word %>% 
  # Make a temporary word ID column
  mutate(wordID = 1:nrow(.)) %>% 
  
  # Make a column called 'time' that includes start and stoptime for every word
  pivot_longer(
    cols = c(start_time, end_time),
    names_to = "word_timelabel",
    values_to = "time"
  ) %>% 
  select(-word_timelabel) %>% 
  
  # Expand 'time' to include every 0.01 second between start and stop
  group_by(ID, disclosure, wordID) %>% 
  complete(time = seq.int(
    from=time[1],
    to=time[2],
    by=0.01
  )) %>% 
  ungroup() %>% 
  select(-text, -wordID) %>%
  
  # Create is_speaking column and label all rows as TRUE
  mutate(is_speaking = TRUE) %>% 

  # Delete duplicate time rows
  group_by(ID, disclosure) %>% 
  distinct(time, .keep_all=T) %>% 
  ungroup() %>% 

  # Aggregate to nearest second, rounded down
  mutate(time = floor(time)) %>% 
  group_by(ID, disclosure, time) %>% 
  summarize(is_speaking = first(is_speaking)) %>% 
  ungroup()

# Save data
write_csv(transcripts_by_time, paste0(save_data_here, "speaking_labels.csv"))

