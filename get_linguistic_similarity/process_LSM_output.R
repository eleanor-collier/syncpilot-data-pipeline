##########################################################
# process LSM output
# Genesis Garza Morales
# 04/11/23
##########################################################
# load packages ----
library(tidyverse)

# load data ----
get_data_here  <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
save_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
LSM_output     <- read_csv(paste0(get_data_here,"/LSM_output.csv"))

# processing LSM data ----
processed_LSM <- LSM_output %>%
  #group ID column split into ID and disclosure
  separate(col = GroupID, into = c('ID', 'disclosure'), sep='_') %>%
  #get rid of columns
  select(-c(Segment, WC.Total)) %>%
  #rename 'LSM' column to 'LSM_score'
  rename(LSM_score = LSM)

# write and save CSV ----
write_csv(processed_LSM, paste0(save_data_here,"/LSM_output_processed.csv"))