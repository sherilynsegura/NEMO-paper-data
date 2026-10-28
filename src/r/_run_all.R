# Script: _run_all.R
# Run the reported analysis and plot copies in Table S1 order.

# Locate the repository and output folder -----------------------------
# Set NEMO_OUTPUT_DIR before running to use an external output folder.
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
if (!file.exists(file.path(repo_root,"data","nemo_analysis_data.csv"))) stop("Run from the repository root or set NEMO_REPO_ROOT.")
output_root <- Sys.getenv("NEMO_OUTPUT_DIR",file.path(repo_root,"outputs"))
dir.create(file.path(output_root,"logs"),recursive=TRUE,showWarnings=FALSE)
Sys.setenv(NEMO_REPO_ROOT=repo_root,NEMO_OUTPUT_DIR=output_root)

# Run numbered scripts in order ---------------------------------------
# Each script runs in a fresh R session; logs record messages and warnings.
scripts <- sort(list.files(file.path(repo_root,"src","r"),pattern="^[0-9].*[.]R$",full.names=TRUE))
status <- lapply(scripts,function(path) {
 cat("Running ",basename(path),"\n",sep="")
 log <- file.path(output_root,"logs",paste0(basename(path),".log"))
 code <- system2(file.path(R.home("bin"),"Rscript"),c("--vanilla",shQuote(path)),stdout=log,stderr=log)
 data.frame(script=basename(path),exit_code=code)
})

# Save completion status ----------------------------------------------
# A nonzero exit code identifies a script that failed.
status <- do.call(rbind,status)
write.csv(status,file.path(output_root,"run_status.csv"),row.names=FALSE)
if(any(status$exit_code!=0))stop("Some scripts failed. See outputs/run_status.csv and outputs/logs.")
cat("All scripts completed. Outputs: ",output_root,"\n",sep="")
