#########################################################################################
# Generate text files from transcripts for DAAP analysis
# Eleanor Collier
# 1/6/2022
#########################################################################################

# NOTE: Run presimdaap (not predaap), then simdaap (not daap) to get scores for single speakers

#Set up workspace
library(tidyverse)

get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"
#save_data_here  <- "~/Documents/DAAP09/syncpilot_by_disclosure/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/processing_pipeline/get_text_vividness/DAAP09/Project/"

#########################################################################################
#Load data
transcripts <- read_csv(paste0(get_data_here, "transcripts.csv")) %>% distinct()

# Save each row of text to a txt file
for (ID_val in unique(transcripts$ID)) {
  disclosures = unique(filter(transcripts, ID==ID_val)$disclosure)
  for (disclosure_val in disclosures) {
      text = filter(transcripts, ID==ID_val & disclosure==disclosure_val)$text
      if (!is.na(text[1])) { #Use first row of text in case of duplicates
        write.table(
          text, 
          file = paste0(save_data_here, "/P", ID_val, "D", disclosure_val, ".txt"),
          row.names = F,
          col.names = F
        ) 
    }
  }
}

