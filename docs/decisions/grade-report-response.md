# Decision Memo: Response to the 2026-09-22 Grading Report

**Status: IMPLEMENTED (2026-09-22).** Pipeline code, tests, the generated-table layer, the paper
text and the documentation were all changed in one pass; the "Real-data results" section below
records what the full `Rscript main.R` re-run produced and what the paper now says about it.

## Motivation

the 2026-09-22 seminar grade report (84/100; not committed -- the file at `docs/grade-reports/` is the later 86/100 report) reviewed `paper/paper.tex` and the pipeline and listed twelve
deductions (W1, W2, M1, M2, M3, R1, R2, R3, T1, T2, E1, C1). The substantive ones were
specification choices a referee would query: a linear-in-exposure DDD with no saturated
comparison (M1); a "gender placebo" that is not a placebo, because fathers are also treated by
remote work (M2); no sensitivity to the bin-median construction of the hours outcome (M3); forty
clusters with no small-cluster correction (R1); the youngest-child age variable unused for hours
even though it is the mechanism's most direct test (R2); no first stage for the occupation-level
score the headline is estimated on (R3). One table note was factually wrong (T1), Table 1 carried
no inference (T2), several claims were uncited (W2), the literature omitted the
continuous-treatment DiD work (E1), caveats were repeated across sections (W1), and the tables
were hand-typed with the crosswalk behind the exposure index undocumented (C1).

## Design

**Specification (M1).** Two new estimators beside the pooled DDD, on the same join and sample.
`scripts/hours_ddd_saturated.R` fits
`WorkHoursCont ~ Mother:Post:WFH_Exposure + controls | occ^ShnatSeker + occ^Mother + Mother^ShnatSeker`,
so occupation-by-year, occupation-by-mother and mother-by-year fixed effects absorb every
lower-order margin; `Mother:Post` is absorbed by `Mother^ShnatSeker` and is deliberately not in
the linear part (verified on a synthetic panel: fixest drops it if included).
`scripts/hours_ddd_binned.R` replaces the score with `i(WFH_Exposure_Q, ref = 1)` on the
pre-period quartile edges of Figure 2, so Table 2's bins ARE the figure's bins; the edges are
computed once by `scripts/occupation_exposure_breaks.R` (extracted from the two inline copies in
`hours_dose_response.R` and `absence_by_exposure_quartile.R`) and handed around by `main.R`.
Coefficients are read by name (`Mother:Post:WFH_Exposure_Q::4`), never by etable label. The
number of occupations per bin is exported and printed because occupation is the cluster.
`run_intensive_margin_reg()` gained `year_fe = TRUE` for a survey-year-effects DiD.

**Outcome coding (M3).** `run_hours_ddd_regression()` gained `outcome =` and `run_mechanism =`.
`main.R` re-estimates the DDD with the irregular-hours codes (11/12) dropped instead of imputed,
and as linear probability models on full-time (>= 35 usual hours) and long-hours (>= 40)
indicators. Both cut-offs are exact bin edges under the bin-median coding, so the indicators
are bin-crossing outcomes, which is what the paper says the small effect represents.

**Inference (R1, M2).** `robustness/hours_ddd_inference.R` holds two functions.
`run_hours_ddd_wild_bootstrap()` wraps `fwildclusterboot::boottest()` (Rademacher, null imposed,
B = 9,999, seeded with `dqrng::dqset.seed()` AND `set.seed()`, since `set.seed()` alone does not
fix the draws) for the headline triple interaction, for each pre-period coefficient of the DDD
event study and for their sum. `run_hours_ddd_permutation_test()` reassigns the forty exposure
scores across the forty occupation codes 999 times (Mother/Post structure and each woman's
occupation fixed), refits the clustered DDD and records the cluster-robust t; the p-value counts
the observed statistic among the draws (Phipson and Smyth 2010) so it can never be zero, and
the studentized statistic is used because reassigning exposure across occupations of very
different sizes makes the raw coefficient non-pivotal. This is the paper's falsification test;
the fathers' comparison is relabelled as a comparison population.

**Child-age heterogeneity (R2).** `scripts/hours_ddd_by_child_age.R` fits the primary DiD and DDD
per youngest-child bin (0-4, 5-9, 10-14, 15-17 from `GilYeledTzairMBNK`), each bin's mothers
against ALL childless women (a bin's mothers alone would leave `Mother` constant). The forest
plot reuses `build_hours_subgroup_comparison()` unchanged.

**First stage and the score table (R3, C1 second half).** `scripts/wfh_occupation_first_stage.R`
computes each occupation's realized WFH share over 2021-23 on men and women pooled (the
calibration's own pooling), for both the reference-week item and the usual-place-of-work item
the calibration targets, and reports correlations and n-weighted slopes of realized WFH on the
calibrated and external scores. Its 40-row table, with ISCO-08 titles from
`data/isco08_2digit_labels.csv`, is the paper's Appendix Table A1; its scatter is Figure A1.

**Table 1 inference (T2).** `build_descriptive_table()` now attaches an IDPUF-clustered SE to every
difference (the Mother coefficient of `y ~ Mother`, or of an indicator regression per categorical
level) and an observation count for the hours rows.

**Generated tables (C1, T1).** Four one-function files: `tex_coef_cell()` formats one coefficient
from the fitted model with fixest's internal `format_number()` so the cell is character-identical
to `etable(digits = 4)`, with stars per the paper's legend as `\sym{}` macros (a testthat check
pins it against etable's string); `format_tex_table_body()` turns a cell matrix into a booktabs
tabular, with `\multicolumn{k}` cells consuming their neighbours; `build_paper_tables()`
assembles nine blocks from the fitted models and result frames and generates the
dropped-coefficient note sentences from each model's `$collin.var` (which is what fixes T1: the
old Table 2 note claimed a religion category was dropped in column (2); it is dropped only in the
Arab-women subsample); `export_paper_tables()` writes `paper/tables/<name>.tex` and
`auto_notes.tex`. `paper.tex` keeps its floats, captions and hand-written notes and `\input{}`s
the blocks.

**Paper text (W1, W2, E1, M2).** Citations added for the fertility claim (OECD Family Database
SF2.1) and the school-closure timeline (Somekh et al. 2021; Hale et al. 2021); the teaching claim
now carries dates. A Literature paragraph on continuous-treatment DiD (Callaway, Goodman-Bacon
and Sant'Anna 2024) states which assumption the dose-response reading needs and points to the
saturated and binned columns. The Empirical Strategy gained the saturated equation, the
inference paragraph and the permutation test; the "gender placebo" is a "fathers' comparison"
throughout. The three repeated caveats (pre-trend power, small clusters, post-period
calibration) are stated once in Results and cross-referenced from Limitations. The Discussion's
"recovered most of the penalty" now compares the implied change for a top-quartile mother
(about 1.4 hours) rather than the between-quartile difference.

## Real-data results

From the full `Rscript main.R` re-run of 2026-09-22 (about 25 minutes, of which 13 are the
999 permutation refits). Every pre-existing CSV except the two descriptive-table files (which
gained SE columns and an hours-N row) reproduced byte for byte, so nothing leaked into the
existing chain. Numbers and their files are itemised in `paper/notes/results_digest.md` §8.

- **Specification (M1).** Pooled 3.224 (SE 1.022) -> saturated **2.876 (0.9495)**, still p < 0.01
  analytically; quartile contrasts vs Q1: 0.75 (0.48), 0.60 (0.48), **Q4 1.844 (0.594)**. The
  linear lower-order terms were not producing the result, and the dose-response is a step at the
  top (six occupations) rather than a smooth gradient. Year-effects DiD 0.2310 (0.1808).
- **Outcome coding (M3).** No imputation 3.056 (1.059); full-time LPM 0.0964 (0.0291); long-hours
  LPM 0.1073 (0.0380). Per SD of exposure, 1.9 and 2.1 percentage points.
- **Inference (R1, M2).** This is the change that matters most for how the paper reads.
  Analytic p = 0.003; **permutation p = 0.032** (31 of 999 reassignments produce |t| >= 3.15);
  **wild-bootstrap p = 0.056**, bootstrap CI [-0.26, 5.84]. The three procedures put the headline
  at the 1%, 5% and 10% levels respectively. The paper now reports all three in Table 4, the
  Abstract, §4.4, §5.2, §5.4, the Discussion and Limitations, and no longer describes the estimate
  as "p < 0.01" without qualification. Pre-trend bootstrap p-values 0.84 / 0.88 / 0.85 leave the
  parallel-trends reading unchanged.
- **Child age (R2).** DDD 3.656 (1.079) for youngest child 0-4, 3.211 (1.311) for 5-9,
  2.741 (1.525) for 10-14, 1.862 (0.935) for 15-17: monotone in the direction the mechanism
  predicts, with overlapping intervals (shared control group, so no cross-row z-test). DiD null in
  every bin.
- **First stage (R3).** 2021-23, men and women pooled, forty occupations. Calibrated score:
  corr 0.529 / n-weighted slope 0.400 (SE 0.087, R2 0.249) against the reference-week share, and
  corr 0.481 / slope 0.255 (SE 0.054, R2 0.285) against the usual-place share the calibration
  targets. Raw external index: corr 0.739 / slope 0.374 (0.097, R2 0.585) and corr 0.588 / slope
  0.205 (0.062, R2 0.502). **The external index fits realized WFH better than the calibrated one
  on both measures.** Cause: the threshold swap puts ten occupations on a realized-share scale and
  leaves thirty on a task-probability scale, so unswapped occupations with gaps just under 0.5
  (e.g. ISCO 21, 26, 35) now rank above swapped ones whose realized share is higher (ISCO 25).
  The paper says this plainly in §3.2 and Limitations, and frames the calibration's contribution
  as removing the ten grossly mis-scored occupations from the treated tail (which the
  unswapped-occupations check isolates), not as a better cross-sectional fit. **Open question for
  the authors:** whether the fully realized index (single scale; DDD 5.195, SE 2.363) should
  become primary. Not decided here.
- **Fathers (M2).** Unchanged numbers (-1.762, SE 1.015, p < 0.1), now read as a comparison
  population consistent with within-household reallocation rather than as a placebo.
- **Tables (C1, T1).** Nine generated blocks; the auto-notes confirm no column of Tables 2 or 7
  drops a coefficient and that only the Arab-women rows drop the `other` religion category.
- **Length (W1).** Prose before the Conclusion, tables excluded: 10,532 words before, 13,354
  after. The repeated caveats were cut to single statements with cross-references (Limitations'
  "Parallel trends", "Inference" and "Exposure is partly post-treatment" paragraphs; the §5.4
  exposure paragraph), but the six new blocks the report asked for (two specification columns,
  outcome coding, inference, falsification, child-age heterogeneity, first stage) add about
  3,000 words, so the paper is longer, not shorter. A further concision pass on Results (4,901
  words) is the obvious next editorial step and was not attempted here.

## Verification

- `Rscript run_tests.R`: **1,284 passing, 0 failing** (951 before this change). Ten new test
  files plus additions to three existing ones; `test-tex_coef_cell.R` pins the generated cells
  against `etable()`'s strings, `test-build_paper_tables.R` builds every table from a synthetic
  input set and checks column counts and the exporter round-trip.
- `Rscript main.R`: exit 0, about 25 minutes. Every pre-existing CSV and PNG byte-identical
  except `descriptive_table_{continuous,categorical}.csv` (new SE columns, one new row).
- `paper/paper.pdf`: recompiled with the manual four-pass sequence (42 pages); no errors, no
  undefined references or citations, no BibTeX warnings, one 1.4pt overfull line in Table 4.
  Tables 1, 2 and 5 are set at `\footnotesize`/`\scriptsize` with 3-4pt column padding to fit
  the text width; Appendix Table A1 at `\scriptsize`.

## Considered and rejected

- **A joint wild bootstrap of the two pre-trend coefficients.** `fwildclusterboot::mboottest()`
  runs only through Julia (WildBootTests.jl), which this project does not use. The joint test
  stays the analytic Wald F; the bootstrap is reported per coefficient and for their sum.
- **A wild bootstrap for the saturated column.** `boottest()` refuses fixest's `^` fixed-effect
  syntax; the column reports analytic SEs, and the pooled column carries the bootstrap.
- **A pre-period timing placebo (fake Post inside 2017-2019).** Every such contrast is a linear
  combination of the two event-study coefficients the joint Wald test already tests, so it can
  never reject where that test does not. Dropped as redundant; the permutation test is the
  non-redundant falsification.
- **A CR2 small-sample correction via `clubSandwich`.** A second new dependency for a correction
  the bootstrap already dominates.
- **Parsing the etable CSV strings to build the LaTeX tables.** Labels drift with `dict` and
  `i()`, and the p < 0.1 marker is a bare dot glued to the number; generating from the models by
  coefficient name is the robust route.
- **Binning the DDD on occupation counts (ten per bin) rather than the row-level pre-period
  quantiles.** Would have decoupled Table 2's bins from Figure 2's; instead the occupation count
  per bin is reported.

## Deferred

- **Crosswalk provenance (grade item C1, first half).** The derivation of
  `data/israeli_cbs_wfh_2digit.csv` remains an open question
  (`docs/decisions/wfh-crosswalk-provenance.md`). Deliberately left to a separate, later plan
  at the authors' request; this change adds the appendix table of the forty scores and states the
  gap in the paper's Data section and Limitations.

## Grade-report items, closed by

| Item | Closed by |
|---|---|
| W1 | Limitations paragraphs cut to cross-references; long sentences split |
| W2 | `oecd2025fertility`, `somekh2021`, `hale2021` cited; teaching claim dated |
| M1 | Table 2 columns (3)-(4); eq. (ddd-sat); year-effects DiD row in the text |
| M2 | Permutation test (§4.6, §5.5, Table 4); fathers' comparison relabelled |
| M3 | Table 4 outcome-coding block |
| R1 | Wild bootstrap rows (Table 4; Figure 4 notes) |
| R2 | §5.6 child-age table and figure |
| R3 | First-stage statistics in §3.2; Appendix Figure A1 |
| T1 | Generated notes from `$collin.var` |
| T2 | Table 1 SEs and N; Table 3 split into panels |
| E1 | Literature paragraph on continuous-treatment DiD |
| C1 | Generated tables; Appendix Table A1; crosswalk rebuild deferred |
