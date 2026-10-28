# Script: 17_E7_self_rated_performance_accuracy.R
# Reports: S1 E7; Figure 4F; S9 accuracy


# Set up paths and shared helpers -------------------------------------
script_id <- "17_E7_self_rated_performance_accuracy"
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) {
  arg <- grep("^--file=",commandArgs(FALSE),value=TRUE)
  if (length(arg)) repo_root <- dirname(dirname(dirname(normalizePath(sub("^--file=","",arg[1])))))
}
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) stop("Run from the nemo-paper-data root or set NEMO_REPO_ROOT.")
source(file.path(repo_root,"src","r","_setup.R"),local=TRUE)

library(dplyr)
library(ggplot2)
library(patchwork)
library(lme4)
library(lmerTest)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
df <- nemo_data %>%
  filter(
    wave <= 6,
    choseSource == 0,
    is.na(z_resid) | z_resid < 3,
    !is.na(s_adj), s_adj >= 0, s_adj <= 1,
    !is.na(age), age >= 6
  ) %>%
  mutate(receiver = ifelse(age <= 18, "child", "caregiver"))
cg <- df %>% filter(receiver == "caregiver")
ch <- df %>% filter(receiver == "child")

# Fit pooled and receiver-specific models -----------------------------
# Centre age and self-rated performance within each model sample.
m_accuracy_all <- lmer(abs(firstEstimate - nAnimals) ~ competence_c + age_c + (1 | ppt),
                       data = df %>%
                         filter(wave %in% 2:5) %>%
                         mutate(
                           age_c        = age - mean(age, na.rm = TRUE),
                           competence_c = competenceLadder - mean(competenceLadder, na.rm = TRUE)
                         ))
m_accuracy_cg <- lmer(abs(firstEstimate - nAnimals) ~ competence_c + age_c + (1 | ppt),
                      data = cg %>%
                        filter(wave %in% 2:5) %>%
                        mutate(
                          age_c        = age - mean(age, na.rm = TRUE),
                          competence_c = competenceLadder - mean(competenceLadder, na.rm = TRUE)
                        ))
m_accuracy_ch <- lmer(abs(firstEstimate - nAnimals) ~ competence_c + age_c + (1 | ppt),
                      data = ch %>%
                        filter(wave %in% 2:5) %>%
                        mutate(
                          age_c        = age - mean(age, na.rm = TRUE),
                          competence_c = competenceLadder - mean(competenceLadder, na.rm = TRUE)
                        ))
library(dplyr)
library(ggplot2)
library(patchwork)

# Prepare the figure sample -------------------------------------------
# The plotting preparation is retained separately from the model samples.
nemo_data <- read.csv(input_file)
df <- nemo_data %>%
  filter(
    wave <= 6,
    choseSource == 0,
    is.na(z_resid) | z_resid < 3,
    !is.na(s_adj), s_adj >= 0, s_adj <= 1,
    !is.na(age), age >= 6
  ) %>%
  mutate(receiver = ifelse(age <= 18, "child", "caregiver"))

# Summarise participant values for plotting ---------------------------
plot_data <- df %>%
  filter(wave %in% 2:5, !is.na(competenceLadder)) %>%
  mutate(
    competence_c = competenceLadder - mean(competenceLadder, na.rm = TRUE),
    abs_error    = abs(firstEstimate - nAnimals),
    receiver     = factor(receiver,
                          levels = c("caregiver", "child"),
                          labels = c("Caregiver", "Child"))
  )
col_caregiver <- "#00BFC4"
col_child     <- "#F8766D"
base_theme <- theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor  = element_blank(),
    axis.title        = element_text(size = 12),
    axis.text         = element_text(size = 11),
    legend.position   = "bottom",
    legend.title      = element_blank(),
    legend.text       = element_text(size = 11),
    plot.tag          = element_text(face = "bold", size = 14)
  )

# Draw the self-rated performance panel -------------------------------
panel_B <- ggplot(plot_data,
                  aes(x = competence_c, y = abs_error,
                      color = receiver, fill = receiver)) +
  geom_jitter(alpha = 0.07, size = 0.8, width = 0.1, height = 0,
              show.legend = FALSE) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.1, alpha = 0.18) +
  scale_color_manual(values = c("Caregiver" = col_caregiver,
                                "Child"     = col_child)) +
  scale_fill_manual(values  = c("Caregiver" = col_caregiver,
                                "Child"     = col_child)) +
  coord_cartesian(ylim = c(0, 40)) +
  labs(
    x        = "Self-rated confidence (mean-centered)",
    y        = "Absolute estimation error",
    tag      = "B",
    subtitle = NULL
  ) +
  base_theme +
  theme(plot.subtitle = element_text(size = 10, color = "grey30", margin = margin(b = 4)))


# Save results and session information --------------------------------
save_model(m_accuracy_all,"m_accuracy_all")
save_model(m_accuracy_cg,"m_accuracy_cg")
save_model(m_accuracy_ch,"m_accuracy_ch")
panel_B <- panel_B + labs(tag="F")
save_plot(panel_B,"panel_B")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
