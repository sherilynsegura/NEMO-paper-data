# Reported analysis and plot scripts

Run from the repository root in R:

```r
source("src/r/_run_all.R")
```

Or run one numbered file, for example `source("src/r/06_P2_adult_vs_peer.R")`. Every numbered analysis file contains its own exclusions, setup and selected model/plot steps. Figure assembly (24) requires panels from preceding files. `_setup.R` provides paths and output helpers; `_run_all.R` runs each file in a separate R process.

Required installed packages: dplyr, tidyr, tibble, ggplot2, patchwork, ggforce, lme4, lmerTest, emmeans, mclogit, nnet and MuMIn. The source copies retain some original imports. The fitted multinomial models require mclogit; no nonmixed fallback is used.

Outputs go to `outputs/<script-name>/`: model coefficients, Wald intervals, variance components, summaries, fitted-model RDS files, plots and session information. Batch logs and exit codes are saved separately. Set `NEMO_OUTPUT_DIR` to write elsewhere; set `NEMO_REPO_ROOT` when running outside this folder. Default PNG resolution is 300 dpi; `NEMO_DPI` controls export resolution.

The first 17 numbers follow Table S1, with `11a` for E1 plots and `17a` for S7. SI-only scripts and panel assembly follow.

The input CSV is never overwritten. Compare generated results with the manuscript and supplied SI values. Set `NEMO_OUTPUT_DIR` before running to retain generated outputs outside the repository.
