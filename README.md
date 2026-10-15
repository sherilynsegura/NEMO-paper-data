# Source selection shapes the strength of cultural transmission pathways

Research data and documentation accompanying the manuscript **Source selection shapes the strength of cultural transmission pathways**, by Sherilyn Segura, Wouter van den Bos, Andrea Gradassi, Esra Cemre Su de Groot, Lucia Hendrikse, Lieke Hofmans, Fleur Korzilius, Sheina Lew-Levy, Ana da Silva Pinho, Scarlett Slagter, Sjanne van der Stappen, and Lucas Molleman.

Children and caregivers estimate the number of animals, view another person's estimate, and provide a second estimate. The study examines source choice, information weighting, age differences, caregiver–child resemblance, and estimation accuracy.

**Status:** local draft; not yet published to GitHub. Full-data sharing is authorized. The reuse license and remaining analysis specifications need confirmation.

## Files

| File | Contents |
| --- | --- |
| `data/nemo_analysis_data.csv` | Processed data: 18,170 trials, 66 variables, 10 waves. |
| `CODEBOOK.md` | Variable definitions, coding and family linkage. |
| `codebook.csv` | Variable dictionary with observed values, wave coverage and missing counts. |
| `ANALYSIS_GUIDE.md` | Instructions and a result index covering all main results, S1–S12, and supplementary statistical figures. |
| `DATA_SUMMARY.md` | Dataset counts and validation checks. |
| `PROVENANCE.md` | Data origin and processing steps. |
| `results/*.csv` | Table-specific statistical results with descriptive column headers. |
| `results/README.md` | Results format, provenance and source issues. |
| `CITATION.cff` | Dataset citation metadata. |


## Study design

Data were collected at NEMO Science Museum, Amsterdam, across ten waves in 2021–2025. Sources were assigned in waves 1–6 and chosen in waves 7–10. Waves 7–8 used one caregiver–child dyad per session; waves 9–10 used two. Wave 2 contains ten rounds; other waves contain five.

Sources include the participant's family member, another adult, and another child. The paired analysis includes 1,281 families. Children aged 6–13 are the main focus; older children are retained in models and age subsets up to 18.

Preregistration: [OSF 9xn87](https://osf.io/9xn87). Assigned-source analyses include registered hypotheses and later-wave extensions. Source-choice and accuracy/confidence analyses are exploratory. Ethics approval: University of Amsterdam, 2021-DP-13852.

## Use the data

Open the CSV with its header row as variable names. Fields are comma-separated, decimals use a point, and `NA` indicates missing values. Treat IDs as identifiers and source codes as categories.

Read `CODEBOOK.md` before applying `ANALYSIS_GUIDE.md`. Filters differ by analysis. Use `ppt` to link repeated participant trials and the specified family ID to pair caregivers with children. Count repeated questionnaire responses once per respondent. Treat `competenceLadder=0` and `coopSports=99` as nonresponse when analyzing those items.

## Reproduce results

Social information use is `s_adj = (secondEstimate − firstEstimate) / (socialInfo − firstEstimate)`: 0 means no revision and 1 means adopting the social estimate. Undefined scores are `NA`; values outside [0,1] remain in the data for analysis-specific filtering.

H1 uses Spearman correlations across the paired sample and age subsets. H2 uses waves 2 and 4; H3–H5 use waves 1–6. The guide also covers source selection, accuracy, confidence and configuration analyses. Preregistered exclusions are supplemented by the age-adjusted performance criterion `z_resid ≥ 3`.

The table-specific CSVs contain transcribed reference statistics, not new model fits. Each uses descriptive headers and one row per predictor, contrast or summary. H1 uses Spearman only. See `results/README.md` for the file list and source issues, including Wave 2 trial scope.

Analyses use R with dplyr/tidyr, lme4/lmerTest, emmeans and plotting packages. The recorded version list is R 4.6.0, lme4 2.0-1, lmerTest 3.2-1, nnet 7.3-20, emmeans 2.0.3 and MuMIn 1.48.19. The mixed multinomial engine and version still need confirmation; the guide specifies participant random intercepts.

## Citation and reuse

Use `CITATION.cff` for author metadata. A publication DOI, repository URL and reuse license have not yet been assigned.

Contact: Lucas Molleman, l.s.molleman@uva.nl. After publication, report corrections through Issues with the release version, variable and analysis concerned.
