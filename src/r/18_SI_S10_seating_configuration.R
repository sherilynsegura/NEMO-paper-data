# Script: 18_SI_S10_seating_configuration.R
# Reports: S10


# Set up paths and shared helpers -------------------------------------
script_id <- "18_SI_S10_seating_configuration"
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
DROP_ANON <- TRUE    # TRUE = drop socialSource == 0 (anonymous) trials in M1
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

# Separate seating and room configuration samples ---------------------
m1_data <- dat %>%
  filter(wave %in% 1:6, !is.na(s_adj), !is.na(source_type)) %>%
  { if (DROP_ANON) filter(., source_type != "anonymous") else . } %>%
  mutate(source_type = droplevels(source_type))
m2_data <- dat %>%
  filter(wave %in% 7:10, !is.na(s_adj), !is.na(source_type)) %>%
  mutate(source_type = droplevels(source_type))

# Retain trials with valid information use ----------------------------
# Apply the source script valid-s preparation to both model samples.
valid_s <- function(d) filter(d, !is.na(s_adj), s_adj >= 0, s_adj <= 1)
m1_valid_data <- m1_data %>% valid_s() %>% mutate(source_type = droplevels(source_type))

# Fit seating model ---------------------------------------------------
m1_excl <- lmer(s_adj ~ seating2 + age_c + source_type + (1|grp) + (1|uid), data=m1_valid_data, REML=TRUE, control=lmerControl(optimizer="bobyqa"))
m2_valid_data <- m2_data %>% valid_s() %>% mutate(source_type = droplevels(source_type))

# Fit room configuration model ----------------------------------------
m2_excl <- lmer(s_adj ~ othersPresent + source_type + age_c + (1|grp) + (1|uid), data=m2_valid_data, REML=TRUE, control=lmerControl(optimizer="bobyqa"))


# Save results and session information --------------------------------
save_model(m1_excl,"m1_excl")
save_model(m2_excl,"m2_excl")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
