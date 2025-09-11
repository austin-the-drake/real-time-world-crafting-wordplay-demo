if(!require(tidyverse)) install.packages("tidyverse")
if(!require(lme4)) install.packages("lme4")
if(!require(lmerTest)) install.packages("lmerTest")
if(!require(performance)) install.packages("performance")

library(tidyverse)
library(lme4)
library(lmerTest)
library(performance)

# I usually load data in the RStudio GUI
#analysis_data <- read.csv("bidirectional_data.csv")

# Convert to factor types
analysis_data <- analysis_data %>%
  mutate(
    description_style = as.factor(description_style),
    description_detail = as.factor(description_detail),
    planning = as.factor(planning)
  )

# Tree edit distance
model_tree_edit <- lmer(score_tree_edit_distance ~ description_style * description_detail +
                          param_component_complexity +
                          param_nesting_complexity +
                          (1 | procedural_code_hash),
                        data = analysis_data)

print("Results for tree edit distance")
summary(model_tree_edit)

print("R-squared for tree edit distance model:")
print(r2(model_tree_edit))


# Jaccard similarity
model_jaccard <- lmer(score_jaccard_similarity ~ description_style * description_detail +
                        param_component_complexity +
                        param_nesting_complexity +
                        (1 | procedural_code_hash),
                      data = analysis_data)

print("Results for Jaccard similarity")
summary(model_jaccard)

print("R-squared for Jaccard similarity model:")
print(r2(model_jaccard))




# Pivot from wide to long for plotting
plot_data_exp2 <- analysis_data %>%
  pivot_longer(
    cols = c(score_tree_edit_distance, score_jaccard_similarity),
    names_to = "metric",
    values_to = "score"
  ) %>%
  # Clean up names for better plot labels
  mutate(
    metric = factor(case_when(
      metric == "score_tree_edit_distance" ~ "Tree Edit Distance (lower is better)",
      metric == "score_jaccard_similarity" ~ "Jaccard Similarity (higher is better)"
    ))
  )

exp2_plot <- ggplot(plot_data_exp2, aes(x = description_style, y = score, fill = description_detail)) +
  
  # Create clustered bars
  stat_summary(fun = mean, geom = "bar", position = position_dodge(width = 0.9)) +
  stat_summary(fun.data = mean_se, geom = "errorbar", position = position_dodge(width = 0.9), width = 0.3) +
  
  # Create two plots
  facet_wrap(~ metric, scales = "free_y") +
  
  scale_fill_manual(values = c("detailed" = "#1f77b4", "summary" = "#ff7f0e")) +
  
  # Add labels
  labs(
    title = "Effect of Description Style and Detail on Information Preservation",
    x = "Description Style",
    y = "Mean Score",
    fill = "Description Detail"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(size = 11),
    strip.text = element_text(face = "bold", size = 11)
  )

print(exp2_plot)
