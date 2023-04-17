#########################################################################################
# Clean up LSM output and calculate mean similarity to partner and group
# Genesis Garza Morales & Eleanor Collier
# 04/11/23
#########################################################################################
# Load packages
library(tidyverse)

# Load data
# get_data_here  <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
# save_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
get_data_here  <- '/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/LSM_tmp'
save_data_here <- '/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure'

LSM_output_pos <- read_csv(paste0(get_data_here, "/LSM_output_pos_raw.csv"))
LSM_output_neu <- read_csv(paste0(get_data_here, "/LSM_output_neu_raw.csv"))
LSM_output_neg <- read_csv(paste0(get_data_here, "/LSM_output_neg_raw.csv"))

#########################################################################################
## Convert data to workable format for calculating means ----
# Positive disclosures
LSM_full_pos <- LSM_output_pos %>%
  # Split ID_disclosure columns into ID and disclosure
  separate(col = Person.1, into = c('ID', 'disclosure'), sep='_') %>% 
  separate(col = Person.2, into = c('ID_compared', 'disclosure_compared'), sep='_') %>% 
  # Expand dataset to include full comparison matrix, not just lower triangle
  bind_rows(
    LSM_output_pos %>%
      # Split ID_disclosure columns into ID and disclosure
      separate(col = Person.1, into = c('ID_compared', 'disclosure_compared'), sep='_') %>% 
      separate(col = Person.2, into = c('ID', 'disclosure'), sep='_')
  )

# Neutral disclosures
LSM_full_neu <- LSM_output_neu %>%
  # Split ID_disclosure columns into ID and disclosure
  separate(col = Person.1, into = c('ID', 'disclosure'), sep='_') %>% 
  separate(col = Person.2, into = c('ID_compared', 'disclosure_compared'), sep='_') %>% 
  # Expand dataset to include full comparison matrix, not just lower triangle
  bind_rows(
    LSM_output_neu %>%
      # Split ID_disclosure columns into ID and disclosure
      separate(col = Person.1, into = c('ID_compared', 'disclosure_compared'), sep='_') %>% 
      separate(col = Person.2, into = c('ID', 'disclosure'), sep='_')
  )

# Negative disclosures
LSM_full_neg <- LSM_output_neg %>%
  # Split ID_disclosure columns into ID and disclosure
  separate(col = Person.1, into = c('ID', 'disclosure'), sep='_') %>% 
  separate(col = Person.2, into = c('ID_compared', 'disclosure_compared'), sep='_') %>% 
  # Expand dataset to include full comparison matrix, not just lower triangle
  bind_rows(
    LSM_output_neg %>%
      # Split ID_disclosure columns into ID and disclosure
      separate(col = Person.1, into = c('ID_compared', 'disclosure_compared'), sep='_') %>% 
      separate(col = Person.2, into = c('ID', 'disclosure'), sep='_')
  )

## Process comparison to group data ----
# Positive disclosures
LSM_pos_processed <- LSM_full_pos %>%
  # Set value to NA when participant is being compared to self
  mutate(LSM = ifelse(ID==ID_compared, NA_real_, LSM)) %>% 
  # For each disclosure, get average similarity to all disclosures of other participants
  group_by(ID, disclosure) %>% 
  summarise(LSM = mean(LSM, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(LSM = replace(LSM, is.nan(LSM), NA_real_))

# Neutral disclosures
LSM_neu_processed <- LSM_full_neu %>%
  # Set value to NA when participant is being compared to self
  mutate(LSM = ifelse(ID==ID_compared, NA_real_, LSM)) %>% 
  # For each disclosure, get average similarity to all disclosures of other participants
  group_by(ID, disclosure) %>% 
  summarise(LSM = mean(LSM, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(LSM = replace(LSM, is.nan(LSM), NA_real_))

# Negative disclosures
LSM_neg_processed <- LSM_full_neg %>%
  # Set value to NA when participant is being compared to self
  mutate(LSM = ifelse(ID==ID_compared, NA_real_, LSM)) %>% 
  # For each disclosure, get average similarity to all disclosures of other participants
  group_by(ID, disclosure) %>% 
  summarise(LSM = mean(LSM, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(LSM = replace(LSM, is.nan(LSM), NA_real_))

# Combine pos, neu, & neg
LSM_group_output <- bind_rows(LSM_pos_processed, LSM_neu_processed, LSM_neg_processed) %>% 
  mutate_at(vars(ID), ~as.numeric(as.character(.))) %>% 
  rename(LSM_group_score = LSM) %>% 
  arrange(ID, disclosure)
  
## Process comparison to partner data ----
# Positive disclosures
LSM_pos_processed <- LSM_full_pos %>%
  # Get partner ID
  mutate_at(vars(ID, ID_compared), ~as.numeric(as.character(.))) %>% 
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
  summarise(LSM = mean(LSM, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(LSM = replace(LSM, is.nan(LSM), NA_real_))

# Neutral disclosures
LSM_neu_processed <- LSM_full_neu %>%
  # Get partner ID
  mutate_at(vars(ID, ID_compared), ~as.numeric(as.character(.))) %>% 
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
  summarise(LSM = mean(LSM, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(LSM = replace(LSM, is.nan(LSM), NA_real_))

# Negative disclosures
LSM_neg_processed <- LSM_full_neg %>%
  # Get partner ID
  mutate_at(vars(ID, ID_compared), ~as.numeric(as.character(.))) %>% 
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
  summarise(LSM = mean(LSM, na.rm = T)) %>% 
  ungroup() %>% 
  # Set NaN to NA
  mutate(LSM = replace(LSM, is.nan(LSM), NA_real_))

# Combine pos, neu, & neg data
LSM_partner_output <- bind_rows(LSM_pos_processed, LSM_neu_processed, LSM_neg_processed) %>% 
  rename(LSM_partner_score = LSM) %>% 
  arrange(ID, disclosure)

## Combine group & partner data & save ----
LSM_combined_output <- full_join(LSM_group_output, LSM_partner_output, by=c('ID', 'disclosure'))

# Save data
write_csv(LSM_combined_output, paste0(save_data_here, '/LSM_scores.csv'))

#########################################################################################
# OLD: Process comparison to partner's data ----
LSM_output <- read_csv(paste0(get_data_here,"/LSM_output.csv"))

# Process LSM data
processed_LSM <- LSM_output %>%
  #group ID column split into ID and disclosure
  separate(col = GroupID, into = c('ID', 'disclosure'), sep='_') %>%
  #get rid of columns
  select(-c(Segment, WC.Total)) %>%
  #rename 'LSM' column to 'LSM_score'
  rename(LSM_score = LSM)

# Write and save CSV
write_csv(processed_LSM, paste0(save_data_here,"/LSM_output_processed.csv"))
