# Analysis guide

## Data and conventions

Run `source("src/r/_run_all.R")` from the repository root, or run the numbered script for the analysis of interest. Fresh model results are written to `outputs/` by default; set `NEMO_OUTPUT_DIR` before running to save them outside the repository.

Read `data/nemo_analysis_data.csv`, treating `NA` as missing. Each row represents one participant's trial. Use the stored `s_adj` and `z_resid` values.

- **Valid s:** nonmissing `s_adj` between 0 and 1, inclusive.
- **Performance filter:** retain missing `z_resid` or `z_resid < 3`, unless an absolute-value filter is specified.
- **Receiver:** child at age ≤18; caregiver at age >18.
- **Family:** `group` in waves 1–8; `dyad` in waves 9–10.
- **S:** participant mean `s_adj` across selected valid trials.
- **Random intercept:** `(1|ppt)` accounts for repeated trials within participants.

`s_adj = (secondEstimate − firstEstimate) / (socialInfo − firstEstimate)`. Missing inputs or a zero denominator give missing s. `z_resid` is participant mean absolute initial estimation error adjusted for age and standardized by the residual SD; retain its existing values when subsetting.

Apply each analysis's filters below. Require complete eligible families and at least three valid trials per member for H1 only. For individual-level analyses, retain eligible participants even when their family member fails an individual criterion.

Fit linear mixed models with REML unless maximum likelihood (ML) is specified. Use ML for likelihood-ratio comparisons of models with different fixed effects. Compare generated values with the manuscript and supplementary tables.

## Result index

| Result | Instructions |
| --- | --- |
| Task and adjustment diagram (Figure 1) | Data and conventions; no model fit |
| Assigned-source age, receiver and pathway effects (Figure 2; S1–S4) | H2–H5; Age and transmission |
| Source-choice proportions and models (Figure 3A–B; S5) | Source selection; Visual summaries |
| Weighting after source choice (Figure 3C–D; S6) | Information weighting after source selection; Visual summaries |
| Active-choice effect (S7) | Effect of source selection on weighting |
| Family resemblance (Figure 4A; Figure S1; S12) | H1; Wave 2 subset |
| Before/after accuracy (Figure 4B–D; Figure S2; S8) | Estimation accuracy; Visual summaries |
| Self-rated performance (Figure 4E–F; S9) | Self-rated performance; Visual summaries |
| Seating and room configuration (S10–S11) | Seating and testing configuration |
| Live-source distance effects (Figure S3) | Distance discounting |
| One/two-dyad child plots (Figure S4) | Configuration-specific child analyses |

S1 is the analysis inventory, not an additional model. S2–S12 report the supplementary results. H1 uses Spearman throughout.

## H1 Caregiver–offspring resemblance

Select assigned-source rows in waves 1–6 (`choseSource=0`) and chosen-source rows in waves 7–10 (`choseSource=1`). Process waves 1–8 by `group` and waves 9–10 by nonmissing `dyad`.

Within each block, apply the performance filter and retain valid s. Remove families containing missing age or age <6 among the remaining observations. Require exactly two participants, one child and one caregiver, with at least three retained trials each. Calculate S per participant, pair family members, and combine the blocks.

Compute the **Spearman rank correlation** between caregiver S and child S. Repeat within child-age bands 6–8, 9–11 and 12–18. The pooled sample contains 1,281 families; age-band samples contain 453, 673 and 155 families, respectively.

### Wave 2 subset

Apply the H1 family rules to Wave 2 and compute Spearman correlation. The 236-family output in the reference table uses all ten periods. Anonymous-only Part A requires `period≤5` and `socialSource=0`, giving 205 eligible families. Match the selected trial scope to its reference result; these samples are not interchangeable.

Calculate approximate 95% confidence intervals for Spearman’s rho using the Fisher-z transformation: `tanh(atanh(rho) ± qnorm(0.975) / sqrt(n - 3))`, where `n` is the number of paired families. Spearman p-values use the asymptotic test for tied data.

## H2 Adult versus peer source

Select `wave` in {2,4}, `choseSource=0`, `socialSource` in {2,3}, nonmissing age ≤18, valid s, and missing `z_resid` or `z_resid < 3`. Define source 2 as other adult and source 3 as peer.

Fit `s_adj ~ source + (1|ppt)`. Estimate the adult-versus-peer contrast. Sample: 336 children; 1,411 trials.

## H3 Children versus caregivers

Select waves 1–6, `choseSource=0`, nonmissing age ≥6, valid s, and the performance filter. Define caregiver as the receiver reference level.

Fit `s_adj ~ receiver + (1|ppt)`. Estimate the child-versus-caregiver effect and fixed-effect Wald confidence intervals. Sample: 1,366 participants; 8,057 trials.

## H4 Child age

Select waves 1–6, `choseSource=0`, nonmissing age 6–18, valid s, and the performance filter. Center age on the mean of retained trial rows. Treat `socialSource` as categorical, retaining anonymous source 0 where present.

Fit `s_adj ~ age_c + factor(socialSource) + (1|ppt)`. Sample: 688 children; 3,862 trials.

## H5 Source and receiver

Select waves 1–6, `choseSource=0`, `socialSource` in {1,2,3}, nonmissing age ≥6, valid s, and the performance filter. Set child as the receiver reference and source 1 as the source reference.

Fit `s_adj ~ receiver * factor(socialSource) + (1|ppt)`. Obtain estimated marginal means and Bonferroni-corrected source contrasts within each receiver. For children, compare source 1 (vertical) with source 2 (oblique) and source 3 (horizontal). For caregivers, source 2 is horizontal and source 3 is oblique. Sample: 1,362 participants; 5,890 trials. Script 09 labels source codes 1/2/3 as Vertical/Oblique/Horizontal for both receivers. In caregiver output, the labels Oblique and Horizontal therefore denote physical source codes 2 (another adult; horizontal) and 3 (another child; oblique), respectively. Interpret caregiver marginal means and contrasts using that reversal. Receiver-by-source coefficient interactions compare physical source codes; reporting interactions by receiver-relative pathway requires explicitly transformed contrasts or a documented recoding, not merely swapping coefficient labels.

## Age and transmission

Select assigned-source waves 1–6, source codes 1–3, nonmissing receiver age 6–70, valid s, and the performance filter. For children, use own age and map sources 1/2/3 to vertical/oblique/horizontal. For caregivers, include source 1 as vertical and source 3 as oblique; derive the age predictor as follows:

| Caregiver source | Waves | Age predictor |
| --- | --- | --- |
| Own child, code 1 | 1, 5 | Maximum child age ≤18 within the filtered wave/group |
| Own child, code 1 | 3 | `ageOther` |
| Other child, code 3 | 2 | `sourceAge` |
| Other child, code 3 | 4, 6 | `shownAge` |

Require a defined transmission category and age predictor ≥6. Center age on the retained trial-row mean. Fit `s_adj ~ age_c * transmission * receiver + (1|ppt)` using ML. Summarize caregiver source-2 trials separately. Sample: 1,183 participants; 5,039 trials. Obtain pathway-specific age slopes and receiver/pathway contrasts from the fitted interaction model. Calculate receiver means from participant-level S, so participants contribute equally.

## Source selection

Select chosen-source waves 7–10, nonmissing age 6–70, identifiable sources 1–3, and missing `z_resid` or `abs(z_resid) < 3`. Retain source choices regardless of s validity. Map transmission from the receiver's perspective.

Use own age for children. For caregivers, join their own child's age by family, independently of the selected source. Center age within each model sample. Fit separate mixed multinomial models for children and caregivers, with transmission as outcome, centered age as predictor, vertical as reference, and participant random intercepts. Calculate odds ratios and Wald confidence intervals. Use a mixed multinomial engine such as `mclogit::mblogit`. Repeat the caregiver model using centered caregiver age for the additional own-age result in S5. Keep own-child age and caregiver age as separate model specifications. The existing source-selection script reports individual age coefficients; it does not export a joint age-term likelihood-ratio test.

## Information weighting after source selection

Select chosen-source waves 7–10, nonmissing age 6–70, valid s, and missing `z_resid` or `abs(z_resid) < 3`. Prepare waves 7–8 and 9–10 separately, then pool within receiver.

For children, use own age and all three transmission categories. For caregivers, include vertical and oblique trials: use own child's age for vertical, `shownAge` for oblique in waves 7–8, and the other family's child age for oblique in waves 9–10. Link other-family children within session using different nonmissing dyads. Summarize caregiver horizontal trials separately.

Center the age predictor on the pooled trial-row mean within receiver. Fit `s_adj ~ age_c * transmission + (1|ppt)` separately for children and caregivers using ML. Samples: 827 children/3,371 trials; 809 caregivers/2,629 trials.

## Effect of source selection on weighting

Select all waves with valid s, nonmissing age ≥6, nonmissing source, and the performance filter. Center age within receiver using retained trial rows. Treat source as categorical with source 0 as reference.

Fit `s_adj ~ choseSource + receiver * age_c + factor(socialSource) + (1|ppt)`. Script 17a controls for physical source codes: 0 is anonymous/unknown, 1 own family member, 2 another adult, and 3 another child. Its Oblique/Horizontal output labels refer to codes 2/3 and do not express receiver-relative pathways for caregivers. Preserve this model when reproducing the existing S7 results.

## Estimation accuracy

Select all waves, retaining only source codes 2/3 within Wave 2. Require nonmissing age ≥6, valid s, and the performance filter. Calculate proportional absolute error before and after social information: `abs(estimate − nAnimals) / nAnimals`; set undefined values to missing. Use receiver-dependent transmission labels.

Reshape each trial into first/second estimate records. Fit models with participant random intercepts:

- `proportional_error ~ estimate + (1|ppt)`
- `proportional_error ~ estimate * receiver + (1|ppt)`
- `proportional_error ~ estimate * transmission + (1|ppt)`

Compare the transmission-interaction model with its additive counterpart using an ML likelihood-ratio test. Calculate estimated marginal E1−E2 improvements by pathway with Bonferroni correction and asymptotic inference. Sample: 3,048 participants; 13,032 task trials reshaped to 26,064 before/after estimate records.

For age plots, average each error measure per participant and fit LOESS smoothers with 95% confidence bands. For before/after pathway summaries, group the eligible estimate records by receiver and transmission. Repeat within assigned-source (`choseSource=0`) and chosen-source (`choseSource=1`) conditions for the experiment-specific summaries. Estimate E1−E2 differences separately within receiver from the receiver-interaction model.

## Self-rated performance

Select assigned-source waves 2–5, nonmissing age ≥6, valid s, and the performance filter. Retain nonmissing self-rated performance values. Center competence and age separately within each receiver-specific and pooled model sample.

Fit `s_adj ~ competence_c + age_c + (1|ppt)` and `abs(firstEstimate − nAnimals) ~ competence_c + age_c + (1|ppt)`. Export fixed effects and participant/residual SDs. Accuracy is measured in animal counts here, rather than proportional error.

## Seating and testing configuration

Define participant ID `uid=(wave,group,ppt)` and session ID `grp=(wave,group)`. Retain nonmissing age and center it on this preparation sample. Use receiver-dependent source categories.

For waves 1–6, define seating as face-to-face in waves 1–2 and facing-away in waves 3–6. Retain valid s and identifiable source categories, excluding anonymous source 0. Fit `s_adj ~ seating + age_c + source + (1|grp) + (1|uid)`.

For waves 7–10, define configuration as two people in waves 7–8 and four people in waves 9–10. Retain valid s and source categories. Fit `s_adj ~ configuration + source + age_c + (1|grp) + (1|uid)`.

Use REML and the `bobyqa` optimizer. These fits use valid s but do not additionally apply the shared minimum-age or performance filters.

For configuration effects on source selection, retain identifiable source choices and fit mixed multinomial models `transmission ~ configuration`, with participant random intercepts and vertical as reference. Fit children, caregivers and pooled data separately.

## Distance discounting

Select identifiable live sources: vertical in all waves and all source types in waves 9–10. Require `firstEstimate > 0`, nonmissing `socialInfo`, nonmissing age ≥6, valid s, and the performance filter. Calculate `distance = abs(socialInfo − firstEstimate) / firstEstimate`.

Fit `s_adj ~ distance * receiver + (1|ppt)` and the quadratic extension `s_adj ~ (distance + I(distance^2)) * receiver + (1|ppt)`. Compare fixed effects using ML likelihood-ratio tests. For display, truncate distance at its 95th percentile; retain the full eligible sample in models. Estimate child and caregiver distance slopes from the receiver interaction, including SEs, p-values and confidence intervals. Compare quadratic and linear specifications on the same complete-case sample. Draw receiver-specific LOESS curves with 95% bands and a vertical reference at distance 0.2.

## Configuration-specific child analyses

Split chosen-source waves into waves 7–8 (one dyad) and waves 9–10 (two dyads). Within each block, use the source-selection filters for choice proportions and the information-weighting filters for adjustment models. Retain child receivers and use own age.

Calculate the proportion of choices for each pathway at each child age, with distinct participant counts. Fit `s_adj ~ age_c * transmission + (1|ppt)` within each block using ML. Center age on that block's eligible weighting sample. Plot pathway means and fixed-effect predictions with 95% confidence bands.

## Visual summaries

For age-by-pathway weighting plots, average valid trial adjustments within age, pathway and receiver. Show distinct participant counts and fixed-effect model predictions; use the fixed-effect covariance matrix for 95% prediction-of-mean bands. Keep ages above 13 in fitted models even when axes end at 13. Display caregiver horizontal weighting as a separate pooled mean where child-source age is undefined.

For source-choice bars, divide pathway trial counts by all eligible choice trials in each receiver/age bin. Count participants separately from trials. Bin caregiver choices by their own child's age, independent of the chosen source.

For family scatterplots, plot one paired S record per family. A least-squares line and its 95% band are visual summaries; use Spearman for the association test.

For self-rated-performance plots, scripts 16–17 use trial-level values and separate least-squares regressions within receiver groups, with 95% mean-response bands. These visual summaries are unadjusted for age and differ from the age-adjusted mixed models used for the reported tests. Plot ratings are centered across the pooled plotting sample. Use the sample filters specified above.

## Output

For each model, export sample sizes, coefficients, standard errors, test statistics, degrees of freedom, p-values and confidence intervals. Include odds ratios for multinomial models and adjusted pairwise contrasts where specified. Record factor references, estimation method and package versions. Compare rounded values with the manuscript and supplementary tables.
