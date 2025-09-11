if(!require(tidyverse)) install.packages("tidyverse")
library(tidyverse)

# I usually just load data through the RStudio GUI
#human_data <- read.csv("human_pilot_data.csv")
#llm_data <- read.csv("llm_on_human_pilot_data.csv")

# Data prep
human_scores <- human_data %>%
  select(input, creative_alignment, instruction_following, emergence)

llm_scores <- llm_data %>%
  select(
    input,
    creative_alignment = score_creative_alignment,
    instruction_following = score_instructional_precision,
    emergence = score_emergence
  )

merged_data <- inner_join(
  human_scores,
  llm_scores,
  by = "input",
  suffix = c("_human", "_llm")
)

cat(paste("Found", nrow(merged_data), "matching inputs.\n\n"))


# Spearman's Rank Correlation
score_metrics <- c("creative_alignment", "instruction_following", "emergence")

for (metric in score_metrics) {
  cat(paste("Spearman's Correlation for:", metric, "\n"))
  
  col_human <- paste0(metric, "_human")
  col_llm <- paste0(metric, "_llm")
  
  corr_test <- cor.test(
    merged_data[[col_human]],
    merged_data[[col_llm]],
    method = "spearman",
    exact = FALSE
  )
  print(corr_test)
}

# Descriptive stats
calculate_mode <- function(x, na.rm = TRUE) {
  if (na.rm) x <- na.omit(x)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

cat("Descriptive stats:\n")

# Loop through scales
score_metrics <- c("creative_alignment", "instruction_following", "emergence")
for (metric in score_metrics) {
  median_val <- median(human_scores[[metric]], na.rm = TRUE)
  mode_val <- calculate_mode(human_scores[[metric]])
  metric_name_formatted <- str_to_title(gsub("_", " ", metric))
  
  cat(paste0(metric_name_formatted, ": Median ", median_val, ", Mode ", mode_val, "\n"))
}
