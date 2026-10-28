# Script: 06_P2_adult_vs_peer.R
# Reports: S1 P2; main source comparison


# Set up paths and shared helpers -------------------------------------
script_id <- "06_P2_adult_vs_peer"
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
library(MuMIn)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
nemo_h2 <- nemo_data %>%
  filter(wave == 2 | wave == 4,
         choseSource == 0)
nemo_h2 <- nemo_h2 %>%
  filter(!is.na(age) & age <= 18)
nemo_h2 <- nemo_h2 %>%
  filter(socialSource %in% c(2, 3))
nemo_h2 <- nemo_h2 %>%
  filter(is.na(z_resid) | z_resid < 3)
nemo_h2 <- nemo_h2 %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
nemo_h2 <- nemo_h2 %>%
  mutate(source = ifelse(socialSource == 2, "adult", "child"))

# Compare adult and peer sources --------------------------------------
# Fit trial-level information use with a participant random intercept.
h2_lmm <- lmer(s_adj ~ source + (1 | ppt), data = nemo_h2)


# Save results and session information --------------------------------
save_model(h2_lmm,"h2_lmm")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
