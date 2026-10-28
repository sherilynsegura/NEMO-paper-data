# Script: 09_P5_transmission_pathways.R
# Reports: S1 P5; S3


# Set up paths and shared helpers -------------------------------------
script_id <- "09_P5_transmission_pathways"
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
library(emmeans)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
nemo_h5 <- nemo_data %>%
  filter(wave <= 6, choseSource == 0)
nemo_h5 <- nemo_h5 %>%
  filter(socialSource %in% c(1, 2, 3))
nemo_h5 <- nemo_h5 %>%
  filter(!is.na(age), age >= 6)
nemo_h5 <- nemo_h5 %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
nemo_h5 <- nemo_h5 %>%
  filter(is.na(z_resid) | z_resid < 3)
nemo_h5 <- nemo_h5 %>%
  mutate(
    transmission = factor(
      socialSource,
      levels = c(1, 2, 3),
      labels = c("Vertical", "Oblique", "Horizontal")
    ),
    receiver = factor(
      ifelse(age <= 18, "Child", "Adult"),
      levels = c("Child", "Adult")
    )
  )

# Compare transmission pathways ---------------------------------------
# Estimate receiver-by-pathway effects.
h5_lmm <- lmer(s_adj ~ receiver * transmission + (1 | ppt),
               data = nemo_h5)

# Calculate pathway contrasts -----------------------------------------
# Compare pathways within each receiver group using Bonferroni adjustment.
emm_h5 <- emmeans(h5_lmm, ~ transmission | receiver)
contrasts_h5 <- pairs(emm_h5, adjust = "bonferroni")


# Save results and session information --------------------------------
write.csv(as.data.frame(emm_h5),file.path(table_dir,"marginal_means.csv"),row.names=FALSE)
write.csv(as.data.frame(contrasts_h5),file.path(table_dir,"pairwise_contrasts.csv"),row.names=FALSE)
save_model(h5_lmm,"h5_lmm")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
