#########################################################################################
# Generate text files from transcripts for DAAP analysis
# Eleanor Collier
# 1/6/2022
#########################################################################################

#Set up workspace
library(tidyverse)

get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/moment_to_moment/"
save_data_here  <- "~/Documents/DAAP09/syncpilot_by_moment/"
#save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/processing_pipeline/get_text_vividness/DAAP09/Project/"

#########################################################################################
#Load data
transcripts_by_window <- read_csv(paste0(get_data_here, "transcripts_by_window.csv"))

# Save each row of text to a txt file
for (ID_val in unique(transcripts_by_window$ID)) {
  disclosures = unique(filter(transcripts_by_window, ID==ID_val)$disclosure)
  for (disclosure_val in disclosures) {
    timestamps = unique(filter(transcripts_by_window, ID==ID_val & disclosure==disclosure_val)$time)
    for (time_val in timestamps) {
      text = filter(transcripts_by_window, ID==ID_val & disclosure==disclosure_val & time==time_val)$text
      if (!is.na(text[1])) { #Use first row of text in case of duplicates
        write.table(
          text, 
          file = paste0(save_data_here, "/P", ID_val, "D", disclosure_val, "T", time_val, ".txt"),
          row.names = F,
          col.names = F
        ) 
      }
    }
  }
}
