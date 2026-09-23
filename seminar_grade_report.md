# Final Grade: 84 / 100

**Paper:** *Did Remote Work Narrow the Motherhood Penalty? Evidence on the Intensive Margin from Israeli Labor Force Survey Microdata, 2017–2023* (`paper/paper.tex`, branch `editorial-audit-sep-22`, commit `7542b21`).
**Reviewed as:** Bachelor's empirical seminar paper, Seminar in Topics in Labor Economics and the Economics of Education.
**Scope note:** Per the grading instructions the **Conclusion section (§9, `paper.tex` line 1307 onward) was not read, graded, or penalised.** Nothing below refers to it. The `\today` submission date on the title page is tied to that section's TODO and is likewise ignored.

## Overall verdict

This is an unusually mature seminar paper. The research question is sharp, the pivot from the extensive to the intensive margin is justified by an explicit power calculation rather than by convenience, and the empirical strategy is stated with a precision (the role of each lower-order DDD term, the single parallel-trends assumption of the triple difference, the exact selection counterfactual behind the trimming bounds) that most Master's theses do not reach. The headline result (a triple interaction of 3.22 hours per unit of WFH exposure, SE 1.02, with a null average DiD of 0.23) is supported by a raw dose-response figure, a DDD-level event study with a joint pre-trend test, generalized Lee bounds with an Imbens–Manski interval, and a robustness table that includes the one check a sceptical reader would demand first (dropping the ten post-period-calibrated occupations). The limitations section is honest to the point of understating the paper's strengths.

The deductions below fall into three groups. The largest are specification choices that a careful referee would ask about: the DDD imposes a linear-in-exposure functional form without ever showing the saturated occupation-fixed-effects version, the "gender placebo" is not a placebo test, and the paper never exploits the youngest-child age variable that would test its own mechanism most directly. The second group is presentation: one table note is factually wrong, Table 1 has no inference, and several claims are uncited. The third is reproducibility of the exposure index's root input, which the repository itself flags as an open question.

I verified every number in all six tables and the figures against the committed `outputs/*.csv` files and against a full re-run of the pipeline on the raw CBS data; all match. Details are in the appendix.

## Rubric

| Category | Weight | Earned | Deductions |
|---|---|---|---|
| Academic writing and structure | 20 | 18 | W1, W2 |
| Correct application of econometric methods | 25 | 20 | M1, M2, M3 |
| Robustness of the empirical strategy | 20 | 16 | R1, R2, R3 |
| Formatting of tables and figures | 10 | 8 | T1, T2 |
| Clarity of the economic argument and literature | 15 | 14 | E1 |
| Reproducibility and soundness of the code | 10 | 8 | C1 |
| **Total** | **100** | **84** | **−16** |

## Point deductions

### Academic writing and structure (−2)

**W1. Deducted 1 point: repetition across sections.**
*Why:* The same caveats are restated in full three or four times. The forty-cluster / pre-trend-power caveat appears in §4.4 (Inference), §5.3 (Diagnostics, "One caveat belongs with this test"), §8 "Parallel trends", and §8 "Inference". The post-period-calibration argument appears in §3.2, §5.4 "Exposure measure" (a full paragraph), §7 (Discussion), and §8 "Exposure is partly post-treatment". Many sentences run past 45 words with stacked em-dash clauses (for example the second paragraph of §5.4 and the fourth paragraph of the Introduction). The paper is roughly 9,000 words before the Conclusion and could lose 15% with no loss of content.
*Better approach:* State each caveat once, at the point where it first bites, and cross-reference elsewhere ("see §4.4"). Limitations should list what is new, not re-argue what Results already argued. Split any sentence with two em-dashes.

**W2. Deducted 1 point: uncited factual claims about Israel.**
*Why:* The Introduction asserts that Israel has "the OECD's highest total fertility rate" with no citation. §3.2 and §7 state that "Israeli schools stayed in person by Ministry of Education policy" as the reason teaching is mis-scored by the external index. Israeli schools were in fact closed for extended periods during the 2020 lockdowns and again in early 2021; the claim is defensible for the 2022–23 window the calibration uses, but it is stated without a date range and without a source. §8 mentions "a third lockdown with partial school closure" in early 2021, again unsourced.
*Better approach:* Cite the OECD Family Database for fertility, and a Ministry of Education or Bank of Israel document (or Yaish et al. 2021, already in the bibliography) for the school-opening timeline, with explicit dates. Rephrase the teaching claim as "by 2022–23 Israeli teaching had returned fully to in-person delivery".

### Correct application of econometric methods (−5)

**M1. Deducted 2 points: the DDD is linear in exposure with no occupation or year fixed effects, and the saturated alternative is never shown.**
*Why:* Equation (2) enters the occupation-level exposure score as a single continuous regressor with its two-way interactions. This forces the occupation-level differences in hours levels (δ3), in the motherhood gap (δ5), and in the post-2021 change (δ6) to be linear in exposure. With only 40 two-digit occupations the standard, more flexible specification is cheap: occupation fixed effects (absorbing δ3), occupation × Post effects (absorbing δ6), Mother × occupation effects (absorbing δ5), and survey-year effects instead of a single Post dummy. The triple interaction remains identified. The paper itself says in §4.5 that the dose-response is "emphatically not linear in exposure" and that "most of the dispersion in the regressor lives in one tail", which is precisely the case where the linear projection can be driven by a few high-exposure occupations. The quartile figure is a partial check, not a substitute, because it drops the controls. The pooled DiD in column (1) likewise uses a single Post dummy rather than year effects, so the 2017–2019 and 2021–2023 year-to-year movements visible in Figure 1 are pooled into the intercept.
*Better approach:* Add a column to Table 2 with occupation FE, occupation × Post, Mother × occupation and year FE (`feols(WorkHoursCont ~ Mother:Post:WFH_Exposure + controls | occ + occ^Post + occ^Mother + year)`), and a binned version with a Q4 indicator in place of the continuous score. If the coefficient is stable, say so in one sentence and move on; if it is not, the paper needs to know.

**M2. Deducted 2 points: the "gender placebo" is not a placebo test, and the paper has no genuine falsification test.**
*Why:* A placebo requires a group that cannot be affected by the treatment. Fathers in teleworkable occupations are treated by the shift to remote work exactly as mothers are; they simply face a different household time constraint. The fathers' DDD is negative and marginally significant (−1.76, SE 1.02, p < 0.1), which the paper reads as the placebo "doing what it should, and more". A more natural reading is that it is a substantive result: within-household reallocation, with fathers in teleworkable jobs reducing hours as mothers increase them. That is interesting, and it is consistent with the mechanism, but it is not evidence against a confound. Meanwhile the fathers' DiD is significant and adverse (−0.40), which the paper concedes "has not demonstrated a clean average effect on that margin". Nothing in the paper tests whether the design produces effects where none should exist.
*Better approach:* Relabel §5.5 as a "fathers' comparison" and discuss it as evidence on household reallocation. Add a true placebo: (i) a fake treatment date inside the pre-period (Post = 2018–2019 vs 2017), which should return zero on the triple interaction; and (ii) permutation inference, randomly reassigning exposure scores across the 40 occupations 1,000 times and reporting where 3.22 falls in that distribution. The second also addresses the small-cluster problem in R1.

**M3. Deducted 1 point: no sensitivity to the construction of the hours outcome.**
*Why:* The outcome is a bin-median approximation (bins about five hours wide) with two irregular-hours codes imputed from period-specific medians. The headline effect (1.4 to 1.7 hours between quartiles) is smaller than one bin width, which the paper acknowledges in §3.1, and the period-specific imputation is itself a design choice that could move the pre/post difference. No alternative coding is reported.
*Better approach:* Add a robustness row estimating the DDD (a) with the imputed irregular-hours rows dropped, (b) with a full-time indicator (≥ 35 usual hours) as the outcome, and (c) with a long-hours indicator (≥ 42). A linear-probability DDD on the bin-crossing that the paper says the effect represents is the most honest version of the result.

### Robustness of the empirical strategy (−4)

**R1. Deducted 1 point: forty clusters and no small-cluster correction.**
*Why:* §4.4 and §8 correctly say that a wild cluster bootstrap is not applied and that the occupation-clustered standard errors are approximate. Naming the gap is not the same as closing it, and closing it costs two lines of code. The DDD event-study pre-trend test in particular has F(2, 39) and confidence intervals wide enough to contain the headline estimate; a bootstrap p-value for the headline and for the joint pre-trend test is the minimum a reader will ask for.
*Better approach:* Report wild-cluster-bootstrap p-values (Rademacher weights, 9,999 draws) for the triple interaction in Table 2 and for the joint Wald tests, or use the permutation test suggested in M2.

**R2. Deducted 2 points: the mechanism predicts heterogeneity by the age of the youngest child, the data contain it, and the paper does not use it.**
*Why:* The Goldin time-constraint mechanism the paper adopts implies that the hours response should be concentrated among mothers of young children, whose care obligations bind hardest, and should be near zero for mothers whose youngest child is fifteen or sixteen. The CBS extract has a youngest-child age bin (`GilYeledTzairMBNK`), and the repository already uses it (`scripts/employment_by_child_age.R`) for the employment margin. It appears nowhere in the hours analysis. This is the most direct test of the mechanism available in the data, and it would also address §8 "Who is childless" by separating mothers of teenagers from the rest. Its absence leaves the mechanism claim resting on the exposure gradient alone.
*Better approach:* Estimate the hours DDD separately for mothers of children aged 0–4, 5–9, 10–14 and 15–16 (against the same childless control), or interact the triple term with a young-child indicator, and report it as a row block in Table 5. A monotone decline with child age would be the strongest evidence in the paper.

**R3. Deducted 1 point: no first stage is reported for the headline regressor.**
*Why:* The design assumes the calibrated occupation-level score predicts actual remote work in the post-period. The pipeline checks this relevance only for the cell-based index used in the employment DDD (`check_wfh_first_stage_relevance()` in `main.R` §8d). For the occupation-level index the paper reports the calibration examples (teaching, clerical, ICT) but never the correlation between the calibrated score and realized 2021–23 WFH across the 40 occupations, nor a regression of realized WFH on the score.
*Better approach:* Add one sentence and one number to §3.2: the occupation-level correlation (or slope with SE) between the calibrated score and the realized reference-week WFH share, on men and women pooled, with the swapped occupations marked. A scatter of the 40 occupations would make an excellent appendix figure.

### Formatting of tables and figures (−2)

**T1. Deducted 1 point: Table 2's note is factually wrong.**
*Why:* The note states that column (2) "drops its smallest religion category ('other') for collinearity, so it estimates four religion categories rather than five". The committed `outputs/ddd_hours_table.csv` and the re-run log both show all four non-reference religion dummies estimated in column (2), including `Dat5` (1.540, SE 0.687). The drop occurs only in the Arab-women subsample (`ddd_hours_arab_table.csv`, and the pipeline warns about it for the Arab employment DiD). The note is stale, probably from an earlier sample definition.
*Better approach:* Delete the sentence from Table 2 and move a corrected version to Table 5's note, where it is true. More generally, generate table notes about dropped coefficients from the fitted model rather than by hand (see C1).

**T2. Deducted 1 point: Table 1 has no inference and mixed sample sizes; Table 3's layout is awkward.**
*Why:* Table 1's "Difference" column reports 38 differences with no standard errors, no tests, and no indication of which are meaningful; the hours rows are computed on the reference-week-worker sample (258,175 rows) while the "Observations" row reports 372,741, and the table does not say so. Table 3 (Lee bounds) forces a three-column bounds panel into an eight-column selection-rate panel with `\multicolumn` padding, which produces a visually confusing block. The Table 1 float also overflows the text width by 5.3pt (an Overfull hbox in the LaTeX log).
*Better approach:* Add clustered standard errors in parentheses under each difference in Table 1 and an N row per panel. Split Table 3 into a 4 × 8 selection table and a 3 × 4 bounds table, or move Panel A to an appendix. Fix the overfull box by reducing the column separation.

### Clarity of the economic argument and literature (−1)

**E1. Deducted 1 point: the literature review does not engage the continuous-treatment difference-in-differences literature, and the Israeli institutional context is thin.**
*Why:* The headline is a dose-response coefficient on a continuous exposure. The interpretation of such a coefficient as an average causal response requires the "strong parallel trends" assumption of Callaway, Goodman-Bacon and Sant'Anna (2024), which is stronger than the single parallel-trends assumption the paper attributes to Olden and Møen (2022) and which the DDD event study does not test. The review also does not discuss the Israeli childcare and school-opening timeline (which determines when the time constraint actually relaxed), and the Israeli evidence cited (Yaish et al. 2021; Madhala 2020; Buzaglo 2023) is mentioned in single sentences. Elsewhere the argument is clear and the connection to Goldin (2014) is well made.
*Better approach:* Add a paragraph on continuous-treatment DiD stating which assumption the dose-response interpretation needs and pointing to the binned specification (M1) as the version that needs less. Add two or three sentences with dates on Israeli school and daycare operation in 2021–2023.

*Note, no deduction:* §7 compares the 1.7-hour Q4-minus-Q1 difference to the 1.74-hour penalty and concludes mothers in teleworkable jobs "recovered most of the penalty". The right quantity is the implied change for a Q4 mother, −0.54 + 3.22 × 0.59 ≈ 1.4 hours, or the raw Q4 DiD of 1.55. The conclusion survives (about 80% of the penalty), but the sentence should use the level change, not the between-quartile difference.

### Reproducibility and soundness of the code (−2)

**C1. Deducted 2 points: the root input to the headline result has no documented derivation.**
*Why:* `data/israeli_cbs_wfh_2digit.csv` supplies the external teleworkability score for every occupation, and the calibration only overrides ten of them. Dingel and Neiman score US SOC occupations; the CBS uses ISCO-08. The crosswalk, the aggregation from four-digit to two-digit, and the weighting are not in the repository. The authors' own audit records this as an open question needing an author answer (`docs/open-question-wfh-crosswalk-provenance.md`, status OPEN), and the bibliography carries an unresolved `% VERIFY` comment on the entry. A reader cannot rebuild the external index or check the swap decisions. Separately, all six tables are hand-typed `tabular` blocks; I verified every cell against `outputs/` and they match, but nothing in the build enforces it, and T1 shows how a note drifts when it is typed rather than generated.
*Better approach:* Commit the crosswalk script and the Dingel–Neiman source file (or a script that downloads it), and add an appendix table listing the 40 occupations with external, realized and calibrated scores and the swap flag. Emit the regression tables as LaTeX fragments from the pipeline (`etable(..., tex = TRUE)` or a small writer) and `\input` them.

## Strengths worth naming

- **Design logic.** The move from the extensive to the intensive margin is motivated by a minimum-detectable-effect calculation against the closest published benchmark, not by which result was significant. The MDE per standard deviation of the regressor (rather than per unit) is the honest scaling and most papers get this wrong.
- **The DDD-level pre-trend test.** §5.3 explains why a DiD pre-trend test does not license a triple difference, then runs the right test. This distinction is routinely missed in published work.
- **Selection correction.** The Lee-bounds construction is adapted to a 2 × 2 design with an explicit parallel-trends-in-selection counterfactual, stratified so it can be applied to the DDD, and reported with an Imbens–Manski interval. The paper states exactly what the construction does not handle.
- **The unswapped-occupations check.** Dropping the ten post-period-calibrated occupations and finding a larger estimate on the remaining thirty is the single most convincing robustness row, and the paper places it where the natural objection arises.
- **Honesty about power and the 2023 survey year.** The paper reports the reweighted attenuation as "the largest single move any check produces" rather than burying it, flags the October 2023 war, and reads the Arab-women estimate as thin-coverage fragility rather than heterogeneity.
- **Reproducibility of everything downstream of the crosswalk.** Forty-four test files on synthetic fixtures, a schema-drift check on the raw files, a hash-keyed cache, and a pipeline that reproduced every committed CSV byte for byte.

## Appendix: reproducibility check

**Test suite.** `Rscript run_tests.R` (R 4.5.1, testthat) completed with `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 951 ]`, exit code 0. The seven snippets in `tests/testthat/_problems/` are testthat's extracted-failure scratch files from earlier sessions; `test_dir` does not pick them up and the corresponding tests currently pass.

**Full pipeline re-run.** `Rscript main.R` against the raw CBS extract on the local G: drive completed with exit code 0 (the cleaned-data cache was valid, so the cleaning step was not re-executed; the hash on `data_processing.R` matched). After the run:

| Artifact class | Result |
|---|---|
| 78 CSV tables in `outputs/` | byte-identical to the committed versions |
| 12 browsing PNGs in `outputs/` | byte-identical |
| 6 vector PDFs (`outputs/figures/*.pdf`, `outputs/event_study_pretrend.pdf`) | regenerated; 0 to 4 bytes larger, differing only in embedded PDF metadata. The CSVs they plot are unchanged. |

The six PDFs are currently left modified in the working tree so the author can inspect them; `git checkout -- outputs/` restores the committed copies.

**Paper-to-output cross-check.** Every cell of Tables 1 to 6, every coefficient quoted in the text of §4 to §8, both event-study coefficient sets, the three joint Wald tests, the two MDEs, both Lee-bounds tables, the Imbens–Manski intervals, the raw DiD, the dose-response quartiles, the realized-WFH shares in the Introduction, the absence shares in the Limitations footnote, and the commuting shares in §4.5 were matched against the corresponding `outputs/*.csv`. All agree to the reported precision. The one discrepancy found is T1 (a table note, not a number).

**Code-to-paper check.** The estimating equations, sample restrictions, clustering levels, and the calibration rule described in §3 and §4 match `scripts/intensive_margin_regression.R`, `scripts/hours_ddd_regression.R`, `scripts/hours_ddd_event_study.R`, `scripts/wfh_exposure_cells.R`, `scripts/hours_ddd_lee_bounds.R`, `robustness/pretrend_wald_test.R` and `robustness/age_balance_robustness.R`. The control set is defined once in `scripts/data_processing.R`. Survey weights are not applied in any outcome regression, as the paper states.

**LaTeX build.** `paper/paper.log` shows no undefined references or citations and no BibTeX warnings. Two cosmetic warnings: one Overfull hbox (Table 1, 5.3pt) and a PDF-version notice on the included figures (version 1.7 figures in a 1.5 document), which does not affect output.
