# Script: 11_E1_source_selection.R
# Reports: S1 E1; S5


# Set up paths and shared helpers -------------------------------------
script_id <- "11_E1_source_selection"
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) {
  arg <- grep("^--file=",commandArgs(FALSE),value=TRUE)
  if (length(arg)) repo_root <- dirname(dirname(dirname(normalizePath(sub("^--file=","",arg[1])))))
}
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) stop("Run from the nemo-paper-data root or set NEMO_REPO_ROOT.")
source(file.path(repo_root,"src","r","_setup.R"),local=TRUE)

library(dplyr)
library(tidyr)
library(mclogit)

# Load data and prepare the analysis sample ---------------------------
nemo_data <- read.csv(input_file)
choice_data <- nemo_data %>%
  filter(wave %in% 7:10, choseSource == 1) %>%
  filter(!is.na(age), age >= 6, age <= 70) %>%
  filter(is.na(z_resid) | abs(z_resid) < 3)
choice_data <- choice_data %>%
  mutate(
    age_group = case_when(
      age >= 6  & age <= 18 ~ "child",
      age >= 19 & age <= 70 ~ "adult",
      TRUE ~ NA_character_
    ),
    transmission = case_when(
      age_group == "child" & socialSource == 1 ~ "Vertical",
      age_group == "child" & socialSource == 2 ~ "Oblique",
      age_group == "child" & socialSource == 3 ~ "Horizontal",
      age_group == "adult" & socialSource == 1 ~ "Vertical",
      age_group == "adult" & socialSource == 2 ~ "Horizontal",
      age_group == "adult" & socialSource == 3 ~ "Oblique",
      TRUE ~ NA_character_
    ),
    dyad_id = if_else(is.na(dyad), paste0("g", wave, "_", group), paste0("d", dyad))
  )
choice_data$age_group    <- factor(choice_data$age_group, levels = c("child", "adult"))
choice_data$transmission <- factor(choice_data$transmission,
                                   levels = c("Vertical", "Oblique", "Horizontal"))
choice_data$transmission <- relevel(choice_data$transmission, ref = "Vertical")

# Link caregivers to their own child age ------------------------------
own_child_age <- choice_data %>%
  filter(age_group == "child") %>%
  group_by(dyad_id) %>%
  summarise(child_age = first(age), .groups = "drop")
choice_data <- choice_data %>%
  left_join(own_child_age, by = "dyad_id")

# Define mixed multinomial and coefficient helpers --------------------
# Vertical transmission is the reference category.
fit_mn <- function(formula, data) {
  mclogit::mblogit(formula, random = ~1|ppt, data=data, trace=FALSE)
}
or_table <- function(model,label) {
  sm <- summary(model)$coefficients
  nm <- rownames(sm)
  data.frame(model=label,contrast=paste0(sub("~.*$","",nm)," vs Vertical"),
             term=sub("^.*~","",nm),B=sm[,"Estimate"],SE=sm[,"Std. Error"],row.names=NULL) %>%
    mutate(OR=exp(B),CI_low=exp(B-1.96*SE),CI_high=exp(B+1.96*SE),z=B/SE,p=2*pnorm(abs(z),lower.tail=FALSE))
}

# Fit child choice model ----------------------------------------------
child_data <- choice_data %>%
  filter(age_group == "child", !is.na(transmission)) %>%
  droplevels()
centre_child <- mean(child_data$age, na.rm = TRUE)
child_data$age_c <- child_data$age - centre_child
m_child <- fit_mn(transmission ~ age_c, child_data)
res_child <- or_table(m_child, "A. children (own age, centered)")

# Fit caregiver choice by own child age -------------------------------
adult_src <- choice_data %>%
  filter(age_group == "adult", !is.na(transmission), !is.na(child_age)) %>%
  droplevels()
centre_adult_src <- mean(adult_src$child_age, na.rm = TRUE)
adult_src$child_age_c <- adult_src$child_age - centre_adult_src
m_adult_src <- fit_mn(transmission ~ child_age_c, adult_src)
res_adult_src <- or_table(m_adult_src, "B. parents (own child age, centered)")

# Fit caregiver choice by caregiver age -------------------------------
adult_own <- choice_data %>%
  filter(age_group == "adult", !is.na(transmission)) %>%
  droplevels()
centre_adult_own <- mean(adult_own$age, na.rm = TRUE)
adult_own$age_c <- adult_own$age - centre_adult_own
m_adult_own <- fit_mn(transmission ~ age_c, adult_own)
res_adult_own <- or_table(m_adult_own, "C. parents (own age, centered)")


# Save results and session information --------------------------------
write.csv(bind_rows(res_child,res_adult_src,res_adult_own),file.path(table_dir,"odds_ratios.csv"),row.names=FALSE)
save_model(m_child,"m_child")
save_model(m_adult_src,"m_adult_src")
save_model(m_adult_own,"m_adult_own")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
