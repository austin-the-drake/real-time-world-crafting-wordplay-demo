if(!require(tidyverse)) install.packages("tidyverse")
if(!require(effectsize)) install.packages("effectsize")

library(tidyverse)
library(effectsize)

# I usually load data in the RStudio GUI
# analysis_data_exp1 <- read.csv("naturalistic_sample_for_comparison.csv")
# analysis_data_exp2 <- read.csv("bidirectional_sample_for_comparison.csv")

# Prepare data
combined_data <- bind_rows(analysis_data_exp1, analysis_data_exp2) %>%
  mutate(procedural = as.factor(procedural))

score_variables <- c(
  "score_creative_alignment",
  "score_instructional_precision",
  "score_emergence",
  "score_structural_coherence"
)

for (score in score_variables) {
  
  formula <- as.formula(paste(score, "~ procedural"))
  
  cat(paste0("\n\nAnalysis for: ", score, "\n"))
  
  # Wilcoxon Test
  wilcox_result <- wilcox.test(formula, data = combined_data, conf.int = TRUE)
  print(wilcox_result)
  
  # Cohen's d
  cohen_d_result <- cohens_d(formula, data = combined_data)
  
  # Calculate means
  group_means <- combined_data %>%
    group_by(procedural) %>%
    summarise(mean_score = mean(.data[[score]], na.rm = TRUE))
  
  mean_procedural_0 <- group_means$mean_score[group_means$procedural == 0]
  mean_procedural_1 <- group_means$mean_score[group_means$procedural == 1]
  
  cat("\nDescriptive Stats\n")
  cat(paste("  Mean (procedural=0):", round(mean_procedural_0, 3), "\n"))
  cat(paste("  Mean (procedural=1):", round(mean_procedural_1, 3), "\n"))
  cat(paste("Mean Difference:", round(mean_procedural_1 - mean_procedural_0, 3), "\n"))
  cat(paste("Cohen's d:", round(cohen_d_result$Cohens_d, 3), "\n"))
}