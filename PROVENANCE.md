# Data provenance

Prepared on 29 October 2026. Permission to share the full dataset was confirmed on that date.

`data/nemo_analysis_data.csv` is an unchanged copy of `data_processed/NEMO_Combined_data_set_with_adjustment.csv`, renamed for release.

## Processing

1. Combine ten collection waves and retain their labels.
2. Remove designated non-parent–child groups and participants. Remove participants with at least three trials containing a zero first or second estimate (which indicates a missing response), and designated affected groups. Convert remaining zero estimates to missing. Remove a designated dyad containing a participant younger than six years old.
3. Calculate participant mean absolute initial estimation error. Regress error on age using complete cases, divide residuals by their sample SD, and join the resulting `z_resid` to trial rows.
4. Calculate `s_adj`, retaining missing scores and values outside [0,1] for analysis-specific filtering.

These steps summarize the available processing files.
