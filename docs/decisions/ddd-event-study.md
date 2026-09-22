# Decision Memo: DDD Event Study (Mother × Year × WFH_Exposure) and Its Own Pre-Trend Test

**Status: IMPLEMENTED** (2026-09-21). New: `scripts/hours_ddd_event_study.R`
(`run_hours_ddd_event_study()`), `scripts/build_ddd_event_study_plot.R`
(`build_ddd_event_study_plot()`). Modified: `robustness/pretrend_wald_test.R`
(`run_pretrend_joint_test()` gains `keep`/`label` parameters), `main.R` §8a. Wired in
unconditionally — no feature flag, matching §8a's existing convention.

## Motivation: the primary estimand had no pre-trend test of its own

Before this, the repo tested parallel trends in exactly two places, and both tested the **wrong
estimand for the primary specification**:

| Existing test | Model | Estimand tested |
|---|---|---|
| `run_diagnostics()` → `run_pretrend_joint_test()` | `Employed ~ … i(ShnatSeker, Mother, ref=2019)`, `cluster = ~IDPUF` | DiD, secondary outcome |
| `run_hours_diagnostics()` → `run_pretrend_joint_test()` | `WorkHoursCont ~ … i(ShnatSeker, Mother, ref=2019)`, `cluster = ~IDPUF` | DiD, primary outcome |

The project's primary estimand is neither of those. It is the triple interaction
`Mother:Post:WFH_Exposure` from `run_hours_ddd_regression()` (Checkpoint 11,
`docs/decisions/hours-ddd-pivot.md`). Both existing tests ask *did mothers and non-mothers trend
together?* The DDD's identifying assumption is the different, stricter claim that *the
mother/non-mother gap trended together **across WFH exposure levels***.

These are not the same test, and the DiD version is not the conservative one. The DiD event study
averages over exposure, so a pre-period divergence that is correlated with exposure but nets to
approximately zero across occupations is invisible to it: the DiD pre-trend can pass while the DDD's
own pre-trend fails. Since `docs/decisions/hours-population-harmonization.md` (Checkpoint 13) turned
the hours DiD pre-trend from a headline violation (F = 23.69) into a pass (F = 0.95, p = 0.387), the
paper's parallel-trends evidence rested entirely on a test of an assumption the primary estimate does
not actually require — and said nothing about the one it does.

## Specification

The saturated triple-difference event study. `Post` is replaced by a full set of survey-year
interactions at every level of the interaction hierarchy:

```
WorkHoursCont ~ Mother * WFH_Exposure
              + i(ShnatSeker, ref = 2019)                 # year main effects
              + i(ShnatSeker, Mother, ref = 2019)         # year × Mother      (= the existing DiD event study)
              + i(ShnatSeker, WFH_Exposure, ref = 2019)   # year × exposure
              + i(ShnatSeker, MotherWFH, ref = 2019)      # year × Mother × exposure  ← coefficients of interest
              + DEFAULT_CONTROLS
```

`cluster = ~MishlachYad_ISCO_08_2`, `Employed == 1` subsample, occupation-level calibrated exposure
joined by ISCO-2 — every one of these matched to `run_hours_ddd_regression()` deliberately. A
diagnostic fit on a different sample, a different exposure measure or a different vcov than the model
it licenses is not testing that model's assumption.

Three points that are easy to get wrong here:

- **All three lower-order year interactions are required.** Drop `i(ShnatSeker, WFH_Exposure)` and
  the `year × MotherWFH` terms absorb occupations' general exposure trend; drop
  `i(ShnatSeker, Mother)` and they absorb the unconditional motherhood gap's own time path. Either
  way the result is a mislabelled two-way estimate that still fits perfectly well.
  `test-hours_ddd_event_study.R` pins all four families of terms for exactly this reason.
- **`MotherWFH` is a materialized product column.** fixest's `i(f, var)` takes a single variable, not
  an expression, for its second argument, so `i(ShnatSeker, Mother:WFH_Exposure)` is not available.
  The resulting coefficient names are `ShnatSeker::<year>:MotherWFH` — verified empirically against
  the installed fixest, not inferred.
- **Inference is t on G − 1, not normal.** Clustering on ISCO-2 occupations leaves 40 clusters and 39 denominator df. Exported p-values and CIs use `qt`/`pt` on `degrees_freedom(model, type = "t")`,
  which reproduces `etable()`'s printed values exactly; a hardcoded `1.96` would have been wrong
  (the 0.975 quantile of t on 39 df is 2.023).

## The `keep` anchor: a silent-wrong-answer bug that had to be fixed first

`run_pretrend_joint_test()` built its restriction set with `keep = "ShnatSeker::(2017|2018):Mother"`
— unanchored. Verified empirically: that regex also matches `ShnatSeker::2017:MotherWFH`. Passing the
DDD event-study model to the function unchanged would have run a **4-restriction** Wald test mixing
the DiD-level and DDD-level pre-period coefficients, while printing and exporting something that
looked like a well-formed 2-restriction pre-trend test.

The fix: `keep` and `label` became parameters, and the *default* `keep` is now anchored with `$`.
Anchoring is behaviour-identical for the two existing call sites (neither model contains a
`MotherWFH` term at all) and makes the collision structurally impossible rather than merely
currently-absent. `label` is parameterized alongside it because it is written into the exported
one-row table, and three Wald F-statistics now land in `outputs/` — a DDD pre-trend filed under the
DiD's hypothesis string would be unattributable.

## Considered and rejected

- **Reusing `run_hours_diagnostics()`'s model with a `WFH_Exposure` interaction bolted on.** That
  model clusters on `~IDPUF` and carries no exposure regressor; retro-fitting it would have left one
  function serving two estimands with two clustering levels selected by argument. A separate
  estimator beside `hours_ddd_regression.R` keeps each pretrend model adjacent to the specification
  it tests.
- **`iplot()` instead of a ggplot builder.** The two existing event studies use fixest's base-graphics
  `iplot()`, which returns nothing and draws to the active device — which is why they reach `outputs/`
  only as whole-device PDFs wrapped in an explicit `pdf()`/`dev.off()` pair in `main.R` §7, and why
  neither can be handed to `export_all_results()` or `export_paper_figures()`. A returned ggplot is
  exported by the same two code paths as every other figure in the project, with no device management
  at the call site. Also: `iplot(i.select = 4)` would have been required to select the triple-
  interaction term, a positional index into the formula that silently plots the wrong series when the
  formula is reordered (`hours_diagnostics.R`'s own header records having been bitten by `i.select`).
## In the paper

Added to `paper/paper.tex` (2026-09-22) as Table `tab:pretrend-ddd` and Figure `fig:pretrend-ddd` in
Results §5.3, under a new `\paragraph{Pre-trends for the triple difference.}` placed directly after
the headline DDD paragraph. Three existing passages were corrected rather than merely
cross-referenced, because each asserted the identifying assumption was supported on the strength of a
DiD-level test alone:

- §5.3's `\paragraph{Pre-trends.}` — now says the two Wald tests support the *difference-in-differences*
  assumption and forward-references the triple difference's own test.
- §4.6 `Diagnostics and placebo` — now describes the DDD event study alongside the two DiD ones.
- §7 `Limitations` — now reports all three F-statistics and states plainly that the one that matters
  for the headline estimate is also the weakest of the three.

The figure is exported at 5.0 × 3.4in to match `hours_dose_response`; every paper figure is printed
at `0.8\textwidth`, so a PDF authored wider than its neighbours is scaled down further and its text
renders smaller on the page.

## Artifacts

| Path | Contents |
|---|---|
| `outputs/hours_ddd_event_study_coefs.csv` | Tidy: term, year, estimate, std_error, t_stat, p_value, ci_low, ci_high, period |
| `outputs/hours_ddd_event_study_table.csv` | `etable()`'s full-model view |
| `outputs/hours_ddd_event_study_plot.png` | 8×5in 150dpi browsing copy (`export_all_results()`) |
| `outputs/figures/hours_ddd_event_study.pdf` | 5.5×3.6in vector (`export_paper_figures()`) |
| `outputs/pretrend_wald_hours_ddd.csv` | One-row joint Wald F on the pre-period triple-interaction terms |


## Real-data results

Run: `Rscript main.R` on branch `2017-fix`, 2026-09-21, exit 0. The run also reproduced the pooled
hours DDD at **3.224 (1.022)** and the hours DiD pre-trend Wald at **F = 0.9487, p = 0.3873**, both
matching their previously recorded values exactly — so these event-study numbers sit on the same
data as the rest of the branch's committed outputs, not on a drifted re-clean.

Estimation sample: 281,622 of 288,400 employed rows (97.6%) matched an occupation-level exposure
value; 40 ISCO-2 clusters, so 39 denominator degrees of freedom.

Joint Wald test, H0: the pre-2020 `Mother:year:WFH_Exposure` coefficients are jointly zero (survey
years 2017 and 2018; 2019 is the omitted reference and 2020 is absent from the sample):

**F(2, 39) = 0.0410, p = 0.9598** — clustered on `MishlachYad_ISCO_08_2`.

Year-by-year triple-interaction estimates (hours per unit of WFH exposure, 95% CI):

| Year | Estimate | SE | p | 95% CI | Period |
|---|---|---|---|---|---|
| 2017 | 0.5866 | 2.2367 | 0.7945 | [−3.938, 5.111] | Pre |
| 2018 | 0.3134 | 1.7449 | 0.8584 | [−3.216, 3.843] | Pre |
| 2019 | 0 (reference) | — | — | — | — |
| 2021 | 3.0114 | 1.2327 | 0.0192 | [0.518, 5.505] | Post |
| 2022 | 3.5454 | 1.0850 | 0.0023 | [1.351, 5.740] | Post |
| 2023 | 4.0203 | 1.3397 | 0.0047 | [1.311, 6.730] | Post |

**Reading.** The pre-trend test passes, and it passes in the informative way rather than the
uninformative one: the two pre-period coefficients are not merely insignificant, they are close to
zero in level (0.59 and 0.31 hours per unit exposure, against post-period estimates 5–13× larger)
and the joint F of 0.041 is far below 1. The post-period path is flat-then-jump-then-rising — nothing
in the pre-period, then 3.01 in 2021, 3.55 in 2022, 4.02 in 2023 — which is what a treatment
switching on in 2021 looks like, and not what a pre-existing trend continuing through the sample
looks like. All three post-period coefficients are individually significant and straddle the pooled
DDD's 3.224, as they should, since the pooled specification's single Post dummy aggregates exactly these three post-period years.

**Caveat, stated rather than buried.** This is a low-powered test. The pre-period standard errors
(2.24 and 1.74) are of the same order as the pooled DDD estimate itself, so each pre-period
confidence interval comfortably contains values larger in magnitude than 3.224 — the test cannot
rule out a pre-trend as large as the effect being claimed. That is a consequence of clustering at the
level the exposure regressor actually varies at (40 clusters), which is the correct choice, not a
fixable one; the pooled DDD carries the same limitation. The right reading is that the evidence is
consistent with parallel trends and shows no sign of a violation, not that a violation has been
ruled out.
