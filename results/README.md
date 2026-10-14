# Statistical results

Each CSV has descriptive headers and one row per analysis, predictor, contrast or sample. Tables with different types of output are split into separate files so columns keep the same meaning throughout. H1 uses Spearman only.

Values are transcribed from the supplied SI tables, not new model fits. Rounding, p-value inequalities and source typos are preserved. Missing statistics are not invented.

## Files

| File | Contents |
| --- | --- |
| [table_S1_analysis_overview.csv](table_S1_analysis_overview.csv) | Analysis IDs, data, models, samples and results. |
| [table_S2_model_coefficients.csv](table_S2_model_coefficients.csv) | Child age and source model. |
| [table_S3A_model_coefficients.csv](table_S3A_model_coefficients.csv) | Receiver-by-source model. |
| [table_S3B_marginal_means.csv](table_S3B_marginal_means.csv) | Estimated pathway means and SEs by receiver. |
| [table_S3C_pairwise_contrasts.csv](table_S3C_pairwise_contrasts.csv) | Within-receiver pathway contrasts; Bonferroni-adjusted p-values. |
| [table_S4_model_coefficients.csv](table_S4_model_coefficients.csv) | Age-by-transmission-by-receiver model. |
| [table_S5_model_coefficients.csv](table_S5_model_coefficients.csv) | Source-choice models, including odds ratios. |
| [table_S6_model_coefficients.csv](table_S6_model_coefficients.csv) | Information weighting after source selection. |
| [table_S7_model_coefficients.csv](table_S7_model_coefficients.csv) | Effect of source selection on weighting. |
| [table_S8A_model_coefficients.csv](table_S8A_model_coefficients.csv) | Before/after accuracy-by-pathway model. |
| [table_S8B_accuracy_improvements.csv](table_S8B_accuracy_improvements.csv) | Estimated accuracy improvement by pathway. |
| [table_S10_model_coefficients.csv](table_S10_model_coefficients.csv) | Seating and testing-configuration models. |
| [table_S11_model_coefficients.csv](table_S11_model_coefficients.csv) | Testing configuration and source-choice models. |
| [table_S11_sample_sizes.csv](table_S11_sample_sizes.csv) | Participant and trial counts for S11. |
| [table_S12_spearman_correlations.csv](table_S12_spearman_correlations.csv) | Family-level Spearman correlations and sample sizes. |
| [table_S9A_social_information_use.csv](table_S9A_social_information_use.csv) | Self-rated performance predicting information use. |
| [table_S9_variance_components.csv](table_S9_variance_components.csv) | Participant and residual SDs for the S9 models. |
| [table_S9B_estimation_accuracy.csv](table_S9B_estimation_accuracy.csv) | Self-rated performance predicting absolute estimation error. |
| [table_S9_sample_sizes.csv](table_S9_sample_sizes.csv) | Participant and trial counts for S9. |

## Read the columns

`group`, `receiver` and `outcome` identify the model or sample. `predictor`, `predictor_or_contrast` and `contrast` identify its terms. Coefficients, SEs, test statistics, degrees of freedom and p-values have separate columns. `confidence_interval_95` preserves the supplied interval; for multinomial coefficients, it is the odds-ratio interval. `estimated_mean` denotes an estimated marginal mean. `improvement_E1_minus_E2` denotes the reduction in proportional error.

P-values such as `< .001` are text. Numeric entries may contain thousands separators or Unicode minus signs; normalize these when importing for computation. Sample-size files distinguish participants from trials. S8 uses before/after estimate records, with two records per eligible trial.

Follow [ANALYSIS_GUIDE.md](../ANALYSIS_GUIDE.md) for preparation and models.

Update the CSVs when the source tables change. Model coefficients have not been independently verified by refitting.
