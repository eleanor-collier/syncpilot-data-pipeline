install.packages("devtools")
devtools::install_github("tomzhang255/CCR")

library(CCR)
ccr_setup()

#load data to dataframe
get_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'
save_data_here <- 'C:/Users/Venus/Desktop/sync_study_analysis/data'

#reading transcript rows into CCR
transcript_row_names <- list.files(
  path = paste0(get_data_here,"/CCR_tmp"),
  pattern = "transcript_row*",
  full.names = TRUE
  )

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

# write and save CSV ----
write_csv(CCR_all_output, paste0(save_data_here,"/CCR_output.csv"))
