# Script: _setup.R
# Shared setup for the reported analyses. Source from each numbered script.

# Session setup -------------------------------------------------------
options(stringsAsFactors=FALSE)
suppressPackageStartupMessages(library(lmerTest))
set.seed(20261026)

# Set input and output paths ------------------------------------------
# Set NEMO_OUTPUT_DIR to save generated files outside the repository.
input_file <- file.path(repo_root,"data","nemo_analysis_data.csv")
output_root <- Sys.getenv("NEMO_OUTPUT_DIR",file.path(repo_root,"outputs"))
output_dir <- file.path(output_root,script_id)
table_dir <- file.path(output_dir,"tables")
figure_dir <- file.path(output_dir,"figures")
dir.create(table_dir,recursive=TRUE,showWarnings=FALSE)
dir.create(figure_dir,recursive=TRUE,showWarnings=FALSE)

# Save model summaries and fitted objects -----------------------------
save_model <- function(model,name) {
  capture.output(summary(model),file=file.path(table_dir,paste0(name,"_summary.txt")))
  saveRDS(model,file.path(table_dir,paste0(name,".rds")))
  if (inherits(model,"mblogit")) {
    write.csv(data.frame(n_choice_trials=nrow(model$model),n_participants=nlevels(model$groups[[1]]),converged=isTRUE(model$converged)),file.path(table_dir,paste0(name,"_sample.csv")),row.names=FALSE)
  }
  co <- summary(model)$coefficients
  if (is.matrix(co)) write.csv(data.frame(term=rownames(co),co,check.names=FALSE),file.path(table_dir,paste0(name,"_coefficients.csv")),row.names=FALSE)
  if (inherits(model,"merMod")) {
    write.csv(data.frame(term=names(lme4::fixef(model)),estimate=lme4::fixef(model),confint(model,parm="beta_",method="Wald"),check.names=FALSE),file.path(table_dir,paste0(name,"_wald_intervals.csv")),row.names=FALSE)
    write.csv(as.data.frame(lme4::VarCorr(model)),file.path(table_dir,paste0(name,"_variance.csv")),row.names=FALSE)
    write.csv(data.frame(n_observations=nobs(model),n_participants=length(unique(model@frame[[names(lme4::getME(model,"flist"))[1]]]))),file.path(table_dir,paste0(name,"_sample.csv")),row.names=FALSE)
  }
}

# Save plot images and reusable plot objects --------------------------
save_plot <- function(plot,name) {
  saveRDS(plot,file.path(figure_dir,paste0(name,".rds")))
  ggplot2::ggsave(file.path(figure_dir,paste0(name,".png")),plot,width=9,height=5.5,dpi=as.numeric(Sys.getenv("NEMO_DPI","300")),limitsize=FALSE)
}
