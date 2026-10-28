# Script: 12_E2_child_chosen_information.R
# Reports: S1 E2; Figure 3C; S6 children


# Set up paths and shared helpers -------------------------------------
script_id <- "12_E2_child_chosen_information"
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
library(lme4)
library(lmerTest)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)

# Prepare Waves 7 and 8 -----------------------------------------------
# Apply trial filters and link family ages within this wave block.
choice_data_w7_8 <- nemo_data %>%
  filter(
    wave %in% c(7, 8),
    choseSource == 1
  )
choice_data_w7_8 <- choice_data_w7_8 %>%
  filter(!is.na(age), age >= 6, age <= 70)
choice_data_w7_8 <- choice_data_w7_8 %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
choice_data_w7_8 <- choice_data_w7_8 %>%
  filter(is.na(z_resid) | abs(z_resid) < 3)
choice_data_w7_8 <- choice_data_w7_8 %>%
  mutate(
    age_group = case_when(
      age >= 6  & age <= 18 ~ "child",
      age >= 19 & age <= 70 ~ "adult",
      TRUE ~ NA_character_
    )
  )
own_child_lookup_w7_8 <- choice_data_w7_8 %>%
  filter(age >= 6, age <= 18) %>%
  distinct(wave, group, ppt, age) %>%
  group_by(wave, group) %>%
  summarise(
    own_child_age = first(age),
    .groups = "drop"
  )
choice_data_w7_8 <- choice_data_w7_8 %>%
  left_join(
    own_child_lookup_w7_8 %>% select(wave, group, own_child_age),
    by = c("wave", "group")
  )
choice_data_w7_8 <- choice_data_w7_8 %>%
  mutate(
    source_child_age = case_when(
      age_group == "child"                              ~ age,
      age_group == "adult" & socialSource == 1         ~ own_child_age,
      age_group == "adult" & socialSource == 3         ~ own_child_age,
      TRUE                                             ~ NA_real_
    )
  )
h5_trials_w7_8 <- choice_data_w7_8 %>%
  mutate(
    age_group = factor(
      if_else(age_group == "child", "Child", "Adult"),
      levels = c("Child", "Adult")
    ),
    transmission = case_when(
      age_group == "Child" & socialSource == 1 ~ "Vertical",
      age_group == "Child" & socialSource == 2 ~ "Oblique",
      age_group == "Child" & socialSource == 3 ~ "Horizontal",
      age_group == "Adult" & socialSource == 1 ~ "Vertical",
      age_group == "Adult" & socialSource == 3 ~ "Oblique",
      TRUE ~ NA_character_
    ),
    age_x = source_child_age
  ) %>%
  filter(
    !is.na(transmission),
    !is.na(age_x),
    age_x >= 6,
    age_x <= 18,
    age_group == "Child"
  ) %>%
  mutate(
    transmission = factor(transmission, levels = c("Vertical", "Oblique", "Horizontal"))
  )

# Prepare Waves 9 and 10 ----------------------------------------------
# Use dyad and participant lookups to identify the chosen source child.
choice_data_w9_10 <- nemo_data %>%
  filter(
    wave %in% c(9, 10),
    choseSource == 1
  )
choice_data_w9_10 <- choice_data_w9_10 %>%
  filter(!is.na(age), age >= 6, age <= 70)
choice_data_w9_10 <- choice_data_w9_10 %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
choice_data_w9_10 <- choice_data_w9_10 %>%
  filter(is.na(z_resid) | abs(z_resid) < 3)
choice_data_w9_10 <- choice_data_w9_10 %>%
  mutate(
    age_group = case_when(
      age >= 6  & age <= 18 ~ "child",
      age >= 19 & age <= 70 ~ "adult",
      TRUE ~ NA_character_
    )
  )
own_child_lookup_w9_10 <- choice_data_w9_10 %>%
  filter(age >= 6, age <= 18) %>%
  distinct(wave, group, dyad, ppt, age) %>%
  group_by(wave, group, dyad) %>%
  summarise(
    own_child_age = first(age),
    .groups = "drop"
  )
choice_data_w9_10 <- choice_data_w9_10 %>%
  left_join(
    own_child_lookup_w9_10 %>% select(wave, group, dyad, own_child_age),
    by = c("wave", "group", "dyad")
  )
group_child_lookup <- choice_data_w9_10 %>%
  filter(age >= 6, age <= 18) %>%
  distinct(wave, group, dyad, child_age = age)
participant_lookup <- choice_data_w9_10 %>%
  distinct(wave, group, dyad, ppt)
other_child_lookup <- participant_lookup %>%
  left_join(
    group_child_lookup,
    by = c("wave", "group"),
    relationship = "many-to-many"
  ) %>%
  filter(dyad.x != dyad.y) %>%
  group_by(wave, group, dyad.x, ppt) %>%
  summarise(
    other_child_age = first(child_age),
    .groups = "drop"
  ) %>%
  rename(dyad = dyad.x)
choice_data_w9_10 <- choice_data_w9_10 %>%
  left_join(
    other_child_lookup %>% select(wave, group, dyad, ppt, other_child_age),
    by = c("wave", "group", "dyad", "ppt")
  )
choice_data_w9_10 <- choice_data_w9_10 %>%
  mutate(
    source_child_age = case_when(
      age_group == "child"                              ~ age,
      age_group == "adult" & socialSource == 1         ~ own_child_age,
      age_group == "adult" & socialSource == 3         ~ other_child_age,
      TRUE                                             ~ NA_real_
    )
  )
h5_trials_w9_10 <- choice_data_w9_10 %>%
  mutate(
    age_group = factor(
      if_else(age_group == "child", "Child", "Adult"),
      levels = c("Child", "Adult")
    ),
    transmission = case_when(
      age_group == "Child" & socialSource == 1 ~ "Vertical",
      age_group == "Child" & socialSource == 2 ~ "Oblique",
      age_group == "Child" & socialSource == 3 ~ "Horizontal",
      age_group == "Adult" & socialSource == 1 ~ "Vertical",
      age_group == "Adult" & socialSource == 3 ~ "Oblique",
      TRUE ~ NA_character_
    ),
    age_x = source_child_age
  ) %>%
  filter(
    !is.na(transmission),
    !is.na(age_x),
    age_x >= 6,
    age_x <= 18,
    age_group == "Child"
  ) %>%
  mutate(
    transmission = factor(transmission, levels = c("Vertical", "Oblique", "Horizontal"))
  )

# Combine the wave blocks ---------------------------------------------
h5_trials_all <- bind_rows(h5_trials_w7_8, h5_trials_w9_10)
pooled_age_mean <- mean(h5_trials_all$age_x, na.rm = TRUE)
h5_trials_all <- h5_trials_all %>%
  mutate(age_c = age_x - pooled_age_mean)

# Fit the pooled chosen-information model -----------------------------
h5_model_combined <- lmer(
  s_adj ~ age_c * transmission + (1 | ppt),
  data = h5_trials_all,
  REML = FALSE
)

# Prepare observed means and model predictions ------------------------
age_means_all <- h5_trials_all %>%
  group_by(age_x, transmission) %>%
  summarise(
    mean_S_age = mean(s_adj, na.rm = TRUE),
    n          = n_distinct(ppt),
    .groups    = "drop"
  )
age_seq <- seq(
  min(h5_trials_all$age_x, na.rm = TRUE),
  max(h5_trials_all$age_x, na.rm = TRUE),
  length.out = 300
)
pred_grid_all <- expand.grid(
  age_x        = age_seq,
  transmission = levels(h5_trials_all$transmission)
) %>%
  as_tibble() %>%
  mutate(
    transmission = factor(transmission, levels = levels(h5_trials_all$transmission)),
    age_c        = age_x - pooled_age_mean
  )
pred_grid_all$fit <- predict(h5_model_combined, newdata = pred_grid_all, re.form = NA)
X_all    <- model.matrix(delete.response(terms(h5_model_combined)), pred_grid_all)
beta_all <- fixef(h5_model_combined)
V_all    <- vcov(h5_model_combined)
X_all    <- X_all[, names(beta_all), drop = FALSE]
pred_grid_all$se  <- sqrt(diag(X_all %*% V_all %*% t(X_all)))
pred_grid_all$lwr <- pred_grid_all$fit - 1.96 * pred_grid_all$se
pred_grid_all$upr <- pred_grid_all$fit + 1.96 * pred_grid_all$se
line_N_all <- h5_trials_all %>%
  group_by(transmission) %>%
  summarise(N = n_distinct(ppt), .groups = "drop") %>%
  mutate(label = paste0("N = ", N))
label_vec_all <- setNames(
  paste0(line_N_all$transmission, " (N = ", line_N_all$N, ")"),
  line_N_all$transmission
)
pred_grid_comb <- pred_grid_all %>%
  mutate(transmission = factor(
    label_vec_all[as.character(transmission)],
    levels = label_vec_all
  ))
age_means_comb <- age_means_all %>%
  mutate(transmission = factor(
    label_vec_all[as.character(transmission)],
    levels = label_vec_all
  )) %>%
  mutate(
    age_x_dodge = case_when(
      grepl("Vertical",   as.character(transmission)) ~ age_x - 0.15,
      grepl("Oblique",    as.character(transmission)) ~ age_x,
      grepl("Horizontal", as.character(transmission)) ~ age_x + 0.15
    )
  )

# Draw the chosen-information panel -----------------------------------
plot_combined <- ggplot() +
  geom_ribbon(
    data = pred_grid_comb,
    aes(x = age_x, ymin = lwr, ymax = upr, fill = transmission),
    alpha = 0.15
  ) +
  geom_line(
    data = pred_grid_comb,
    aes(x = age_x, y = fit, color = transmission),
    linewidth = 1.3
  ) +
  geom_point(
    data = age_means_comb,
    aes(x = age_x_dodge, y = mean_S_age, shape = transmission, fill = transmission, size = n),
    color  = "black",
    stroke = 0.7
  ) +
  scale_color_manual(values = setNames(c("#F8766D", "#00BA38", "#619CFF"), label_vec_all)) +
  scale_fill_manual(values  = setNames(c("#F8766D", "#00BA38", "#619CFF"), label_vec_all)) +
  scale_shape_manual(values = setNames(c(21, 24, 22), label_vec_all)) +
  scale_size_continuous(range = c(1, 10)) +
  scale_x_continuous(
    breaks = 6:15,
    expand = c(0.02, 0)
  ) +
  scale_y_continuous(
    breaks = seq(0, 0.6, 0.2),
    expand = c(0.02, 0)
  ) +
  coord_cartesian(xlim = c(5.5, 15.5), ylim = c(0, 0.75)) +
  labs(
    title    = "Adjustment by Child Age and Chosen Source (Experiment 2)",
    subtitle = paste0("N = ", n_distinct(h5_trials_all$ppt), " children, waves 7\u201310 pooled"),
    x        = "Child Age (years)",
    y        = "Mean Adjustment (S)",
    color    = "Transmission",
    fill     = "Transmission",
    shape    = "Transmission"
  ) +
  guides(size = "none") +
  theme_minimal(base_size = 14) +
  theme(
    plot.title       = element_text(face = "bold", size = 18),
    plot.subtitle    = element_text(size = 11),
    axis.title       = element_text(face = "bold"),
    axis.text.x      = element_text(size = 14),
    panel.grid.minor = element_blank(),
    legend.position  = "top"
  )


# Save results and session information --------------------------------
save_model(h5_model_combined,"h5_model_combined")
save_plot(plot_combined,"plot_combined")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
