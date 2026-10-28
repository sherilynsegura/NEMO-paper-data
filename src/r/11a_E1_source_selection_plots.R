# Script: 11a_E1_source_selection_plots.R
# Reports: Figure 3A–B


# Set up paths and shared helpers -------------------------------------
script_id <- "11a_E1_source_selection_plots"
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
library(nnet)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
choice_data <- nemo_data %>%
  filter(wave %in% 7:10, choseSource == 1)
choice_data <- choice_data %>%
  filter(!is.na(age), age >= 6, age <= 70)
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
choice_data$age_group <- factor(choice_data$age_group, levels = c("child", "adult"))
choice_data <- choice_data %>%
  mutate(
    transmission = case_when(
      age_group == "child" & socialSource == 1 ~ "Vertical",
      age_group == "child" & socialSource == 2 ~ "Oblique",
      age_group == "child" & socialSource == 3 ~ "Horizontal",
      age_group == "adult" & socialSource == 1 ~ "Vertical",
      age_group == "adult" & socialSource == 2 ~ "Horizontal",
      age_group == "adult" & socialSource == 3 ~ "Oblique",
      TRUE ~ NA_character_
    )
  )
choice_data$transmission <- factor(
  choice_data$transmission,
  levels = c("Vertical", "Oblique", "Horizontal")
)
choice_data$transmission <- relevel(choice_data$transmission, ref = "Vertical")
choice_data$transmission <- factor(
  choice_data$transmission,
  levels = c("Vertical", "Oblique", "Horizontal")
)
tx_colours <- c(
  "Vertical"   = "#F8766D",
  "Oblique"    = "#00BA38",
  "Horizontal" = "#619CFF"
)
tx_shapes <- c("Vertical" = 16, "Oblique" = 17, "Horizontal" = 15)
choice_data <- choice_data %>%
  mutate(age_f = factor(age, levels = 6:15))

# Summarise child source choices --------------------------------------
source_child <- choice_data %>%
  filter(age_group == "child", !is.na(transmission)) %>%
  group_by(age_f, transmission) %>%
  summarise(n = n(), .groups = "drop") %>%
  complete(age_f, transmission, fill = list(n = 0)) %>%
  group_by(age_f) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()
n_child <- choice_data %>%
  filter(age_group == "child", !is.na(transmission)) %>%
  group_by(age_f) %>%
  summarise(n = n_distinct(ppt), .groups = "drop")

# Draw child choice proportions ---------------------------------------
p_child <- ggplot(source_child, aes(x = age_f, y = prop, fill = transmission)) +
  geom_col(width = 0.80) +
  geom_point(
    aes(shape = transmission, color = transmission),
    size = 0, stroke = 0
  ) +
  geom_text(
    data        = n_child,
    aes(x = age_f, y = 1.04, label = paste0("n = ", n)),
    inherit.aes = FALSE,
    size        = 4.5
  ) +
  scale_y_continuous(
    limits = c(0, 1.08),
    breaks = seq(0, 1, by = 0.2)
  ) +
  scale_x_discrete(drop = FALSE) +
  scale_fill_manual(values = tx_colours) +
  scale_color_manual(values = tx_colours) +
  scale_shape_manual(values = tx_shapes) +
  guides(
    fill = guide_legend(
      override.aes = list(
        fill     = NA,
        shape    = c(16, 17, 15),
        size     = 5.5,
        color    = unname(tx_colours),
        linetype = 0
      )
    ),
    shape = "none",
    color = "none"
  ) +
  labs(
    title = "Chosen Social Information Source by Age (Children \u226418, Waves 7\u201310)",
    x     = "Child Age (years)",
    y     = "Proportion of Trials",
    fill  = "Chosen source"
  ) +
  theme_minimal() +
  theme(
    plot.title      = element_text(face = "bold", size = 18),
    axis.title      = element_text(face = "bold"),
    axis.text.x     = element_text(size = 16),
    axis.title.x    = element_text(size = 18),
    axis.text.y     = element_text(size = 14),
    axis.title.y    = element_text(size = 18),
    legend.title    = element_text(size = 18),
    legend.text     = element_text(size = 16),
    legend.position = "top"
  )

# Group caregivers by their own child age -----------------------------
own_child_age <- choice_data %>% filter(age_group=="child") %>%
  mutate(family_id=ifelse(is.na(dyad),paste0("g",wave,"_",group),paste0("d",dyad))) %>%
  group_by(family_id) %>% summarise(child_age=first(age),.groups="drop")
adult_data <- choice_data %>% filter(age_group=="adult") %>%
  mutate(family_id=ifelse(is.na(dyad),paste0("g",wave,"_",group),paste0("d",dyad))) %>%
  left_join(own_child_age,by="family_id") %>% filter(!is.na(child_age))
adult_data <- adult_data %>%
  filter(!is.na(transmission)) %>%
  mutate(child_age_f = factor(round(child_age), levels = 6:15))
source_adult <- adult_data %>%
  group_by(child_age_f, transmission) %>%
  summarise(n = n(), .groups = "drop") %>%
  complete(child_age_f, transmission, fill = list(n = 0)) %>%
  group_by(child_age_f) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()
# Labels intentionally show child sample sizes within the own-child-age buckets.
n_adult <- choice_data %>%
  filter(age_group == "child", !is.na(transmission)) %>%
  mutate(child_age_f = factor(round(age), levels = 6:15)) %>%
  group_by(child_age_f) %>%
  summarise(n = n_distinct(ppt), .groups = "drop")

# Draw caregiver choice proportions -----------------------------------
p_adult <- ggplot(source_adult, aes(x = child_age_f, y = prop, fill = transmission)) +
  geom_col(width = 0.80) +
  geom_point(
    aes(shape = transmission, color = transmission),
    size = 0, stroke = 0
  ) +
  geom_text(
    data        = n_adult,
    aes(x = child_age_f, y = 1.04, label = paste0("n = ", n)),
    inherit.aes = FALSE,
    size        = 4.5
  ) +
  scale_y_continuous(
    limits = c(0, 1.08),
    breaks = seq(0, 1, by = 0.2)
  ) +
  scale_x_discrete(drop = FALSE) +
  scale_fill_manual(values = tx_colours) +
  scale_color_manual(values = tx_colours) +
  scale_shape_manual(values = tx_shapes) +
  guides(
    fill = guide_legend(
      override.aes = list(
        fill     = NA,
        shape    = c(16, 17, 15),
        size     = 5.5,
        color    = unname(tx_colours),
        linetype = 0
      )
    ),
    shape = "none",
    color = "none"
  ) +
  labs(
    title = "Chosen Social Information Source by Child Age (Adults >18, Waves 7\u201310)",
    x     = "Age of Child Source (years)",
    y     = "Proportion of Trials",
    fill  = "Chosen source"
  ) +
  theme_minimal() +
  theme(
    plot.title      = element_text(face = "bold", size = 18),
    axis.title      = element_text(face = "bold"),
    axis.text.x     = element_text(size = 16),
    axis.title.x    = element_text(size = 18),
    axis.text.y     = element_text(size = 14),
    axis.title.y    = element_text(size = 18),
    legend.title    = element_text(size = 18),
    legend.text     = element_text(size = 16),
    legend.position = "top"
  )


# Save results and session information --------------------------------
save_plot(p_child,"p_child")
save_plot(p_adult,"p_adult")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
