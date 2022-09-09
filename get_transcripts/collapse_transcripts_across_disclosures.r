#########################################################################################
# Script to collapse transcripts across each disclosure
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


