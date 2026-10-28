# Script: 04_P1-E3_resemblance_age_9-11.R
# Reports: S1 P1.E3; Figure S1; S12


# Set up paths and shared helpers -------------------------------------
script_id <- "04_P1-E3_resemblance_age_9-11"
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

# Load data and prepare the analysis sample ---------------------------
nemo_data_full <- read.csv(input_file)

# Define family exclusions --------------------------------------------
# Remove invalid trials, then incomplete families and members with fewer than three valid trials.
apply_exclusions <- function(df, id_var) {
  
  df <- df %>% filter(is.na(z_resid) | z_resid < 3)
  df <- df %>% filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
  
  units_to_remove <- df %>%
    group_by(across(all_of(id_var))) %>%
    summarise(any_missing_age = any(is.na(age)),
              any_under_6    = any(age < 6, na.rm = TRUE),
              .groups = "drop") %>%
    filter(any_missing_age | any_under_6) %>%
    select(all_of(id_var))
  
  df <- df %>% anti_join(units_to_remove, by = id_var)
  
  units_incomplete <- df %>%
    distinct(across(all_of(c(id_var, "ppt")))) %>%
    count(across(all_of(id_var)), name = "n_ppt") %>%
    filter(n_ppt != 2) %>%
    select(all_of(id_var))
  
  df <- df %>% anti_join(units_incomplete, by = id_var)
  
  valid_counts <- df %>%
    group_by(across(all_of(c(id_var, "ppt")))) %>%
    summarise(n_valid = n(), .groups = "drop")
  
  units_lt3 <- valid_counts %>%
    group_by(across(all_of(id_var))) %>%
    summarise(min_valid = min(n_valid), .groups = "drop") %>%
    filter(min_valid < 3) %>%
    select(all_of(id_var))
  
  df %>% anti_join(units_lt3, by = id_var)
}

# Calculate paired participant means ----------------------------------
# Average valid trials within participants, then pair child and caregiver means.
build_dyad_S <- function(df, id_var) {
  
  S_per_ppt <- df %>%
    group_by(across(all_of(c(id_var, "ppt")))) %>%
    summarise(age = first(age), s_mean = mean(s_adj), .groups = "drop")
  
  role_check <- S_per_ppt %>%
    mutate(role = ifelse(age <= 18, "child", "caregiver")) %>%
    count(across(all_of(id_var)), role) %>%
    pivot_wider(names_from = role, values_from = n, values_fill = 0)
  
  bad_units <- role_check %>% filter(child != 1 | caregiver != 1)
  if (nrow(bad_units) > 0) {
    warning(paste("Bad role composition in", nrow(bad_units), "units."))
    print(bad_units)
  }
  
  dyad_wide <- S_per_ppt %>%
    mutate(role = ifelse(age <= 18, "child", "caregiver")) %>%
    select(all_of(c(id_var, "role", "s_mean"))) %>%
    pivot_wider(names_from = role, values_from = s_mean)
  
  stopifnot(!any(is.na(dyad_wide$child)))
  stopifnot(!any(is.na(dyad_wide$caregiver)))
  
  child_age <- S_per_ppt %>% filter(age <= 18) %>% select(all_of(id_var), age)
  
  dyad_wide %>%
    left_join(child_age, by = id_var) %>%
    rename(dyad_id = all_of(id_var))
}

# Select waves and the child age band ---------------------------------
# Pair families within each wave block before combining and selecting child ages.
d18 <- nemo_data_full %>%
  filter((wave <= 6 & choseSource == 0) | (wave %in% 7:8 & choseSource == 1))
d18 <- apply_exclusions(d18, "group")
dyad_S_18 <- build_dyad_S(d18, "group")
d910 <- nemo_data_full %>% filter(wave %in% 9:10, choseSource == 1, !is.na(dyad))
d910 <- apply_exclusions(d910, "dyad")
dyad_S_910 <- build_dyad_S(d910, "dyad")
dyad_all <- bind_rows(dyad_S_18, dyad_S_910)
dyad_C <- dyad_all %>% filter(age >= 9,  age <= 11)

# Define plot labels and resemblance panel ----------------------------
# Annotations use Spearman correlation; the line is a least-squares visual smoother.
fmt_r <- function(x) {
  s <- sub("^(-?)0\\.", "\\1.", sprintf("%.2f", x))
  if (s == "-.00") s <- ".00"
  s
}
fmt_p_txt <- function(p) {
  if (p < .001) "< .001" else sub("0\\.", ".", sprintf("= %.3f", p))
}
make_panel <- function(d, tag, subtitle_base) {
  sp <- suppressWarnings(cor.test(d$caregiver, d$child, method="spearman"))
  subtitle <- sprintf("%s, n = %d", subtitle_base, nrow(d))
  footer <- sprintf("Spearman rho = %s, p %s", fmt_r(sp$estimate), fmt_p_txt(sp$p.value))

  ggplot(d, aes(x = caregiver, y = child)) +
    geom_point(alpha = 0.25, size = 1.4, color = "#999999") +
    geom_smooth(method = "lm", se = TRUE,
                color = "#2166AC", fill = "#2166AC", alpha = 0.15,
                linewidth = 0.9) +
    scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
    labs(x = "Parent mean S", y = "Child mean S",
         tag = tag, subtitle = subtitle, caption = footer) +
    theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.tag         = element_text(face = "bold", size = 14),
      plot.subtitle    = element_text(size = 11, face = "bold", hjust = 0.5),
      plot.caption     = element_text(size = 9, hjust = 0.5, color = "grey30"),
      axis.title       = element_text(size = 11),
      axis.text        = element_text(size = 10)
    )
}


# Save results and session information --------------------------------
selected <- dyad_C
plot_subset <- make_panel(selected,"C","Child age 9-11")

test <- suppressWarnings(cor.test(selected$caregiver, selected$child, method="spearman"))
# Approximate 95% CI for Spearman rho using the Fisher-z transformation.
# This is a newly documented approximation, not an interval returned by cor.test.
# It describes the correlation; the plotted band describes the least-squares line.
n_pairs <- nrow(selected)
rho <- unname(test$estimate)
stopifnot(n_pairs > 3L, is.finite(rho), abs(rho) <= 1,
          all(is.finite(selected$caregiver)), all(is.finite(selected$child)))
conf_level <- 0.95
z_margin <- qnorm((1 + conf_level) / 2) / sqrt(n_pairs - 3)
rho_ci <- tanh(atanh(rho) + c(-1, 1) * z_margin)

write.csv(data.frame(
  n_families = n_pairs,
  rho = rho,
  p_value = test$p.value,
  conf_low = rho_ci[1],
  conf_high = rho_ci[2],
  conf_level = conf_level,
  ci_method = "Fisher-z approximation for Spearman rho"
), file.path(table_dir, "spearman.csv"), row.names = FALSE)
save_plot(plot_subset,"plot_subset")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
