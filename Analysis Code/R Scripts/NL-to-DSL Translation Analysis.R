if(!require(tidyverse)) install.packages("tidyverse")
if(!require(afex)) install.packages("afex")
if(!require(effectsize)) install.packages("effectsize")
if(!require(emmeans)) install.packages("emmeans")

library(tidyverse)
library(afex)
library(effectsize)
library(emmeans)

# I usually just load data through the RStudio GUI
#analysis_data <- read.csv("nl_to_dsl_spells.csv")
#analysis_data <- read.csv("nl_to_dsl_automata.csv")

# Convert columns to factors
analysis_data <- analysis_data %>%
  mutate(
    problem_hash = as.factor(problem_hash),
    model_name = as.factor(model_name),
    shot_strategy = as.factor(shot_strategy),
    planning = as.factor(planning),
    
    # New column for testing gemma specifically
    model_group = as.factor(ifelse(model_name == "gemma-3-4b-it", "gemma-3-4b-it", "Other"))
  )

score_variables <- c(
  "score_creative_alignment",
  "score_instructional_precision",
  "score_emergence",
  "score_structural_coherence"
)

# ANOVA
cat("ANOVA Results\n")
for (score in score_variables) {
  cat("\nResults for:", score, "\n")
  
  # Within-subjects formula using Error(id / factors)
  formula_str <- as.formula(
    paste(score, "~ model_name * shot_strategy * planning + Error(problem_hash / (model_name * shot_strategy * planning))")
  )
  
  aov_model <- aov_car(formula_str, data = analysis_data)
  
  print(aov_model)
  
  # Run posthoc tests
  cat("\nPost-hoc Tests (Tukey's HSD)\n")
  
  # Pairwise comparisons for model_name
  emm_model <- emmeans(aov_model, ~ model_name)
  print(pairs(emm_model, adjust = "tukey"))
  
  # Pairwise comparisons for shot_strategy
  emm_shot <- emmeans(aov_model, ~ shot_strategy)
  print(pairs(emm_shot, adjust = "tukey"))
}

# Calculating the mean difference and Cohen's d for the small model
cat("\n\nEffect Sizes (gemma-3-4b-it vs. Other)\n")

for (score in score_variables) {
  cat("Effect Size for:", score, "\n")
  formula <- as.formula(paste(score, "~ model_group"))
  
  # Calculate Cohen's d
  effect_size_result <- cohens_d(formula, data = analysis_data)
  
  # Calculate group means
  group_means <- analysis_data %>%
    group_by(model_group) %>%
    summarise(mean_score = mean(.data[[score]], na.rm = TRUE), .groups = 'drop')
  
  mean_gemma <- group_means$mean_score[group_means$model_group == "gemma-3-4b-it"]
  mean_other <- group_means$mean_score[group_means$model_group == "Other"]
  
  # Print the results
  cat(paste("Mean Score (gemma-3-4b-it):", round(mean_gemma, 2), "\n"))
  cat(paste("Mean Score (Other Models):", round(mean_other, 2), "\n"))
  cat(paste("Cohen's d:", round(effect_size_result$Cohens_d, 3), "\n\n"))
}

# Calculate the success rate
asr_summary <- analysis_data %>%
  # Convert the pass/fail factor to numeric
  mutate(success = ifelse(score_programmatic_validation == "Passed", 1, 0)) %>%
  
  group_by(model_name, shot_strategy, planning) %>%
  summarise(asr = mean(success, na.rm = TRUE)) %>%
  
  ungroup() %>%
  
  # Make the planning column more readable
  mutate(planning = ifelse(planning == 1, "CoT", "Standard")) %>%
  
  # Pivot the table into a wide format
  pivot_wider(
    names_from = c(shot_strategy, planning),
    values_from = asr,
    names_sep = " + "
  )

print(asr_summary, width=Inf)


# Visualisation
plot_data <- analysis_data %>%
  pivot_longer(
    cols = all_of(score_variables),
    names_to = "metric",
    values_to = "score"
  ) %>%
  mutate(
    metric = factor(case_when(
      metric == "score_creative_alignment"      ~ "Creative Alignment",
      metric == "score_instructional_precision" ~ "Instruction Following",
      metric == "score_emergence"               ~ "Emergence",
      metric == "score_structural_coherence"    ~ "Structural Coherence"
    ), levels = c("Creative Alignment", "Instruction Following", "Emergence", "Structural Coherence")),
    
    model_name_clean = factor(case_when(
      grepl("claude", model_name) ~ "Claude 4 Sonnet",
      grepl("gemini", model_name) ~ "Gemini 2.5 Flash",
      grepl("gemma", model_name) ~ "Gemma 3 (4B)",
      grepl("gpt", model_name) ~ "GPT-4.1 Mini"
    )),
    
    shot_strategy = factor(shot_strategy, levels = c("zeroshot", "oneshot", "fewshot")),
    planning_clean = factor(ifelse(planning == 1, "Chain-of-Thought", "Standard"),
                            levels = c("Standard", "Chain-of-Thought"))
  )

interaction_plot <- ggplot(plot_data, aes(x = shot_strategy, y = score,
                                             color = model_name_clean,
                                             linetype = planning_clean,
                                             group = interaction(model_name_clean, planning_clean))) +
  
  stat_summary(fun = mean, geom = "line", linewidth = 1) +
  stat_summary(fun = mean, geom = "point", size = 2.5) +
  
  facet_wrap(~ metric, ncol = 4) +
  
  scale_color_manual(values = c(
    "Claude 4 Sonnet" = "#1f77b4",
    "Gemini 2.5 Flash" = "#ff7f0e",
    "Gemma 3 (4B)" = "#2ca02c",
    "GPT-4.1 Mini" = "#d62728"
  )) +
  
  labs(
    title = "Interaction of Model, Planning, and Shot Strategy on Qualitative Scores",
    x = "Shot Strategy",
    y = "Mean Score (1-5)",
    color = "Model",
    linetype = "Planning"
  ) +
  theme_bw() +
  theme(
    strip.text = element_text(face = "bold")
  ) +
  coord_cartesian(ylim = c(1, 5))

print(interaction_plot)

