# Script: 19_SI_S11_configuration_choice.R
# Reports: S11; configuration percentage-point changes


# Set up paths and shared helpers -------------------------------------
script_id <- "19_SI_S11_configuration_choice"
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) {
  arg <- grep("^--file=",commandArgs(FALSE),value=TRUE)
  if (length(arg)) repo_root <- dirname(dirname(dirname(normalizePath(sub("^--file=","",arg[1])))))
}
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) stop("Run from the nemo-paper-data root or set NEMO_REPO_ROOT.")
source(file.path(repo_root,"src","r","_setup.R"),local=TRUE)

library(dplyr)
library(tidyr)
library(lme4)
library(lmerTest)   # p-values for LMMs
library(emmeans)    # condition contrasts from LMMs
library(nnet)
library(mclogit)    # mblogit: mixed (random-intercept) multinomial

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
dat <- nemo_data %>%
  mutate(
    age          = suppressWarnings(as.numeric(age)),
    s_adj        = suppressWarnings(as.numeric(s_adj)),
    socialSource = suppressWarnings(as.numeric(socialSource)),
    uid = interaction(wave, group, ppt, drop = TRUE),  # participant  (trial cluster)
    grp = interaction(wave, group,      drop = TRUE)   # group / room (condition cluster)
  ) %>%
  filter(!is.na(age)) %>%
  mutate(
    age_c     = as.numeric(scale(age, center = TRUE, scale = FALSE)),  # centered (bimodal age)
    age_group = factor(if_else(age < 19, "child", "adult"),
                       levels = c("child", "adult")),
    
    seating = case_when(
      wave %in% 1:2  ~ "face_to_face",
      wave %in% 3:6  ~ "facing_away",
      wave %in% 7:8  ~ "divider_2",
      wave %in% 9:10 ~ "divider_4"
    ),
    seating = factor(seating,
                     levels = c("face_to_face", "facing_away", "divider_2", "divider_4")),
    
    seating2 = factor(case_when(
      wave %in% 1:2 ~ "face_to_face",
      wave %in% 3:6 ~ "facing_away"
    ), levels = c("face_to_face", "facing_away")),
    
    othersPresent = factor(case_when(
      wave %in% 7:8  ~ "2_present",
      wave %in% 9:10 ~ "4_present"
    ), levels = c("2_present", "4_present")),
    
    source_type = case_when(
      socialSource == 0                          ~ "anonymous",
      age_group == "child" & socialSource == 1   ~ "vertical",
      age_group == "child" & socialSource == 2   ~ "oblique",
      age_group == "child" & socialSource == 3   ~ "horizontal",
      age_group == "adult" & socialSource == 1   ~ "vertical",    # reverse vertical
      age_group == "adult" & socialSource == 2   ~ "horizontal",
      age_group == "adult" & socialSource == 3   ~ "oblique",
      TRUE ~ NA_character_
    ),
    source_type = factor(source_type,
                         levels = c("vertical", "oblique", "horizontal", "anonymous"))
  )

# Select source choice trials -----------------------------------------
choice_data <- dat %>%
  filter(wave %in% 7:10, !is.na(source_type)) %>%
  mutate(source_type = droplevels(source_type))          # no anonymous in 7-10
choice_data$source_type <- relevel(choice_data$source_type, ref = "vertical")

# Fit pooled configuration choice model -------------------------------
m3 <- mblogit(
  source_type ~ othersPresent,
  random  = ~ 1 | uid,          # repeated choices within participant
  data    = choice_data,
  estimator = "REML"
)
choice_data$age_group <- relevel(droplevels(factor(choice_data$age_group)),
                                 ref = "child")

# Fit receiver-specific configuration models --------------------------
m3_child <- mblogit(source_type ~ othersPresent, random = ~ 1 | uid,
                    data = droplevels(subset(choice_data, age_group == "child")),
                    estimator = "REML")
m3_adult <- mblogit(source_type ~ othersPresent, random = ~ 1 | uid,
                    data = droplevels(subset(choice_data, age_group == "adult")),
                    estimator = "REML")

# Calculate observed percentage-point changes -------------------------
oblique_rates <- choice_data %>%
  mutate(is_oblique = source_type == "oblique") %>%           # already remapped per receiver
  group_by(age_group, othersPresent) %>%
  summarise(n_trials = n(),
            pct_oblique = 100 * mean(is_oblique),
            .groups = "drop") %>%
  tidyr::pivot_wider(names_from = othersPresent,
                     values_from = c(n_trials, pct_oblique))
oblique_rates <- oblique_rates %>%
  mutate(pp_diff = pct_oblique_4_present - pct_oblique_2_present)


# Save results and session information --------------------------------
write.csv(oblique_rates,file.path(table_dir,"oblique_percentage_points.csv"),row.names=FALSE)
save_model(m3,"m3")
save_model(m3_child,"m3_child")
save_model(m3_adult,"m3_adult")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
