# Implementation Roadmap

Sequential, actionable checkpoints from the current codebase to the full empirical strategy in [`motherhood_penalty_wfh_research.md`](./motherhood_penalty_wfh_research.md), built on the gap analysis and proposed signatures in [`docs/LLD.md`](LLD.md). Each checkpoint is meant to be implemented and verified independently, in order — later checkpoints depend on earlier ones being done first (dependencies noted per checkpoint).

Checkpoints 1-10 predate a later pivot: weekly work hours (the intensive margin) is now the project's **primary** dependent variable, and the binary employment indicator used as `Y_{it}` throughout Checkpoints 4/5/7 below is now the **secondary** specification. See Checkpoint 11 and [`docs/decisions/hours-ddd-pivot.md`](decisions/hours-ddd-pivot.md) for the pivot itself; the checkpoint write-ups below are left as historically accurate records of what was originally built; and are cross-referenced forward where relevant.

Not covered here: general test-suite construction (unit/integration tests for the *existing* functions) — the live `tests/testthat/` suite (run via `Rscript run_tests.R`) is the source of truth for that.

> **This document is a historical record, not a work queue.** All 15 checkpoints are implemented; there is no pending roadmap item (`docs/LLD.md` says the same). Each checkpoint below carries a `**Status:**` line, and the write-ups are preserved as accurate records of what was built and why, including options that were considered and rejected. Numbers quoted inside a checkpoint are as-of that checkpoint — where a later change superseded one, the superseding value is noted inline. New work should get its own checkpoint entry or a decision memo in [`docs/decisions/`](decisions/) rather than editing history here.

---

## Checkpoint 1 — Data Validation & Quality Guard Layer

**Status:** Implemented — `scripts/validation.R`'s `validate_cleaned_df()`, called from `main.R` §3.

**Objective:** Add an explicit guard function that enforces `docs/LLD.md`'s hard-fail and soft-fail thresholds, so every later checkpoint builds on data that's been verified, not assumed, correct.

**Implementation Tasks:**
- New file `validation.R`, function `validate_cleaned_df(cleaned_df)`.
- Hard-fail checks (call `stop()`): `all(cleaned_df$Min == 2)`; `all(as.integer(as.character(cleaned_df$GilNK)) %in% 3:7)`; `all(cleaned_df$ShnatSeker %in% c(2017,2018,2019,2021,2022,2023))`; `sum(is.na(cleaned_df$Employed)) == 0` (same for `Mother`, `Post`); `nrow(cleaned_df) > 0`.
- Soft-fail checks (call `warning()`/`message()`, don't stop): any regression control (`MatzavMishpachti`, `Dat`, `GilNK`, `MachozMegurim`, `TeudaGvoha`) with NA rate `> 5%`; any comparative-stats-only variable with NA rate `> 70%`.
- Wire `validate_cleaned_df(cleaned_df)` into `main.R` immediately after the `load_and_clean_data()` / cache-load step, before any analysis function runs.

**Verification Step:**
```r
Rscript main.R
```
Confirm it completes with no `stop()` triggered and no unexpected warnings. Then negative-test it: `df_bad <- cleaned_df; df_bad$Min[1] <- 1; validate_cleaned_df(df_bad)` in an interactive session must `stop()` with a clear message.

---

## Checkpoint 2 — Schema-Drift Check

**Status:** Implemented — `scripts/validation.R`'s `check_schema_drift()`, called from `main.R` §3 before a non-cached load.

**Objective:** Guard the fragile positional column-drop ranges in `data_processing.R` against a future CBS file-format change silently dropping or keeping the wrong columns.

**Implementation Tasks:**
- Add `check_schema_drift(folder_path)` to `validation.R`.
- For each yearly CSV in `folder_path`, read only the header row and assert the named boundary columns of all 7 positional drop ranges (`RamatDat`/`BituachLeumi`, `Yeladim0_1Prat`/`Yeladim15_17Prat`, `MisparHachlafa`/`YachasKirvaNK`, `MisparNefashotGilAvodaV2007`/`MisparPrat`, `ChipusAvodaSherutTaasuka`/`ChipusAvodaOfenAcher`, `EizeChozemechushav`/`ChodeshKodemShaa`, `MimaHaMigbala`/`PniyaLmaasik`) occupy the same relative column position across every year's file.
  - *Since superseded:* only **5** positional ranges remain. `EizeChozemechushav`/`ChodeshKodemShaa` and `MimaHaMigbala`/`PniyaLmaasik` were converted to name-based `any_of()` drops (`scripts/data_processing.R:258-272`); `docs/LLD.md` records the current set.
- Call `check_schema_drift(folder_path)` in `main.R` before `load_and_clean_data()` runs.

**Verification Step:**
```r
Rscript main.R
```
Confirm it passes silently against the current 6 CSVs. Then negative-test: copy one CSV, swap two column positions in the header with a text editor, point `check_schema_drift()` at the copy, and confirm it throws a clear "column order changed" error rather than passing silently.

---

## Checkpoint 3 — Shared `controls` Constant

**Status:** Implemented — `DEFAULT_CONTROLS` in `scripts/data_processing.R`, now the single source of truth repo-wide (`tests/testthat/test-controls-consistency.R` guards it).

**Objective:** Eliminate the 3-way copy-pasted `controls` vector before Checkpoint 4 onward adds regression functions that would otherwise duplicate it a 4th and 5th time.

**Implementation Tasks:**
- Define `DEFAULT_CONTROLS <- c("MatzavMishpachti", "Dat", "GilNK", "MachozMegurim", "TeudaGvoha")` once, at the top of `data_processing.R` (already sourced by every other file).
- Replace the local `controls <- c(...)` block in `basic_regression.R`, `basic_reg_compared_data.R`, and `employment_by_child_age.R` with a reference to `DEFAULT_CONTROLS`.
- Replace the inline control list in `Diagnostics.R`'s `feols()` formula the same way.

**Verification Step:**
```r
Rscript main.R
```
Diff the printed `etable()` coefficients/SEs for `basic_reg()` against a saved copy of the pre-change output — they must be byte-identical (this is a pure refactor, not a logic change).

---

## Checkpoint 4 — Intensive-Margin Regression

**Status:** Implemented — `scripts/intensive_margin_regression.R`'s `run_intensive_margin_reg()`. Since **designated primary** by Checkpoint 11.

**Objective:** Implement the weekly-work-hours regression required by the research doc's core DiD specification (Part 2 §1 / Part 4 §2), alongside the employment-margin regression already in place. (Note: this hours regression has since become the project's *primary* specification, per Checkpoint 11 — at the time this checkpoint was written, it was the newly-added second regression.)

**Implementation Tasks:**
- New file `intensive_margin_regression.R`, function `run_intensive_margin_reg(cleaned_df, controls = DEFAULT_CONTROLS)` per the signature in `docs/LLD.md`.
- Formula: `WorkHoursCont ~ Mother + Post + Mother:Post + <controls>`, `data = filter(cleaned_df, Employed == 1)`, `cluster = ~IDPUF` (hours are only meaningful conditional on employment).
- Wire a call into `main.R` alongside the existing `basic_reg()` call.

**Verification Step:**
```r
Rscript main.R
```
Confirm the new regression prints without error. Check `nobs(model)` equals `sum(cleaned_df$Employed == 1 & !is.na(cleaned_df$WorkHoursCont))` (accounting for any additional listwise deletion on the controls). Sanity-check the `Mother:Post` coefficient is within a plausible range (single-digit to low-double-digit hours, not e.g. >40 or highly implausible in sign given the extensive-margin result from Checkpoint 3's baseline). (This hours regression's DDD generalization later became the project's primary specification — see Checkpoint 11.)

---

## Checkpoint 5 — Gender Placebo Test

**Objective:** Implement the fathers-vs-childless-men replication (Part 2 §3 / Part 4 §5) that tests whether the observed effect is specifically a *motherhood* penalty rather than a general parenthood or macro shift.

**Implementation Tasks:**
- Modify `load_and_clean_data()`'s signature to `load_and_clean_data(folder_path, sex_filter = c("women", "men"))`, defaulting to `"women"` (preserves `Min==2` for every existing caller); `"men"` selects `Min==1`.
- New file `gender_placebo.R`, function `run_gender_placebo(folder_path)` that calls `load_and_clean_data(folder_path, sex_filter = "men")`, runs `validate_cleaned_df()` (Checkpoint 1) against the male subsample, then calls `basic_reg()` on it.
- Before trusting the output, re-check each control's category sizes within the male subsample (a category that's sparse for women may be near-empty for men, e.g. `MisparHorimYechidim` single-father counts) — extend Checkpoint 1's soft-fail check or note any category needing collapse.

**Verification Step:**
```r
Rscript -e 'source("main.R"); run_gender_placebo("G:/My Drive/Uni/econ/csv_data")'
```
Confirm the model fits without a `fixest` collinearity/singularity error. Per the research doc's own success criterion, an **insignificant** `Mother:Post` coefficient (relabelled conceptually as the father-treatment interaction) supports the motherhood-specific interpretation — record the coefficient and p-value alongside the primary model's for direct comparison.

Note: this placebo is built on `basic_reg()` (the now-secondary, employment-outcome regression). **Update 2026-09-19: an hours-based placebo does now exist** — `scripts/hours_gender_placebo.R`, called unconditionally from `main.R` and exported as `hours_gender_placebo_{did,ddd}_table.csv`; it is the placebo the paper reports. The employment placebo above remains manual and unexported.

---

## Checkpoint 6 — WFH-Exposure Index

**Status:** Implemented — `scripts/wfh_exposure_index.R`'s `build_wfh_exposure_index()`, anchored to 2021 per `docs/decisions/checkpoint6-wfh-anchor-year.md`.

**Objective:** Build the occupation-level remote-work-exposure measure needed for the Triple-Differences mechanism test (Part 2 §2 / Part 4 §4).

**Implementation Tasks:**
- **Decision required first** (not code): the research doc anchors WFH exposure to the *2020* WFH variable, but 2020 is excluded from this project's sample entirely. Resolve by either (a) pulling a separate 2020-only CBS extract for this index alone, or (b) formally documenting a deviation to use 2021 as the exposure-anchor year. Record the decision in `motherhood_penalty_wfh_research.md` or a short addendum before writing code.
- New file `wfh_exposure_index.R`, function `build_wfh_exposure_index(cleaned_df, isco_col = "MishlachYad_ISCO_08_2", wfh_col = "WFH", ref_year)` per the `docs/LLD.md` signature, returning one row per occupation code with its WFH share in `ref_year`.
- Cross-reference resulting exposure values against the literature anchors the research doc names (Bloom; Cohen & Manor 2024) as a plausibility check, not an automated test.

**Verification Step:**
```r
idx <- build_wfh_exposure_index(cleaned_df, ref_year = 2021)
```
Inspect `idx` manually: confirm no `NA` exposure values silently propagate for occupation codes with nonzero observations, and confirm the ordering is directionally sane (e.g., tech-coded ISCO groups show materially higher exposure than cleaning/service-coded groups, matching the research doc's own worked example in Part 4 §4).

---

## Checkpoint 7 — DDD Mechanism Regression

**Objective:** Test whether the narrowing of the motherhood penalty is actually driven by an occupation's WFH exposure, closing out Part 2 §2's mechanism test.

**Implementation Tasks:**
- New file `ddd_regression.R`, function `run_ddd_regression(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS)` per the `docs/LLD.md` signature.
- Model 1 (triple interaction): `Employed ~ Mother*Post*WFH_Exposure + controls`, joined to `exposure_index` by occupation code. (This `Employed`-outcome DDD is now the **secondary** DDD specification — superseded in primacy by the hours-outcome DDD added in Checkpoint 11; see `docs/decisions/hours-ddd-pivot.md`.)
- Model 2 (second-stage mechanism): extract per-occupation `Mother:Post` estimates (β_j) from occupation-stratified runs of `basic_reg()`, then regress `β_j ~ γ_0 + γ_1·WFH_Exposure_j`.
- Depends on Checkpoint 6's `exposure_index`.

**Verification Step:**
```r
ddd <- run_ddd_regression(cleaned_df, idx)
```
Confirm both models fit without collinearity errors. Check `γ_1`'s sign matches the mechanism hypothesis (positive: higher WFH exposure associated with a larger reduction in the penalty). Cross-check the per-occupation β_j estimates feeding Model 2 are consistent in sign/magnitude with Model 1's triple-interaction coefficient.

**Update (2026-09-12): `ddd_regression.R` and this Model 1/Model 2 implementation were removed** as part of deprecating the secondary DDD's occupation-level robustness variants — see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`). This checkpoint's write-up above is left as a historically accurate record of what was originally built; the secondary DDD itself (`main.R` §8b) is unaffected.

---

## Checkpoint 8 — Age/Age² Escalation

**Objective:** Resolve the confirmed data-availability gap (no continuous age or birth-year variable exists anywhere in the current raw CBS extract) blocking Part 4 §2's stated control set.

**Implementation Tasks:** None (not a coding task). Either:
- (a) Request a wider CBS data extract that includes continuous age or birth year, then re-run Checkpoints 1–2 against the new extract before using it, **or**
- (b) Formally amend `motherhood_penalty_wfh_research.md` Part 4 §2 to specify the categorical `GilNK` age-group control already in use everywhere (which is what Part 3 §3's advisor feedback called for in the first place) instead of continuous age.

**Verification Step:** Not a test — this checkpoint's "done" state is a recorded decision. Confirm completion by checking `motherhood_penalty_wfh_research.md`'s Part 4 §2 control list matches whatever was actually decided (either a new column appears in `docs/LLD.md`'s Data Schema after a re-run of the schema dump, or the doc text is edited to drop continuous age).

---

## Checkpoint 9 — Persisted Output/Export Layer

**Status:** Implemented — `scripts/export_results.R`'s `export_all_results()`, called from `main.R` §9.

**Objective:** Give the pipeline a durable output artifact so the research doc's "drafting findings" step (Part 1 §VI) has something to work from besides console scrollback.

**Implementation Tasks:**
- New file `export_results.R`, function `export_all_results(results_list, output_dir = "outputs")` that writes each `etable()`/summary tibble to CSV and each `ggplot` object to PNG.
- New dependency: pick one of `gt`/`officer`/`rmarkdown` if a formatted (not just CSV) table export is wanted — explicitly optional/deferred per `docs/LLD.md`; CSV + PNG alone need no new dependency.
- Wire a final `export_all_results()` call at the end of `main.R`, collecting the `invisible(list(...))` returns already produced by every existing function.

**Verification Step:**
```r
Rscript main.R
ls outputs/
```
Confirm `outputs/` contains one file per regression table (e.g. `basic_reg_table.csv`) and one PNG per plot (e.g. `child_age_plot.png`), and that opening one CSV/PNG matches what was printed to the console during the same run.

---

## Checkpoint 10 — Full-Pipeline Rollup Verification

**Objective:** Confirm the fully extended pipeline (Checkpoints 1–9) runs end-to-end and every requirement in the research doc's empirical strategy is now either implemented or explicitly, deliberately deferred.

**Implementation Tasks:** None new — this is an integration checkpoint, not a build step.

**Verification Step:**
```r
Rscript main.R
```
Must exit with status 0, no hard-fail validation errors, and produce the full set of `outputs/` artifacts from Checkpoint 9. Then manually tick every row of `docs/LLD.md`'s "HLD Gap Analysis" table against what now runs — every row should resolve to either "implemented" (Checkpoints 3–7) or "explicitly deferred with a recorded reason" (Checkpoint 8's age/age² decision, Checkpoint 9's optional formatted-report dependency).

---

## Checkpoint 11 — Hours-Worked DDD Pivot (Intensive Margin Becomes Primary)

**Objective:** Pivot the project's primary dependent variable from the extensive margin (`Employed`) to the intensive margin (`WorkHoursCont`, weekly work hours), generalizing Checkpoint 7's DDD mechanism regression and Checkpoint 4's intensive-margin regression to a single hours-outcome triple-interaction model with pure occupation-level WFH exposure and a generalized Lee-bounds selection correction.

**Status:** Implemented (`scripts/hours_ddd_regression.R`, `scripts/hours_ddd_lee_bounds.R`, `scripts/imbens_manski_ci.R`), wired into `main.R` §8a, unconditional (no feature flag). **Designated primary** by decision recorded 2026-09-12. Run three times — once each for the calibrated/external/realized occupation-level exposure measures, mirroring the pattern Checkpoint 7's now-removed occupation-level robustness variants used (see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`)).

Full motivation, design, and real-data results are recorded in [`docs/decisions/hours-ddd-pivot.md`](decisions/hours-ddd-pivot.md) — not duplicated here. In brief: the Checkpoint 7 `Employed`-outcome DDD remained underpowered (MDE ~4x the point estimate) even after Checkpoint 6/7's exposure-measure refinements; the hours-outcome DDD unlocks a more precise occupation-level exposure regressor (unavailable to the employment-outcome DDD because occupation is undefined for the non-employed) and yields a statistically significant, Lee-bounds-robust result well outside its own MDE.

**Verification Step:** See `docs/decisions/hours-ddd-pivot.md`'s "Real-data results" section for the confirmed point estimate, MDE, and Lee-bounds/Imbens-Manski CI values.

---

## Checkpoint 12 — Paper Figure Layer (Descriptive Statistics Section)

**Objective:** Give the paper a standalone Descriptive Statistics section with figures, and give the pipeline a vector-PDF export path, a shared plot theme, and descriptive builders for the primary (hours) margin — which had none.

**Status:** Implemented. New: `scripts/paper_theme.R`, `scripts/export_paper_figures.R`, `scripts/hours_descriptive_plots.R`, `scripts/hours_dose_response.R`, `scripts/build_mechanism_scatter.R`. Wired into `main.R` §8e (unconditional, no feature flag) plus a second export call after §9. `paper/paper.tex` gains §4 "Descriptive Statistics" with six figures; §4–§8 renumbered to §5–§9 and Table 1 moved from §3.1 into §4.1.

Full motivation, the plot triage, and the design rationale are recorded in [`docs/decisions/paper-figure-layer.md`](decisions/paper-figure-layer.md) — not duplicated here. In brief: after Checkpoint 11 made hours the primary outcome, four of the repo's six plots still described the secondary margin and none described the primary one, so the paper asserted its headline result numerically without ever showing it.

Two notes that matter for anyone extending this:

- **`export_all_results()` is unchanged.** Paper figures are written twice on purpose — an 8x5in 150dpi PNG for browsing `outputs/`, and a vector PDF at ~5in for the paper. Keys in `main.R`'s `paper_figures` list are filenames that `paper.tex` hard-codes, so renaming one breaks the LaTeX build.
- **The mechanism scatter is built and its data exported, but the figure is deliberately not in the paper** — `paper/notes/results_digest.md` §1.5's 2026-09-15 out-of-scope decision stands. Exporting `hours_ddd$mechanism_data` closes the separate open item at §7 item 1; refitting from `outputs/hours_mechanism_data.csv` reproduces slope 2.1977 (SE 0.9068, p 0.0207), n = 37.

**Verification Step:**
```r
Rscript run_tests.R   # 732 passing
Rscript main.R        # writes outputs/figures/*.pdf + outputs/hours_mechanism_data.csv
```
Then, from inside `paper/`: `pdflatex`, `bibtex`, `pdflatex`, `pdflatex`. Check `paper/paper.log` for `File ... not found` and undefined citations/references directly rather than trusting the hook's summary line — the figures must exist before the `.tex` edit compiles.

---

## Checkpoint 13 — Hours Population Harmonization (the 2017 Zero-Hours Defect)

**Objective:** Remove a year-specific inconsistency in how `WorkHoursCont` was defined, and re-establish the intensive-margin results on a hours population that is identical across all six survey years.

**Status:** Implemented. `WorkHoursCont` is now defined only for rows that are both `Employed == 1` and `AvadBeshavua == 1` (worked the reference week). Touches `scripts/data_processing.R`, both Lee-bounds scripts, `scripts/hours_diagnostics.R`, `scripts/validation.R` (new soft-fail check) and the test fixtures.

Full diagnosis, rejected alternatives, and the complete before/after table are in [`docs/decisions/hours-population-harmonization.md`](decisions/hours-population-harmonization.md) — not duplicated here. In brief: the 2017 CBS file recorded usual hours as bin 0 ("no usual hours") for the employed-but-absent, who from 2018 on received a real code. Because absenteeism is mother-skewed (12.4% vs 7.3%), that produced a spurious `Mother x year` effect in the pre-period — and it was the sole source of the paper's headline parallel-trends violation.

**The result that matters:** the hours pre-trend Wald test now **passes** (F = 23.69, p = 5.2e-11 -> F = 0.95, p = 0.387), and the 2017 event-study coefficient goes from -1.524*** to an insignificant +0.3515. The headline hours DDD survives at 3.2240 (SE 1.0223); the secondary hours DiD does not, falling from 0.8261*** to 0.2280 (SE 0.1809). Dropping 2017 entirely afterwards moves the DDD by 0.15 SE and the DiD by 0.44 SE, so 2017 is genuinely rehabilitated rather than merely less contaminated.

Two notes for anyone extending this:

- **The Lee-bounds change was required, not incidental.** Both bounds scripts `arrange()` by `WorkHoursCont` and dplyr sorts NA last; harmonization puts ~12% NA into the `Mother==1,Post==1` cell, which would have made the lower bound trim unobserved rows on an inflated denominator. Latent before, live after.
- **Establish a no-op baseline before re-running.** `Rscript main.R` on an unchanged tree shows all 8 PDFs as modified (both base-`pdf()` devices *and* all six `cairo_pdf` figures are nondeterministic) while every CSV and PNG is byte-stable. Without that baseline the PDF churn is indistinguishable from signal.

**Verification Step:**
```r
Rscript run_tests.R   # 740 passing
Rscript main.R        # exit 0; 31 CSVs + 6 PNGs change, all in the hours chain
```
Every control artifact must stay byte-identical — the four `wfh_exposure_*.csv`, both Lee-bounds selection-rate files, and the entire employment margin. Any of those moving means the change leaked outside `WorkHoursCont`.

**Downstream (completed since):** `paper/paper.tex`, `paper/notes/results_digest.md` and `paper/paper.pdf` were subsequently brought in line with the post-fix `outputs/` (commits `cc759d4`, `605e56e`, `b53846f`, `bdad127`). The 2017 anomaly paragraph, the 2018-2019 restriction on the identifying assumption, and the old §4.3 were rewritten or removed rather than merely renumbered.

---

## Checkpoint 14 — Grade-Report Response (specification, inference, heterogeneity, generated tables)

**Objective:** Close the twelve deductions in the 2026-09-22 seminar grade report (84/100; not kept in the repo -- the later 86/100 report of 2026-09-23 is answered by Checkpoint 15) that could be closed inside the pipeline and the paper, without touching the Conclusion (work in progress) and without rebuilding the exposure crosswalk (deferred to its own plan).

**Status:** Implemented 2026-09-22. New files: `scripts/occupation_exposure_breaks.R`, `scripts/hours_ddd_saturated.R`, `scripts/hours_ddd_binned.R`, `scripts/hours_ddd_by_child_age.R`, `scripts/wfh_occupation_first_stage.R`, `scripts/build_permutation_plot.R`, `scripts/tex_coef_cell.R`, `scripts/format_tex_table_body.R`, `scripts/build_paper_tables.R`, `scripts/export_paper_tables.R`, `robustness/hours_ddd_inference.R`, `data/isco08_2digit_labels.csv`, `paper/tables/*.tex` (generated). Changed: `main.R` (§8a additions, new §8f inference block, §8g table assembly), `scripts/hours_ddd_regression.R` (`outcome`, `run_mechanism`), `scripts/intensive_margin_regression.R` (`year_fe`), `scripts/descriptive_table.R` (clustered SEs on every difference), `scripts/hours_dose_response.R` and `scripts/absence_by_exposure_quartile.R` (shared breaks helper), the test helper and eleven test files, `CLAUDE.md`, `README.md`, `paper/paper.tex`, `paper/references.bib`.

Full design, rejected alternatives and the item-by-item closure table were recorded in `docs/decisions/grade-report-response.md`, deleted 2026-09-24 (`git show c800efe^:docs/decisions/grade-report-response.md`); the `main.R` and `scripts/` comments that cite it by item ID (C1, M1–M3, R1–R3) refer to that memo. In brief: the hours DDD is now reported three ways (pooled, fully saturated with occupation×year, occupation×mother and mother×year fixed effects, and quartile-binned on Figure 2's bins); the forty-cluster problem is met with a wild cluster bootstrap (`fwildclusterboot`, the one dependency added beyond tidyverse + fixest) and a permutation test that reassigns the forty exposure scores across occupations, which is also the paper's falsification test; the hours DiD/DDD are split by the youngest child's age; the occupation-level score gets a first stage; and every paper table is generated from the fitted models into `paper/tables/` and `\input{}` by `paper.tex`.

**The result that matters:** the headline triple interaction (3.224, SE 1.022) is 2.876 (SE 0.9495) under the saturated specification and 1.844 (SE 0.594) as a top-vs-bottom-quartile contrast; its analytic p is 0.003, the permutation p is 0.032 and the wild-bootstrap p is 0.056, and the paper now reports all three rather than one. The child-age gradient is monotone: 3.656 (0-4), 3.211 (5-9), 2.741 (10-14), 1.862 (15-17). The stale Table 2 note (a religion category "dropped for collinearity" that was not dropped) is gone because the notes are now generated from `$collin.var`.

Two notes for anyone extending this:

- **`paper/tables/*.tex` are build products.** Change `scripts/build_paper_tables.R`, never the fragments. (Until Checkpoint 15, `tex_coef_cell()` mirrored `etable(digits = 4)`; it now prints fixed decimals, see Checkpoint 15.)
- **Seeds.** `INFERENCE_SEED` in `main.R` §8f seeds both `dqrng::dqset.seed()` (which the bootstrap actually draws from) and `set.seed()` (the permutation test). `set.seed()` alone does not reproduce `boottest()`.

**Verification Step:**
```r
Rscript run_tests.R   # 1,284 passing (was 951 before this checkpoint)
Rscript main.R        # exit 0; ~25 min (999 permutation refits); writes outputs/ and paper/tables/
```
Every pre-existing CSV except `descriptive_table_{continuous,categorical}.csv` (which gained SE columns and an hours-N row) must stay byte-identical.

## Checkpoint 15 — Grade-Report-2 Response (exposure calibration tests, sorting, leave-one-out, balance, fixed-decimal tables)

**Objective:** Close the fourteen deductions in the 2026-09-23 seminar grade report (86/100; removed from the repo 2026-09-24, git history keeps it) inside the pipeline and the paper, without touching the Conclusion.

**Status:** Implemented 2026-09-23. New files: `scripts/hours_ddd_swap_control.R`, `scripts/exposure_sorting_check.R`, `scripts/hours_ddd_cell_exposure.R`, `scripts/hours_ddd_leave_one_out.R`, `scripts/build_leave_one_out_plot.R`, `scripts/build_balance_by_exposure_quartile.R`, six matching test files, `paper/tables/tab_balance_quartile.tex` (generated), `outputs/figures/hours_ddd_leave_one_out.pdf`. Changed: `main.R` (grade-report-2 block after the outcome-coding checks; men-only calibration; t-based MDE; table, export and figure lists), `scripts/tex_coef_cell.R` (fixed decimals), `scripts/build_paper_tables.R` (three decimals, R² to three, Clusters column, new Table 4 rows and blocks, Table A2), `scripts/ddd_mde_diagnostics.R` (`df`), `scripts/hours_ddd_regression.R` / `hours_ddd_saturated.R` / `hours_ddd_binned.R` / `robustness/age_balance_robustness.R` (return `n_clusters`), `scripts/hours_descriptive_plots.R` (Figure 1 axis floor), the test helper and three test files, `README.md`, `paper/paper.tex`, `paper/references.bib`.

Design, the per-deduction closure table and the real-data numbers were recorded in `docs/decisions/grade-report-2-response.md`, deleted 2026-09-24 (`git show c800efe^:docs/decisions/grade-report-2-response.md`); the `main.R` and `scripts/` comments that cite it by section (Methods 1–2, Robustness 1–2, the MDE and table-formatting notes) refer to that memo. In brief: the calibration is tested with the sample held fixed (men-only shares: 3.869; external score with swapped-occupation terms: 2.339 beside a negative swapped-group change); occupational sorting is diagnosed (a DiD on the exposure score itself is a zero) and bounded (pre-period cell exposure: 0.139 per SD, imprecise); forty leave-one-out refits span 2.415–3.580 with none outside one headline SE; a balance table by exposure quartile replaces the prose numbers; every hours table prints three fixed decimals and Table 4 a cluster count; the MDE uses t(39).

A follow-up concision pass on `paper/paper.tex` (2026-09-23) cut the manuscript excluding the Conclusion from 10,359 to 9,565 words (prose 8,606 to 7,804) by removing repeated caveats and doubled numbers; no label, citation, float, footnote or number was removed, and the Conclusion skeleton is untouched. A structural second pass the same day split the appendix into `paper/appendix.tex` (data details, exposure construction, the selection correction, additional results), moved four floats there, merged the two event studies into one float, dropped the redundant child-age forest plot and rewrote the Literature Review, Data and Strategy sections; see `docs/decisions/paper-structural-cut.md`.

Two notes for anyone extending this:

- **`tex_coef_cell()` no longer mirrors `etable()`.** Cells are `formatC(x, digits, format = "f")`; `test-tex_coef_cell.R` pins that. Checkpoint 14's note about character-identity with `etable(digits = 4)` is superseded.
- **Cluster counts travel on the result objects.** Every DDD runner returns `n_clusters`; `build_paper_tables()` falls back to fixest's t degrees of freedom plus one for a bare model. If you add a Table 4 row, pass the count explicitly when the row's model is not one-way clustered on occupation.

**Verification Step:**
```r
Rscript run_tests.R   # 1,472 passing (was 1,284 before this checkpoint)
Rscript main.R        # exit 0; ~27 min; writes outputs/ and paper/tables/
```
Every pre-existing CSV except the three MDE files (which gained `df` and `multiplier` columns) must stay byte-identical.
