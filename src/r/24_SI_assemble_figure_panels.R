# Script: 24_SI_assemble_figure_panels.R
# Reports: assembled Figures 3, 4, S1, S2 and S4. No model fits.

# Set up paths and shared helpers -------------------------------------
script_id <- "24_SI_assemble_figure_panels"
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
source(file.path(repo_root,"src","r","_setup.R"),local=TRUE)
library(ggplot2); library(patchwork)

# Load saved plot objects ---------------------------------------------
# Run the contributing analysis scripts first, using the same output folder.
load_panel <- function(id,object) {
 p <- file.path(output_root,id,"figures",paste0(object,".rds"))
 if (!file.exists(p)) stop("Run the preceding numbered scripts first: ",p)
 readRDS(p)
}

# Assemble Figure 3 ---------------------------------------------------
p3a <- load_panel("11a_E1_source_selection_plots","p_child")
p3b <- load_panel("11a_E1_source_selection_plots","p_adult")
p3c <- load_panel("12_E2_child_chosen_information","plot_combined")
p3d <- load_panel("13_E3_caregiver_chosen_information","plot_h5_adults_combined")
figure3 <- ((p3a+labs(tag="A",title=NULL,subtitle=NULL)) | (p3b+labs(tag="B",title=NULL,subtitle=NULL))) /
 ((p3c+labs(tag="C",title=NULL,subtitle=NULL)) | (p3d+labs(tag="D",title=NULL,subtitle=NULL)))

# Assemble Figure 4 ---------------------------------------------------
p4a <- load_panel("02_P1-E1_all_wave_resemblance","panel_A")
p4b <- load_panel("14_E4_estimation_accuracy","plot_err_children")
p4c <- load_panel("14_E4_estimation_accuracy","plot_err_adults")
p4d <- load_panel("15_E5_accuracy_by_pathway","plot_comet_pooled_combined")
p4e <- load_panel("16_E6_self_rated_performance_information","panel_A")
p4f <- load_panel("17_E7_self_rated_performance_accuracy","panel_B")
figure4 <- (p4a | (p4b+labs(tag="B")) | (p4c+labs(tag="C"))) /
 ((p4d+labs(tag="D")) | p4e | p4f)

# Assemble Figure S1 --------------------------------------------------
s1a <- load_panel("01_P1_wave2_resemblance","plot_P1")
s1b <- load_panel("03_P1-E2_resemblance_age_6-8","plot_subset")
s1c <- load_panel("04_P1-E3_resemblance_age_9-11","plot_subset")
s1d <- load_panel("05_P1-E4_resemblance_age_12-18","plot_subset")
figureS1 <- (s1a | s1b) / (s1c | s1d)

# Assemble Figure S2 --------------------------------------------------
figureS2 <- load_panel("15_E5_accuracy_by_pathway","plot_comet_children") |
 load_panel("15_E5_accuracy_by_pathway","plot_comet_caregivers")

# Assemble Figure S4 --------------------------------------------------
s4choice <- load_panel("23_SI_FigureS4_source_choice","plot_choice") +
 facet_wrap(~configuration,labeller=labeller(configuration=c("One dyad"="A. One dyad","Two dyads"="B. Two dyads")))
s4c <- load_panel("21_SI_FigureS4_children_waves_7-8","plot3_h5_w7_8") +
 labs(title=NULL,subtitle=NULL,tag="C") + guides(size="none") + theme(legend.text=element_text(size=8),legend.title=element_text(size=9))
s4d <- load_panel("22_SI_FigureS4_children_waves_9-10","plot3_h5_w9_10") +
 labs(title=NULL,subtitle=NULL,tag="D") + guides(size="none") + theme(legend.text=element_text(size=8),legend.title=element_text(size=9))
figureS4 <- s4choice / (s4c | s4d)

# Save assembled figures ----------------------------------------------
for (name in c("figure3","figure4","figureS1","figureS2","figureS4")) {
 plot <- get(name)
 ggsave(file.path(figure_dir,paste0(name,".png")),plot,width=if(name=="figure4")18 else 14,
        height=if(name=="figureS2")6 else 11,dpi=as.numeric(Sys.getenv("NEMO_DPI","300")),limitsize=FALSE)
 saveRDS(plot,file.path(figure_dir,paste0(name,".rds")))
}
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
