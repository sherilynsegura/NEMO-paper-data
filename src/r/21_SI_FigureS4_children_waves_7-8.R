# Script: 21_SI_FigureS4_children_waves_7-8.R
# Reports: Figure S4C–D


# Set up paths and shared helpers -------------------------------------
script_id <- "21_SI_FigureS4_children_waves_7-8"
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

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
choice_data <- nemo_data %>%
  filter(
    wave %in% c(7, 8),
    choseSource == 1
  )
choice_data <- choice_data %>%
  filter(!is.na(age), age >= 6, age <= 70)
choice_data <- choice_data %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
choice_data <- choice_data %>%
  filter(is.na(z_resid) | abs(z_resid) < 3)
choice_data <- choice_data %>%
  mutate(
    age_group = case_when(
      age >= 6  & age <= 18 ~ "child",
      age >= 19 & age <= 70 ~ "adult",
      TRUE ~ NA_character_
    )
  )

# Link family and source ages -----------------------------------------
own_child_lookup <- choice_data %>%
  filter(age >= 6, age <= 18) %>%
  distinct(wave, group, ppt, age) %>%
  group_by(wave, group) %>%
  summarise(
    own_child_age = first(age),
    n_child_in_group = n_distinct(age),
    .groups = "drop"
  )
choice_data <- choice_data %>%
  left_join(
    own_child_lookup %>%
      select(wave, group, own_child_age),
    by = c("wave", "group")
  )
choice_data <- choice_data %>%
  mutate(
    source_child_age = case_when(
      age_group == "child" ~ age,
      age_group == "adult" & socialSource == 1 ~ own_child_age,
      age_group == "adult" & socialSource == 3 ~ own_child_age,
      TRUE ~ NA_real_
    )
  )
choice_data <- choice_data %>%
  mutate(
    transmission = case_when(
      socialSource == 1 ~ "vertical",
      socialSource == 2 ~ "horizontal",
      socialSource == 3 ~ "oblique",
      TRUE ~ NA_character_
    )
  )
h5_trials_w7_8 <- choice_data %>%
  mutate(
    age_group = factor(
      if_else(age_group == "child", "Child", "Adult"),
      levels = c("Child", "Adult")
    ),
    transmission = case_when(
      age_group == "Child" & socialSource == 1 ~ "Vertical",
      age_group == "Child" & socialSource == 2 ~ "Horizontal",
      age_group == "Child" & socialSource == 3 ~ "Oblique",
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
    age_x <= 18
  ) %>%
  mutate(
    transmission = factor(
      transmission,
      levels = c("Vertical", "Oblique", "Horizontal")
    )
  )
h5_trials_w7_8 <- h5_trials_w7_8 %>%
  filter(age_group == "Child")
h5_trials_w7_8 <- h5_trials_w7_8 %>%
  mutate(age_c = age_x - mean(age_x, na.rm = TRUE))

# Fit the wave-block child model --------------------------------------
h5_model_lmer_w7_8 <- lmer(
  s_adj ~ age_c * transmission + (1 | ppt),
  data = h5_trials_w7_8,
  REML = FALSE
)

# Prepare observed means and model predictions ------------------------
age_means <- h5_trials_w7_8 %>%
  group_by(age_x, transmission) %>%
  summarise(
    mean_S_age = mean(s_adj, na.rm = TRUE),
    n = n_distinct(ppt),
    .groups = "drop"
  )
age_seq <- seq(6, 18, length.out = 300)
pred_grid <- expand.grid(
  age_x = age_seq,
  transmission = levels(h5_trials_w7_8$transmission)
) %>%
  as_tibble() %>%
  mutate(
    transmission = factor(transmission, levels = levels(h5_trials_w7_8$transmission)),
    age_c = age_x - mean(h5_trials_w7_8$age_x, na.rm = TRUE)
  )
pred_grid$fit <- predict(h5_model_lmer_w7_8, newdata = pred_grid, re.form = NA)
X <- model.matrix(delete.response(terms(h5_model_lmer_w7_8)), pred_grid)
beta <- fixef(h5_model_lmer_w7_8)
V <- vcov(h5_model_lmer_w7_8)
X <- X[, names(beta), drop = FALSE]
pred_grid$se  <- sqrt(diag(X %*% V %*% t(X)))
pred_grid$lwr <- pred_grid$fit - 1.96 * pred_grid$se
pred_grid$upr <- pred_grid$fit + 1.96 * pred_grid$se
line_N <- h5_trials_w7_8 %>%
  group_by(transmission) %>%
  summarise(N = n_distinct(ppt), .groups = "drop") %>%
  mutate(label = paste0("N = ", N))
label_vec <- setNames(
  paste0(line_N$transmission, " (N = ", line_N$N, ")"),
  line_N$transmission
)
pred_grid_comb <- pred_grid %>%
  mutate(transmission = factor(label_vec[as.character(transmission)],
                               levels = label_vec))
age_means_comb <- age_means %>%
  mutate(transmission = factor(label_vec[as.character(transmission)],
                               levels = label_vec))
age_means_comb <- age_means_comb %>%
  mutate(
    age_x_dodge = case_when(
      grepl("Vertical",   as.character(transmission)) ~ age_x - 0.15,
      grepl("Oblique",    as.character(transmission)) ~ age_x,
      grepl("Horizontal", as.character(transmission)) ~ age_x + 0.15
    )
  )

# Draw the wave-block information-use panel ---------------------------
plot3_h5_w7_8 <- ggplot() +
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
    color = "black",
    stroke = 0.7
  ) +
  scale_color_manual(values = setNames(c("#F8766D", "#00BA38", "#619CFF"), label_vec)) +
  scale_fill_manual(values = setNames(c("#F8766D", "#00BA38", "#619CFF"), label_vec)) +
  scale_shape_manual(values = setNames(c(21, 24, 22), label_vec)) +
  scale_size_continuous(range = c(1, 10)) +
  scale_x_continuous(
    breaks = 6:15,
    expand = c(0.02, 0)
  ) +
  coord_cartesian(xlim = c(5, 15.5), ylim = c(0, 0.85)) +
  labs(
    title = "Adjustment by Child Age and Chosen Source (2-in-Room)",
    subtitle = paste0("N = ", n_distinct(h5_trials_w7_8$ppt), " children"),
    x = "Child Age (years)",
    y = "Mean Adjustment (S)",
    color = "Transmission",
    fill  = "Transmission",
    shape = "Transmission"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(face = "bold"),
    axis.text.x = element_text(size = 14),
    panel.grid.minor = element_blank(),
    legend.position = "top"
  )


# Save results and session information --------------------------------
save_model(h5_model_lmer_w7_8,"h5_model_lmer_w7_8")
save_plot(plot3_h5_w7_8,"plot3_h5_w7_8")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
