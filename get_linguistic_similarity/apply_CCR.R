#########################################################################################
# Get semantic similarity of disclosures using CCR
# Genesis Garza Morales & Eleanor Collier
# 3/29/23
#########################################################################################
# Load packages
# install.packages("devtools")
# devtools::install_github("tomzhang255/CCR")
library(tidyverse)
library(CCR)
ccr_setup()

# Paths to data
# get_data_here  <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
# save_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
get_data_here  <- '/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure'
save_data_here <- '/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure'

# Get list of transcript row files to apply CCR to
transcript_row_names <- list.files(
  path = paste0(get_data_here,"/CCR_tmp"),
  pattern = "transcript_row*",
  full.names = TRUE
)

#########################################################################################
## Apply CCR to each transcript row ----
CCR_all_output_pos <- data.frame()
CCR_all_output_neu <- data.frame()
CCR_all_output_neg <- data.frame()
for (transcript_row_name in transcript_row_names) {
  
  # Select correct group data csv based on disclosure valence
  disclosure_code = read.csv(transcript_row_name)$disclosure[1]
  if (disclosure_code %in% c('pos1', 'pos2')) {
    group_data <- paste0(get_data_here,"/transcripts_pos.csv")
  } else if (disclosure_code %in% c('neu1', 'neu2')) {
    group_data <- paste0(get_data_here,"/transcripts_neu.csv")
  } else if (disclosure_code %in% c('neg1', 'neg2')) {
    group_data <- paste0(get_data_here,"/transcripts_neg.csv")
  }
  
  # Apply CCR
  CCR_transcript_row_output <- ccr_wrapper(
    data_file = transcript_row_name,
    data_col = "text",
    q_file = group_data,
    q_col = "text",
    model = "all-MiniLM-L6-v2"
  )
  
  # Bind output to correct group dataframe based on disclosure valence
  if (disclosure_code %in% c('pos1', 'pos2')) {
    CCR_all_output_pos <- bind_rows(CCR_all_output_pos, CCR_transcript_row_output)
  } else if (disclosure_code %in% c('neu1', 'neu2')) {
    CCR_all_output_neu <- bind_rows(CCR_all_output_neu, CCR_transcript_row_output)
  } else if (disclosure_code %in% c('neg1', 'neg2')) {
    CCR_all_output_neg <- bind_rows(CCR_all_output_neg, CCR_transcript_row_output)
  }
  
  print(paste("Ran CCR on", transcript_row_name))
}

# write and save csv
write_csv(CCR_all_output_pos, paste0(save_data_here,"/CCR_tmp/CCR_output_pos_raw.csv"))
write_csv(CCR_all_output_neu, paste0(save_data_here,"/CCR_tmp/CCR_output_neu_raw.csv"))
write_csv(CCR_all_output_neg, paste0(save_data_here,"/CCR_tmp/CCR_output_neg_raw.csv"))

## Convert data to workable format for calculating means ----
# Positive disclosures
CCR_long_pos <- CCR_all_output_pos %>% 
  # Rename columns with ID & disclosure being compared
  rename_at(vars(matches('sim_item')), ~paste(CCR_all_output_pos$ID, CCR_all_output_pos$disclosure, sep = "_")) %>% 
  # Convert to long format
  pivot_longer(cols = matches('pos'), names_to = 'ID_disclosure_compared', values_to = 'CCR_score') %>% 
  # Split ID_disclosure_compared columns into ID and disclosure
  separate(col = ID_disclosure_compared, into = c('ID_compared', 'disclosure_compared'), sep='_')

# Neutral disclosures
CCR_long_neu <- CCR_all_output_neu %>% 
  # Rename columns with ID & disclosure being compared
  rename_at(vars(matches('sim_item')), ~paste(CCR_all_output_neu$ID, CCR_all_output_neu$disclosure, sep = "_")) %>% 
  # Convert to long format
  pivot_longer(cols = matches('neu'), names_to = 'ID_disclosure_compared', values_to = 'CCR_score') %>% 
  # Split ID_disclosure_compared columns into ID and disclosure
  separate(col = ID_disclosure_compared, into = c('ID_compared', 'disclosure_compared'), sep='_')

# Negative disclosures
CCR_long_neg <- CCR_all_output_neg %>% 
  # Rename columns with ID & disclosure being compared
  rename_at(vars(matches('sim_item')), ~paste(CCR_all_output_neg$ID, CCR_all_output_neg$disclosure, sep = "_")) %>% 
  # Convert to long format
  pivot_longer(cols = matches('neg'), names_to = 'ID_disclosure_compared', values_to = 'CCR_score') %>% 
  # Split ID_disclosure_compared columns into ID and disclosure
  separate(col = ID_disclosure_compared, into = c('ID_compared', 'disclosure_compared'), sep='_')

## Get group similarity mean scores ----
# Positive disclosures
CCR_group_means_pos <- CCR_long_pos %>% 
  # Set value to NA when participant is being compared to self
  mutate(CCR_score = ifelse(ID==ID_compared, NA_real_, CCR_score)) %>% 
  # For each disclosure, get average similarity to all disclosures of other participants
  group_by(ID, disclosure) %>% 
  summarise(CCR_score = mean(CCR_score, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(CCR_score = replace(CCR_score, is.nan(CCR_score), NA_real_))

# Neutral disclosures
CCR_group_means_neu <- CCR_long_neu %>% 
  # Set value to NA when participant is being compared to self
  mutate(CCR_score = ifelse(ID==ID_compared, NA_real_, CCR_score)) %>% 
  # For each disclosure, get average similarity to all disclosures of other participants
  group_by(ID, disclosure) %>% 
  summarise(CCR_score = mean(CCR_score, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(CCR_score = replace(CCR_score, is.nan(CCR_score), NA_real_))

# Negative disclosures
CCR_group_means_neg <- CCR_long_neg %>% 
  # Set value to NA when participant is being compared to self
  mutate(CCR_score = ifelse(ID==ID_compared, NA_real_, CCR_score)) %>% 
  # For each disclosure, get average similarity to all disclosures of other participants
  group_by(ID, disclosure) %>% 
  summarise(CCR_score = mean(CCR_score, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(CCR_score = replace(CCR_score, is.nan(CCR_score), NA_real_))

# Combine pos, neu, & neg
CCR_group_means <- bind_rows(CCR_group_means_pos, CCR_group_means_neu, CCR_group_means_neg) %>% 
  rename(CCR_group_score = CCR_score) %>% 
  arrange(ID, disclosure)
  
## Get partner similarity mean scores ----
# Positive disclosures
CCR_partner_means_pos <- CCR_long_pos %>%
  # Get partner ID
  mutate(
    partner_ID = case_when(
      (ID %% 2 == 1) ~ (ID + 1),
      (ID %% 2 == 0) ~ (ID - 1)
    )
  ) %>% 
  # Select only rows where participant is being compared to partner
  filter(ID_compared==partner_ID) %>% 
  # For each disclosure, get average similarity to partner's disclosures
  group_by(ID, disclosure) %>% 
  summarise(CCR_score = mean(CCR_score, na.rm = T)) %>% 
  ungroup() %>%
  # Set NaN to NA
  mutate(CCR_score = replace(CCR_score, is.nan(CCR_score), NA_real_))

# Neutral disclosures
CCR_partner_means_neu <- CCR_long_neu %>% 
  # Get partner ID
  mutate(
    partner_ID = case_when(
      (ID %% 2 == 1) ~ (ID + 1),
      (ID %% 2 == 0) ~ (ID - 1)
    )
  ) %>% 
  # Select only rows where participant is being compared to partner
  filter(ID_compared==partner_ID) %>% 
  # For each disclosure, get average similarity to partner's disclosures
  group_by(ID, disclosure) %>% 
  summarise(CCR_score = mean(CCR_score, na.rm = T)) %>% 
  ungroup() %>%
  # Set NaN to NA
  mutate(CCR_score = replace(CCR_score, is.nan(CCR_score), NA_real_))

# Negative disclosures
CCR_partner_means_neg <- CCR_long_neg %>% 
  # Get partner ID
  mutate(
    partner_ID = case_when(
      (ID %% 2 == 1) ~ (ID + 1),
      (ID %% 2 == 0) ~ (ID - 1)
    )
  ) %>% 
  # Select only rows where participant is being compared to partner
  filter(ID_compared==partner_ID) %>% 
  # For each disclosure, get average similarity to partner's disclosures
  group_by(ID, disclosure) %>% 
  summarise(CCR_score = mean(CCR_score, na.rm = T)) %>% 
  ungroup() %>%
  # Set NaN to NA
  mutate(CCR_score = replace(CCR_score, is.nan(CCR_score), NA_real_))

# Combine pos, neu, & neg
CCR_partner_means <- bind_rows(CCR_partner_means_pos, CCR_partner_means_neu, CCR_partner_means_neg) %>% 
  rename(CCR_partner_score = CCR_score) %>% 
  arrange(ID, disclosure)

## Combine & save group means & partner means ----
CCR_combined_scores <- full_join(CCR_group_means, CCR_partner_means, by=c('ID', 'disclosure'))

# write and save csv
write_csv(CCR_combined_scores, paste0(save_data_here,"/CCR_scores.csv"))

#########################################################################################
# OLD: Get similarity to partner's combined disclosures ----
#applying CCR to each transcript row
CCR_all_output <- data.frame()
for (transcript_row_name in transcript_row_names) {
  CCR_transcript_row_output <- ccr_wrapper(
    data_file = transcript_row_name,
    data_col = "text",
    q_file = transcript_row_name,
    q_col = "partner_combined_disclosures",
    model = "all-MiniLM-L6-v2"
  )
  CCR_all_output <- bind_rows(CCR_all_output, CCR_transcript_row_output)
  print(paste("Ran CCR on", transcript_row_name))
  print(paste("Number of rows in CCR_all_output:", nrow(CCR_all_output)))
}

CCR_all_output_cleaned <- CCR_all_output

# write and save csv
write_csv(CCR_all_output_cleaned, paste0(save_data_here,"/CCR_output_partner.csv"))
