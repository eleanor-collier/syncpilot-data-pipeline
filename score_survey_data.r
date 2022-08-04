#########################################################################################
# Script to process baseline survey data
# Eleanor Collier
# 1/29/22
#########################################################################################

# Set up workspace
library(tidyverse)

get_data_here  <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/raw/"
save_data_here <- "/Volumes/GoogleDrive/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/"

# Load data
baseline_raw <- read_csv(paste0(get_data_here, "baseline_raw.csv"))

# Questionnaire columns
ID_col <- grep("participant ID", baseline_raw)
IOS_cols <- grep("select the picture", baseline_raw)
closeness_col <- grep("How close do you feel", baseline_raw)
SA_cols <- grep("Read each situation carefully", baseline_raw)
IRI_cols <- grep("thoughts and feelings in a variety", baseline_raw)
SSS_cols <- grep("Please indicate the degree to which", baseline_raw)
depression_cols <- grep("Below is a list of ways you might have felt", baseline_raw)[1:20]
anxiety_cols <- grep("Below is a list of ways you might have felt", baseline_raw)[21:27]
BFI_cols <- grep("I am someone who", baseline_raw)
GPA_col <- grep("current GPA", baseline_raw)
age_col <- grep("your age", baseline_raw)
gender_cols <- grep("What gender do you", baseline_raw)
race_cols <- grep("your race", baseline_raw)
education_col <- grep("level of education", baseline_raw)

numeric_cols <- c(
  closeness_col, SA_cols, IRI_cols, SSS_cols, depression_cols, anxiety_cols, BFI_cols, 
  GPA_col, age_col
)
factor_cols <- c(
  gender_cols, race_cols, education_col
)

# Subscale columns
IRI_PT_cols <- IRI_cols[c(3, 8, 11, 15, 21, 25, 28)]
IRI_FS_cols <- IRI_cols[c(1, 5, 7, 12, 16, 23, 26)]
IRI_EC_cols <- IRI_cols[c(2, 4, 9, 14, 18, 20, 22)]
IRI_PD_cols <- IRI_cols[c(6, 10, 13, 17, 19, 24, 27)]

SSS_RE_cols <- SSS_cols[1:7]
SSS_GE_cols <- SSS_cols[8:12]
SSS_RI_cols <- SSS_cols[13:16]
SSS_GI_cols <- SSS_cols[17:21]

BFI_E_cols <- BFI_cols[c(1,6,11)]
BFI_A_cols <- BFI_cols[c(2,7,12)]
BFI_C_cols <- BFI_cols[c(3,8,13)]
BFI_N_cols <- BFI_cols[c(4,9,14)]
BFI_O_cols <- BFI_cols[c(5,10,15)]

# Columns to reverse score
IRI_rev_cols <- IRI_cols[c(3, 4, 7, 12, 13, 14, 15, 18, 19)]
depression_rev_cols <- depression_cols[c(4, 8, 12, 16)]
BFI_rev_cols <- BFI_cols[c(1, 3, 7, 8, 10, 14)]

### Clean up the rows & format data ----
baseline_cleaned <- baseline_raw[-c(1:2),] %>% 
  mutate_at(
    vars(all_of(numeric_cols)),
    list(~as.numeric(as.character(.)))
  ) %>% 
  mutate_at(
    vars(all_of(ID_col)),
    list(~as.factor(.))
  ) %>% 
  # Get rid of test data
  filter(!(ID %in% c("test", "00")), !is.na(Consent)) %>% 
  # Get rid of duplicate IDs with multiple IP addresses, keeping the correct one only
  filter(
    !(ID=="02" & IPAddress=="169.235.64.254"),
    !(ID=="119" & IPAddress=="66.215.202.125"),
    !(ID=="127" & IPAddress=="47.149.106.132"),
    !(ID=="128" & IPAddress=="97.90.202.0"),
    !(ID=="128" & IPAddress=="98.149.18.249"),
    !(ID=="99" & IPAddress=="76.86.127.180"),
    !(ID=="98" & IPAddress=="71.95.191.6")
  ) %>% 
  # Get rid of duplicate IDs with same IP addresses, keeping the first one only
  arrange(as.numeric(as.character(ID))) %>% 
  distinct(ID, .keep_all = TRUE)

### Score questionnaires ----
baseline_processed <- baseline_cleaned %>% 
  
  # Reverse score relevant questionnaire columns
  mutate_at( # Reverse score IRI items
    vars(all_of(IRI_rev_cols)),
    list(~6 - .)
  ) %>% 
  mutate_at( # Reverse score CES-D items
    vars(all_of(depression_rev_cols)),
    list(~3 - .)
  ) %>% 
  mutate_at( # Reverse score BFI
    vars(all_of(BFI_rev_cols)),
    list(~6 - .)
  ) %>% 
  
  # Create new columns w/ total scores for every scale & subscale
  mutate( # Create new columns w/ total scores for every scale & subscale
    socialAnxiety=rowSums(.[SA_cols]),
    IRI_overall=rowMeans(.[IRI_cols]),
    IRI_PT=rowMeans(.[IRI_PT_cols]),
    IRI_FS=rowMeans(.[IRI_FS_cols]),
    IRI_EC=rowMeans(.[IRI_EC_cols]),
    IRI_PD=rowMeans(.[IRI_PD_cols]),
    socialSupport_overall=rowMeans(.[SSS_cols]),
    socialSupport_RE=rowMeans(.[SSS_RE_cols]),
    socialSupport_GE=rowMeans(.[SSS_GE_cols]),
    socialSupport_RI=rowMeans(.[SSS_RI_cols]),
    socialSupport_GI=rowMeans(.[SSS_GI_cols]),
    depression=rowSums(.[depression_cols]),
    anxiety=rowSums(.[anxiety_cols]),
    extraversion=rowSums(.[BFI_E_cols]),
    agreeableness=rowSums(.[BFI_A_cols]),
    conscientiousness=rowSums(.[BFI_C_cols]),
    neuroticism=rowSums(.[BFI_N_cols]),
    openness=rowSums(.[BFI_O_cols]),
    GPA=unlist(.[GPA_col]),
    age=unlist(.[age_col]),
    gender=recode_factor(
      unlist(.[gender_cols[1]]),
      "1"="Male", "2"="Female", "3"="Other"
    ),
    race=recode_factor(
      unlist(.[race_cols[1]]),
      "1"="White", "2"="African American", "3"="Hispanic", "4"="Asian",
      "5"="Middle Eastern", "6"="Native American", "7"="Pacific Islander", 
      "8"="Other", .default="Mixed"
    ),
    education=recode_factor(
      unlist(.[education_col]),
      "1"="Less than high school", "2"="High school/GED", "3"="Some college",
      "4"="2 year degree", "5"="4 year degree", "6"="Masters degree", 
      "7"="Doctorate degree", "8"="Professional degree"
    )
  ) %>% 
  # Score IOS scale
  mutate_at(vars(IOS_1), ~case_when(.=="On" ~1, .=="Off" ~0)) %>% 
  mutate_at(vars(IOS_2), ~case_when(.=="On" ~2, .=="Off" ~0)) %>% 
  mutate_at(vars(IOS_3), ~case_when(.=="On" ~3, .=="Off" ~0)) %>% 
  mutate_at(vars(IOS_4), ~case_when(.=="On" ~4, .=="Off" ~0)) %>% 
  mutate_at(vars(IOS_5), ~case_when(.=="On" ~5, .=="Off" ~0)) %>% 
  mutate_at(vars(IOS_6), ~case_when(.=="On" ~6, .=="Off" ~0)) %>% 
  mutate_at(vars(IOS_7), ~case_when(.=="On" ~7, .=="Off" ~0)) %>% 
  mutate(IOS_score = rowSums(select(., IOS_1:IOS_7), na.rm = T) %>% na_if(0)) %>% 
  # Rename closeness
  rename(closeness=Closeness_1) %>% 
  # Get rid of unnecessary columns
  select(ID, closeness, socialAnxiety:IOS_score)

# Save data
write_csv(baseline_processed, paste0(save_data_here, "baseline_data.csv"))
