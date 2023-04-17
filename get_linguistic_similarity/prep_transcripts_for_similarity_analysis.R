#########################################################################################
# Prep participants' disclosure transcripts for LSM & CCR analysis
# Genesis Garza Morales & Eleanor Collier
# 03/29/23
#########################################################################################
# Load packages
library(tidyverse)

# Load data
# get_data_here  <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
# save_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
get_data_here  <- '/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure'
save_data_here <- '/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure'

transcripts   <- read.csv(paste0(get_data_here,"/transcripts.csv"))

#########################################################################################
## Prep main transcripts file for CCR & LSM full analysis (group & pairwise) ----
# Note: this transcript will be used in CCR as the q_file (file each disclosure is being compared to)
transcripts_only <- transcripts %>% 
  select(ID, disclosure, text) %>% 
  mutate(
    ID_disclosure = paste(ID, disclosure, sep = "_"),
    LSM_group = rep_len(1, nrow(.))
  )

transcripts_pos <- transcripts_only %>% filter(disclosure %in% c('pos1', 'pos2'))
transcripts_neu <- transcripts_only %>% filter(disclosure %in% c('neu1', 'neu2'))
transcripts_neg <- transcripts_only %>% filter(disclosure %in% c('neg1', 'neg2'))

# Save data
write_csv(transcripts_pos, paste0(save_data_here,"/transcripts_pos.csv"))
write_csv(transcripts_neu, paste0(save_data_here,"/transcripts_neu.csv"))
write_csv(transcripts_neg, paste0(save_data_here,"/transcripts_neg.csv"))

## Prep individual transcript fles for CCR full analysis (group & pairwise) ----
# Note: these transcripts will be used in CCR as the data_file (file to compare to all other disclosures)
transcripts_only <- transcripts %>% 
  select(ID, disclosure, text)

# Save transcript for each individual disclosure as its own csv file
for (i in c(1:nrow(transcripts_only))) {
  transcript_row <- transcripts_only[i,]
  write_csv(transcript_row, paste0(save_data_here, "/CCR_tmp/transcript_row", str_pad(i, 3, pad = "0"), ".csv"))
}

#########################################################################################
# OLD: Prep transcripts for CCR pairwise analysis using partner's combined disclosures ----
# squash together people's stories by type of story
transcripts_squashed <- transcripts %>%
  # remove numerical value(s) from disclosure label
  mutate(disclosure_type = gsub("[[:digit:]]", "", disclosure))   %>%
  # group text by disclosure type within ID
  group_by(ID, disclosure_type) %>%
  # concatenate pair of disclosures within each group
  mutate(combined_disclosures = paste(first(text), last(text), " ")) %>%
  # reminder to ungroup
  ungroup()

# swap people's own squashed stories w/ partner's squashed stories
transcripts_swapped <- transcripts_squashed %>%
  # make extant ID column exclusively numeric
  mutate_at(vars(ID), ~ as.numeric(.)) %>%
  # make new pair_ID column w/exclusively odd numbers
  mutate(
    pair_ID = case_when(
      ID %% 2 == 1 ~ ID,
      ID %% 2 == 0 ~ ID - 1
      )
    ) %>%
  # group by pair_ID 
  group_by(pair_ID) %>%
  # arrange pair_ID's in descending order
  arrange(pair_ID, desc(ID)) %>%
  # 
  bind_cols(
    transcripts_squashed %>%
      select(combined_disclosures) %>%
      rename_with(~ paste0("partner_", .))
    ) %>%
  # reminder to ungroup
  ungroup() %>%
  # remove unwanted columns
  select(-c(start_time:disclosure_type, pair_ID)) %>% 
  # arrange by ID & disclosure
  arrange(ID, disclosure)

# prep transcripts for CCR
for (i in c(1:nrow(transcripts_swapped))) {
  transcript_row <- transcripts_swapped[i,]
  write_csv(transcript_row, paste0(save_data_here, "/CCR_tmp/transcript_row", str_pad(i, 3, pad = "0"), ".csv"))
}

#########################################################################################
# OLD: Prep transcripts for LSM pairwise analysis using partner's combined disclosures ----
transcripts_for_LSM <- transcripts_swapped %>% 
  pivot_longer(
    cols = c('text', 'partner_combined_disclosures'),
    names_to = 'label',
    values_to = 'text_to_compare'
  ) %>% 
  mutate(ID_disclosure = paste(ID, disclosure, sep = "_"))

# Write and save csv
write_csv(transcripts_for_LSM, paste0(save_data_here,"/transcripts_for_LSM.csv"))



