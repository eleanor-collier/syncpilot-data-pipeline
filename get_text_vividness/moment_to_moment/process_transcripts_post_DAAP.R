# Process output files from DAAP analysis of transcripts
# Eleanor Collier
# 1/6/2022
#########################################################################################

#Set up workspace
library(tidyverse)

get_data_here   <- "~/Documents/DAAP09/Project/DATA/"
save_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"

#########################################################################################
# Load data
text_vividness_raw <- read_csv(paste0(get_data_here, "ProjectAG2.csv"))

# Process data
text_vividness <- text_vividness_raw %>% 
  # Delete unnecessary headings
  slice(-seq(0, nrow(.), 2)) %>% 
  # Convert vividness scores to numeric & rename
  mutate_at(vars(MWRAD, MHWRAD, MSenS), ~as.numeric(as.character(.))) %>% 
  rename(
    vividness = MWRAD,
    vividness_aboveNeu = MHWRAD,
    sensory_somatic = MSenS
  ) %>% 
  # Generate subject ID, disclosure, & time columns from file name column
  mutate(
    ID = str_extract(File, "(?<=P)([:digit:]+)"),
    disclosure = str_extract(File, "(?<=D)([:alnum:[^T]+]+)"),
    time = str_extract(File, "(?<=T)([:digit:]+)")
  ) %>% 
  mutate_at(vars(ID, time), ~as.numeric(as.character(.))) %>% 
  arrange(ID, disclosure, time) %>% 
  select(ID, disclosure, time, vividness, vividness_aboveNeu, sensory_somatic)
  

# Save data
write_csv(text_vividness, paste0(save_data_here, "transcripts_by_window_DAAP.csv"))
