#########################################################################################
# Script to process empathic accuracy data
# Eleanor Collier, Julia Hopkins, Genesis Morales, & Katelynn Bergman
# 4/21/21
#########################################################################################

# Set up workspace
library(tidyverse)
library(zoo)
library(TTR)
library(DescTools)

get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/raw/empAcc/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/"

#########################################################################################
## Load valence rating  data ----
# NOTE: These csvs are from the Inquisit folders labeled "XXX_raw", not "raw"
# NOTE: Must first delete test data rows
rate_self_even  <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_even_rate_self_disclosures_raw.csv"), col_types = "ccddcdcddcdc")
rate_self_odd   <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_odd_rate_self_disclosures_raw.csv"), col_types = "ccddcdcddcdc")
rate_other_even <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_even_rate_other_disclosures_raw.csv"), col_types = "ccddcdcddcdc")
rate_other_odd  <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_odd_rate_other_disclosures_raw.csv"), col_types = "ccddcdcddcdc")

## Fix some duplicate ID issues ----
# Fix ID issue for P142
rate_self_even[rate_self_even$subject==141,]$subject <- 142
rate_other_even[rate_other_even$subject==141,]$subject <- 142
# Fix ID issue for P100
rate_self_even[rate_self_even$subject==99,]$subject <- 100
rate_other_even[rate_other_even$subject==99,]$subject <- 100
# Get rid of first instance of P95/P96; these were test subjects
rate_self_even <- filter(rate_self_even, !date=="2020/8/3")
rate_self_odd <- filter(rate_self_odd, !date=="2020/8/3")

## Merge dataframes into master dataframe ----
rate_self  <- bind_rows(rate_self_even, rate_self_odd) %>% 
  select(-time) %>% 
  rename(ID=subject, disclosure=videoname, time=timeofrating)
rate_other <- bind_rows(rate_other_even, rate_other_odd) %>% 
  select(-time) %>% 
  rename(ID=subject, disclosure=videoname, time=timeofrating)

## List IDs of problem participants ----
problem_IDs <- c(1, 2, 9, 29, 30, 33, 34, 39, 40, 93, 94, 147, 148, 149, 150, 179, 180)
# NOTE: P129 was too quiet, so removing 129 from rate_self only and 130 from rate_other only
# NOTE: P43 & P55 are missing data for rate_other, so removing 43/55 from rate_other only and 44/56 from rate_self only
# NOTE: P16 neu2 was cut short, so removing 16 neu2 from rate_self only and 15 neu2 from rate_other only

## Get accurate timestamps of when participants started/stopped speaking from transcripts ----
transcripts <- read_csv("/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/transcripts.csv", col_types = "dccdddd")
timestamps  <- unique(transcripts) %>% select(ID, disclosure, start_time, end_time)
partner_timestamps <- timestamps %>% 
  mutate(partner_id = case_when(
    ID %% 2 ==1 ~ ID + 1, # odd
    ID %% 2 ==0 ~ ID - 1 # even
  )) %>% 
  select(-ID)



## Process data ----
# SELF-RATINGS ----
rate_self_processed <- rate_self %>% 
  ### Clean data
  # Get rid of subjects that aren't in both datasets
  # filter(!ID %in% setdiff(unique(rate_self$ID), unique(rate_other$ID))) %>% 
  # Get rid of problematic participants, header rows & test data
  filter(!ID %in% c(problem_IDs, 129, 44, 56)) %>% 
  filter(!(ID==16 & disclosure=="self_disclosure_neu2.m4a")) %>% 
  filter(ID != "subject") %>% 
  drop_na(disclosure) %>% 
  # Delete useless columns
  select(ID, time, valence_rating, disclosure) %>% 
  # Sort by desired columns
  arrange(ID, disclosure, time) %>% 
  # Change time of rating from milliseconds to seconds & round to nearest second
  mutate_at(vars(time), ~round(./1000)) %>% 
  # Make valence column numeric & scale to 0-100
  mutate_at(vars(valence_rating), ~as.numeric(gsub("pct", "", .))*2) %>% 
  # Get rid of excess text in recording name
  mutate_at(vars(disclosure), ~sub("self_disclosure_", "", .)) %>% 
  mutate_at(vars(disclosure), ~sub(".m4a", "", .)) %>% 
  
  ### Standardize timeseries
  # For seconds with multiple ratings, average to get one rating per second
  group_by(ID, disclosure, time) %>%
  summarize_at(vars(valence_rating), ~mean(., na.rm = T)) %>%
  # Make sure all timeseries start with 0 and end with 180
  group_by(ID, disclosure) %>%
  complete(time = full_seq(0:180, 1)) %>%
  ungroup() %>%
  # Create rows for all missing time points with explicit NAs
  complete(ID, disclosure, time, fill = list(valence_rating = NA)) %>%
  # Fill in missing values based on previous values
  group_by(ID, disclosure) %>%
  fill(valence_rating) %>%
  replace_na(list(valence_rating = 50)) %>% #For NAs at early time points, use valence rating of 50
  # Delete all time points when PARTICIPANT wasn't really talking based on transcript timestamps
  inner_join(timestamps, by=c("ID", "disclosure")) %>% 
  filter(time >= start_time & time <= end_time & time <= 180) %>% 
  select(-start_time, -end_time) %>% 

  ### Z-score valence rating values
  mutate_at(vars(valence_rating), ~scale(.)) %>%
  mutate_at(vars(valence_rating), ~na_if(., "NaN")) %>%
  ungroup() %>% 
  
  ### Assign pair numbers equal to odd subject number in each pair
  mutate(pair_id = case_when(
    ID %% 2 ==1 ~ ID, # odd
    ID %% 2 ==0 ~ ID - 1 # even
    ))

# OTHER-RATINGS ----
rate_other_processed <- rate_other %>% 
  ### Clean data
  # Get rid of subjects that aren't in both datasets
  # filter(!ID %in% setdiff(unique(rate_other$ID), unique(rate_self$ID))) %>% 
  # Get rid of problematic participants, header rows & test data
  filter(!ID %in% c(problem_IDs, 130, 43, 55)) %>% 
  filter(!(ID==15 & disclosure=="other_disclosure_neu2.m4a")) %>% 
  filter(ID != "subject") %>% 
  drop_na(disclosure) %>% 
  # Delete useless columns
  select(ID, time, valence_rating, disclosure) %>% 
  # Sort by desired columns
  arrange(ID, disclosure, time) %>% 
  # Change time of rating from milliseconds to seconds & round to nearest second
  mutate_at(vars(time), ~round(./1000)) %>% 
  # Make valence column numeric & scale to 0-100
  mutate_at(vars(valence_rating), ~as.numeric(gsub("pct", "", .))*2) %>% 
  # Get rid of excess text in recording name
  mutate_at(vars(disclosure), ~sub("other_disclosure_", "", .)) %>% 
  mutate_at(vars(disclosure), ~sub(".m4a", "", .)) %>% 
  
  ### Standardize timeseries
  # For seconds with multiple ratings, average to get one rating per second
  group_by(ID, disclosure, time) %>%
  summarize_at(vars(valence_rating), ~mean(., na.rm = T)) %>%
  # Make sure all timeseries start with 0 and end with 180
  group_by(ID, disclosure) %>%
  complete(time = full_seq(0:180, 1)) %>%
  ungroup() %>%
  # Create rows for all missing time points with explicit NAs
  complete(ID, disclosure, time, fill = list(valence_rating = NA)) %>%
  # Fill in missing values based on previous values
  group_by(ID, disclosure) %>%
  fill(valence_rating) %>%
  replace_na(list(valence_rating = 50)) %>% #For NAs at early time points, use valence rating of 50
  # Delete all time points when STUDY PARTNER wasn't really talking based on transcript timestamps
  inner_join(partner_timestamps, by=c("ID"="partner_id", "disclosure")) %>% 
  filter(time >= start_time & time <= end_time & time <= 180) %>% 
  select(-start_time, -end_time) %>% 
  
  ### Z-score valence rating values
  mutate_at(vars(valence_rating), ~scale(.)) %>%
  mutate_at(vars(valence_rating), ~na_if(., "NaN")) %>%
  ungroup() %>% 
  
  ### Assign pair numbers equal to odd subject number in each pair
  mutate(pair_id = case_when(
    ID %% 2 ==1 ~ ID, # odd
    ID %% 2 ==0 ~ ID - 1 # even
  )) %>% 
  # Switch order of subject numbers in pair in order to later combine with self-rating dataset
  group_by(pair_id) %>% 
  arrange(pair_id, desc(ID)) %>% 
  ungroup()

## Code to test mismatched ID issues ----
# test1 <- unique(rate_self_processed %>% select(pair_id, disclosure, time))
# test2 <- unique(rate_other_processed %>% select(pair_id, disclosure, time))
# test <- setdiff(test1, test2)

## Combine rate self-ratings and partner's ratings ----
partnered_data <- bind_cols(
  rate_self_processed %>% select(pair_id, everything()), 
  rate_other_processed %>% select(ID, valence_rating) %>% rename_with(~paste0("partner_", .))
  ) %>% 
  # Get rid of disclosures where there were too many NA values (slider was not moved at all)
  group_by(ID, disclosure) %>%
  filter(
    !mean(is.na(valence_rating)) > .5,
    !mean(is.na(partner_valence_rating)) > .5
  ) %>%
  # Get rid of disclosures where one person didn't move the slider more than a certain amount
  # Exclusion threshold is equal to desired fraction of total disclosure time
  # mutate(
  #   longest_nochange_self  = max(rle(as.vector(valence_rating))$lengths),
  #   longest_nochange_other = max(rle(as.vector(partner_valence_rating))$lengths),
  #   exclusion_threshold    = max(time) * 0.85
  #   ) %>%
  # filter(
  #   !longest_nochange_self  > exclusion_threshold,
  #   !longest_nochange_other > exclusion_threshold
  #   ) %>%
  # select(-c(longest_nochange_self, longest_nochange_other, exclusion_threshold)) %>%
  ungroup() 

# Check how many stories are left after exclusion
nrow(unique(partnered_data %>% select(ID, disclosure)))

## Compute empathic accuracy as mean correlation between pair ratings ----
mean_empAcc_by_disclosure <-  partnered_data %>% 
  group_by(ID, disclosure) %>% 
  summarise(partner_empAcc = cor.test(valence_rating, partner_valence_rating)$estimate) %>% 
  ungroup() %>% 
  mutate_at(vars(partner_empAcc), ~na_if(., "NaN")) %>% 
  # Convert R to Z
  mutate_at(vars(partner_empAcc), ~recode(., `1`=0.9999999999999999, `-1`=-0.9999999999999999)) %>%
  mutate_at(vars(partner_empAcc), ~FisherZ(.)) %>%
  mutate_at(vars(partner_empAcc), ~na_if(., "NaN"))
write_csv(mean_empAcc_by_disclosure, paste0(save_data_here, "mean_by_disclosure/empathic_accuracy.csv"))


# Average within valence categories
mean_empAcc_by_valence <-  mean_empAcc_by_disclosure %>% 
  mutate_at(vars(disclosure), ~(sub('1', '', .))) %>% 
  mutate_at(vars(disclosure), ~(sub('2', '', .))) %>% 
  group_by(ID, disclosure) %>% 
  summarise_at(vars(partner_empAcc), ~mean(., na.rm=T)) %>% 
  ungroup() %>% 
  mutate_at(vars(partner_empAcc), ~na_if(., "NaN")) %>% 
  mutate_at(vars(disclosure), ~as.factor(.))
write_csv(mean_empAcc_by_valence, paste0(save_data_here, "mean_empAcc_by_valence.csv"))

# Compute empathic accuracy across time as rolling correlation between pair ratings
moment_to_moment_empAcc <- partnered_data %>% 
  group_by(ID, disclosure) %>% 
  mutate(partner_empAcc = runCor(valence_rating, partner_valence_rating, n=15)) %>% 
  mutate_at(vars(partner_empAcc), ~na_if(., "NaN")) %>% 
  # Convert R to Z
  mutate_at(vars(partner_empAcc), ~recode(., `1`=0.9999999999999999, `-1`=-0.9999999999999999)) %>% 
  mutate_at(vars(partner_empAcc), ~FisherZ(.)) %>% 
  mutate_at(vars(partner_empAcc), ~na_if(., "NaN")) %>% 
  select(ID, disclosure, time, partner_empAcc)
write_csv(moment_to_moment_empAcc, paste0(save_data_here, "moment_to_moment/empathic_accuracy_by_window_15s.csv"))

## Analyses for Genesis + Katelynn poster ----
# # COMPARE MEAN EMPATHIC ACCURACY FOR DIFFERENT VALENCES
# # Compare partner's empathic accuracy for negative vs neutral disclosures
# t.test(
#   filter(empAcc_data_by_valence, disclosure=="neg")$partner_empAcc,
#   filter(empAcc_data_by_valence, disclosure=="neu")$partner_empAcc
# )
# 
# # Compare partner's empathic accuracy for positive vs neutral disclosures
# t.test(
#   filter(empAcc_data_by_valence, disclosure=="pos")$partner_empAcc,
#   filter(empAcc_data_by_valence, disclosure=="neu")$partner_empAcc
# )
# 
# Plot data
# ggplot(data=mean_empAcc_by_valence) +
#   geom_bar(aes(disclosure, partner_empAcc, fill = disclosure),
#            position = "dodge", stat = "summary", fun = "mean")
