if(!require(tidyverse)) install.packages("tidyverse")
if(!require(effectsize)) install.packages("effectsize")
if(!require(afex)) install.packages("afex")
if(!require(emmeans)) install.packages("emmeans")

library(tidyverse)
library(effectsize)
library(afex)
library(emmeans)

# I usually just load data through the RStudio GUI
#data <- read.csv("latency_spells.csv")

# Set a specfic order for the plot
model_order <- c("gemma-3-4b-it", "gpt-4.1-mini", "claude-sonnet-4-20250514", "gemini-2.5-flash")

# Set cleaner labels
model_labels <- c(
  "gemma-3-4b-it" = "Gemma 3 (4B)",
  "gpt-4.1-mini" = "GPT 4.1 Mini",
  "claude-sonnet-4-20250514" = "Claude 4 Sonnet",
  "gemini-2.5-flash" = "Gemini 2.5 Flash"
)

strategy_labels <- c(
  "zeroshot" = "Zero-Shot",
  "oneshot" = "One-Shot",
  "fewshot" = "Few-Shot"
)

planning_labels <- c(
  "0" = "No Planning",
  "1" = "With Planning"
)


# Data prep
data_prepared <- data %>%
  mutate(
    # Add an ID column for afex
    id = as.factor(row_number()),
    model_name = factor(model_name, levels = model_order),
    shot_strategy = as.factor(shot_strategy),
    planning = as.factor(planning)
  )

# Calculate main effect means
print("Mean latency by factor")
print(data_prepared %>% group_by(model_name) %>% summarise(mean_latency = mean(time, na.rm = TRUE)))
print(data_prepared %>% group_by(shot_strategy) %>% summarise(mean_latency = mean(time, na.rm = TRUE)))
print(data_prepared %>% group_by(planning) %>% summarise(mean_latency = mean(time, na.rm = TRUE)))


# ANOVA
print("ANOVA")
# aov_4 is meant for between-subjects designs.
# The random effect (1|id) is required but is essentially just an intercept
aov_model <- aov_4(time ~ model_name * shot_strategy * planning + (1|id), data = data_prepared)
print(aov_model)

print("Effect Sizes (Eta Squared)")
print(eta_squared(aov_model, generalized = TRUE))


# Posthoc tests
print("Post-Hoc Test (Tukey's HSD for model)")
emm_model <- emmeans(aov_model, ~ model_name)
print(pairs(emm_model, adjust = "tukey"))


# Interaction plot
interaction_plot <- ggplot(data_prepared, aes(x = model_name, y = time, color = shot_strategy, group = shot_strategy)) +
  stat_summary(fun = mean, geom = "line", linewidth = 1) +
  stat_summary(fun.data = mean_se, geom = "point", size = 2.5) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2) +
  
  # Apply labels
  facet_wrap(~planning, labeller = as_labeller(planning_labels)) +
  scale_x_discrete(labels = model_labels) +
  
  scale_color_manual(values = c("zeroshot" = "#1f77b4", "oneshot" = "#ff7f0e", "fewshot" = "#2ca02c"),
                     labels = strategy_labels) +
  
  labs(
    title = "Interaction of Model, Strategy, and Planning on Task Latency",
    x = "Model",
    y = "Average Latency (seconds)",
    color = "Shot Strategy"
  ) +
  
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold"),
    legend.position = "right"
  )

print(interaction_plot)
