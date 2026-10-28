# Script: 15_E5_accuracy_by_pathway.R
# Reports: S1 E5; Figure 4D; Figure S2; S8


# Set up paths and shared helpers -------------------------------------
script_id <- "15_E5_accuracy_by_pathway"
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

# Summarise before and after error by pathway -------------------------
comet_data <- fig4a_data %>%
  filter(!is.na(source_label), !is.na(condition)) %>%
  mutate(
    condition_comet = ifelse(source_label == "Vertical", "Pooled", condition)
  ) %>%
  group_by(source_label, condition_comet, receiver) %>%
  summarise(
    mean_E1  = mean(prop_error_E1, na.rm = TRUE),
    mean_E2  = mean(prop_error_E2, na.rm = TRUE),
    n_trials = n(),
    .groups  = "drop"
  )
comet_data <- comet_data %>%
  mutate(
    source_condition = case_when(
      source_label == "Vertical"                    ~ "Vertical",
      TRUE ~ paste0(source_label, "\n(", condition_comet, ")")
    ),
    source_condition = factor(source_condition,
                              levels = c(
                                "Vertical",
                                "Oblique\n(Assigned)",
                                "Oblique\n(Chosen)",
                                "Horizontal\n(Assigned)",
                                "Horizontal\n(Chosen)"
                              ))
  )

# Define receiver-specific error panels -------------------------------
make_comet_plot <- function(receiver_str, fill_colour, subtitle_text) {
  
  plot_data <- comet_data %>% filter(receiver == receiver_str)
  
  ggplot(plot_data) +
    ggforce::geom_link(
      aes(x         = source_condition,
          xend      = source_condition,
          y         = mean_E1,
          yend      = mean_E2,
          linewidth = after_stat(index)),
      colour  = fill_colour,
      alpha   = 0.8,
      n       = 900,
      lineend = "round"
    ) +
    scale_linewidth(range = c(0.1, 6), guide = "none") +
    geom_point(
      aes(x = source_condition, y = mean_E1),
      shape  = 16,
      size   = 2,
      colour = "#999999"
    ) +
    geom_point(
      aes(x = source_condition, y = mean_E2),
      shape  = 21,
      size   = 4,
      colour = fill_colour,
      fill   = "white",
      stroke = 1.0      
    ) +
    geom_text(
      aes(x     = source_condition,
          y     = mean_E1,
          label = sprintf("%.2f", mean_E1)),
      hjust  = -0.4,
      vjust  = 0,
      size   = 4.5,
      colour = "#888888"
    ) +
    geom_text(
      aes(x     = source_condition,
          y     = mean_E2,
          label = sprintf("%.2f", mean_E2)),
      hjust  = -0.4,
      vjust  = 0.8,
      size   = 4.5,
      colour = fill_colour
    ) +
    scale_y_continuous(
      limits = c(0, 0.45),
      breaks = seq(0, 0.4, by = 0.1)
    ) +
    labs(
      y        = "Mean proportional error (|E - T| / T)",
      x        = NULL,
      subtitle = subtitle_text,
      caption  = "Open circle = before (E1); filled circle = after (E2)"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      axis.text.x      = element_text(size = 11)
    )
}
plot_comet_children <- make_comet_plot(
  receiver_str  = "child",
  fill_colour   = "#F8766D",
  subtitle_text = paste0("Children  |  ", n_label_children)
)
plot_comet_caregivers <- make_comet_plot(
  receiver_str  = "caregiver",
  fill_colour   = "#00BFC4",
  subtitle_text = paste0("Caregivers  |  ", n_label_caregivers)
)

# Prepare trial-level accuracy data -----------------------------------
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

# Fit pathway effects and additive comparator -------------------------
# The additive model supports the interaction likelihood-ratio comparison.
m10_3 <- lmer(prop_error ~ estimate * source_label + (1 | ppt),
              data = acc_long %>% filter(!is.na(source_label)),
              REML = FALSE)
m10_3_base <- lmer(prop_error ~ estimate + source_label + (1 | ppt),
                   data = acc_long %>% filter(!is.na(source_label)),
                   REML = FALSE)
emm10_3 <- emmeans(m10_3, ~ estimate | source_label)

# Prepare pooled pathway panel ----------------------------------------
comet_data_pooled <- fig4a_data %>% filter(!is.na(source_label)) %>%
 group_by(source_label,receiver) %>%
 summarise(mean_E1=mean(prop_error_E1,na.rm=TRUE),mean_E2=mean(prop_error_E2,na.rm=TRUE),n_trials=n(),.groups="drop") %>%
 mutate(source_label=factor(source_label,levels=c("Vertical","Oblique","Horizontal")))
dodge_w <- 0.19   # horizontal separation between the two receivers
comet_data_combined <- comet_data_pooled %>%
  mutate(
    receiver  = factor(receiver, levels = c("child", "caregiver")),
    x_num     = as.numeric(source_label) +
      ifelse(receiver == "child", -dodge_w, dodge_w),
    lab_hjust = -0.3
  )
col_child     <- "#F8766D"
col_caregiver <- "#00BFC4"

# Draw pooled accuracy panel ------------------------------------------
plot_comet_pooled_combined <- ggplot(comet_data_combined) +
  ggforce::geom_link(
    aes(x = x_num, xend = x_num,
        y = mean_E1, yend = mean_E2,
        colour = receiver, linewidth = after_stat(index)),
    alpha = 0.8, n = 900, lineend = "round", show.legend = FALSE
  ) +
  scale_linewidth(range = c(0.1, 6), guide = "none") +
  geom_point(aes(x = x_num, y = mean_E1),
             shape = 16, size = 2, colour = "#999999") +
  geom_point(aes(x = x_num, y = mean_E2, colour = receiver),
             shape = 21, size = 4, fill = "white", stroke = 1.0) +
  geom_text(aes(x = x_num, y = mean_E1, label = sprintf("%.2f", mean_E1),
                hjust = lab_hjust),
            vjust = 0, size = 4, colour = "#888888") +
  geom_text(aes(x = x_num, y = mean_E2, label = sprintf("%.2f", mean_E2),
                hjust = lab_hjust, colour = receiver),
            vjust = 0.8, size = 4, show.legend = FALSE) +
  scale_colour_manual(
    values = c("child" = col_child, "caregiver" = col_caregiver),
    labels = c("child" = "Child", "caregiver" = "Caregiver"),
    name   = NULL
  ) +
  scale_x_continuous(
    breaks = 1:3,
    labels = c("Vertical", "Oblique", "Horizontal"),
    limits = c(0.45, 3.75)
  ) +
  scale_y_continuous(limits = c(0, 0.45), breaks = seq(0, 0.4, by = 0.1)) +
  labs(
    x        = NULL,
    y        = "Mean proportional error (|E - T| / T)",
    subtitle = paste0("Children: ", n_label_children,
                      "  |  Caregivers: ", n_label_caregivers),
    caption  = "Open circle = before (E1); filled circle = after (E2)"
  ) +
  guides(colour = guide_legend(override.aes = list(size = 4, linewidth = 0))) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x      = element_text(size = 12),
    legend.position  = "bottom"
  )


# Save results and session information --------------------------------
write.csv(as.data.frame(anova(m10_3_base,m10_3)),file.path(table_dir,"interaction_lrt.csv"))
write.csv(as.data.frame(pairs(emm10_3,adjust="bonferroni")),file.path(table_dir,"pathway_improvements.csv"),row.names=FALSE)
save_model(m10_3,"m10_3")
save_model(m10_3_base,"m10_3_base")
save_plot(plot_comet_pooled_combined,"plot_comet_pooled_combined")
save_plot(plot_comet_children,"plot_comet_children")
save_plot(plot_comet_caregivers,"plot_comet_caregivers")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
