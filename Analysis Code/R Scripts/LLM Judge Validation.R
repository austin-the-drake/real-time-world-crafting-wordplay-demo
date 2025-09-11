if(!require(tidyverse)) install.packages("tidyverse")
if (!require(pROC)) install.packages("pROC")
if (!require(irr)) install.packages("irr")

library(tidyverse)
library(irr)
library(pROC)

# I usually load data in the RStudio GUI
#validation_data <- read.csv("judge_validation_spells_gpt.csv")
#validation_data_alt <- read.csv("judge_validation_spells_gemini.csv")

#validation_data <- read.csv("judge_validation_automata_gpt.csv")
#validation_data_alt <- read.csv("judge_validation_automata_gemini.csv")

# Define the score columns and better titles
score_cols <- c(
  "score_creative_alignment", "score_instructional_precision",
  "score_emergence", "score_structural_coherence"
)
plot_titles <- c("Creative Alignment", "Instruction Following", "Emergence", "Structural Coherence")


# Paired Wilcoxon Signed-Rank Test

cat("Paired Wilcoxon Signed-Rank Test Results\n")

# Create a temporary wide dataframe
data_wide <- validation_data %>%
  pivot_wider(
    id_cols = problem_hash,
    names_from = model_name,
    values_from = all_of(score_cols)
  )

# Run and display tests for each scale
for (score in score_cols) {
  col_good <- paste0(score, "_validation_good")
  col_bad <- paste0(score, "_validation_poor")
  
  x <- data_wide[[col_good]]
  y <- data_wide[[col_bad]]
  
  test_result <- wilcox.test(x, y, paired = TRUE, exact = FALSE)
  
  cat(paste("Outcome Variable:", score, "\n"))
  p_value_formatted <- format.pval(test_result$p.value, digits = 4, eps = 0.0001)
  cat(paste("test statistic:", round(test_result$statistic, 4), "\n"))
  cat(paste("p-value:", p_value_formatted, "\n\n"))
}

# Classification performance
classification_data <- validation_data %>%
  mutate(true_class = ifelse(model_name == "validation_good", 1, 0))

cat("Best F1 score by classification threshold\n\n")
thresholds <- seq(0.5, 5.5, by = 1)
f1_results_list <- list()

# Find best F1 scores by looping over classification thresholds
for (score in score_cols) {
  f1_by_threshold <- data.frame()
  for (thresh in thresholds) {
    predictions <- ifelse(classification_data[[score]] >= thresh, 1, 0)
    tp <- sum(predictions == 1 & classification_data$true_class == 1)
    fp <- sum(predictions == 1 & classification_data$true_class == 0)
    fn <- sum(predictions == 0 & classification_data$true_class == 1)
    
    precision <- ifelse((tp + fp) > 0, tp / (tp + fp), 0)
    recall <- ifelse((tp + fn) > 0, tp / (tp + fn), 0)
    
    f1 <- ifelse((precision + recall) > 0, 2 * (precision * recall) / (precision + recall), 0)
    f1_by_threshold <- rbind(f1_by_threshold, data.frame(threshold = thresh, f1_score = f1))
  }
  best_result <- f1_by_threshold %>% arrange(desc(f1_score)) %>% head(1)
  f1_results_list[[score]] <- best_result
}

best_f1_summary <- do.call(rbind, f1_results_list)
best_f1_summary$score_metric <- rownames(best_f1_summary)
rownames(best_f1_summary) <- NULL
print(best_f1_summary[, c("score_metric", "threshold", "f1_score")])
cat("\n")

cat("ROC curve analysis\n")

# Prepare data
roc_data_list <- list()
for (i in seq_along(score_cols)) {
  score <- score_cols[i]
  
  # Calculate ROC object
  roc_obj <- roc(
    response = classification_data$true_class,
    predictor = classification_data[[score]],
    levels = c(0, 1), 
    direction = "<" 
  )
  
  # Extract data points and calculate AUC
  auc_value <- auc(roc_obj)
  plot_title <- paste0(plot_titles[i], "\n(AUC = ", format(auc_value, digits = 3), ")")
  
  # Sorting the points
  roc_data_list[[i]] <- tibble(
    specificity = roc_obj$specificities,
    sensitivity = roc_obj$sensitivities,
    metric = factor(plot_title)
  ) %>% arrange(1 - specificity, sensitivity)
}
plot_data <- bind_rows(roc_data_list)

roc_plot <- ggplot(plot_data, aes(x = 1 - specificity, y = sensitivity)) +
  # Add the ROC curve line and reference line
  geom_line(color = "#0072B2", linewidth = 1.1) +
  geom_abline(linetype = "dashed", color = "gray50") +
  
  # Create a separate plot for each scale in a single row
  facet_wrap(~ metric, ncol = 4) +
  
  # Ensure plots are square
  coord_fixed(xlim = c(0, 1), ylim = c(0, 1)) +
  
  labs(
    x = "1 - Specificity (False Positive Rate)",
    y = "Sensitivity (True Positive Rate)"
  ) +
  
  theme_bw() +
  theme(
    axis.title = element_text(size = 12),
    strip.text = element_text(face = "bold", size = 11)
  )

print(roc_plot)

#########################################################
########################################################
########################################################

# Inter-rater reliability

# Merge dataframes from different judge models
merged_data_irr <- inner_join(
  validation_data,
  validation_data_alt,
  by = c("problem_hash", "model_name"),
  suffix = c("_judge1", "_judge2")
)

for (score in score_cols) {
  cat(paste("Metric:", score, "\n"))
  
  # Define columns for the current metric
  col1 <- merged_data_irr[[paste0(score, "_judge1")]]
  col2 <- merged_data_irr[[paste0(score, "_judge2")]]
  
  # Spearman's rank-order correlation
  corr_test <- cor.test(col1, col2, method = "spearman", exact = FALSE)
  cat(paste("  Spearman's rho:", round(corr_test$estimate, 3), "\n"))
  
  # Prepare data matrix for Kappa and ICC
  ratings_matrix <- as.matrix(cbind(col1, col2))
  
  # Weighted Cohen's Kappa (quadratic)
  kappa_result <- kappa2(ratings_matrix, weight = "squared")
  cat(paste("  Weighted Kappa:", round(kappa_result$value, 3), "\n"))
  
  # Intraclass Correlation Coefficient (ICC)
  icc_agreement <- icc(ratings_matrix, model = "twoway", type = "agreement", unit = "single")
  icc_consistency <- icc(ratings_matrix, model = "twoway", type = "consistency", unit = "single")
  cat(paste("  ICC (Agreement):", round(icc_agreement$value, 3), "\n"))
  cat(paste("  ICC (Consistency):", round(icc_consistency$value, 3), "\n\n"))
}
