# Source selection shapes the strength of cultural transmission pathways

Research data and documentation accompanying the manuscript **Source selection shapes the strength of cultural transmission pathways**, by Sherilyn Segura, Wouter van den Bos, Andrea Gradassi, Esra Cemre Su de Groot, Lucia Hendrikse, Lieke Hofmans, Fleur Korzilius, Sheina Lew-Levy, Ana da Silva Pinho, Scarlett Slagter, Sjanne van der Stappen, and Lucas Molleman.

Children and their parents estimate the number of animals, view another person's estimate, and provide a second estimate. The study examines source choice, information weighting, age differences, parent–child resemblance, and estimation accuracy.

## Files

| File | Contents |
| --- | --- |
| `data/nemo_analysis_data.csv` | Processed data: 18,170 trials, 66 variables, 10 waves. |
| `CODEBOOK.md` | Variable definitions, coding and family linkage. |
| `codebook.csv` | Variable dictionary with observed values, wave coverage and missing counts. |
| `src/r/` | Numbered R scripts, shared setup and batch runner. |
| `ANALYSIS_GUIDE.md` | Instructions and a result index covering all main results, S1–S12, and supplementary statistical figures. |
| `DATA_SUMMARY.md` | Dataset counts and validation checks. |
| `PROVENANCE.md` | Data origin and processing steps. |
| `CITATION.cff` | Dataset citation metadata. |

Reported analysis and plotting scripts are in `src/r`. 


## Study design

Data were collected at NEMO Science Museum, Amsterdam, across ten waves in 2021–2025. Sources were assigned in waves 1–6 and chosen in waves 7–10. Waves 7–8 used one parent–child dyad per session; waves 9–10 used two. Wave 2 contains ten rounds (including 5 with an unidentified (anonymous) source); other waves contain five.

Sources include the participant's family member, another adult, and another child. The paired analysis includes 1,281 families. Children aged 6–13 are the main focus; older children are retained in models and age subsets up to 18.

Preregistration: [OSF 9xn87](https://osf.io/9xn87). Assigned-source analyses include registered hypotheses and later-wave extensions. Source-choice and accuracy/confidence analyses are exploratory. Ethics approval: University of Amsterdam, 2021-DP-13852.


## Use the data

Open the CSV with its header row as variable names. Fields are comma-separated, decimals use a point, and `NA` indicates missing values. Treat IDs as identifiers and source codes as categories.

Read `CODEBOOK.md` before applying `ANALYSIS_GUIDE.md`. Filters differ by analysis. Use `ppt` to link repeated participant trials and the specified family ID to pair parents with children. Count repeated questionnaire responses once per respondent. Treat `coopSports=99` as nonresponse when analyzing that item.


## Reproduce results

Run the scripts from the repository root with `source("src/r/_run_all.R")` in R. Fresh outputs go to `outputs/` by default. Set `NEMO_OUTPUT_DIR` before running to keep generated files outside the repository. See [src/r/README.md](src/r/README.md) for dependencies.

Social information use is quantified as the adjustment from the first to the second estimate, divided by the difference between the first estimate and social information: `s_adj = (secondEstimate − firstEstimate) / (socialInfo − firstEstimate)`. Here, 0 means no revision and 1 means adopting the social information. Undefined scores are `NA`; values outside [0,1] remain in the data for analysis-specific filtering.

H1 uses Spearman correlations across the paired sample and age subsets. H2 uses waves 2 and 4; H3–H5 use waves 1–6. The guide also covers the analyses on source selection, accuracy, self-efficacy and robustness tests for the number of dyads per session. Preregistered exclusions are supplemented by the age-adjusted performance criterion `z_resid ≥ 3` (removing extremely inaccurate estimates, which likely represent mistakes in entering the estimate).

Compare generated statistics with the manuscript and supplementary tables. H1 uses Spearman only. See `ANALYSIS_GUIDE.md` for the Wave 2 trial-scope distinction and interval-method limitations.

Analyses use R with dplyr/tidyr, lme4/lmerTest, emmeans and plotting packages. The recorded version list is R 4.6.0, lme4 2.0-1, lmerTest 3.2-1, mclogit 0.9.15, emmeans 2.0.3 and MuMIn 1.48.19. The copied mixed multinomial models use mclogit with participant random intercepts. Each run records its installed package versions and fit warnings.


## Additional measures

In addition to the variables used in the manuscript, the dataset contains questionnaire measures collected to explore potential determinants of social information use, including measures of parenting practices, family relationships, and some individual characteristics. These measures were introduced in different data collection waves, partly to address additional research questions pursued in student thesis projects. They are retained to preserve the broader dataset and facilitate secondary analyses, but are not part of the analyses reported in the manuscript. All variables, including their coding and availability across waves, are documented in CODEBOOK.md and codebook.csv.

## Citation and reuse

See CITATION.cff for citation information.

Contact: Lucas Molleman, l.s.molleman@uva.nl. After publication, report corrections through Issues with the release version, variable and analysis concerned.
