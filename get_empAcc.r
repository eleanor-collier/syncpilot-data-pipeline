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

get_data_here  <- "/Users/Eleanor2/Google Drive/Docs on Laptop/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/raw/"
save_data_here <- "/Users/Eleanor2/Google Drive/Docs on Laptop/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/"

# Load data
# NOTE: before loading data in R, delete test rows from all csv files ending in '2'

# rate_self_even1  <- read_csv(paste0(get_data_here, "even_rate_self_disclosures_raw_wtestdata.csv"), col_types = "ccddcdcddcdc")
# rate_other_even1 <- read_csv(paste0(get_data_here, "even_rate_other_disclosures_raw_21_01_29.csv"), col_types = "ccddcdcddcdc")
# rate_self_odd1   <- read_csv(paste0(get_data_here, "odd_rate_self_disclosures_wtestdata.csv"), col_types = "ccddcdcddcdc")
# rate_other_odd1  <- read_csv(paste0(get_data_here, "odd_rate_other_disclosures_raw_21_01_29.csv"), col_types = "ccddcdcddcdc")
# rate_self_even2  <- read_csv(paste0(get_data_here, "even_rate_self_disclosures_raw.csv"), col_types = "ccddcdcddcdc")
# rate_other_even2 <- read_csv(paste0(get_data_here, "even_rate_other_disclosures_raw_21_01_29 (1).csv"), col_types = "ccddcdcddcdc")
# rate_self_odd2   <- read_csv(paste0(get_data_here, "odd_rate_self_disclosures_raw.csv"), col_types = "ccddcdcddcdc")
# rate_other_odd2  <- read_csv(paste0(get_data_here, "odd_rate_other_disclosures_raw_21_01_29 (1).csv"), col_types = "ccddcdcddcdc")

rate_self_even1  <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_even_rate_self_disclosures_raw1.csv"), col_types = "ccddcdcddcdc")
rate_self_even2  <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_even_rate_self_disclosures_raw2.csv"), col_types = "ccddcdcddcdc")
rate_other_even1 <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_even_rate_other_disclosures_raw1.csv"), col_types = "ccddcdcddcdc")
rate_other_even2 <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_even_rate_other_disclosures_raw2.csv"), col_types = "ccddcdcddcdc")

rate_self_odd1   <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_odd_rate_self_disclosures_raw1.csv"), col_types = "ccddcdcddcdc")
rate_self_odd2   <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_odd_rate_self_disclosures_raw2.csv"), col_types = "ccddcdcddcdc")
rate_other_odd1  <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_odd_rate_other_disclosures_raw1.csv"), col_types = "ccddcdcddcdc")
rate_other_odd2  <- read_csv(paste0(get_data_here, "syncdiscpilot_ratedisclosures_odd_rate_other_disclosures_raw2.csv"), col_types = "ccddcdcddcdc")


# Merge dataframes into master dataframe
rate_self  <- bind_rows(rate_self_even1, rate_self_odd1, rate_self_even2, rate_self_odd2) %>% 
  select(-time) %>% 
  rename(ID=subject, disclosure=videoname, time=timeofrating)
rate_other <- bind_rows(rate_other_even1, rate_other_odd1, rate_other_even2, rate_other_odd2) %>% 
  select(-time) %>% 
  rename(ID=subject, disclosure=videoname, time=timeofrating)

# Process data
rate_self <- rate_self %>% 
  ### Clean data
  # Get rid of subjects that aren't in both datasets
  filter(!ID %in% setdiff(unique(rate_self$ID), unique(rate_other$ID))) %>% 
  # Get rid of problematic participants, header rows & test data
  filter(!ID %in% c("1", "2", "9")) %>% 
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
  
  ### Z-score valence rating values
  mutate_at(vars(valence_rating), ~scale(.)) %>%
  mutate_at(vars(valence_rating), ~na_if(., "NaN")) %>%
  ungroup() %>% 
  
  ### Assign pair numbers equal to odd subject number in each pair
  mutate(pair_id = case_when(
    ID %% 2 ==1 ~ ID, # odd
    ID %% 2 ==0 ~ ID - 1 # even
    ))

rate_other <- rate_other %>% 
  ### Clean data
  # Get rid of subjects that aren't in both datasets
  filter(!ID %in% setdiff(unique(rate_other$ID), unique(rate_self$ID))) %>% 
  # Get rid of problematic participants, header rows & test data
  filter(!ID %in% c("1", "2", "9")) %>% 
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

# Combine rate self-ratings and partner's ratings
partnered_data <- bind_cols(
  rate_self %>% select(pair_id, everything()), 
  rate_other %>% select(ID, valence_rating) %>% rename_with(~paste0("partner_", .))
  ) %>% 
  # Get rid of disclosures where one person didn't move the slider enough
  group_by(ID, disclosure) %>%
  filter(!mean(is.na(valence_rating))>.50) %>%
  filter(!mean(is.na(partner_valence_rating))>.50) %>%
  ungroup()

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
write_csv(moment_to_moment_empAcc, paste0(save_data_here, "moment_to_moment_empAcc.csv"))

# Compute empathic accuracy as mean correlation between pair ratings
mean_empAcc_by_disclosure <-  partnered_data %>% 
  group_by(ID, disclosure) %>% 
  summarise(partner_empAcc = cor.test(valence_rating, partner_valence_rating)$estimate) %>% 
  ungroup() %>% 
  mutate_at(vars(partner_empAcc), ~na_if(., "NaN")) %>% 
  # Convert R to Z
  mutate_at(vars(partner_empAcc), ~recode(., `1`=0.9999999999999999, `-1`=-0.9999999999999999)) %>% 
  mutate_at(vars(partner_empAcc), ~FisherZ(.)) %>% 
  mutate_at(vars(partner_empAcc), ~na_if(., "NaN"))
write_csv(mean_empAcc_by_disclosure, paste0(save_data_here, "mean_empAcc_by_disclosure.csv"))

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
