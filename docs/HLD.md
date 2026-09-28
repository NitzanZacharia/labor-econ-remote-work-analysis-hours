# High-Level Design: Motherhood Penalty / WFH Analysis Pipeline

## 1. Purpose & Scope

This document describes the system that implements the research design in [`motherhood_penalty_wfh_research.md`](./motherhood_penalty_wfh_research.md) (Parts 1–4): an individual-level Difference-in-Differences (and Triple-Differences) analysis of whether the post-COVID shift to remote work altered the "motherhood penalty" in the Israeli labor market.

**Status: the original 10-checkpoint roadmap ([`docs/ROADMAP.md`](ROADMAP.md)) is complete.** Every component that document scoped is implemented, tested, and wired into `main.R`'s default run. A second tranche of work — a statistically-calibrated exposure measure, a cell-based primary DDD, and a descriptive market-mismatch exhibit — was added on top of Checkpoints 6/7 without a matching roadmap entry; see [`docs/decisions/calibrated-exposure-and-cell-ddd.md`](decisions/calibrated-exposure-and-cell-ddd.md) for that methodology's own rationale. A third tranche — a pre-period covariate-balance/age-imbalance robustness chain (`robustness/`) — was added the same way; see [`docs/decisions/age-balance-robustness-chain.md`](decisions/age-balance-robustness-chain.md). A fourth tranche — the hours-worked DDD pivot, now the project's **primary** specification — generalizes the intensive-margin regression and DDD mechanism regression to a single triple-interaction hours model, since fully implemented in the code (no feature flag; unconditional default run) — see [`docs/decisions/hours-ddd-pivot.md`](decisions/hours-ddd-pivot.md) and `docs/ROADMAP.md`'s Checkpoint 11. A fifth tranche removed the secondary (employment) DDD's occupation-level robustness variants and the never-wired `phase2_robustness.R` — see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`). This HLD describes the system **as it actually runs today**, not a plan toward it — treat any place this doc and the code disagree as this doc being wrong, and fix the doc.

## 2. System Architecture

**Execution model**: a single-machine, local R session (RStudio or `Rscript`). There is no database, API, scheduler, or CI — `main.R` is the sole orchestrator, run manually. State between runs is a cached file (`cleaned_df.rds`, invalidated automatically via a hash of `data_processing.R` — not just its own existence). Every result is both printed to the console and exported to `outputs/`.

**Layers:**

| Layer | File(s) | Role |
|---|---|---|
| Raw Data Layer | *(external — not in repo)* | Yearly CBS Labor Force Survey CSVs + `H20231031Codebook.xlsx`, at a path set locally in `main.R` (`folder_path`). Gitignored (`*.csv`). |
| Ingestion & Cleaning Layer | `data_processing.R` | `load_and_clean_data(folder_path, sex_filter)` — reads, filters, recodes, and prunes raw data into an analysis-ready data frame. Defines `DEFAULT_CONTROLS`, the single source of truth for regression controls. |
| Cached Processed-Data Layer | `cleaned_df.rds` + `cleaned_df.rds.meta.rds` | Disk-persisted cleaning output; the sidecar records a hash of `data_processing.R` so a stale cache is detected and rebuilt automatically rather than silently reused. |
| Data-Quality / Validation Layer | `validation.R` | `validate_cleaned_df()` (hard/soft-fail gates), `check_schema_drift()` (raw-CSV column-order guard), `check_idpuf_panel_structure()` (reports `IDPUF` repetition across years/the `Post` divide), `check_wfh_refweek_avadbeshavua()` (verifies a raw-data assumption stated in `data_processing.R`'s comments). All four run automatically in `main.R`; the last two are reporting-only, not gates. |
| Descriptive/Comparative Statistics Layer | `comparative_statistics.R` | `run_comparative_stats()` — missingness, employment-variable audit, group means, mobility trend. |
| Intensive-Margin Modeling Layer (primary) | `intensive_margin_regression.R`, `intensive_margin_lee_bounds.R` | The **primary** hours-worked DiD (`WorkHoursCont ~ Mother*Post + controls`, conditional on `Employed==1`), plus a Lee (2009) trimming-bounds correction for the selection risk that conditioning introduces — see [`docs/decisions/intensive-margin-lee-bounds.md`](decisions/intensive-margin-lee-bounds.md). |
| Extensive-Margin Modeling Layer (secondary) | `basic_regression.R`, `basic_reg_compared_data.R`, `employment_by_child_age.R` | The secondary `Employed ~ Mother*Post + controls` DiD (pooled + Jewish/Arab strata), a robustness check against `Muasak`-observed-only rows, and a child-age-bin breakdown. |
| Gender Placebo Layer | `gender_placebo.R`, `hours_gender_placebo.R` | `run_gender_placebo(folder_path)` — reruns the secondary (employment) DiD on men (fathers vs. childless men) via `load_and_clean_data(..., sex_filter = "men")`, as a falsification check. `run_hours_gender_placebo(folder_path)` — the primary (hours) outcome analog. Both are called by default from `main.R` as of 2026-09-19, and both accept a preloaded `cleaned_men` to avoid reloading the male subsample. |
| WFH-Exposure & Mechanism (DDD) Layer | `wfh_exposure_index.R`, `wfh_exposure_cells.R`, `isco_masking_diagnostics.R`, `ddd_collinearity_diagnostics.R`, `hours_ddd_regression.R`, `hours_ddd_lee_bounds.R`, `imbens_manski_ci.R` | Builds four separate occupation/cell-level WFH-exposure measures (external, calibrated, realized, cell-based shift-share) from `exposure_population_df` (women + men, not the women-only analysis sample — see §4.2), a sensitivity check for ISCO disclosure-masking, a runtime collinearity diagnostic, and two triple-interaction DDD regressions on the same exposure measures: the **primary DDD on hours** (`WorkHoursCont`, pure occupation-level exposure, plus a generalized Lee-bounds correction and a second-stage mechanism regression, run three times for the calibrated/external/realized exposure measures — see [`docs/decisions/hours-ddd-pivot.md`](decisions/hours-ddd-pivot.md)), and the **secondary DDD on employment** (`Employed`, cell-based exposure, two specs). Clustered on the exposure regressor's own assignment level (cell, or occupation), not `IDPUF`. The secondary DDD's own occupation-level robustness variants (`ddd_regression.R`) were removed — see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`). |
| Age-Balance Robustness Layer | `robustness/balance_test.R`, `robustness/age_balance_robustness.R`, `robustness/pretrend_wald_test.R` | Pre-period covariate-balance test (Mother vs. non-Mother, by `WFH_Exposure` quartile), a diagnosed `GilNK` (age-group) imbalance concentrated in the lowest exposure quartile, comparison DDD specs for both the secondary DDD (age-interacted; `GilNK`-reweighted) and the primary hours DDD (`run_hours_ddd_age_interacted()`/`run_hours_ddd_reweighted()`), and a joint Wald test on `Diagnostics.R`'s pre-trend coefficients (run for both DDDs' pretrend models). **This whole layer runs on a default `Rscript main.R` as of 2026-09-19.** `pretrend_wald_test.R` is unflagged entirely — its two F-statistics are the paper's parallel-trends evidence, so it is sourced at the top of `main.R` and runs unconditionally in §7, exporting `outputs/pretrend_wald_{hours,employment}.csv`. The balance-test and age-balance specs sit behind `RUN_AGE_BALANCE_ROBUSTNESS`, which defaults to `TRUE`; the flag is kept so the chain can still be switched off for a fast run — see [`docs/decisions/age-balance-robustness-chain.md`](decisions/age-balance-robustness-chain.md). `robustness/phase2_robustness.R` was removed — see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`). |
| Descriptive Mismatch Exhibit | `israeli_market_mismatch.R`, `run_mismatch.R` | `check_market_mismatch()` — a thin, descriptive-only wrapper around `calibrate_isco_exposure()` reporting how far realized Israeli WFH adoption diverges from the external teleworkability benchmark, by occupation. Invoked via `run_mismatch.R` against a cached `cleaned_df.rds`, not sourced by `main.R`. |
| Diagnostics Layer | `Diagnostics.R`, `hours_diagnostics.R` | `run_diagnostics()` — 2×2 DiD table, parallel-trends event-study plot (Mother×Year, ref=2019), missing-value audits (secondary/employment outcome); still draws via `iplot()`, as a repo diagnostic the paper does not print. `run_hours_diagnostics()` — the primary (hours) pretrend/event-study analog, `Employed==1` subsample; returns tidy per-year coefficients instead of drawing, and `main.R` plots them with `build_event_study_plot()` as the paper's Figure 6. |
| Paper-Figure Layer | `paper_theme.R`, `export_paper_figures.R`, `hours_descriptive_plots.R`, `hours_dose_response.R`, `build_mechanism_scatter.R`, `descriptive_table.R`, `hours_subgroup_comparison.R` | Checkpoint 12 ([`docs/decisions/paper-figure-layer.md`](decisions/paper-figure-layer.md)). `theme_paper()`/`PAPER_PALETTE` — one shared theme and palette so a colour means the same thing in every figure. `build_descriptive_table()` — the paper's Table 1. `build_hours_descriptive_plots()`, `build_hours_dose_response()`, `build_mechanism_scatter()`, `build_hours_subgroup_comparison()` — the descriptive figure builders. `export_paper_figures()` — a second export pass rewriting the handful of figures `paper.tex` includes as vector PDFs at print size, keyed by filename (renaming a key breaks the LaTeX build). Runs unconditionally in `main.R` §8e. |
| Shared Statistical Helpers | `clustered_se.R`, `imbens_manski_ci.R`, `lee_trim_proportion.R`, `lee_trim_cell.R`, `assign_wfh_quartile.R`, `ddd_mde_diagnostics.R`, `wfh_first_stage_check.R`, `ddd_collinearity_diagnostics.R` | `clustered_se()` — cluster-robust SEs for the descriptive/figure layer (adopting it moved intervals only, never point estimates). `imbens_manski_ci()` — shared partial-identification CI solver for both Lee-bounds files; `lee_trim_proportion()`/`lee_trim_cell()` — the trim arithmetic and cell trimming both Lee-bounds files share; `assign_wfh_quartile()` — the one `cut()` every exposure-quartile consumer applies. `compute_ddd_mde()` — closed-form minimum detectable effect, so a null can be read against what the design could detect. `check_wfh_first_stage_relevance()` — tests that `WFH_Exposure` actually predicts realized WFH, the shift-share design's relevance assumption. `check_spec1_collinearity()`/`check_for_dropped_coefficients()` — runtime collinearity guards. |
| Orchestration Layer | `main.R` | Sources every module and calls them in sequence; the only entry point. |
| Output/Export Layer | `export_results.R` | `export_all_results()` — walks every analysis function's `invisible(list(...))` return and writes each data frame to CSV, each `ggplot` to PNG, under `outputs/`. Called once, at the very end of `main.R`, covering every result including §8's exposure/DDD output. |

**Layer diagram:**

```
 [ Raw CBS LFS CSVs, external ]
              |
              v
 [ Ingestion & Cleaning: data_processing.R ]
              |
              v
 [ Cached Processed Data: cleaned_df.rds (+ hash-checked .meta.rds) ]
              |
              v
 [ Validation & Diagnostics: validation.R ]
              |
   +----------+----------+--------------------+--------------------+
   v          v          v                    v                    v
[ Comparative ] [ Intensive/Extensive ] [ Child-Age Het. ] [ Diagnostics ] [ Gender Placebo ]
[   Stats     ] [   Margin Modeling   ] [                ] [              ] [   (default)    ]
   |          |          |                    |                    |
   +----------+----------+--------------------+--------------------+
              |
              v
 [ WFH-Exposure & DDD Layer: wfh_exposure_index.R / wfh_exposure_cells.R /
   isco_masking_diagnostics.R / ddd_collinearity_diagnostics.R /
   hours_ddd_regression.R / hours_ddd_lee_bounds.R / imbens_manski_ci.R ]
              |
   +----------+----------+
   v                      v
[ Primary DDD (hours),  ]  [ Secondary DDD (Employed) ]
[ 3 exposure variants   ]
              |
              v
   [ Age-Balance Robustness Chain: robustness/balance_test.R /
     age_balance_robustness.R / pretrend_wald_test.R ]  (on by default; covers both DDDs)
              |
              v
 [ Paper-Figure Layer: paper_theme.R / descriptive_table.R /
   hours_descriptive_plots.R / hours_dose_response.R /
   build_mechanism_scatter.R / hours_subgroup_comparison.R ]
              |
   +----------+----------------------------+
   v                                        v
 [ Output/Export: export_results.R      ]  [ export_paper_figures.R ->
   -> outputs/ (CSV + PNG, everything)  ]    outputs/figures/ (vector PDF,
                                             only what paper.tex includes) ]
```

`israeli_market_mismatch.R` / `run_mismatch.R` sit outside this default flow — a separate, manually-run descriptive exhibit against a cached `cleaned_df.rds`, sharing `wfh_exposure_cells.R`'s `calibrate_isco_exposure()`.

## 3. Data Flow

The lifecycle of the labor force data, from raw ingestion through to regression output:

1. **Ingestion** — `load_and_clean_data()` reads every yearly CSV in `folder_path` (`read_csv` + `map_df`, tagged with a `file_source` column).
2. **Sample filtering** — restricts to `Min == 2` (women) or `Min == 1` (men) per the `sex_filter` argument (default `"women"`), `GilNK` between 3–7 (ages 25–59), and survey years `{2017,2018,2019,2021,2022,2023}` (2020 excluded as a transitional year — no raw 2020 extract exists for this project).
3. **Variable construction** (all in `data_processing.R`):
   - `Employed` — secondary (extensive-margin) outcome, `1` iff `Muasak == 1`; unemployed and not-in-labor-force are both `0`. Also the selection variable for `WorkHoursCont`'s Lee-bounds correction.
   - `Mother`, `Post` — treatment and period dummies (children <17; post ≥ 2021). Sex-agnostic in derivation, so for the male subsample `Mother` is conceptually read as "Father" without a column rename.
   - `WFH`, `WFH_RefWeek`, `WFH_Hours`, `WFH_Share`, `WFH_Arrangement` — the WFH block. CBS's yes/no items (1=yes, 2=no, 9=unknown) are mapped so code 9 becomes `NA`, never `0`; hour items in the 90s (CBS's own "irregular"/"unknown" codes) are excluded from the hours/share computation. Only defined for `ShnatSeker >= 2021` (the questions weren't asked before).
   - `WorkHoursCont` — **primary (intensive-margin) outcome**: bin-median lookup for regular-hours codes, plus a median imputation for irregular-hours codes (11/12) computed **separately within each `Post` period**, not pooled across 2017–2023 (pooling would blend the pre/post hour distributions and mechanically dampen any real period-specific intensity shift — exactly what the intensive-margin DiD is designed to detect).
   - `MishlachYad_ISCO_08_2`, `ISCO_masked`, `ISCO1` — the ISCO-08 occupation code, parsed to numeric; CBS's disclosure mask (`"XX"`, `"7X"`, …) is recorded explicitly (`ISCO_masked`) rather than silently becoming an unexplained `NA`, and the 1-digit major group is recovered where it survives partial masking (`ISCO1`).
   - `TeudaGvoha` (education, collapsed to 6 groups), `BirthContinent` (country of birth by continent), `WorksOutsideLocality` (commuting indicator, descriptive-only — see §4.3) — advisor-feedback-driven engineered variables.
   - Categorical controls (`MatzavMishpachti`, `Dat`, `GilNK`, `MachozMegurim`, `TeudaGvoha`) converted to factors; `DEFAULT_CONTROLS` is the single source of truth every regression function references (Checkpoint 3). Continuous age/age² was formally decided against in favor of `GilNK` — see `docs/decisions/checkpoint8-age-age2-controls.md` — this is a closed decision, not an open gap.
4. **Column pruning** — irrelevant raw columns dropped via three mechanisms: an explicit name list (`any_of()`), a regex prefix match (`matches()`), and 5 positional range drops (`select(-(a:b))`, order-dependent on the raw CSV schema, guarded by `check_schema_drift()`).
5. **Caching** — result saved to `cleaned_df.rds` alongside a hash of `data_processing.R`; a cache is only reused while that hash still matches, so a `data_processing.R` change (a coding-rule fix, a new derived column) invalidates it automatically rather than silently serving stale data.
6. **Data-quality checks** — `validate_cleaned_df()` (hard-fail on impossible states; soft-fail/warn on NA-rate thresholds), `check_idpuf_panel_structure()`, and `check_wfh_refweek_avadbeshavua()` all run immediately after load, cached or fresh.
7. **Fan-out to analysis** (from `main.R`, unless noted as manual):
   - `run_comparative_stats(cleaned_df)` — descriptive means, dependent-variable baselines.
   - `run_intensive_margin_reg(cleaned_df)` + `run_intensive_margin_lee_bounds(cleaned_df)` — the **primary** hours-worked DiD and its selection-bias-bounded counterpart.
   - `basic_reg(cleaned_df)` / `basic_reg(filter(cleaned_df, Leom==1))` / `==2` — the **secondary** DiD, pooled and Jewish/Arab-stratified.
   - `employment_by_child_age(cleaned_df)` — employment rates and a controlled regression by youngest-child age.
   - `run_diagnostics(cleaned_df)` — 2×2 DiD table and the parallel-trends event-study plot (`i.select = 2` selects the Mother×Year interaction term specifically, not the year main effects that would otherwise plot by default).
   - `run_gender_placebo(folder_path, cleaned_men = ...)` — called by default as of 2026-09-19; reruns `basic_reg()` and the employment DDD on the male subsample.
   - **WFH-exposure measures** (four, built for different purposes, never combined into one "best" index fed to a single regression — see `docs/decisions/calibrated-exposure-and-cell-ddd.md`): `build_exposure_isco2()` (external Dingel & Neiman teleworkability), `calibrate_isco_exposure()` (statistically-calibrated swap against realized 2022-23 data, one-sided cluster-robust test), `build_wfh_exposure_index()` (realized-only, 2021-anchored), `build_exposure_cells()` (pre-period 2017-2019 shift-share exposure by demographic cell — the only one defined for non-employed rows too, and the secondary DDD's exposure regressor). `check_isco_masking_sensitivity()` runs alongside as a proxy check for whether disclosure-masked occupations bias the index.
   - **Primary DDD (intensive margin, hours)** — `WorkHoursCont ~ Mother*Post*WFH_Exposure + controls`, `Employed==1` only, clustered on occupation code, plus a generalized Lee-bounds selection correction (`run_hours_ddd_lee_bounds()`) and an Imbens-Manski CI, plus a precision-weighted second-stage occupation-by-occupation mechanism regression. Run three times — once each for the calibrated, external, and realized occupation-level exposure measures (`main.R` §8a), mirroring the pattern the now-removed secondary-DDD robustness variants used (see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`)). Real-data result (calibrated exposure, post-2026-09-21 harmonization): `Mother:Post:WFH_Exposure` = 3.224 (SE 1.022, p = 0.003; Imbens–Manski [1.021, 5.324]), well outside its own MDE and Lee-bounds-robust — see `paper/notes/results_digest.md` §1 (the pivot memo's own results section predates the harmonization). Unconditional (no feature flag).
   - **Secondary DDD (extensive margin, employment)** — `Employed ~ Mother*Post*WFH_Exposure + Mother:GilNK + controls`, cell-based exposure, two specs (additive controls; interacted cell fixed effects — the standard fix for this shift-share regressor's collinearity with its own controls), clustered on the `(GilNK, TeudaGvoha, MachozMegurim)` cell. `Mother:GilNK` (added 2026-09-11) corrects for a confirmed pre-period age imbalance between mothers/non-mothers whose size varies by exposure quartile — see `docs/decisions/age-balance-robustness-chain.md`; it doesn't change the `Mother:Post:WFH_Exposure` conclusion but surfaces its own real age-heterogeneous-penalty finding. `check_spec1_collinearity()` reports the additive spec's collinearity at runtime; `check_for_dropped_coefficients()` guards both specs generically. This was the project's primary DDD before the hours pivot (`docs/decisions/hours-ddd-pivot.md`); still run and reported, no longer the headline result. Its own three occupation-level robustness variants (`ddd_regression.R`) were removed — see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`).
   - **Age-balance robustness chain** — `RUN_AGE_BALANCE_ROBUSTNESS` flag (default `TRUE` as of 2026-09-19) in `main.R`: `run_balance_test()`, `diagnose_gilnk_by_quartile()`, `run_ddd_age_interacted()`, `run_ddd_reweighted()` (secondary DDD), `run_hours_ddd_age_interacted()`, `run_hours_ddd_reweighted()` (primary DDD), and `run_pretrend_joint_test()` (run once per DDD's own pretrend model). See `docs/decisions/age-balance-robustness-chain.md` for the real-data verification of the `GilNK` imbalance this chain checks for.
8. **Export** — `export_all_results()` writes every result above to `outputs/` in one pass at the end of `main.R` (CSV for tables, PNG for plots). `idpuf_panel_check`'s per-`IDPUF` tables are deliberately excluded (row-level identifiable data; only its console summary is surfaced), as are the age-balance chain's row-level `pre_df` frames — everything else, including the newest WFH-exposure/DDD and (when the flag is on) age-balance results, is included.

## 4. Needed Components

### 4.1 Existing

| File | Function(s) | Implements | Key dependencies |
|---|---|---|---|
| `main.R` | — (orchestrator) | Pipeline sequencing and final export | — |
| `data_processing.R` | `load_and_clean_data()` | Cleaning, DV/control definition (Checkpoints 1–5's shared groundwork) | `tidyverse` |
| `validation.R` | `validate_cleaned_df()`, `check_schema_drift()`, `check_idpuf_panel_structure()`, `check_wfh_refweek_avadbeshavua()` | Checkpoints 1–2, plus two later reporting-only audits | `tidyverse` |
| `comparative_statistics.R` | `run_comparative_stats()` | Descriptive statistics | `tidyverse` |
| `basic_regression.R` | `basic_reg()` | Secondary DiD, extensive margin (Checkpoint 3's `DEFAULT_CONTROLS` consumer) | `fixest` |
| `basic_reg_compared_data.R` | `basic_reg_comp()` | Robustness: full sample vs. `Muasak`-observed only; not called by default | `fixest` |
| `employment_by_child_age.R` | `employment_by_child_age()` | Child-age-bin employment breakdown (secondary/extensive margin) | `tidyverse`, `fixest` |
| `intensive_margin_regression.R` | `run_intensive_margin_reg()` | Checkpoint 4: **primary** intensive-margin DiD | `fixest` |
| `intensive_margin_lee_bounds.R` | `run_intensive_margin_lee_bounds()` | Selection-bias correction for the above — see `docs/decisions/intensive-margin-lee-bounds.md` | `fixest` (base R `lm`) |
| `gender_placebo.R` | `run_gender_placebo()` | Checkpoint 5; called by default as of 2026-09-19 (secondary/employment outcome) | `fixest` |
| `hours_gender_placebo.R` | `run_hours_gender_placebo()` | Hours-outcome gender placebo, added for the hours pivot; called by default | `fixest` |
| `wfh_exposure_index.R` | `build_wfh_exposure_index()` | Checkpoint 6: realized-WFH occupation index (2021 anchor — see `docs/decisions/checkpoint6-wfh-anchor-year.md`) | `tidyverse` |
| `wfh_exposure_cells.R` | `build_exposure_isco2()`, `calibrate_isco_exposure()`, `build_exposure_cells()` | Beyond Checkpoint 6 — see `docs/decisions/calibrated-exposure-and-cell-ddd.md` | `tidyverse`, `fixest` |
| `isco_masking_diagnostics.R` | `check_isco_masking_sensitivity()` | Sensitivity check for the WFH-exposure index's ISCO-masking exclusion | `tidyverse`, `fixest` |
| `ddd_collinearity_diagnostics.R` | `check_spec1_collinearity()`, `check_for_dropped_coefficients()` | Runtime collinearity diagnostic for the secondary (employment) DDD's additive spec, plus a dropped-coefficient guard reused by both DDDs (base R only — no `car` dependency) | base R (`lm`, `kappa`) |
| `hours_ddd_regression.R` | `run_hours_ddd_regression()` | Checkpoint 11: **primary** triple-interaction DDD on hours, pure occupation-level exposure, plus a second-stage mechanism regression, run three times for the calibrated/external/realized exposure measures — see `docs/decisions/hours-ddd-pivot.md`. The secondary DDD's own equivalent (`ddd_regression.R`) was removed — see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`) | `fixest` |
| `hours_ddd_lee_bounds.R` | `run_hours_ddd_lee_bounds()` | Generalized Lee-bounds selection correction for the above, stratified by cell-based exposure quartile | `fixest` |
| `imbens_manski_ci.R` | `imbens_manski_ci()` | Shared Imbens-Manski (2004) CI solver, extracted from `intensive_margin_lee_bounds.R` for reuse by both Lee-bounds files | base R |
| `lee_trim_proportion.R`, `lee_trim_cell.R` | `lee_trim_proportion()`, `lee_trim_cell()` | The excess-selection trim proportion and the top-/bottom-trim of one cell, shared by both Lee-bounds files | `tidyverse` |
| `assign_wfh_quartile.R` | `assign_wfh_quartile()` | The shared quartile `cut()` for every exposure-quartile consumer (moved out of `robustness/age_balance_robustness.R`) | `tidyverse` |
| `israeli_market_mismatch.R` | `check_market_mismatch()` | Descriptive-only exhibit, beyond the original roadmap | `tidyverse` |
| `descriptive_table.R` | `build_descriptive_table()` | The paper's Table 1 (summary statistics) | `tidyverse` |
| `clustered_se.R` | `clustered_se()` | Cluster-robust SEs for the descriptive/figure layer | `fixest` |
| `ddd_mde_diagnostics.R` | `compute_ddd_mde()` | Closed-form minimum detectable effect for both DDD specs | base R |
| `wfh_first_stage_check.R` | `check_wfh_first_stage_relevance()` | Shift-share relevance check: does `WFH_Exposure` predict realized WFH? | `fixest` |
| `hours_subgroup_comparison.R` | `build_hours_subgroup_comparison()` | Jewish/Arab and gender-placebo subgroup comparison figures | `tidyverse` |
| `paper_theme.R` | `theme_paper()` (+ `PAPER_PALETTE`) | Checkpoint 12: shared figure theme/palette | `ggplot2` |
| `hours_descriptive_plots.R` | `build_hours_descriptive_plots()` | Checkpoint 12: hours-by-year / by-period descriptive figures | `tidyverse` |
| `hours_dose_response.R` | `build_hours_dose_response()` | Checkpoint 12: hours DiD by occupation-exposure quartile | `tidyverse` |
| `build_mechanism_scatter.R` | `build_mechanism_scatter()` | Checkpoint 12: per-occupation beta_j vs. exposure scatter (repo diagnostic; deliberately not in the paper) | `tidyverse` |
| `export_paper_figures.R` | `export_paper_figures()` | Checkpoint 12: vector-PDF export pass for the figures `paper.tex` includes | `ggplot2` |
| `run_mismatch.R` | — (script) | Invokes `check_market_mismatch()` against a cached `cleaned_df.rds` | — |
| `robustness/balance_test.R` | `run_balance_test()` | Pre-period covariate balance (Mother vs. non-Mother) by `WFH_Exposure` quartile — see `docs/decisions/age-balance-robustness-chain.md` | `tidyverse` |
| `robustness/age_balance_robustness.R` | `diagnose_gilnk_by_quartile()`, `run_ddd_age_interacted()`, `build_gilnk_rake_weights()`, `run_ddd_reweighted()`, `run_hours_ddd_age_interacted()`, `run_hours_ddd_reweighted()` | Diagnoses the `GilNK` imbalance found in the balance test, and builds comparison specs for both the secondary DDD (age-interacted; reweighted, cell-based exposure) and the primary hours DDD (same two comparison specs, occupation-level exposure) | `tidyverse`, `fixest` |
| `robustness/pretrend_wald_test.R` | `run_pretrend_joint_test()` | Joint Wald test on a fitted pretrend model's pre-2020 coefficients of interest. Run three times: both DiD-level pretrend models, plus the primary DDD's own triple-interaction event study (`keep`/`label` are parameters; the default `keep` is anchored so the DiD and DDD restriction sets cannot collide) | `fixest` |
| `hours_ddd_event_study.R` | `run_hours_ddd_event_study()` | Year-by-year DDD event study (Mother×Year×WFH_Exposure), occupation-clustered — the parallel-trends test for the **primary** estimand, which neither DiD-level event study tests. See [`docs/decisions/ddd-event-study.md`](decisions/ddd-event-study.md) | `tidyverse`, `fixest` |
| `tidy_event_study_coefs.R` | `tidy_event_study_coefs()` | Extracts a fitted `i(ShnatSeker, …)` event study's coefficients into a tidy per-year frame (estimate, SE, t, p, 95% CI, pre/post), selecting terms by anchored name. Shared by the DiD and DDD event studies | `tidyverse`, `fixest` |
| `build_event_study_plot.R` | `build_event_study_plot()` | ggplot event-study plot (point estimates + 95% CI, zero line, treatment-boundary rule, hollow pinned reference year). Draws both the paper's Figure 6 (DiD) and Figure 7 (DDD); returns a ggplot, so both exporters handle it like every other figure rather than needing `main.R` to manage a device | `tidyverse` |
| `Diagnostics.R` | `run_diagnostics()` | 2×2 DiD, parallel-trends event study (secondary/employment outcome) | `tidyverse`, `fixest` |
| `hours_diagnostics.R` | `run_hours_diagnostics()` | Hours-outcome parallel-trends/pretrend model, `Employed==1` subsample, added for the hours pivot's robustness-parity pass | `tidyverse`, `fixest` |
| `export_results.R` | `export_all_results()` | Checkpoint 9: persisted output layer, now covering every result including §8 | `ggplot2` |

R dependencies in use today: **`tidyverse`**, **`fixest`**. No lockfile/renv; no database, API, or scheduling dependency. `car` was considered for a VIF-based collinearity diagnostic and deliberately not added — `ddd_collinearity_diagnostics.R` implements the one VIF this project needs in base R instead (see that file's header comment).

### 4.2 Known limitations & deliberate decisions

Everything the original roadmap scoped is built. What remains are documented methodological choices and open caveats, not missing components:

| Item | Where documented | Notes |
|---|---|---|
| Survey weights (`MishkalSofi`, etc.) are not applied in any outcome regression | `README.md` Known Limitations, `CLAUDE.md` | Deliberate, not an oversight — do not add without raising it first. `build_exposure_cells()` is the one exception (weights the exposure regressor's own construction, not a survey-representativeness correction). A second, not-yet-approved exception (`robustness/phase2_robustness.R`'s `run_ddd_weights_check()`) was removed along with that file — see `docs/decisions/employment-ddd-robustness-removal.md` (deleted 2026-09-24, in git at `c800efe^`). |
| Lee (2009) bounds only handle excess selection in one direction | `docs/decisions/intensive-margin-lee-bounds.md`; generalized to the DDD in `docs/decisions/hours-ddd-pivot.md` | Under-selection in the `Mother==1,Post==1` cell isn't addressed by this construction. As of the 2026-09-09 audit fix, the bounds also report a per-model SE/CI and an Imbens-Manski (2004) CI for the identified set, not just bare point estimates. The hours-DDD pivot generalizes this same machinery to the triple-interaction (`Mother x Post x WFH_Exposure`) specification, stratifying the selection counterfactual by cell-based exposure quartile. |
| Calibrated-exposure / cell-based-DDD methodology | `docs/decisions/calibrated-exposure-and-cell-ddd.md` | Records why an earlier ad hoc gap-threshold rule was replaced with a statistical test, and why the DDD's primary spec is now cell-based rather than occupation-level. As of the 2026-09-09 audit fix, the calibrated/realized measures are built from a population that also includes men (`exposure_population_df`), not the women-only analysis sample. |
| `GilNK` (age-group) imbalance between Mother and non-Mother, concentrated in the lowest `WFH_Exposure` quartile | `docs/decisions/age-balance-robustness-chain.md` | Confirmed against real data; figures refreshed 2026-09-19 from `outputs/age_balance_robustness_age_imbalance_by_quartile.csv`: the gap is largest in Q1 (-0.974 age-group units, t = -94.0) and shrinks/reverses to +0.057 by Q4. (The earlier "~0.8, t≈-81" reading predated the `BirthContinent` change to the exposure cells.) Comparison specs exist for both the secondary DDD (age-interacted; `GilNK`-reweighted) and the primary hours DDD (same two comparison specs, occupation-level exposure) but none has replaced either DDD's own primary spec — that's a separate, still-open decision. |
| ISCO disclosure-masking's effect on the exposure index | `isco_masking_diagnostics.R` | A proxy check via the coarser `ISCO1`, not a full resolution — a fully-masked ("XX") row still carries zero occupation signal at any resolution. |
| `IDPUF` cross-period repetition | `validation.R`'s `check_idpuf_panel_structure()` | Reported, not corrected — the same person can in principle contribute to both `Post==0` and `Post==1` rows. |
| Secondary (extensive-margin) DDD's null `Mother:Post:WFH_Exposure` was underpowered — root cause diagnosed and partially fixed | `docs/decisions/exposure-cell-granularity-fix.md` (diagnosis in its B1/B2 section, then the fix) → `docs/decisions/hours-ddd-pivot.md` (ultimate resolution: pivot to the non-underpowered primary hours DDD) | Root cause: `WFH_Exposure` was built from exactly the same 3 variables used as the regression's own controls/FE, so its minimum detectable effect was ~51% of baseline employment — far larger than the actual point estimates. Fixed by building `WFH_Exposure` on a finer partition (+`MatzavMishpachti`, +`Dat`) than the regression's controls/FE, verified against real data to cut the MDE substantially with negligible cell-size cost; after the final `BirthContinent` refinement the MDE is ~26% of baseline (0.2031 and 0.2022 across the two specs), not the ~32% an intermediate candidate gave. Still underpowered at that level, but no longer aliased with its own controls by construction. `RUN_NULL_VS_POWER_AUDIT` flag, default `TRUE` as of 2026-09-19. |

### 4.3 Reconciliation note

Part 3 §1 of the research doc ("Variables to Exclude") says to drop the work-mobility variable **entirely**. What's actually implemented is different: `WorksOutsideLocality` is built and reported in `run_comparative_stats()`, but deliberately excluded from every regression's `controls` list. This HLD records that as a later refinement of the written doc, not a contradiction. The research doc is kept as originally written; its status banner (added 2026-09-26) points here for the refinement.
