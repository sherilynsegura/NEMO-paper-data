# Script: 10_P5-E1_age_transmission_receiver.R
# Reports: S1 P5.E1; Figure 2; S4


# Set up paths and shared helpers -------------------------------------
script_id <- "10_P5-E1_age_transmission_receiver"
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
nemo_h5 <- nemo_data %>%
  filter(wave <= 6, choseSource == 0)
nemo_h5 <- nemo_h5 %>%
  filter(socialSource %in% c(1, 2, 3))
nemo_h5 <- nemo_h5 %>%
  filter(!is.na(age), age >= 6, age <= 70) %>%
  mutate(age_group = if_else(age <= 18, "Child", "Parent"))
nemo_h5 <- nemo_h5 %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
nemo_h5 <- nemo_h5 %>%
  filter(is.na(z_resid) | z_resid < 3)
nemo_h5 <- nemo_h5 %>%
  mutate(
    sourceAge = suppressWarnings(as.numeric(sourceAge)),
    ageOther  = suppressWarnings(as.numeric(ageOther)),
    shownAge  = suppressWarnings(as.numeric(shownAge))
  )

# Link child ages to family members -----------------------------------
child_age_by_group <- nemo_h5 %>%
  group_by(wave, group) %>%
  summarise(
    child_age_in_group = {
      x <- age[age <= 18]
      if (length(x) == 0) NA_real_ else max(x, na.rm = TRUE)
    },
    .groups = "drop"
  )
nemo_h5 <- nemo_h5 %>%
  left_join(child_age_by_group, by = c("wave", "group"))
h5_trials <- nemo_h5 %>%
  mutate(
    age_group = factor(if_else(age <= 18, "Child", "Parent"),
                       levels = c("Child", "Parent")),
    
    transmission = case_when(
      age_group == "Child" & socialSource == 1 ~ "Vertical",
      age_group == "Child" & socialSource == 2 ~ "Oblique",
      age_group == "Child" & socialSource == 3 ~ "Horizontal",
      
      age_group == "Parent" & socialSource == 1 ~ "Vertical",  # groupmate / own child
      age_group == "Parent" & socialSource == 3 ~ "Oblique",   # other child
      
      TRUE ~ NA_character_
    ),
    
    age_x = case_when(
      age_group == "Child" ~ age,
      
      age_group == "Parent" & socialSource == 1 & wave %in% c(1, 5) ~ child_age_in_group,
      age_group == "Parent" & socialSource == 1 & wave == 3         ~ ageOther,
      
      age_group == "Parent" & socialSource == 3 & wave == 2         ~ sourceAge,
      age_group == "Parent" & socialSource == 3 & wave %in% c(4, 6) ~ shownAge,
      
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(transmission), !is.na(age_x), age_x >= 6) %>%
  mutate(
    transmission = factor(transmission, levels = c("Vertical", "Oblique", "Horizontal"))
  )
h5_trials <- h5_trials %>%
  mutate(age_c = age_x - mean(age_x, na.rm = TRUE))

# Fit age by pathway and receiver model -------------------------------
h5_model_lmer <- lmer(
  s_adj ~ age_c * transmission * age_group + (1 | ppt),
  data = h5_trials,
  REML = FALSE
)
n_child  <- h5_trials %>% filter(age_group == "Child") %>% pull(ppt) %>% n_distinct()
n_adult <- union(
  h5_trials %>% filter(age_group == "Parent") %>% pull(ppt),
  nemo_h5   %>% filter(age_group == "Parent", socialSource == 2) %>% pull(ppt)
) %>% n_distinct()

# Prepare observed means and model predictions ------------------------
age_means <- h5_trials %>%
  group_by(age_x, transmission, age_group) %>%
  summarise(
    mean_S_age = mean(s_adj, na.rm = TRUE),
    n = n_distinct(ppt),
    .groups = "drop"
  )
age_seq <- seq(min(h5_trials$age_x, na.rm = TRUE),
               max(h5_trials$age_x, na.rm = TRUE),
               length.out = 300)
pred_grid <- expand.grid(
  age_x = age_seq,
  transmission = levels(h5_trials$transmission),
  age_group = levels(h5_trials$age_group)
) %>%
  as_tibble() %>%
  filter(!(age_group == "Parent" & transmission == "Horizontal")) %>%
  mutate(
    transmission = factor(transmission, levels = levels(h5_trials$transmission)),
    age_group    = factor(age_group, levels = levels(h5_trials$age_group)),
    age_c        = age_x - mean(h5_trials$age_x, na.rm = TRUE)
  )
pred_grid$fit <- predict(h5_model_lmer, newdata = pred_grid, re.form = NA)
X <- model.matrix(delete.response(terms(h5_model_lmer)), pred_grid)
beta <- fixef(h5_model_lmer)
V <- vcov(h5_model_lmer)
X <- X[, names(beta), drop = FALSE]
pred_grid$se  <- sqrt(diag(X %*% V %*% t(X)))
pred_grid$lwr <- pred_grid$fit - 1.96 * pred_grid$se
pred_grid$upr <- pred_grid$fit + 1.96 * pred_grid$se
line_N <- h5_trials %>%
  group_by(transmission, age_group) %>%
  summarise(
    N = n_distinct(ppt),
    .groups = "drop"
  ) %>%
  mutate(
    label = paste0(age_group, " (N = ", N, ")")
  )
n_labels <- tibble(
  transmission = factor(
    c("Vertical", "Vertical", "Oblique", "Oblique", "Horizontal"),
    levels = c("Vertical", "Oblique", "Horizontal")
  ),
  age_group = factor(
    c("Child", "Parent", "Child", "Parent", "Child"),
    levels = c("Child", "Parent")
  ),
  x = c(6.2, 6.2, 6.2, 6.2, 6.2),
  y = c(0.735, 0.675, 0.735, 0.675, 0.735)
) %>%
  left_join(line_N, by = c("transmission", "age_group"))
adult_horizontal_line <- nemo_h5 %>%
  filter(age_group == "Parent", socialSource == 2) %>%
  summarise(
    mean_S = mean(s_adj, na.rm = TRUE),
    N = n_distinct(ppt)
  ) %>%
  mutate(
    transmission = factor("Horizontal", levels = c("Vertical", "Oblique", "Horizontal")),
    age_group = factor("Parent", levels = c("Child", "Parent")),
    x_start = 6,
    x_end = 18,
    label = paste0("Parent (N = ", N, ")")
  )

# Draw Figure 2 -------------------------------------------------------
plot2_h5 <- ggplot() +
  geom_ribbon(
    data = pred_grid,
    aes(x = age_x, ymin = lwr, ymax = upr, fill = age_group),
    alpha = 0.15
  ) +
  geom_line(
    data = pred_grid,
    aes(x = age_x, y = fit, color = age_group, linetype = age_group),
    linewidth = 1.1
  ) +
  scale_linetype_manual(values = c("Child" = "solid", "Parent" = "solid")) +
  geom_segment(
    data = adult_horizontal_line,
    aes(
      x = x_start, xend = x_end,
      y = mean_S, yend = mean_S,
      color = age_group
    ),
    linewidth = 1.1,
    linetype = "dotted",
    inherit.aes = FALSE
  ) +
  geom_point(
    data = age_means,
    aes(x = age_x, y = mean_S_age, fill = age_group, shape = transmission, size = n),
    color = "black",
    stroke = 0.7,
    ) +
  scale_shape_manual(values = c("Vertical" = 21, "Oblique" = 24, "Horizontal" = 22)) +
  scale_size_continuous(range = c(2, 6), name = "N participants") +
  geom_text(
    data = n_labels,
    aes(x = x, y = y, label = label, color = age_group),
    hjust = 0.1,
    size = 3.7,
    show.legend = FALSE
  ) +
  geom_text(
    data = adult_horizontal_line,
    aes(
      x = 6.2,
      y = 0.67,
      label = label,
      color = age_group
    ),
    hjust = 0.1,
    size = 3.7,
    show.legend = FALSE,
    inherit.aes = FALSE
  ) +
  facet_wrap(~ transmission, nrow = 1) +
  scale_x_continuous(
    breaks = seq(6, 12, 2),
    expand = c(0.02, 0)
  ) +
  coord_cartesian(xlim = c(5.5, 13.5), ylim = c(0, 0.75)) +
  labs(
    title = "Adjustment Type by Child Age (Children + Parents)",
    subtitle = paste0("N = ", n_child, " children, ", n_adult, " parents"),
    x = "Child Age",
    y = "Mean Adjustment (S)",
    color = "Participant",
    fill  = "Participant"
  ) +
  guides(
    color = guide_legend(override.aes = list(linewidth = 1.5, linetype = c("solid", "solid"))),
    linetype = "none",
    fill  = "none",
    shape = "none"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    strip.text = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(face = "bold"),
    axis.text.x = element_text(size = 14),
    panel.grid.minor = element_blank(),
    legend.position = "top"
  )
cutoff <- 13   # integer ages > 13 fall off-screen (14, 15, ...)
children_region <- h5_trials %>%
  filter(age_group == "Child") %>%
  group_by(ppt) %>%
  summarise(age_x = max(age_x, na.rm = TRUE), .groups = "drop") %>%
  mutate(region = if_else(age_x <= cutoff, "shown", "hidden"))
children_summary <- children_region %>%
  count(region) %>%
  mutate(pct = round(100 * n / sum(n), 1))


# Save results and session information --------------------------------
save_model(h5_model_lmer,"h5_model_lmer")
save_plot(plot2_h5,"plot2_h5")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
