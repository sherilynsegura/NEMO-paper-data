# Script: 20_SI_distance_discounting.R
# Reports: Figure S3


# Set up paths and shared helpers -------------------------------------
script_id <- "20_SI_distance_discounting"
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
nemo_data <- nemo_data %>%
  mutate(across(c(age, firstEstimate, secondEstimate, socialInfo,
                  nAnimals, s_adj, z_resid), as.numeric))
nemo_dist <- nemo_data %>%
  filter(socialSource %in% c(1, 2, 3))
nemo_dist <- nemo_dist %>%
  mutate(source_mode = if_else(socialSource %in% c(2, 3) & wave <= 8,
                               "controlled", "live"))
nemo_dist <- nemo_dist %>%
  filter(source_mode == "live")
nemo_dist <- nemo_dist %>%
  filter(!is.na(firstEstimate), firstEstimate > 0, !is.na(socialInfo))
nemo_dist <- nemo_dist %>%
  filter(is.na(z_resid) | z_resid < 3)
nemo_dist <- nemo_dist %>%
  filter(!is.na(s_adj) & s_adj >= 0 & s_adj <= 1)
nemo_dist <- nemo_dist %>%
  filter(!is.na(age), age >= 6)
nemo_dist <- nemo_dist %>%
  mutate(
    rel_dist = abs(socialInfo - firstEstimate) / firstEstimate,
    raw_dist = abs(socialInfo - firstEstimate),
    receiver = factor(ifelse(age <= 18, "Child", "Adult"),
                      levels = c("Child", "Adult")),
    transmission = case_when(
      socialSource == 1 ~ "Vertical",
      receiver == "Child" & socialSource == 2 ~ "Oblique",
      receiver == "Child" & socialSource == 3 ~ "Horizontal",
      receiver == "Adult" & socialSource == 2 ~ "Horizontal",
      receiver == "Adult" & socialSource == 3 ~ "Oblique"
    ),
    transmission = factor(transmission,
                          levels = c("Vertical", "Oblique", "Horizontal"))
  )

# Estimate distance slopes and curvature ------------------------------
# Compare receiver slopes and retain the quadratic comparator.
m2 <- lmer(s_adj ~ rel_dist * receiver + (1 | ppt), data = nemo_dist)
m2_quad <- lmer(s_adj ~ (rel_dist + I(rel_dist^2)) * receiver + (1 | ppt),
                data = nemo_dist)
emt_receiver <- emtrends(m2, ~ receiver, var = "rel_dist")

# Draw distance discounting panel -------------------------------------
# The display ends at the 95th percentile; models use the selected full sample.
x_cap <- as.numeric(quantile(nemo_dist$rel_dist, 0.95, na.rm = TRUE))
figS3 <- ggplot(nemo_dist, aes(x = rel_dist, y = s_adj)) +
  geom_point(alpha = 0.06, size = 0.6, colour = "grey40") +
  geom_vline(xintercept = 0.20, linetype = "dashed", colour = "grey50") +
  geom_smooth(aes(colour = receiver), method = "loess", se = TRUE) +
  facet_wrap(~ receiver) +
  scale_colour_manual(values = c(Child = "#F8766D", Adult = "#00BFC4"),
                      guide = "none") +
  coord_cartesian(xlim = c(0, x_cap), ylim = c(0, 1)) +
  theme_minimal(base_size = 16) +
  labs(
    title = "Figure S3. Social information use as a function of distance between E1 and X",
    subtitle = "Live sources only (vertical all waves; all sources waves 9-10). Dashed line = controlled target (~20% of E1).",
    x = "Relative distance  |X - E1| / E1",
    y = "Social information use (s)"
  )


# Save results and session information --------------------------------
write.csv(as.data.frame(summary(emt_receiver,infer=c(TRUE,TRUE))),file.path(table_dir,"receiver_slopes.csv"),row.names=FALSE)
write.csv(as.data.frame(anova(m2,m2_quad)),file.path(table_dir,"quadratic_lrt.csv"))
save_model(m2,"m2")
save_model(m2_quad,"m2_quad")
figS3 <- figS3 + labs(title="Distance discounting",subtitle="Live sources; dashed line marks 20% distance")
save_plot(figS3,"figS3")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
