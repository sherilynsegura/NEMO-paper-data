# Script: 07_P3_children_vs_caregivers.R
# Reports: S1 P3; main receiver comparison


# Set up paths and shared helpers -------------------------------------
script_id <- "07_P3_children_vs_caregivers"
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
library(emmeans)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
nemo_h3 <- nemo_data %>%
  filter(wave <=6,
         choseSource == 0)
nemo_h3 <- nemo_h3 %>%
  filter(is.na(z_resid) | z_resid < 3)
nemo_h3 <- nemo_h3 %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
nemo_h3 <- nemo_h3 %>%
  filter(!is.na(age),
         age >= 6)
nemo_h3 <- nemo_h3 %>%
  mutate(receiver = ifelse(age <= 18, "child", "caregiver"))

# Compare children and caregivers -------------------------------------
# Account for repeated trials within participants.
h3_lmm <- lmer(s_adj ~ receiver + (1 | ppt), data = nemo_h3)


# Save results and session information --------------------------------
write.csv(as.data.frame(emmeans(h3_lmm,~receiver)),file.path(table_dir,"receiver_means.csv"),row.names=FALSE)
save_model(h3_lmm,"h3_lmm")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
