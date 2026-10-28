# Script: 14_E4_estimation_accuracy.R
# Reports: S1 E4; Figure 4B–C


# Set up paths and shared helpers -------------------------------------
script_id <- "14_E4_estimation_accuracy"
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) {
  arg <- grep("^--file=",commandArgs(FALSE),value=TRUE)
  if (length(arg)) repo_root <- dirname(dirname(dirname(normalizePath(sub("^--file=","",arg[1])))))
}
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) stop("Run from the nemo-paper-data root or set NEMO_REPO_ROOT.")
source(file.path(repo_root,"src","r","_setup.R"),local=TRUE)

library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)
library(tibble)
library(ggforce)
library(lme4)
library(lmerTest)
library(emmeans)
library(MuMIn)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
fig4a_data <- nemo_data %>%
  filter(wave != 2 | socialSource %in% c(2, 3))
fig4a_data <- fig4a_data %>%
  filter(is.na(z_resid) | z_resid < 3)
fig4a_data <- fig4a_data %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
fig4a_data <- fig4a_data %>%
  filter(!is.na(age), age >= 6)
fig4a_data <- fig4a_data %>%
  mutate(
    receiver      = ifelse(age <= 18, "child", "caregiver"),
    prop_error_E1 = abs(firstEstimate  - nAnimals) / nAnimals,
    prop_error_E2 = abs(secondEstimate - nAnimals) / nAnimals,
    condition     = case_when(
      choseSource == 0 ~ "Assigned",
      choseSource == 1 ~ "Chosen",
      TRUE             ~ NA_character_
    ),
    source_label  = case_when(
      socialSource == 1                                    ~ "Vertical",
      socialSource == 2 & receiver == "child"             ~ "Oblique",
      socialSource == 2 & receiver == "caregiver"         ~ "Horizontal",
      socialSource == 3 & receiver == "child"             ~ "Horizontal",
      socialSource == 3 & receiver == "caregiver"         ~ "Oblique",
      TRUE                                                 ~ NA_character_
    )
  )

# Summarise error for each participant --------------------------------
ppt_summary <- fig4a_data %>%
  group_by(ppt, receiver) %>%
  summarise(
    age         = first(age),
    mean_S      = mean(s_adj,         na.rm = TRUE),
    mean_err_E1 = mean(prop_error_E1, na.rm = TRUE),
    mean_err_E2 = mean(prop_error_E2, na.rm = TRUE),
    n_trials    = n(),
    .groups     = "drop"
  )
ppt_children  <- ppt_summary %>% filter(receiver == "child")
ppt_caregivers <- ppt_summary %>% filter(receiver == "caregiver")
n_children         <- nrow(ppt_children)
n_caregivers       <- nrow(ppt_caregivers)
n_label_children   <- paste0("n = ", n_children)
n_label_caregivers <- paste0("n = ", n_caregivers)

# Prepare before and after error plots --------------------------------
ppt_err_long <- ppt_summary %>%
  select(ppt, receiver, age, mean_err_E1, mean_err_E2) %>%
  pivot_longer(
    cols      = c(mean_err_E1, mean_err_E2),
    names_to  = "estimate",
    values_to = "prop_error"
  ) %>%
  mutate(
    estimate = recode(estimate,
                      "mean_err_E1" = "Before (E1)",
                      "mean_err_E2" = "After (E2)")
  )
plot_err_children <- ppt_err_long %>%
  filter(receiver == "child") %>%
  ggplot(aes(x = age, y = prop_error, linetype = estimate,
             colour = estimate, fill = estimate)) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 1) +
  scale_x_continuous(breaks = seq(6, 18, by = 2)) +
  scale_linetype_manual(
    values = c("Before (E1)" = "dashed", "After (E2)" = "solid")
  ) +
  scale_colour_manual(
    values = c("Before (E1)" = "#999999", "After (E2)" = "#F8766D")
  ) +
  scale_fill_manual(
    values = c("Before (E1)" = "#999999", "After (E2)" = "#F8766D")
  ) +
  coord_cartesian(ylim = c(0, 0.45)) +
  labs(
    x        = "Age (years)",
    y        = "Mean proportional error (|E - T| / T)",
    linetype = NULL,
    colour   = NULL,
    fill     = NULL,
    subtitle = n_label_children
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")
plot_err_adults <- ppt_err_long %>%
  filter(receiver == "caregiver") %>%
  ggplot(aes(x = age, y = prop_error, linetype = estimate,
             colour = estimate, fill = estimate)) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 1) +
  scale_linetype_manual(
    values = c("Before (E1)" = "dashed", "After (E2)" = "solid")
  ) +
  scale_colour_manual(
    values = c("Before (E1)" = "#999999", "After (E2)" = "#00BFC4")
  ) +
  scale_fill_manual(
    values = c("Before (E1)" = "#999999", "After (E2)" = "#00BFC4")
  ) +
  coord_cartesian(ylim = c(0, 0.45)) +
  labs(
    x        = "Age (years)",
    y        = "Mean proportional error (|E - T| / T)",
    linetype = NULL,
    colour   = NULL,
    fill     = NULL,
    subtitle = n_label_caregivers
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")

# Prepare trial-level error comparisons -------------------------------
acc_long <- fig4a_data %>%
  filter(!is.na(prop_error_E1), !is.na(prop_error_E2)) %>%
  select(ppt, wave, receiver, age, source_label, prop_error_E1, prop_error_E2) %>%
  pivot_longer(
    cols      = c(prop_error_E1, prop_error_E2),
    names_to  = "estimate",
    values_to = "prop_error"
  ) %>%
  mutate(
    estimate     = factor(
      recode(estimate, "prop_error_E1" = "Before", "prop_error_E2" = "After"),
      levels = c("Before", "After")        # Before = reference level
    ),
    receiver     = factor(receiver,     levels = c("caregiver", "child")),
    source_label = factor(source_label, levels = c("Vertical", "Oblique", "Horizontal"))
  )

# Fit overall and receiver-specific accuracy models -------------------
m10_1 <- lmer(prop_error ~ estimate + (1 | ppt),
              data = acc_long, REML = FALSE)
m10_2 <- lmer(prop_error ~ estimate * receiver + (1 | ppt),
              data = acc_long, REML = FALSE)
emm10_2 <- emmeans(m10_2, ~ estimate | receiver)


# Save results and session information --------------------------------
write.csv(as.data.frame(pairs(emm10_2,adjust="bonferroni")),file.path(table_dir,"receiver_improvements.csv"),row.names=FALSE)
save_model(m10_1,"m10_1")
save_model(m10_2,"m10_2")
save_plot(plot_err_children,"plot_err_children")
save_plot(plot_err_adults,"plot_err_adults")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
