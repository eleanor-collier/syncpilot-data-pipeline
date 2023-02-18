#########################################################################################
# Analyze type-token ratio
# Eleanor Collier
# 2/15/23
#########################################################################################

# Set up workspace
library(tidyverse)
library(tm)

#########################################################################################
## MEAN BY DISCLOSURE ----
# Load data
get_data_here  <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"
save_data_here <- "/Users/Eleanor2/Library/CloudStorage/GoogleDrive-airfire246@gmail.com/My Drive/UCR/UCR SNL/Research Projects/SyncDisclosures/Pilot/Analysis/Data/processed/mean_by_disclosure/"

transcripts <- read_csv(paste0(get_data_here, "transcripts.csv")) %>% unique(.)

# Create a corpus
corpus <- Corpus(VectorSource("I like pie a lot and birds fly fast like birds"))
# process to remove stopwords, punctuation, etc. 
skipWords <- function(x) removeWords(x, stopwords("english"))
funcs <- list(tolower, removePunctuation, removeNumbers, stripWhitespace, skipWords)
corpus.proc <- tm_map(corpus, FUN = tm_reduce, tmFuns = funcs)
# create a document term matrix
corpusa.dtm <- DocumentTermMatrix(corpus.proc, control = list(wordLengths = c(3,10)))

# Find the number of tokens (total number of words in corpus)
n_tokens <- sum(as.matrix(corpusa.dtm))

# Find the number of types (number of unique words in corpus)
n_types <- length(corpusa.dtm$dimnames$Terms)

# Compute type-token ratio
TTR = n_types / n_tokens

# Process to remove stopwords, punctuation, etc. 
skipWords <- function(x) removeWords(x, stopwords("english"))
funcs <- list(tolower, removePunctuation, removeNumbers, stripWhitespace, skipWords)

# Compute TTR for each transcript in the dataset
TTR <- transcripts %>% 
  select(ID, disclosure, text) %>% 
  mutate(corpus = map(text, ~Corpus(VectorSource(.)))) %>% 
  mutate(corpus.proc = map(corpus, ~tm_map(., FUN = tm_reduce, tmFuns = funcs))) %>% 
  mutate(corpusa.dtm = map(corpus.proc, ~DocumentTermMatrix(., control = list(wordLengths = c(3,10))))) %>% 
  mutate(n_tokens = map_dbl(corpusa.dtm, ~sum((.[[3]])))) %>% 
  mutate(n_types = map_dbl(corpusa.dtm, ~length(.$dimnames$Terms))) %>% 
  mutate(TTR = n_types / n_tokens) %>% 
  select(ID, disclosure, TTR)

# Save data
write_csv(TTR, paste0(save_data_here, "type_token_ratio.csv"))

