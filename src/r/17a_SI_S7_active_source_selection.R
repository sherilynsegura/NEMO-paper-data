# Script: 17a_SI_S7_active_source_selection.R
# Reports: S7; active source selection effect


# Set up paths and shared helpers -------------------------------------
script_id <- "17a_SI_S7_active_source_selection"
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) {
  arg <- grep("^--file=",commandArgs(FALSE),value=TRUE)
  if (length(arg)) repo_root <- dirname(dirname(dirname(normalizePath(sub("^--file=","",arg[1])))))
}
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) stop("Run from the nemo-paper-data root or set NEMO_REPO_ROOT.")
source(file.path(repo_root,"src","r","_setup.R"),local=TRUE)

library(dplyr)
library(ggplot2)
library(lme4)
library(lmerTest)
library(emmeans)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
df_chose <- nemo_data %>%
  filter(
    is.na(z_resid) | z_resid < 3,
    !is.na(s_adj), s_adj >= 0, s_adj <= 1,
    !is.na(age), age >= 6,
    !is.na(socialSource)
  ) %>%
  mutate(
    receiver = ifelse(age <= 18, "child", "caregiver"),
    socialSource = case_when(
      socialSource == 0 ~ "Unknown",
      socialSource == 1 ~ "Vertical",
      socialSource == 2 ~ "Oblique",
      socialSource == 3 ~ "Horizontal",
      TRUE ~ NA_character_
    ),
    socialSource = factor(socialSource, levels = c("Unknown", "Vertical", "Oblique", "Horizontal"))
  ) %>%
  group_by(receiver) %>%
  mutate(age_c = age - mean(age)) %>%
  ungroup()

# Estimate the active choice association ------------------------------
# Control for source and the receiver-by-age interaction.
m_chose <- lmer(s_adj ~ choseSource + receiver * age_c + socialSource + (1 | ppt),
                data = df_chose)


# Save results and session information --------------------------------
save_model(m_chose,"m_chose")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
