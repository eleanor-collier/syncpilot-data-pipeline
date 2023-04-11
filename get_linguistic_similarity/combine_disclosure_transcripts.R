##########################################################
# combine participants' disclosure transcripts
# Genesis Garza Morales
# 03/20/23
##########################################################
# load packages ----
library(tidyverse)

# load data ----
get_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
save_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
transcripts   <- read.csv(paste0(get_data_here,"/transcripts.csv"))

# squash together people's stories by type of story ----
transcripts_squashed <- transcripts %>%
  # remove numerical value(s) from disclosure label
  mutate(disclosure_type = gsub("[[:digit:]]", "", disclosure))   %>%
  # group text by disclosure type within ID
  group_by(ID, disclosure_type) %>%
  # concatenate pair of disclosures within each group
  mutate(combined_disclosures = paste(first(text), last(text), " ")) %>%
  # reminder to ungroup
  ungroup()

# swap people's own squashed stories w/ partner's squashed stories ----
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
  select(-c(start_time:disclosure_type, pair_ID))

# prep transcripts for CCR
for (i in c(1:nrow(transcripts_swapped))) {
  transcript_row <- transcripts_swapped[i,]
  write_csv(transcript_row, paste0(save_data_here, "/CCR_tmp/transcript_row", i, ".csv"))
}

# prep transcripts for LSM
transcripts_for_LSM <- transcripts_swapped %>% 
  pivot_longer(
    cols = c('text', 'partner_combined_disclosures'),
    names_to = 'label',
    values_to = 'text_to_compare'
  ) %>% 
  mutate(ID_disclosure = paste(ID, disclosure, sep = "_"))

#write and save CSV ----
write_csv(transcripts_for_LSM, paste0(save_data_here,"/transcripts_for_LSM.csv"))

