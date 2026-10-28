# Script: 08_P4_child_age.R
# Reports: S1 P4; S2


# Set up paths and shared helpers -------------------------------------
script_id <- "08_P4_child_age"
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
nemo_h4 <- nemo_data %>%
  filter(wave <= 6, choseSource == 0)
nemo_h4 <- nemo_h4 %>%
  filter(!is.na(age), age <= 18,  age >=6)
nemo_h4 <- nemo_h4 %>%
  filter(is.na(z_resid) | z_resid < 3)
nemo_h4 <- nemo_h4 %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
nemo_h4 <- nemo_h4 %>%
  mutate(age_c = age - mean(age, na.rm = TRUE))

# Estimate the child age association ----------------------------------
# Control for source category and repeated trials within participants.
h4_lme <- lmer(s_adj ~ age_c + factor(socialSource) + (1 | ppt), data = nemo_h4)


# Save results and session information --------------------------------
save_model(h4_lme,"h4_lme")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
