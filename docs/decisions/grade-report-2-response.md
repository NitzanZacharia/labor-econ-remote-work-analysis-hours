# Decision Memo: Response to the 2026-09-23 Grading Report

**Status: IMPLEMENTED (2026-09-23).** Pipeline code, tests, the generated-table layer, the paper
text and the documentation were changed in one pass; the "Real-data results" section below
records what the full `Rscript main.R` re-run produced and what the paper now says about it.

## Motivation

`docs/grade-reports/2026-09-23-seminar-grade-report.md` (86/100) lists fourteen deductions. Two are identification
concerns the previous response did not reach: the headline is not robust to the only fully
pre-treatment exposure index and the calibrated index was chosen as primary after the results
were known (Methods, 3 points); and occupation is measured contemporaneously, so post-2021
sorting of mothers into teleworkable occupations is an unaddressed channel (Methods, 2 points).
Two are missing robustness artefacts: no leave-one-occupation-out check although six occupations
drive the top-quartile result (1 point), and no covariate-balance table by exposure quartile
(1 point). Two are table and figure formatting (mixed significant-digit precision, five-decimal
R², no cluster count in Table 4, a truncated axis in Figure 1). The rest are manuscript:
length and repetition (2), a literature gap on remote work and hours (1), a sample-size
inconsistency between Section 4.3 and Table 2 (1), and a mis-scaled "four fifths of the penalty"
sentence plus unaddressed demand-side alternatives in the Discussion (1). The MDE's normal
multiplier was noted without deduction.

User decisions taken before implementation: fixed three-decimal tables with the prose re-rounded
to match; cut the manuscript to about 9,000 words; the Conclusion stays untouched.

## Design

**Exposure measure (Methods 1).** Two new estimates beside the unswapped-30 row, both on all forty
occupations so the sample no longer changes with the measure.

- *Men-only calibration.* `main.R` calls `calibrate_isco_exposure()` (unchanged) on
  `cleaned_men_for_exposure` alone, so no woman in the regression contributes to her own
  regressor, and runs the primary DDD on the resulting index. The number of occupations the
  men-only rule swaps is printed in the Table 4 row label.
- *Fixed-sample calibration test.* `scripts/hours_ddd_swap_control.R`,
  `run_hours_ddd_swap_control()`: the external Dingel–Neiman score as regressor, plus a `Swapped`
  indicator for the ten calibrated occupations entered with the full `Mother * Post *` structure.
  `Mother:Post:WFH_Exposure` is the external-score gradient with the swapped occupations' own
  post-2021 change in the motherhood gap absorbed; `Mother:Post:Swapped` is that change. Both
  are Table 4 rows.
- The paper states the selection rule for the primary index in Section 3.2 before any result.

**Occupational sorting (Methods 2).** Diagnosed and bounded.

- `scripts/exposure_sorting_check.R`, `run_exposure_sorting_check()`: a DiD with the
  occupation-level exposure score as the *outcome* on the hours DDD's estimation sample, a
  linear-probability version on Figure 2's top-quartile indicator, and the event-study form,
  all clustered by individual. Pre-period levels by group are returned so the DiD can be read
  against them.
- `scripts/hours_ddd_cell_exposure.R`, `run_hours_ddd_cell_exposure()`: the hours DDD with the
  pre-period demographic-cell exposure (`exposure_cells`, already built for the employment DDD)
  as regressor, clustered on the coarser demographic cell as that DDD is. A woman's post-2021
  occupation cannot move this regressor. Reported per SD of the cell index, since its scale is
  a third of the occupation score's.

**Leave-one-occupation-out (Robustness 1).** `scripts/hours_ddd_leave_one_out.R`,
`run_hours_ddd_leave_one_out()`: forty refits of `run_hours_ddd_regression()` with one occupation
removed each time; summary = range, and occupations whose removal moves the estimate by more than
one headline SE. `scripts/build_leave_one_out_plot.R` draws the influence plot (Appendix
Figure A1). Table 4 gains a range row.

**Balance by exposure quartile (Robustness 2).** `scripts/build_balance_by_exposure_quartile.R`,
`build_balance_by_exposure_quartile()`: pre-period, on the DDD's estimation sample, quartiles of
the occupation-level score (Figure 2's bins via `assign_wfh_quartile()`), mother-minus-childless
differences in the age code, married, academic, below-high-school, Jewish-household-head,
Center/Tel Aviv and Arab shares, each with an IDPUF-clustered SE from `clustered_se()`. Appendix
Table A2, built by `build_paper_tables()` as `tab_balance_quartile`.

**Tables and figures.** `tex_coef_cell()` now prints a fixed number of decimals (three; the
employment table passes four) instead of fixest's four significant digits; R² prints three
decimals; Table 4 has a Clusters column (counts carried on each result object as `n_clusters`,
or recovered as fixest's t degrees of freedom plus one); Figure 1's levels panel is pinned to at
least 36–42 hours by a blank layer. `compute_ddd_mde()` takes `df` and uses the t multiplier
when given; the hours MDE is now on t(39).

**Manuscript.** Numbers re-rounded to the tables; Section 4.3's sample count corrected and the
loss to missing controls explained; the "four fifths" sentence recomputed on the exposure-specific
penalty; a demand-side-alternatives paragraph in the Discussion; a WFH-and-hours paragraph in the
Literature Review with Crossref-verified entries; the three repeated caveats stated once; the
Abstract halved; total length cut toward 9,000 words. Conclusion untouched.

## Closure table

| Report item | Points | Closed by |
|---|---:|---|
| Methods 1: post-treatment exposure, ex-post choice of index | 3 | men-only calibration row; fixed-sample swap-control rows; rule stated in §3.2 |
| Methods 2: occupational sorting | 2 | exposure-as-outcome DiD; pre-period cell-exposure DDD; §5.3 paragraph |
| Methods note: MDE multiplier | 0 | `compute_ddd_mde(df =)` |
| Robustness 1: leave-one-out | 1 | `run_hours_ddd_leave_one_out()`, Table 4 row, Figure A1 |
| Robustness 2: balance by quartile | 1 | `build_balance_by_exposure_quartile()`, Table A2 |
| Tables/figures | 2 | fixed decimals, R² 3 dp, Clusters column, Figure 1 axis, hyperref anchors |
| Writing: length and repetition | 2 | manuscript cut (see results section for the count) |
| Writing: literature | 1 | WFH-and-hours paragraph |
| Writing: inconsistencies | 1 | §4.3 sample sentence; one panel denominator |
| Argument: four fifths; demand-side alternatives | 1 | Discussion recomputation and new paragraph |

## Real-data results

From the full `Rscript main.R` re-run of 2026-09-23 (about 27 minutes, of which 13 are the 999
permutation refits and 1.3 the forty leave-one-out refits). Every pre-existing CSV reproduced byte
for byte except `mde_hours.csv`, `null_vs_power_audit_mde_additive.csv` and
`null_vs_power_audit_mde_fe.csv`, which gained the `df` and `multiplier` columns; the hours MDE
moved from 2.864 (normal) to **2.938** (t(39)). New CSVs: `wfh_exposure_calibrated_men.csv`,
`ddd_hours_calibrated_men.csv`, `ddd_hours_swap_control_{table,coefs}.csv`,
`exposure_sorting_check_{table,pre_levels,event_study}.csv`, `ddd_hours_cell_exposure_{table,coefs}.csv`,
`hours_ddd_leave_one_out_{table,summary}.csv`, `balance_by_exposure_quartile.csv`; new figure
`outputs/figures/hours_ddd_leave_one_out.pdf`; new table `paper/tables/tab_balance_quartile.tex`.

- **Exposure measure (Methods 1).** Men-only calibration swaps 12 of 40 occupations (the pooled
  rule's ten plus ICT technicians and numerical clerks) and gives **3.869 (SE 0.979)**, larger
  than the headline. The fixed-sample test on all forty occupations gives an external-score
  gradient of **2.339 (SE 1.352, p = 0.09)** once the ten swapped occupations carry their own
  `Mother x Post` change, which is itself negative (**-1.347, SE 0.926**): the occupations the
  external index places in the treated tail did not respond, and allowing them not to restores
  two thirds of the headline gradient in the external score. The unswapped-30 row is unchanged
  at 4.309 (1.192). Paper: §3.2 states the selection rule before results; §5.4 *Exposure
  measure* reports the three checks.
- **Occupational sorting (Methods 2).** DiD on the exposure score itself: **0.0013 (SE 0.0035)**,
  0.7% of the score's pre-period SD; top-quartile indicator: 0.004 (SE 0.007); event study flat
  in every year (all |t| < 1.1). Pre-period cell-exposure DDD: 2.076 (SE 2.371) per unit,
  **0.139 (SE 0.159) per SD** of that index (SD 0.067), 245 clusters, against 0.640 per SD of
  the occupation score. Paper: new §5.3 paragraph "Sorting across occupations"; Table 4 block.
- **Leave-one-occupation-out (Robustness 1).** Range **2.415** (without science and engineering
  professionals) to **3.580** (without business and administration associate professionals);
  largest move 0.79 headline SEs; no refit leaves the ±1 SE band; every refit p ≤ 0.017.
- **Balance by quartile (Robustness 2).** On the pre-period estimation sample the age gap runs
  from -0.54 codes (Q1) to +0.08 (Q4); the academic-degree gap from +10.8 pp (Q1) to +1.8 (Q4);
  the marriage gap from +32 to +43 pp; the Jewish-household-head gap spikes at +14.3 pp in Q3.
  The paper's earlier prose figure of -0.97 for the Q1 age gap referred to the cell-index
  quartiles on the full sample and is replaced by the table.
- **Tables and figures.** All hours tables at three decimals, the employment table at four, R² at
  three; Table 4 carries a Clusters column (the realized-index row has 36 clusters, the
  no-2023 row 39, the unswapped row 30, which the old table did not reveal); Figure 1's levels
  panel spans 36–42 hours.
- **Manuscript.** Excluding the Conclusion, the paper went from about 12,900 words to 10,354, of
  which 8,601 are prose and 1,753 sit inside table and figure floats (captions and notes); the
  Abstract from about 330 words to 199; the PDF from 42 to 39 pages. The cut absorbed roughly
  900 words of new required material (the sorting paragraph, the balance and leave-one-out
  paragraphs, the demand-side paragraph and the WFH-and-hours literature paragraph).
  Section 4.3 now states that the regression sample is 251,857
  rows from 63,199 respondents and that the 6,318 rows lost from the descriptive count are the
  ones with a missing education code, the only control with missing values (confirmed on
  `cleaned_df.rds`). The Discussion's recovered-share sentence now uses the exposure-specific
  penalty (about -2.2 hours at top-quartile exposure), giving three fifths rather than four
  fifths, and a new paragraph lists the demand-side alternatives. Five Crossref-verified
  references added (`barrero2023`, `emanuelharrington2024`, `gibbs2023`, `pabilonia2022`,
  `budig2023`). A concision pass later the same day (2026-09-23) removed repetition only,
  taking the count to 9,565 words (7,804 prose, 1,761 in floats; abstract 190; 38 pages) with
  every label, citation, table, figure, footnote and number kept and the Conclusion untouched.
