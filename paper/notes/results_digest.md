# Results Digest — WFH and the Motherhood Penalty (Israel, CBS LFS 2017–19 / 2021–23)

**Purpose.** Fact-extraction pass for the seminar paper. No prose, no LaTeX. Every number is
tagged with the exact file it was read from. Where the only source is a console message quoted in
a decision memo (never exported to `outputs/`), that is stated explicitly. Anything not confirmable
from a repo artifact was marked `[TODO: confirm]` and unverified citation fields `[VERIFY]`; as of 2026-09-24 no marker of either kind remains.

**Authors (paper byline):** Inbal Moryles and Nitzan Zacharia. (The research doc's byline spells
the first author "Inbal Muriel" — that spelling is wrong; do not copy it into the paper.)

**Digest date:** 2026-09-15, **hours sections fully revised 2026-09-21**. **Repo state:** branch
`2017-fix`. Live `outputs/*.csv` files were regenerated 2026-09-21 after Checkpoint 13
([`docs/decisions/hours-population-harmonization.md`](../../docs/decisions/hours-population-harmonization.md))
harmonized the hours population on reference-week work and a follow-up redefined the Lee-bounds
selection rate on the observed-hours sample.

> **What Checkpoint 13 changed, in one place.** The 2017 CBS file recorded zero usual hours for
> respondents who were employed but absent from the reference week; every later year gave them a
> real value. Absence is mother-skewed (12.4% of employed mothers vs 7.3% of childless women), so
> those zeros landed on one side of the paper's comparison. Defining hours on reference-week
> workers in every year fixes it, at the cost of ~10% of each year's employed sample and a
> narrower estimand. Headline consequences: the hours pre-trend Wald test now **passes**
> (F = 23.69 → **0.949**, p = 0.387); the hours DiD becomes a **null** (0.8261\*\*\* → **0.2280**);
> the headline DDD **survives** (3.4073\*\*\* → **3.224**\*\*). All hours sections below carry the
> post-fix values. §5.4's parallel-trends caveat is withdrawn. **The employment margin, the
> WFH-exposure construction and Table 1's non-hours rows are untouched by all of this.**

**Significance codes** (fixest `etable` convention, used throughout): `***` p<0.001, `**` p<0.01,
`*` p<0.05, `.` p<0.1, `(ns)` p≥0.1.

---

## 0. Model hierarchy — verified against the repo

| Role | Outcome | Model | Exposure regressor | Cluster | Status in code |
|---|---|---|---|---|---|
| **PRIMARY** | `WorkHoursCont` (weekly hours, `Employed==1` only) | DiD `Mother*Post`; DDD `Mother*Post*WFH_Exposure` | DDD: **occupation-level (ISCO-08 2-digit) calibrated** score, ~40 groups | DiD: `IDPUF`; DDD: `MishlachYad_ISCO_08_2` | `main.R` §5 (DiD) and §8a (DDD), unconditional |
| **SECONDARY** | `Employed` (0/1, full sample) | DiD `Mother + Post + Mother:Post`; DDD `Mother*Post*WFH_Exposure + Mother:GilNK` | DDD: **demographic-cell shift-share** (pre-period 2017–19), ~8,884 cells | DiD: `IDPUF`; DDD: `GilNK^TeudaGvoha^MachozMegurim` (~210 clusters) | `main.R` §5 (DiD) and §8b (DDD), unconditional |

Verification sources: `README.md` "Research design" (hours = primary, employment = secondary);
`docs/HLD.md` §1 and §3 step 7; `docs/ROADMAP.md` Checkpoint 11; `docs/decisions/hours-ddd-pivot.md`
"Resolved: hours DDD is now the primary specification" (decided 2026-09-12); `main.R` §8a/§8b comments.

**The two DDDs use different exposure measures and must not be conflated** (stated explicitly in
`docs/decisions/calibrated-exposure-and-cell-ddd.md`, top "Update (2026-09-12)" note, and in
`scripts/hours_ddd_lee_bounds.R` header). The hours DDD's Lee-bounds step is the one place both
measures appear together, in different roles (see §1.4).

**Controls (all models):** `DEFAULT_CONTROLS = c("MatzavMishpachti","Dat","GilNK","MachozMegurim","TeudaGvoha")`
= marital status, religiosity, age group (categorical, 25–59 → codes 3–7), district, education
(6 groups). Defined once in `scripts/data_processing.R`. No survey weights in any outcome
regression (see §5).

**Sample:** women aged 25–59, survey years 2017, 2018, 2019, 2021, 2022, 2023. `Mother` = any child
under 17. `Post` = year ≥ 2021. (`README.md` "Key variables"; `docs/HLD.md` §3 step 2.)

**Stale / trap artifacts — deleted 2026-09-21.** Fourteen superseded CSVs (`ddd_calibrated_*`,
`ddd_external_*`, `ddd_realized_*`, `ddd_primary.csv`, `hours_ddd_pivot_*`) were quarantined to
`outputs/archive/` on 2026-09-19 and deleted outright on 2026-09-21. They came from the since-removed
`ddd_regression.R` (an occupation-level DDD on the *employment* outcome), an old `ddd_primary`
export key, and a removed `RUN_HOURS_DDD_PIVOT` flag; no current code path regenerates any of them.
Git retains them if a number ever needs tracing. Nothing in `outputs/` is a trap artifact today —
every file there is produced by the current pipeline.

---

## 1. PRIMARY — Intensive margin (hours)

### 1.1 [PRIMARY] Hours DiD

- **Function / file:** `run_intensive_margin_reg()`, `scripts/intensive_margin_regression.R`
- **Formula (verbatim from script):** `WorkHoursCont ~ Mother + Post + Mother:Post + MatzavMishpachti + Dat + GilNK + MachozMegurim + TeudaGvoha`
- **Sample:** `Employed == 1 & AvadBeshavua == 1` (reference-week workers — the harmonized hours
  population, see `docs/decisions/hours-population-harmonization.md`); **cluster:** `~IDPUF`
- **Source table:** `outputs/intensive_margin_table.csv`

| Term | Coef | SE | Sig. |
|---|---|---|---|
| `Mother x Post` | **0.2280** | 0.1809 | (none) |
| `Mother` | −1.739 | 0.1441 | *** |
| `Post` | −0.0570 | 0.1481 | (none) |
| Constant | 32.35 | 0.3182 | *** |

- **N = 251,857**; R² = 0.04049.
- Full-precision estimate (from `outputs/hours_did_subgroup_comparison_data.csv`, row "All women
  (primary)"): 0.227954, SE 0.180893, 95% CI [−0.1266, 0.5825]. **t = 1.26 — not significant.**
- **This is a null, and the paper characterizes it as a reasonably precise one.** At this SE the
  minimum detectable effect is 2.8016 × 0.1809 ≈ **0.51 hours**, so average gains much above half
  an hour a week are ruled out. The distinction between a precise and an underpowered null is the
  same one §2.3 draws for the employment margin, and the paper applies it on both.
- **Baseline means** (`outputs/hours_diagnostics_hours_by_period.csv`, reference-week workers):
  non-mothers pre 40.04 (n 50,144) / post 40.08 (n 43,838); mothers pre 38.54 (n 88,114) /
  post 38.84 (n 76,079). Pooled mean = **39.18 hours (n = 258,175)**
  (`outputs/comparative_stats_hours_summary.csv`; median 42, SD 11.82).
- Raw 2×2 DiD (`outputs/hours_descriptives_raw_did.csv`): **0.2658, SE 0.1810**, 95% CI
  [−0.0890, 0.6206] — (38.84−38.54) − (40.08−40.04) = 0.31 − 0.04. **Clustered by IDPUF as of
  2026-09-21**, so it now agrees with the regression DiD (0.2280, SE 0.1809) on both magnitude and
  precision; both are nulls. Previously this SE was 0.0978, computed as if the four cell means were
  independent, which made the raw DiD look significant when the regression's did not.
- ⚠️ **Label discrepancy:** `outputs/descriptive_table_continuous.csv` still names these rows
  "Usual weekly hours (employed), mean/SD". The population is reference-week workers; the label
  lives in `scripts/descriptive_table.R` and was not updated. `paper.tex` Table 1 uses the correct
  label. Cosmetic in the CSV, but do not copy the CSV's wording.

### 1.2 [PRIMARY] Lee (2009) bounds on the hours DiD

- **Function / file:** `run_intensive_margin_lee_bounds()`, `scripts/intensive_margin_lee_bounds.R`;
  method memo `docs/decisions/intensive-margin-lee-bounds.md`.
- **Construction:** `s_ab = P(hours observed | Mother=a, Post=b)` — employed **and** working the
  reference week, i.e. the estimation sample rather than the employed population. (This was
  `P(Employed==1)` until 2026-09-21; see the follow-up section of
  `docs/decisions/hours-population-harmonization.md` for why it had to change.) Counterfactual
  `s11* = s10 + (s01 − s00)`; if `s11 > s11*`, trim share `p = 1 − s11*/s11` from the
  `Mother=1,Post=1` cell's `WorkHoursCont` distribution (top-trim → lower bound, bottom-trim →
  upper bound); refit the DiD on each trimmed sample.
- **Selection rates** (`outputs/intensive_margin_lee_bounds_diagnostics_selection_rates.csv`):

| Mother | Post | selection rate | n |
|---|---|---|---|
| 0 | 0 | 0.7010 | 71,532 |
| 0 | 1 | 0.7058 | 62,114 |
| 1 | 0 | 0.6786 | 129,856 |
| 1 | 1 | 0.6964 | 109,239 |

  → `s11* = 0.6786 + (0.7058 − 0.7010) = 0.6833`; `s11 = 0.6964 > s11*` ⇒ excess selection;
  implied trim ≈ 1 − 0.6833/0.6964 ≈ **1.9%** — **derived from the selection rates above, not
  directly exported by the pipeline**; cite it as a derived figure (footnoted), not a sourced one.
  These rates are lower than the pre-2026-09-21 figures because they condition on working the
  reference week as well as on holding a job; the `n` column is unchanged (it counts all rows in
  the cell).

- **Bounds table** (`outputs/intensive_margin_lee_bounds_table.csv`):

| Bound | `Mother:Post` | SE | 95% CI |
|---|---|---|---|
| Lower | −0.5166 | 0.1781 | [−0.8657, −0.1675] |
| Point (untrimmed) | 0.2280 | 0.1809 | [−0.1266, 0.5825] |
| Upper | 0.8017 | 0.1789 | [0.4511, 1.1523] |

  Full precision: lower −0.516593 / 0.178096; point 0.227954 / 0.180893; upper 0.801657 / 0.178878.

- **95% Imbens–Manski CI for the identified set: [−0.810, 1.096]**, `c_α = 1.644854` — crosses
  zero. Recomputed 2026-09-21 by sourcing `scripts/imbens_manski_ci.R` against the bounds above;
  **not in any CSV**.
- **Reading:** the correction *widens the interval around a null* rather than overturning a
  finding. The point estimate is already insignificant (§1.1), so the earlier framing — an
  "honest two-step" in which a significant DiD fails a selection correction — no longer applies
  and has been removed from the paper. Nothing in the paper's argument rests on the plain DiD.
  The DDD (§1.3) is the substantive result.

### 1.3 [PRIMARY — HEADLINE] Hours DDD (occupation-level calibrated exposure)

- **Function / file:** `run_hours_ddd_regression()`, `scripts/hours_ddd_regression.R`; called in
  `main.R` §8a with `hours_exposure_index = exposure_calibrated %>% select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)`.
- **Formula (verbatim from script):** `WorkHoursCont ~ Mother*Post*WFH_Exposure + MatzavMishpachti + Dat + GilNK + MachozMegurim + TeudaGvoha`
- **Sample:** reference-week workers (`Employed == 1 & AvadBeshavua == 1`), inner-joined to the
  occupation exposure index on `MishlachYad_ISCO_08_2` (drops disclosure-masked / unmapped ISCO
  codes). N = 246,326 after listwise deletion on controls, against §1.1's 251,857 — the difference
  is the unmatched-occupation rows. ⚠ The old "281,622 of 288,400 (97.6%) matched" coverage figure
  was console-only and exists in no CSV at any commit; it has been **dropped from the paper**
  rather than re-derived. If it is wanted back, it must be recomputed in the exposure merge.
- **Cluster:** `~MishlachYad_ISCO_08_2` (occupation; Moulton reasoning, ~40 clusters).
- **Exposure measure:** `wfh_exposure_calibrated` from `calibrate_isco_exposure()`
  (`scripts/wfh_exposure_cells.R`): Dingel & Neiman external teleworkability score, replaced by
  realized 2022–23 Israeli WFH share only where gap > 0.5 and statistically distinguishable from
  sampling noise (one-sided cluster-robust test, 95%). 10 of 40 ISCO-2 occupations swapped
  (`outputs/wfh_exposure_calibrated.csv`, `swap == TRUE` rows: ISCO 41, 23, 12, 11, 24, 14, 25, 33,
  44, 13). Examples from that file: ISCO 23 (teaching) external 0.966 → calibrated 0.069; ISCO 41
  (clerical) 1.000 → 0.098; ISCO 25 (ICT) 1.000 → 0.360. Built from `exposure_population_df`
  (women + men), not the women-only analysis sample (`main.R` §8 comment; `docs/HLD.md` §4.2).
- **Source table:** `outputs/ddd_hours_table.csv`

| Term | Coef | SE | Sig. |
|---|---|---|---|
| **`Mother x Post x WFH_Exposure`** | **3.224** | **1.022** | **\*\*** |
| `Mother x Post` | **−0.5385** | 0.3364 | (ns) |
| `Mother x WFH_Exposure` | −1.295 | 1.053 | (ns) |
| `Post x WFH_Exposure` | −0.5483 | 0.8102 | (ns) |
| `WFH_Exposure` | 1.128 | 3.912 | (ns) |
| `Mother` | −1.449 | 0.3512 | *** |
| `Post` | 0.0535 | 0.2732 | (ns) |

- **N = 246,326**; R² = 0.04094.
- Full-precision triple interaction (`outputs/hours_ddd_subgroup_comparison_data.csv`, "All women
  (primary)"): 3.224042, SE 1.022271, 95% CI [1.2204, 5.2277].
- **Interpretation note — this is the paper's central argument and it changed in kind.** The bare
  `Mother x Post` in this column is **−0.5385**, i.e. the implied hours change for mothers at
  *zero* exposure is if anything negative. Set against §1.1's near-zero average DiD, the reading
  is **not** "a broad gain that is larger in teleworkable jobs" but "no gain outside teleworkable
  jobs at all; the entire effect is the exposure gradient." The pre-2026-09-21 framing — the bare
  term "collapsing" from 0.826 to 0.015 and being "absorbed into exposure heterogeneity" — is
  obsolete: there is no average effect to absorb. §1.9's dose-response shows the same thing
  non-parametrically (three quartiles at zero, one well above).
- **MDE** (`compute_ddd_mde()`, `scripts/ddd_mde_diagnostics.R`, formula
  `MDE = SE × (qnorm(0.975) + qnorm(0.80)) = SE × 2.8016`): **2.86398** — now exported to
  `outputs/mde_hours.csv` (it was console-only when this digest was first written; see §7 item 3).
  That file also gives baseline mean hours **39.1819** and `mde_pct_of_baseline` **7.309%**;
  `within_mde = FALSE`.
  - MDE as a share of the point estimate: 2.86398/3.22404 = **88.8%** (was 76.5%). The estimate is
    still detectable but with materially less headroom than before — the paper says "inside the
    design's power, though not by a wide margin" rather than "well inside".
  - ⚠ Any doc still saying the MDE is "68% of the point estimate" is wrong twice over: it confuses
    the 7.3%-of-mean-hours figure with the share-of-estimate figure, and both values have moved.

### 1.4 [PRIMARY] Generalized Lee bounds on the hours DDD + Imbens–Manski CI

- **Function / file:** `run_hours_ddd_lee_bounds()`, `scripts/hours_ddd_lee_bounds.R`.
- **Design (from script header):** selection counterfactual `s11*(q) = s10(q) + (s01(q) − s00(q))`
  computed **separately within each quartile q of the cell-based `WFH_Exposure`** (defined for
  employed and non-employed alike; quartile breaks from the pre-period); each quartile's
  `Mother=1,Post=1` employed slice is trimmed by its own `trim_prop(q)`; the trimmed subsets are
  recombined and the full triple-interaction formula (with **occupation-level** `WFH_Exposure` as
  regressor, clustered on occupation) is refit on point / lower / upper samples. Two exposure
  measures, two roles — the cell-based one stratifies selection, the occupation-level one is the
  regressor.
- **Quartile diagnostics** (`outputs/hours_lee_bounds_quartiles.csv`):

| Q | s00 | s01 | s10 | s11 | s11* | n(M=1,P=1) | Excess? | trim_prop |
|---|---|---|---|---|---|---|---|---|
| 1 | 0.5830 | 0.5862 | 0.5497 | 0.5788 | 0.5529 | 21,655 | TRUE | 4.48% |
| 2 | 0.7070 | 0.7120 | 0.6856 | 0.6977 | 0.6906 | 28,540 | TRUE | 1.01% |
| 3 | 0.7542 | 0.7450 | 0.7554 | 0.7522 | 0.7462 | 34,293 | TRUE | 0.80% |
| 4 | 0.8194 | 0.8029 | 0.7352 | 0.7399 | 0.7188 | 21,815 | TRUE | 2.85% |

  As in §1.2, `s_ab` is now `P(hours observed)` rather than `P(Employed==1)`, so all four rates
  are lower than the pre-2026-09-21 figures. The `n(M=1,P=1)` column is unchanged — it counts all
  post-period mothers in the quartile, working or not, because the cell-based index is defined for
  the non-employed too.
- **Rows trimmed** (`outputs/hours_lee_bounds_n_trimmed.csv`): Q1 548 of 12,249; Q2 197 of 19,511;
  Q3 202 of 25,317; Q4 449 of 15,743 (total **1,396 of 72,820** occupation-matched post-period
  mothers with observed hours).
- **Bounds table** (`outputs/hours_lee_bounds_table.csv`), term `Mother:Post:WFH_Exposure`:

| Bound | Coef | SE | 95% CI |
|---|---|---|---|
| Lower | 3.1255 | 1.1440 | [0.8833, 5.3677] |
| Point (untrimmed) | 3.2319 | 1.0538 | [1.1664, 5.2973] |
| Upper | 3.4434 | 1.0220 | [1.4404, 5.4465] |

  Full precision: lower 3.125517 / 1.143991; point 3.231854 / 1.053815; upper 3.443446 / 1.021983.
  The "point" here (3.2319, SE 1.0538) differs slightly from §1.3's 3.224 (SE 1.022) because this
  function additionally requires a matched *cell*-based exposure — stated in the script header.
  N for the three fits (`outputs/hours_lee_bounds_table.csv`, `n_obs`): point 242,552; lower 241,166; upper 241,167 (1,386 and 1,385 rows trimmed).
- **95% Imbens–Manski CI for the identified set: [1.021, 5.324]**, `c_α = 1.839787` — excludes
  zero. Recomputed 2026-09-21 by sourcing `scripts/imbens_manski_ci.R`; **not in any CSV**.
  - ⚠ **Historical note worth keeping.** Between the harmonization and the selection-rate fix, the
    bounds briefly *inverted* (lower 3.30763 above upper 3.30592 — an empty identified set), which
    silently tripped the degenerate branch in `imbens_manski_ci()` and returned a plain
    `c_α = 1.96` instead of a root-found one. Defining `s_ab` on the observed-hours sample fixed
    both the ordering and the critical value. If a future change makes the bounds cross again,
    that is the symptom to look for.

### 1.5 [PRIMARY — **OUT OF SCOPE, DO NOT DRAFT**] Second-stage occupation-level mechanism regression

> **Scope decision (2026-09-15):** this regression is **not** to be drafted into the paper's
> results section. It is not one of the three core models (hours DiD, hours DDD, employment
> DiD/DDD), and its underlying data is not verifiably exported (see the ⚠ below and §7 item 1).
> Recorded here for completeness only. Note this also removes the Jewish/Arab mechanism-slope
> numbers in §3.3(b) from anything the paper can cite directly — §3.3's conclusion should rest on
> (a) the z-test and (c) the occupational-concentration argument, referring to (b) only as an
> unexported internal check if at all.

- **Function:** inside `run_hours_ddd_regression()` (Model 2): per-occupation `Mother:Post` from
  `run_intensive_margin_reg()` on that occupation's rows (β_j, se_j), then
  `lm(beta_j ~ wfh_exposure, weights = 1/se_j^2)`.
- **Result:** slope = **2.198 (SE 0.907), p = 0.021**, R² = 0.144, n = 37 occupations (3 of 40
  dropped for degenerate fits). Source: `outputs/hours_mechanism_data.csv` (refit verifiable from
  disk; see below).
  - ✅ **Resolved 2026-09-20 (Checkpoint 12).** `main.R` §8e now exports the real frame as
    `outputs/hours_mechanism_data.csv`, and refitting from it gives **slope 2.1977, SE 0.9068,
    p = 0.0207, R² = 0.1437, n = 37** — verifiable from disk.
  - ⚠️ **Corrected 2026-09-21.** The figures above previously read 2.639 / SE 0.899 / p 0.006 /
    R² 0.197, which predate the hours-population harmonization
    (`docs/decisions/hours-population-harmonization.md`). Note the p-value moves across the 1%
    threshold: the effect is significant at 5%, not at 1%. §3.3's table below already carried the
    corrected row. The previously-cited
    `ddd_calibrated_mechanism_data.csv` (since deleted) was **stale** (committed 2026-09-11 by the
    removed employment-outcome `ddd_regression.R`; its `beta_j` values are in
    employment-probability units, −0.19 to +0.13, not hours) and should not be used. Note this
    closes the *data* gap only: the scope decision above is unchanged, and this regression is
    still not to be drafted into the paper.

### 1.6 [PRIMARY] Exposure-measure sensitivity (same formula, different occupation index)

| Exposure measure | `Mother x Post x WFH_Exposure` | SE | Sig. | N | Source |
|---|---|---|---|---|---|
| Calibrated (primary) | 3.224 | 1.022 | ** | 246,326 | `outputs/ddd_hours_table.csv` |
| External (Dingel–Neiman, `tele_ext`) | 0.6720 | 0.8838 | (ns) | 246,326 | `outputs/ddd_hours_external.csv` |
| Realized (2021-anchored, `min_n = 200`) | 5.195 | 2.363 | * | 246,037 | `outputs/ddd_hours_realized.csv` |

Framing: "directionally robust, not point-estimate robust." The external index stays positive and
insignificant, which is the form the paper's "measurement is part of the result" argument needs —
the mechanism is visible only once exposure is measured as Israeli jobs were actually done.

**Added 2026-09-22 (editorial audit, `paper/notes/editorial-audit-2026-09-22.md` step 2).** Three
more rows in the paper's robustness table, all from `run_hours_ddd_regression()` call sites in
`main.R` §8a with no new econometric machinery:

| Specification | `Mother x Post x WFH_Exposure` | SE | Sig. | N | Source |
|---|---|---|---|---|---|
| Unswapped occupations only (30 of 40; calibrated == external on these rows) | 4.309 | 1.192 | ** | 132,046 | `outputs/ddd_hours_unswapped.csv` |
| Excluding survey year 2023 | 2.979 | 1.170 | * | 208,833 | `outputs/ddd_hours_ex2023.csv` |
| Two-way clustering (IDPUF + occupation), same fit | 3.224 | 1.022 | ** | 246,326 | `outputs/ddd_hours_twoway_cluster.csv` |

The plain hours DiD without 2023 is 0.0710 (SE 0.1975), N = 213,385
(`outputs/intensive_margin_ex2023.csv`). The unswapped row is the direct answer to "the result
appears only once post-period data enter the regressor": on the thirty occupations where no
post-period information enters, the estimate is larger, not smaller. All ten swaps are downward
(`outputs/wfh_exposure_calibrated.csv`, `swap == TRUE`).

Two descriptives were added at the same time. `outputs/wfh_share_by_year.csv`: realized WFH among
employed women 25–59, usual location 15.7% / 13.0% / 12.7% (2021/2022/2023) and reference-week
21.3% / 21.9% / 22.2% (denominator: those at work that week); NA before 2021 by construction.
`outputs/absence_by_exposure_quartile_by_quartile.csv`: reference-week absence 14.4% / 8.5% /
9.5% / 9.6% from Q1 to Q4 of the occupation-level index (the `by_cell` file splits by Mother ×
Post; mothers' Q4 share falls 12.1% → 10.4% while Q1 rises 15.5% → 16.9%). The dose-response frame
`outputs/hours_dose_response_data.csv` gained `mean_exposure` (Q1 0.060, Q4 0.592), which gives
the paper's implied Q4−Q1 effect of 3.224 × 0.531 = 1.71 hours against the raw 1.87.

### 1.7 [PRIMARY] Age-balance robustness (hours DDD)

Source: `outputs/age_balance_robustness_hours_ddd_age_interacted.csv`,
`outputs/age_balance_robustness_hours_ddd_reweighted.csv` (produced with
`RUN_AGE_BALANCE_ROBUSTNESS <- TRUE`, which is now the default; `docs/hours-intensive-margin-analysis.md` §3).

| Spec | `Mother x Post x WFH_Exposure` | SE | Sig. | N |
|---|---|---|---|---|
| Primary | 3.224 | 1.022 | ** | 246,326 |
| Age-interacted (`+ Mother:GilNK`) | 3.205 | 1.055 | ** | 246,326 |
| Reweighted (pre-period `GilNK` raking) | 2.597 | 1.050 | * | 242,552 |

⚠ **The reweighted spec is now significant at 5%, not 1%** — any text saying "still significant at
the 1% level" is false and has been corrected in `paper.tex`. Attenuation is **19.4%**
(1 − 2.597/3.224), up from ~17%, and at 2.597 the estimate sits only narrowly above the MDE of
2.864. The paper now reads this as "robust to age imbalance in direction and approximate
magnitude, not insensitive to it", and flags it as the largest single move any check produces.

Incidental finding (age-interacted spec): `Mother x GilNK4` = −2.266*** (0.5058); `GilNK5` −1.150*
(0.4759); `GilNK6` 0.4192 (ns); `GilNK7` 0.9627 (0.5566, 10% only). The profile now reads as
rising from group 4 to group 7 with only groups 4 and 5 significant — the earlier
"significant, non-monotonic" characterisation no longer fits.

Underlying imbalance (`outputs/age_balance_robustness_age_imbalance_by_quartile.csv`, pre-period
mean `GilNK` gap Mother − non-Mother by cell-exposure quartile): Q1 −0.974 (t = −94.0), Q2 −0.735
(t = −62.8), Q3 −0.169 (t = −12.0), Q4 +0.057 (t = 5.0).
⚠ `docs/hours-intensive-margin-analysis.md` §1 quotes "−0.797 … to +0.239" and `docs/HLD.md` §4.2
quotes "~0.8, t≈−81"; the current CSV says −0.974 / +0.057. The docs appear to predate the
`BirthContinent` change to the exposure cells (which shifts quartile membership). Cite the CSV.

### 1.8 [PRIMARY] Pre-trend / event study (hours)

`outputs/hours_diagnostics_pretrend_table.csv` (`WorkHoursCont`, reference-week workers,
`Mother x ShnatSeker`, ref = 2019, cluster `IDPUF`, N = 251,857):

| Year | Coef | SE | Sig. |
|---|---|---|---|
| 2017 | **0.3515** | 0.2570 | (ns) |
| 2018 | 0.2013 | 0.2191 | (ns) |
| 2021 | 0.3923 | 0.2612 | (ns) |
| 2022 | 0.1213 | 0.2654 | (ns) |
| 2023 | 0.7517 | 0.2650 | ** |

(`Mother` main effect in the same model: −1.930, SE 0.1963, ***.)

Joint Wald test on 2017+2018: **F(2, 63,198) = 0.949, p = 0.387 — DOES NOT REJECT.** Same test on
the employment outcome: F(2, 79,069) = 0.63, p = 0.53 (unchanged; employment is unaffected by the
hours fix). Both are exported: `outputs/pretrend_wald_hours.csv` and
`outputs/pretrend_wald_employment.csv`. Full precision: 0.948655498493358
(p 0.387266861630637) and 0.630649732652335 (p 0.532248548305119).

**This is the single largest change in the digest, and it reverses a stated limitation.** The
2017 coefficient was −1.524*** and the joint test rejected at p = 5.2e-11, on the strength of
which the paper confined parallel trends to a 2018–2019 window. That was an artifact: the 2017
CBS file recorded zero usual hours for the employed-but-absent, a population that is
mother-skewed (12.4% of employed mothers vs 7.3% of childless women), so the spurious zeros
depressed mothers' 2017 hours specifically. Harmonizing the hours population on reference-week
work removes both the artifact and the apparent violation. **Parallel trends now hold on both
margins over the full 2017–2019 pre-period**, and §5.4's verbatim caveat below is obsolete.

Robustness of that claim: re-fitting post-harmonization on `ShnatSeker != 2017` moves the hours
DiD by 0.44 SE (0.2280 → 0.3072) and the DDD by 0.15 SE (3.2240 → 3.3769), so 2017 now behaves
like any other pre-period year rather than merely being less contaminated.

### 1.9 [PRIMARY] Descriptive figures — §4 of the paper

Added 2026-09-21. These numbers back `paper.tex` §4.2–§4.4 and had no section in this digest
before; their only upstream record was `docs/decisions/paper-figure-layer.md`.

**Raw 2×2** (`outputs/hours_descriptives_hours_by_period.csv`, `_raw_did.csv`), reference-week
workers:

| Group | Pre-2021 | n | Post-2021 | n | Change |
|---|---|---|---|---|---|
| Childless | 40.039 | 50,144 | 40.079 | 43,838 | +0.040 |
| Mothers | 38.539 | 88,114 | 38.844 | 76,079 | +0.305 |

Raw DiD = **0.2658, SE 0.1810**, 95% CI [−0.0890, 0.6206].

> **All standard errors in this section are clustered by IDPUF as of 2026-09-21.** They previously
> used independent-observations formulas — `sd/sqrt(n)` for a cell mean, `sqrt(se_a² + se_b²)` for
> a difference, `sqrt(p(1−p)/n)` for a rate — which understated them by **~1.8× (hours)** and
> **~2.0× (employment rates)**, because the LFS observes each respondent about four times overall
> and two to three times within a single year. **Point estimates did not move**: every quantity
> here is a saturated difference in means, so `feols` reproduces the same arithmetic. See
> `scripts/clustered_se.R`. The by-year and dose-response tables below carry the corrected SEs.

**Mother-minus-non-mother gap by year** (`outputs/hours_descriptives_hours_by_year.csv`):

| Year | Gap | SE |
|---|---|---|
| 2017 | −1.373 | 0.1839 |
| 2018 | −1.482 | 0.1866 |
| 2019 | −1.672 | 0.1823 |
| 2021 | −1.368 | 0.1873 |
| 2022 | −1.533 | 0.1923 |
| 2023 | −0.796 | 0.1922 |

The pre-period is flat within about a third of an hour — the descriptive counterpart of §1.8's
passing Wald test. Pre-harmonization the 2017 gap read −3.30; that value survives in the paper only
as an explicit description of the artifact, never as a current figure.

**Dose-response by exposure quartile** (`outputs/hours_dose_response_data.csv`), raw DiD within
each quartile of the **occupation-level calibrated** measure:

| Q | Exposure range | Raw DiD | SE | n |
|---|---|---|---|---|
| 1 | 0.000–0.097 | −0.3171 | 0.3950 | 61,571 |
| 2 | 0.097–0.143 | 0.2700 | 0.3228 | 66,612 |
| 3 | 0.143–0.300 | −0.0186 | 0.3297 | 74,911 |
| 4 | 0.300–0.750 | **1.5514** | 0.4143 | 48,874 |

Q4 95% CI [0.7395, 2.3634]. **Three quartiles are indistinguishable from zero and one is not** —
this is the non-parametric version of §1.3's argument, and it is why §1.1's average is near zero.
⚠ The Q2/Q3 breakpoint moved (0.1230 → 0.1431) because `hours_dose_response.R` computes quartile
breaks *after* filtering on non-missing hours, so at least one occupation changed quartile.
Pre/post-fix quartile values are therefore **not** a like-for-like comparison. This does not affect
`compute_pre_period_quartile_breaks()`, which is hours-independent and whose quartiles are stable.

---

## 2. SECONDARY — Extensive margin (employment)

### 2.1 [SECONDARY] Employment DiD (pooled)

- **Function / file:** `basic_reg()`, `scripts/basic_regression.R`
- **Formula (verbatim):** `Employed ~ Mother + Post + Mother:Post + MatzavMishpachti + Dat + GilNK + MachozMegurim + TeudaGvoha`
- **Sample:** full `cleaned_df` (employed + non-employed); **cluster:** `~IDPUF`
- **Source:** `outputs/basic_reg_table.csv`

| Term | Coef | SE | Sig. |
|---|---|---|---|
| `Mother x Post` | **−0.0053** | 0.0052 | (ns) |
| `Mother` | −0.0034 | 0.0041 | (ns) |
| `Post` | 0.0153 | 0.0043 | *** |
| Constant | 0.4926 | 0.0085 | *** |

- **N = 364,784**; R² = 0.22689.
- Baseline employment rates (`outputs/comparative_stats_emp_by_mother.csv`): non-mothers 0.7574
  (n 133,646); mothers 0.7828 (n 239,095); pooled ≈ 0.7737 (n 372,741).

### 2.2 [SECONDARY] Employment DDD (cell-based exposure)

- **Where:** inline in `main.R` §8b (no separate script). Two specs.
- **Spec 1 formula (verbatim from `main.R`):**
  `Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK + MatzavMishpachti + Dat + GilNK + MachozMegurim + TeudaGvoha`
- **Spec 2 formula:** `Employed ~ Mother * Post * WFH_Exposure + Mother:GilNK + MatzavMishpachti + Dat | GilNK^TeudaGvoha^MachozMegurim`
- **Cluster (both):** `~GilNK^TeudaGvoha^MachozMegurim` (~210 clusters).
- **Exposure:** `build_exposure_cells()` (`scripts/wfh_exposure_cells.R`) — pre-period (2017–19)
  `MishkalSofi`-weighted mean of the calibrated occupation score within cells defined by
  `exposure_cell_vars = c("Min","GilNK","TeudaGvoha","MachozMegurim","MatzavMishpachti","Dat","BirthContinent")`
  (7 vars, 8,884 cells; `main.R` §8 and `docs/decisions/exposure-cell-granularity-fix.md`
  "Update: adding BirthContinent"). Defined for non-employed rows too. Join unmatched: 9,962 rows
  (2.67%) per that memo.
- **Source:** `outputs/ddd_employment.csv`

| Term | Spec 1 (additive) | Spec 2 (cell FE) |
|---|---|---|
| **`Mother x Post x WFH_Exposure`** | **−0.0257 (0.0725)** (ns) | **−0.0194 (0.0722)** (ns) |
| `Mother x Post` | 0.0065 (0.0168) | 0.0044 (0.0166) |
| `Mother x WFH_Exposure` | −0.1404. (0.0803) | −0.0818 (0.0702) |
| `Post x WFH_Exposure` | −0.1555** (0.0566) | −0.1516** (0.0554) |
| `WFH_Exposure` | 0.0131 (0.0565) | 0.0056 (0.0490) |
| `Mother x GilNK5` | 0.0311* (0.0144) | 0.0453** (0.0141) |
| `Mother x GilNK6` | 0.0301* (0.0142) | 0.0447** (0.0138) |
| `Mother x GilNK7` | 0.0226 (0.0167) | 0.0341* (0.0164) |
| N | 355,984 | 355,984 |
| R² | 0.22103 | 0.22952 (within 0.07043) |

Spec 1 runtime collinearity (`check_spec1_collinearity()`, console; quoted in
`docs/decisions/exposure-cell-granularity-fix.md`): R² of `WFH_Exposure` on `cell_fe_vars` = 0.285,
VIF = 1.40 (7-var cells). `WFH_Exposure`'s main effect is **not** dropped in Spec 2 (confirmed).

### 2.3 [SECONDARY] "Underpowered, not null" — MDE record

Source chain: `docs/decisions/null-vs-power-audit.md` (diagnosis, pre-fix numbers) →
`docs/decisions/exposure-cell-granularity-fix.md` (fix + current numbers) →
`docs/decisions/hours-ddd-pivot.md` (resolution = pivot). MDE formula: `SE × 2.8016`
(`scripts/ddd_mde_diagnostics.R`, α = 0.05, power = 0.80). Baseline employment rate 0.7737.

| Design stage | Spec | Point est. | SE | MDE | MDE / baseline | MDE / |point| | Source |
|---|---|---|---|---|---|---|---|
| Original (4-var cells = FE) | 1 | 0.1033 | 0.1419 | 0.3975 | 51.4% | 3.8× | null-vs-power-audit.md B2 |
| Original | 2 | 0.1309 | 0.1399 | 0.3920 | 50.7% | 3.0× | same |
| +MatzavMishpachti+Dat (6-var) | 1 | −0.0331 | 0.0890 | 0.2494 | 32.2% | 7.5× | granularity-fix.md "Post-fix numbers" |
| +… (6-var) | 2 | −0.0260 | 0.0881 | 0.2469 | 31.9% | 9.5× | same |
| **+BirthContinent (7-var, CURRENT)** | 1 | **−0.0257** | **0.0725** | **0.2031** | **26.3%** | **7.9×** | granularity-fix.md "Post-change numbers"; matches `outputs/ddd_employment.csv` |
| **CURRENT** | 2 | **−0.0194** | **0.0722** | **0.2022** | **26.1%** | **10.4×** | same |

> **The "% of baseline" column is a per-UNIT figure and overstates the shortfall (added
> 2026-09-19).** The MDE is a coefficient: an effect per one unit of `WFH_Exposure`. On the
> estimation sample that regressor has SD 0.0706, IQR 0.0766, and never spans a unit, so
> comparing the per-unit MDE to the baseline employment rate answers a question the data cannot
> pose. Correctly scaled, and now exported in
> `outputs/null_vs_power_audit_mde_{additive,fe}.csv`: **MDE per SD = 0.0143 (1.43 pp, 1.85% of
> baseline); per IQR = 0.0156 (1.56 pp, 2.01%).** Against `harrington2025`'s ~0.78 pp per 10%
> rise in WFH, the design is underpowered by roughly 2–3x, not the 8–10x a reader infers from
> "26% of baseline". **The `MDE / |estimate|` column is a ratio, is scale-invariant, and is
> unaffected — it remains the basis for the "uninformative, not null" verdict.**
>
> Fixes tested and rejected (none rescues the design; it is structural): clustering on the
> exposure cell rather than the coarse FE cell moves the SE 0.0725 → 0.0711; the combined margin
> (hours incl. zeros) leaves the triple interaction at 0.45 of its own MDE; a one-sided test buys
> 11%; finer cells were already exhausted over two rounds (51% → 32% → 26%).

- **Verbatim verdict** (`null-vs-power-audit.md`, "Verdict"): "**Underpowered, not a genuine
  null.** The null `Mother:Post:WFH_Exposure` result is not informative about whether a
  WFH-exposure-driven motherhood employment effect exists — the design could not have detected a
  real effect unless that effect were implausibly large."
- **Verbatim, current design** (`exposure-cell-granularity-fix.md`, "Post-change numbers"): "Still
  well inside the (now smaller, but still substantial) MDE — this remains an
  underpowered-not-informative result … not a newly-significant finding."
- ⚠ `docs/decisions/hours-ddd-pivot.md` "Motivation" and `docs/hours-intensive-margin-analysis.md`
  §4 say the MDE is "roughly 4x the point estimate". The 4× ratio belongs to the *original* design
  (0.3975/0.1033). With current numbers the MDE is ~8–10× the point estimate. The "26% of baseline"
  figure is correct for the current design.
- **First-stage relevance** (`outputs/null_vs_power_audit_wfh_first_stage_table.csv`, `Post==1`
  only, N = 110,051, cluster on `cell_fe_vars`): `WFH_Exposure → WFH_RefWeek` = 0.6557*** (0.0954)
  level spec; dynamic spec 0.6397*** (0.0987), `× 2022` = 0.0118 (ns), `× 2023` = 0.0379. (p<0.1).
  (The memos quote 1.787 / 0.9313 for earlier cell designs; the CSV is the current 7-var design.)
- **Rejected power fixes** (`exposure-cell-granularity-fix.md`): occupation-level exposure for the
  employment outcome (conditions the outcome on itself; the removed robustness specs showed ~9.7×
  tighter SE but 17.4% of sample dropped non-randomly); cell-level WLS aggregation (algebraically
  identical to the individual regression — point estimates matched to 12 decimals, no SE gain).

---

## 3. Jewish / Arab subgroup splits

Split variable: `Leom == 1` (Jewish) / `Leom == 2` (Arab). Same functions, same formulas, filtered
input (`main.R` §5 and §8a).

### 3.1 [SECONDARY] Employment DiD by group

| Group | `Mother x Post` | SE | Sig. | N | Source |
|---|---|---|---|---|---|
| Pooled | −0.0053 | 0.0052 | (ns) | 364,784 | `outputs/basic_reg_table.csv` |
| Jewish women | −0.0041 | 0.0058 | (ns) | 283,975 | `outputs/basic_reg_jewish_table.csv` |
| Arab women | −0.0208 | 0.0138 | (ns) | 65,598 | `outputs/basic_reg_arab_table.csv` |

Other terms — Jewish: `Mother` 0.0054 (0.0045), `Post` 0.0070 (0.0049), Constant 0.5920***
(0.0119), R² 0.04336 (adj. 0.04328). Arab: `Mother` 0.0200. (0.0110), `Post` 0.0601*** (0.0111),
Constant 0.6300*** (0.0582), R² 0.24314 (adj. 0.24286). (Constant/R² added 2026-09-15 from the
same two CSVs.)
**Footnote for the paper (near the subgroup results; no further investigation — resolved
2026-09-15):** The Jewish-women tables (employment *and* hours) contain no `Dat` coefficients at
all, while the Arab tables have `Dat2–Dat4` only, so the religiosity control's coding (and hence
the effective control set) may differ by subgroup; the stratified estimates should be read with
that caveat. Suggested footnote text: *"The religiosity control (`Dat`) is not identified within
the Jewish-only subsample and enters with fewer categories in the Arab-only subsample, so the
effective control set differs slightly across the stratified models."*

### 3.2 [PRIMARY] Hours DiD and DDD by group

Point estimates (4 s.f.) from `outputs/hours_did_subgroup_comparison_data.csv` and
`outputs/hours_ddd_subgroup_comparison_data.csv`; N from the per-group `etable` CSVs.

| Subgroup | DiD `Mother:Post` | SE | 95% CI | N (DiD) | DDD `Mother:Post:WFH_Exposure` | SE | 95% CI | N (DDD) |
|---|---|---|---|---|---|---|---|---|
| All women (primary) | 0.2280 (ns) | 0.1809 | [−0.1266, 0.5825] | 251,857 | 3.2240** | 1.0223 | [1.2204, 5.2277] | 246,326 |
| Jewish women | 0.3021 (ns) | 0.2027 | [−0.0952, 0.6994] | 214,449 | 2.8465** | 0.9125 | [1.0579, 4.6351] | 209,727 |
| Arab women | −0.0724 (ns) | 0.4785 | [−1.0103, 0.8656] | 24,975 | 5.5069* | 2.6741 | [0.2657, 10.7481] | 24,307 |
| Men (placebo) | −0.4002* | 0.1883 | [−0.7692, −0.0311] | 261,543 | −1.7620 (.) | 1.0153 | [−3.7519, 0.2279] | 251,779 |

**Neither women's subgroup shows an average effect any more; both show an exposure gradient.** The
"Jewish women carry the pooled DiD" framing is obsolete — the Jewish DiD (0.3021, SE 0.2027) is
itself insignificant. What Jewish women carry is the pooled **DDD**.

Per-group table sources: `outputs/intensive_margin_jewish_table.csv`,
`outputs/intensive_margin_arab_table.csv`, `outputs/ddd_hours_jewish_table.csv`,
`outputs/ddd_hours_arab_table.csv`, `outputs/hours_gender_placebo_did_table.csv`,
`outputs/hours_gender_placebo_ddd_table.csv`. Other notable terms: Arab hours DiD `Post` =
**−2.162*** (0.3903)** (Arab women's hours fell post-2021 overall); Jewish hours DiD `Post` =
0.1101 (0.1688, ns).

**Sample-size gap:** Jewish 209,727 vs Arab 24,307 in the DDD (≈ 8.6×); 214,449 vs 24,975 in the
DiD. Arab DDD SE (2.674) is ≈ 2.9× the Jewish SE (0.913).

⚠ The men's DDD is now marginally significant at the 10% level (`.`), where it was flatly
insignificant before. It is still negative and still opposite-signed, so the placebo argument on
the DDD is unaffected in substance — but do not write "insignificant" without the qualifier.

### 3.3 Arab (5.507) vs Jewish (2.847): why we do not claim heterogeneity

Verdict: **small-sample / thin-occupational-coverage fragility, NOT a documented heterogeneous
treatment effect.** Three arguments, all from §5.2:

(a) **Not statistically distinguishable.** Two-sample z (disjoint samples, covariance exactly zero):
`z = (5.5069 − 2.8465) / sqrt(2.6741² + 0.9125²) = 2.6604 / 2.8255 = 0.942, p = 0.346`. Same test on
the DiD: z = −0.720, p = 0.471 — now NEGATIVE, since the Arab DiD point estimate sits below the Jewish one. Both DiDs are indistinguishable from zero (Arab −0.0724, SE 0.4785; Jewish 0.3021, SE 0.2027).
(Arithmetic re-checked from the CSV values: ✓.)

(b) ~~**The Arab DDD's own mechanism check contradicts its sign.**~~ **WITHDRAWN — this argument
reversed when the slopes were recomputed 2026-09-21.** All three second-stage slopes, current:

| Subgroup | Slope | SE | t | p | R² | n | Dropped |
|---|---|---|---|---|---|---|---|
| Full sample | +2.198 | 0.907 | 2.42 | 0.021 | 0.144 | 37 | 3 (ISCO 62, 63, 95) |
| Jewish women | +3.571 | 2.365 | 1.51 | 0.140 | 0.061 | 37 | 3 (ISCO 62, 63, 95) |
| Arab women | **+7.572** | 2.383 | 3.18 | 0.004 | 0.305 | 25 | 15 (37.5%) |

The Arab slope was **−19.29 (SE 7.04), p = 0.011, n = 26** before the harmonization — significantly
*negative*, which is what made this the strongest of the three objections. It is now significantly
*positive* and consistent in sign with the Arab DDD itself (+5.507), so the within-subgroup check
**corroborates** the Arab estimate rather than contradicting it. The Jewish slope moved the other
way, from a marginal +2.148 (p = 0.067) to an insignificant +3.571 (p = 0.140) with roughly double
the SE. Both subgroup slopes are positive; neither is well identified.

That a slope can swing from −19.29 to +7.572 is itself the most useful thing here: it says these
subgroup mechanism regressions, fitted on 25–37 occupation-level points, are not stable enough to
adjudicate anything. Still console-only (no CSV) — recomputed by reproducing `main.R:325-328`.

(c) **Mechanical cause — occupational concentration.** The 35% occupation dropout for Arab women vs
7.5% for Jewish/full sample is consistent with Arab women's employment being concentrated in
education and health-aide occupations; with only 26 informative occupations, a few high-leverage
ones can flip the mechanism slope.

Conclusion (restated post-2026-09-21 with current numbers; the original §5.2 wording quoted the
pre-fix 6.006 / 2.924 pair): report the Arab DDD point estimate (**5.507\***, nominally significant
on its own one-sample test) transparently, but do **not** characterize it as evidence that the
WFH-exposure mechanism is stronger for Arab women than for Jewish women. The Jewish-women estimate
(**2.847\*\***) is the more credible of the two ethnicity-specific results and should anchor any
subgroup claim the paper makes. The argument is unchanged by the fix — the gap narrowed slightly
(2.66 rather than 3.08 raw) and the z-test moved from 1.105 to 0.942, both comfortably short of
significance.

### 3.4 Gender placebo (hours) — §5.3 of the same doc

**The placebo now splits by margin, and the paper reports the two halves differently.** Recomputed
2026-09-21 from the subgroup CSVs: **DDD** all women vs men **z = 3.461, p = 0.0005**; **DiD**
**z = 2.406, p = 0.0161**. Men's DiD `Father:Post` = **−0.4002\*** (SE 0.1883); men's DDD
**−1.7620** (SE 1.0153), negative and significant at the 10% level only.

- **On the DDD the placebo does its job**, and more than the minimum: fathers show no positive
  WFH-linked hours response, the point estimate is negative, and the two coefficients are
  distinguishable. A macro trend common to all workers cannot produce a positive exposure gradient
  for mothers alongside a negative one for fathers. This is where the paper's mechanism claim rests.
- **On the plain DiD the placebo is ADVERSE and the paper says so explicitly.** Fathers move
  −0.4002 (SE 0.1883) against mothers' insignificant 0.2280 (SE 0.1809) — the placebo is *larger in
  magnitude and more significant than the treatment estimate*. The z-test still rejects, but for
  the wrong reason: the difference is manufactured by the fathers' coefficient, not the mothers'.
  A parenthood-common trend (parents of both sexes losing hours relative to non-parents, mothers by
  less) is a live alternative on this margin. The paper concedes this in `sec:res-subgroup` and
  frames it as a consistency check — the placebo agrees the female DiD is nothing — rather than
  leaving a referee to compute it.
- ⚠ **Do not reuse the old "the placebo strengthens it" framing unqualified.** It was written when
  the female DiD was 0.8261*** and the male −0.3860*, so "opposite signs, both meaningful" held.
  It no longer does on the DiD margin.

**All six z-tests, recomputed 2026-09-21** from the current subgroup CSVs:

| Comparison | DiD | DDD |
|---|---|---|
| All women vs men | z = 2.406, p = 0.0161 | z = 3.461, p = 0.0005 |
| Jewish vs men | z = 2.538, p = 0.0111 | z = 3.376, p = 0.0007 |
| Arab vs men | **z = 0.637, p = 0.524 (ns)** | z = 2.541, p = 0.0110 |
| Arab vs Jewish | z = −0.720, p = 0.4712 | z = 0.942, p = 0.3464 |

⚠ **The Arab-vs-men DiD is no longer significant** (was not separately reported pre-fix). So the
old blanket claim that "every female subgroup is statistically distinguishable from the male
placebo on both margins" is false — it holds on the DDD for all three, and on the DiD for the
pooled and Jewish samples only. Stated placebo limitations (§5.3): no
second-stage mechanism regression exists for men; men's labor supply has unmodeled institutional
drivers (reserve duty, retirement timing); the test compares independently-fit models rather than a
joint `× Sex` specification. **Update 2026-09-19: the employment-outcome gender placebo now runs.** `run_gender_placebo()` is
called unconditionally by `main.R` and exports `outputs/gender_placebo_did_table.csv` and
`gender_placebo_ddd_table.csv`. Results, men with `Mother` read as `Father`: DiD
`Mother:Post` = 0.0077 (SE 0.0054); DDD `Mother:Post:WFH_Exposure` = 0.0444 (SE 0.0833) additive
and 0.0661 (SE 0.0849) with cell FE. All insignificant, which is the direction a placebo should
go. **Decided 2026-09-19: deliberately NOT reported in the paper.** The hours placebo does the
falsification work for the primary specification, and the employment placebo sits on a margin the
paper itself establishes as underpowered (§2.3), so reporting its null as corroboration would
repeat, in the placebo, the error the paper is careful to avoid in the main result. The artifacts
are kept in `outputs/` for completeness and because the pipeline produces them; their absence from
the paper is a choice, not an oversight. Note that the
employment DDD is underpowered in its own right (§2.3), so a null placebo on that margin is
uninformative in the same way the main employment DDD is, and should not be presented as
corroboration without that caveat.

---

## 4. Treatment timing and exposure-anchor rationale

### 4.1 Post = 2021–2023 vs. 2017–2019; 2020 excluded

- `docs/motherhood_penalty_wfh_research.md` **Part 4 §1**, verbatim: "**Timeframe:** 2017–2019
  (Pre-COVID baseline) and 2021–2023 (Post-COVID period)." Part 4 §2: "**Time Variable
  ($Post_t$):** A dummy variable equal to 1 for the post-COVID period (2021–2023)." — Part 4 §1
  itself gives **no explicit reason** for dropping 2020; the reasons live elsewhere in the same doc:
  - Part 1 §V: "The year 2020 is excluded as it is considered a transitional year."
  - Part 2 §1: "$\text{Post}_t$ … capturing the structural shift toward remote work, equal to 1 for
    the post-pandemic period (2021-2023) and 0 for the pre-pandemic baseline (2017-2019). The
    transitional year of 2020 is explicitly excluded from the data."
- **COVID-driven WFH-shift motivation** — Part 1 §III: "Working from home surged from approximately
  5% of total workdays to 25-30% after the pandemic." Mechanisms listed: reduced commute friction,
  time flexibility, shifting organizational norms, location flexibility (narrowing); reduced
  visibility, slower advancement, new stigmas (widening). Direction is treated as an empirical
  question (`README.md` "Why remote work might change it").
- **Additional, data-driven reason** (not in the research doc): no 2020 raw CBS extract exists for
  this project at all — `docs/decisions/checkpoint6-wfh-anchor-year.md` "The problem"; `README.md`
  "Data → Sample"; `docs/HLD.md` §3 step 2. `validate_cleaned_df()` hard-fails on any 2020 row.
- **Post-period shape** (§1.8 above): effect rises gradually, significant only by 2023 — the
  narrative doc §4 reads this as a multi-year adjustment, not an instantaneous 2020–21 shock.

### 4.2 Disclosed deviation: WFH-exposure index anchored to 2021, not 2020

Source: `docs/decisions/checkpoint6-wfh-anchor-year.md` (Status: DECIDED — Path B).

- **Original spec** (research doc Part 4 §4, verbatim): "This index will be constructed using the
  **2020** CBS work-from-home variable to measure actual 'WFH Exposure'."
- **Why it could not be followed:** "there is no `2020_Data.csv` … at all. This isn't a filtering
  choice that can be reversed in code — the raw 2020 extract was never acquired."
- **Decision:** "Path B: 2021 is the WFH-exposure anchor year … `build_wfh_exposure_index()` will
  default `ref_year = 2021`." (`main.R` §8(c) calls it with `ref_year = 2021, min_n = 200`.)
- **Stated justification (Pros of Path B):** no new data acquisition — 2021 already passes the full
  validated pipeline; and "2021 is arguably a *more stable* measurement point than 2020 … a WFH
  measure taken during 2020's emergency/ad-hoc disruption might reflect improvisation rather than
  each occupation's settled remote-work potential."
- **Stated downside (Cons of Path B, verbatim):** "This is a genuine, documented deviation from the
  research doc's literal specification … should be disclosed and justified in the paper's methods
  section"; and "Conceptually measures a different quantity than what Part 4 §4 describes: by 2021,
  occupations had already had a year to adapt their WFH practices in response to the 2020 shock. If
  adaptation was uneven across occupations … a 2021-based index could rank occupations' 'exposure'
  meaningfully differently than a 2020-based one would have."
- **Where the 2021-anchored index is actually used now:** only as the *realized* robustness
  variant (§1.6, coef 6.416*). The primary hours DDD uses the *calibrated* index, which draws on
  realized **2022–23** data (not 2021) for its swap test — itself a "documented compromise, not a
  fully pre-treatment measure" (`docs/decisions/calibrated-exposure-and-cell-ddd.md`, measure 2).
  The secondary employment DDD's cell measure is built from 2017–19 occupational composition
  weighted by the calibrated score.

---

## 5. Limitations (verbatim)

### 5.1 `README.md` — "Known limitations" (snapshot as of 2026-09-19; `README.md` has since been rewritten — check it for the current wording, which now enumerates four legitimate `weights =` uses rather than one — the fourth, added 2026-09-22, is the occupation-cell-size weight in `build_wfh_occupation_first_stage()`)

> - **Survey weights are intentionally not applied in any regression.** CBS weight columns
>   (`MishkalSofi`, `MishkalShnati`, etc.) exist in the raw data and are deliberately excluded from
>   every regression in this repo (`basic_reg()`, the intensive-margin/DDD models, the pretrend
>   model, etc.) — this is a scope decision, not an oversight, and should not be "fixed" without a
>   separate discussion. Reported rates and regression coefficients are unweighted estimates on the
>   analysis sample, not population-representative statistics. (The one exception is
>   `build_exposure_cells()` in `wfh_exposure_cells.R`, which does weight by `MishkalSofi` when
>   aggregating occupation exposure up to demographic cells — that weighting is internal to building
>   the exposure regressor, not a survey-representativeness correction for the outcome regressions
>   themselves.)
> - The WFH-exposure index and age controls both deviate from the research doc's literal
>   specification, as documented decisions (see `docs/decisions/`), because the raw CBS extract
>   lacks a 2020 file and any continuous age/birth-year variable.

### 5.2 `docs/HLD.md` §4.2 "Known limitations & deliberate decisions" (snapshot as of 2026-09-19, Notes column; see the erratum below the table and `docs/HLD.md` for current wording)

| Item | Notes (verbatim) |
|---|---|
| Survey weights (`MishkalSofi`, etc.) are not applied in any outcome regression | Deliberate, not an oversight — do not add without raising it first. `build_exposure_cells()` is the one exception (weights the exposure regressor's own construction, not a survey-representativeness correction). A second, not-yet-approved exception (`robustness/phase2_robustness.R`'s `run_ddd_weights_check()`) was removed along with that file — see `docs/decisions/employment-ddd-robustness-removal.md`. |
| Lee (2009) bounds only handle excess selection in one direction | Under-selection in the `Mother==1,Post==1` cell isn't addressed by this construction. As of the 2026-09-09 audit fix, the bounds also report a per-model SE/CI and an Imbens-Manski (2004) CI for the identified set, not just bare point estimates. The hours-DDD pivot generalizes this same machinery to the triple-interaction (`Mother x Post x WFH_Exposure`) specification, stratifying the selection counterfactual by cell-based exposure quartile. |
| Calibrated-exposure / cell-based-DDD methodology | Records why an earlier ad hoc gap-threshold rule was replaced with a statistical test, and why the DDD's primary spec is now cell-based rather than occupation-level. As of the 2026-09-09 audit fix, the calibrated/realized measures are built from a population that also includes men (`exposure_population_df`), not the women-only analysis sample. |
| `GilNK` (age-group) imbalance between Mother and non-Mother, concentrated in the lowest `WFH_Exposure` quartile | Confirmed against real data (2026-09-09): the gap is largest in Q1 (~0.8 age-group units, t≈-81) and shrinks/reverses by Q4. Comparison specs exist for both the secondary DDD (age-interacted; `GilNK`-reweighted) and the primary hours DDD (same two comparison specs, occupation-level exposure) but none has replaced either DDD's own primary spec — that's a separate, still-open decision. |
| ISCO disclosure-masking's effect on the exposure index | A proxy check via the coarser `ISCO1`, not a full resolution — a fully-masked ("XX") row still carries zero occupation signal at any resolution. |
| `IDPUF` cross-period repetition | Reported, not corrected — the same person can in principle contribute to both `Post==0` and `Post==1` rows. |
| Secondary (extensive-margin) DDD's null `Mother:Post:WFH_Exposure` was underpowered — root cause diagnosed and partially fixed | Root cause: `WFH_Exposure` was built from exactly the same 3 variables used as the regression's own controls/FE, so its minimum detectable effect was ~51% of baseline employment — far larger than the actual point estimates. Fixed by building `WFH_Exposure` on a finer partition (+`MatzavMishpachti`, +`Dat`) than the regression's controls/FE, verified against real data to cut the MDE by ~37% (to ~32% of baseline) with negligible cell-size cost. Still underpowered at that level, but no longer aliased with its own controls by construction. `RUN_NULL_VS_POWER_AUDIT` flag, default `FALSE`. |

(Erratum, three items in the table above are out of date:
1. the last row's "~32% of baseline" predates the `BirthContinent` addition; current is ~26% — see §2.3;
2. the `GilNK` row's "~0.8, t≈−81" likewise predates it; current CSV says −0.974, t = −94;
3. the last row's "`RUN_NULL_VS_POWER_AUDIT` flag, default `FALSE`" is wrong — it was flipped to
   `TRUE` on 2026-09-19, as was `RUN_AGE_BALANCE_ROBUSTNESS`. Both audit blocks run on a default
   `Rscript main.R`.)

### 5.3 Lee-bounds directionality — `docs/decisions/intensive-margin-lee-bounds.md` (verbatim)

> - Only handles excess selection in the `Mother==1,Post==1` cell — the direction this project's
>   own hypothesis predicts. Under-selection in that cell (fewer employed mothers than the
>   counterfactual implies) is a missing-data problem, not an excess-observed-data problem, and
>   isn't addressed by this construction.
> - Relies on the same parallel-trends assumption already underlying the extensive-margin DiD
>   itself (see `Diagnostics.R`'s pretrend check) to define the selection counterfactual `s11*`.
> - Assumes monotone selection (WFH weakly increases, never decreases, a mother's employment
>   probability) to justify trimming from a single tail.
> - Consistent with this project's separate, deliberate decision not to apply `MishkalSofi` survey
>   weights anywhere … the selection rates `s_ab` are computed unweighted.

> … a finding of "no excess selection" in the real data should be read as "this construction
> found nothing to correct," not as proof the selection concern doesn't exist.

Additional hours-DDD-specific limitation (`scripts/hours_ddd_lee_bounds.R` header): a quartile with
few `Mother==1,Post==1` rows makes its `trim_prop` noisy (warning threshold 30 rows; all four
quartiles here have >21,000, so not triggered).

### 5.4 ~~Parallel-trends caveat~~ — **OBSOLETE, superseded 2026-09-21**

The caveat this section recorded no longer applies. It read:

> ~~**Implication for identification**: the paper's parallel-trends assumption should be stated as
> resting on the 2018-2019 comparison, not the full 2017-2019 window, and the 2017 anomaly should
> be disclosed as a limitation rather than smoothed over.~~
>
> ~~- The Lee-bounds counterfactual itself relies on the same parallel-trends assumption already
>   dented by the 2017 finding in §1.~~

**Both clauses are withdrawn.** The 2017 anomaly was a data defect, not a trend: the 2017 CBS file
coded the employed-but-absent as zero usual hours, and because absence is mother-skewed that
produced a spurious `Mother × year` effect. Harmonizing the hours population on reference-week work
(`docs/decisions/hours-population-harmonization.md`) removes it. Parallel trends now hold on both
margins over the **full** 2017–2019 pre-period — hours F(2, 63,198) = 0.949, p = 0.387; employment
F(2, 79,069) = 0.63, p = 0.53 — so neither the outcome equation nor the Lee-bounds counterfactual
carries a 2018–2019 restriction any longer. See §1.8.

**What replaces it as a limitation** (and is what `paper.tex` §8 now says): the correction narrows
the estimand to usual hours among women who were *working*, excluding roughly 10% of each year's
employed sample. If absence from the reference week is itself related to WFH exposure — plausibly,
if teleworkable jobs make it easier to work while unwell or while caring for a child — the
restriction is not innocuous for the triple interaction. The absentee share is only mildly related
to exposure across quartiles (12.4 / 8.6 / 8.2 / 10.1% in 2017), but this cannot be ruled out.

### 5.5 Other stated limitations (short pointers)

- Cluster counts: hours DDD ~40 occupation clusters; employment DDD ~210 cell clusters; no
  small-cluster correction (wild bootstrap would need `fwildclusterboot`, not added)
  (`docs/decisions/calibrated-exposure-and-cell-ddd.md`; `main.R` §8b comment).
- ISCO masking: pooled `ISCO_masked` coefficient 0.045* (SE 0.021), within-R² 9.45e-5 — "no strong
  evidence" of bias, not a clean bill of health (`docs/hours-intensive-margin-analysis.md` §3;
  `outputs/isco_masking_sensitivity_*.csv`).
- Calibrated exposure uses 2022–23 realized data (inside the post period) — a documented
  compromise (`docs/decisions/calibrated-exposure-and-cell-ddd.md`, measure 2).
- Age control is categorical `GilNK`, not age/age² (no continuous age in the extract) —
  `docs/decisions/checkpoint8-age-age2-controls.md`.

---

## 6. Literature citations

Verified by web search on 2026-09-15 unless marked. Scope decisions recorded 2026-09-15 (user
instruction): the paper's bibliography consists of the **five substantive citations (§6.1)** plus
the **two methods citations (§6.2)**. Everything in §6.3 is out of scope. Goldin and Olden & Møen
are not cited anywhere in the repo; their roles are fixed below.

### 6.1 Substantive citations (Introduction / Literature Review) — REQUIRED

1. **Harrington, Emma, and Matthew E. Kahn (2025).** "Has the Rise of Work from Home Reduced the
   Motherhood Penalty in the Labor Market?" NBER Working Paper No. 34147.
   - **Central, required citation.** This project's design is directly modeled on / extends this
     paper to the Israeli context. The Introduction should frame the project explicitly as
     **testing Harrington & Kahn's US finding on Israeli CBS Labor Force Survey microdata**.
   - **Byline is two authors — Harrington & Kahn — not "et al."** (confirmed from the NBER listing;
     the repo's `README.md` / research doc write "Harrington et al. (2025)", which is wrong and
     should not be carried into the paper).
   - Their headline (from the NBER abstract): a 10% rise in WFH raises mothers' employment ~0.78 pp
     relative to other women, concentrated in careers with high returns to hours / inflexible time
     demands; employed mothers' incomes rise ~1.3% relative to other employed women. Note the
     margin contrast: their main result is extensive-margin/income; this project's headline is
     intensive-margin (hours).

2. **Goldin, Claudia (2014).** "A Grand Gender Convergence: Its Last Chapter." *American Economic
   Review*, 104(4): 1091–1119. DOI 10.1257/aer.104.4.1091.
   - **Locked in** as the intended Goldin citation (over the 2021 *Career and Family* book): the
     standard reference for the **temporal-flexibility mechanism** this project's WFH-exposure
     design is built around.

3. **Kleven, Henrik, Camille Landais, and Jakob Egholt Søgaard (2019).** "Children and Gender
   Inequality: Evidence from Denmark." *American Economic Journal: Applied Economics*, 11(4):
   181–209. DOI 10.1257/app.20180010. (= the repo's "Kleven et al. (2019, Denmark)".)

4. **Kleven, Henrik, Camille Landais, Johanna Posch, Andreas Steinhauer, and Josef Zweimüller
   (2019).** "Child Penalties across Countries: Evidence and Explanations." *AEA Papers and
   Proceedings*, 109: 122–126. DOI 10.1257/pandp.20191078. (= the repo's "Kleven et al. (2019,
   cross-country)".)

5. **Dingel, Jonathan I., and Brent Neiman (2020).** "How Many Jobs Can Be Done at Home?" *Journal
   of Public Economics*, 189: 104235. DOI 10.1016/j.jpubeco.2020.104235. (Source of the external
   teleworkability score in `data/israeli_cbs_wfh_2digit.csv` / `build_exposure_isco2()`.
   **Provenance resolved 2026-09-23:** the file is D&N's published binary indicator mapped to
   ISCO-08 through the BLS 2012 ISCO-08/SOC-2010 crosswalk (cited as `bls2012crosswalk`) and
   averaged without weights within each two-digit group; rebuilding from the two public files
   reproduces it exactly — see `docs/decisions/wfh-crosswalk-provenance.md` and the last block
   of `tests/testthat/test-wfh_crosswalk_integrity.R`.)

### 6.2 Methods citations (Empirical Strategy section only) — REQUIRED, but NOT literature review

These belong in the Empirical Strategy section's discussion of identification (DDD) and of the
Lee-bounds correction / partial-identification CI. **Do not lump them in with §6.1's substantive
comparisons** in the Introduction or Literature Review.

6. **Olden, Andreas, and Jarle Møen (2022).** "The Triple Difference Estimator." *The Econometrics
   Journal*, 25(3): 531–553. DOI 10.1093/ectj/utac010 `[VERIFY DOI — not blocking]`. (DDD
   identification / interpretation of the triple interaction.)

7. **Lee, David S. (2009).** "Training, Wages, and Sample Selection: Estimating Sharp Bounds on
   Treatment Effects." *Review of Economic Studies*, 76(3): 1071–1102. `[VERIFY: not web-checked]`
   (Trimming bounds, §1.2 and §1.4.)

8. **Imbens, Guido W., and Charles F. Manski (2004).** "Confidence Intervals for Partially
   Identified Parameters." *Econometrica*, 72(6): 1845–1857. `[VERIFY: not web-checked]`
   (CI for the identified set, §1.2 and §1.4.)

### 6.3 OUT OF SCOPE for this paper's bibliography (background citations used elsewhere in the repo)

Recorded only so the draft step knows they were considered and deliberately excluded. **Do not add
to the paper.**

- Correll, Shelley J., Stephen Benard, and In Paik (2007). "Getting a Job: Is There a Motherhood
  Penalty?" *American Journal of Sociology*, 112(5): 1297–1338. (Cited in `README.md` Background.)
- Cohen & Manor (2024) — Israeli WFH policy paper named in research doc Part 4 §4; no full
  reference exists in the repo.
- Bloom / "WFH Research (Nick Bloom, Stanford)" — named in research doc Part 4 §4 as a
  plausibility anchor for the exposure index; no specific paper identified in the repo.

---

## 7. Open items / things not confirmable from artifacts

1. ~~Hours mechanism regression slope (2.198, SE 0.907, p 0.021, n 37) and its Jewish/Arab analogs —
   console only; the CSV the narrative doc cites is a stale employment-outcome artifact (§1.5).~~
   **Resolved 2026-09-15: §1.5 is out of scope — not to be drafted.**
   **Export gap closed 2026-09-20** (Checkpoint 12, `docs/decisions/paper-figure-layer.md`):
   `main.R` now exports `hours_ddd$mechanism_data` as `outputs/hours_mechanism_data.csv` (37 rows:
   `occupation_code, wfh_exposure, beta_j, se_j` + CI columns). Refitting
   `lm(beta_j ~ wfh_exposure, weights = 1/se_j^2)` from that file reproduces **slope 2.1977,
   SE 0.9068, p 0.0207, n 37**, establishing the figures from disk rather than console
   scrollback, and superseding the stale, since-deleted `ddd_calibrated_mechanism_data.csv`
   (employment-probability units). The §1.5 scope decision is unaffected — the data is now
   verifiable, but the regression is still not drafted into the paper. The Jewish/Arab analogs
   remain console-only.
2. ~~Imbens–Manski CIs for both Lee-bounds tables — console only.~~ **Resolved 2026-09-22:** exported by `main.R` as `outputs/hours_lee_bounds_imbens_manski.csv` ([1.0208, 5.3237], c_α 1.8398) and `outputs/intensive_margin_lee_bounds_imbens_manski.csv` ([−0.8095, 1.0959], c_α 1.6449). Earlier note: **recomputed 2026-09-21** by sourcing `scripts/imbens_manski_ci.R` against the regenerated bounds: DiD [−0.810, 1.096] (c_α 1.644854), DDD [1.021, 5.324] (c_α 1.839787). Still not written to any CSV. Arithmetically consistent with the
   exported per-bound SEs (§1.2, §1.4).
3. ~~Hours-DDD MDE (2.6059) — console only; arithmetically verified from the exported SE (§1.3).~~
   **Resolved 2026-09-19:** `compute_ddd_mde()` now returns a one-row data frame, so all three
   MDEs are exported: `outputs/mde_hours.csv` (**2.86398, 7.31% of the 39.18 mean weekly hours** post-harmonization,
   `within_mde` FALSE — the effect is detectable) and, under `RUN_NULL_VS_POWER_AUDIT`,
   `null_vs_power_audit_mde_{additive,fe}.csv` (0.20312 and 0.20224, 26.25% and 26.14% of the
   0.7737 baseline, `within_mde` TRUE for both — the employment design cannot detect its own point
   estimate). The `within_mde` column makes the paper's "underpowered, not null" argument
   machine-checkable rather than a claim a reader has to recompute.
   The narrative doc's "68% of the point estimate" was a mis-statement; the current share-of-estimate figure is **88.8%** (2.86398/3.22404). Corrected in
   `docs/hours-intensive-margin-analysis.md` on the same day.
4. ~~Pre-trend joint Wald F-tests — console only (§1.8).~~ **Resolved 2026-09-19:** the test now
   runs unconditionally and exports `outputs/pretrend_wald_{hours,employment}.csv`. The paper's
   parallel-trends evidence is reproducible by a default `Rscript main.R`.
5. "MDE ≈ 4× the point estimate" for the employment DDD refers to the original design; current
   ratio is 8–10× (§2.3).
6. `GilNK` imbalance figures in the narrative doc / HLD (−0.797 / +0.239; "~0.8, t≈−81") differ from
   the current CSV (−0.974 / +0.057; t = −94) — docs predate the `BirthContinent` cell change (§1.7).
7. ~~Employment-outcome gender placebo (`run_gender_placebo()`) has no exported result (§3.4).~~
   **Resolved 2026-09-19:** wired into `main.R` and exporting
   `outputs/gender_placebo_{did,ddd}_table.csv`. Two defects had to be fixed for this: the
   function always reloaded the male subsample from the raw CSVs instead of accepting the one
   already in memory, and `run_gender_ddd_placebo()` printed its etable without returning it, so
   the DDD table reached no file even once the call was wired in (§3.4).
8. Why the Jewish-women tables carry no `Dat` coefficients (§3.1). **Resolved 2026-09-15: no
   investigation; handled as a one-sentence footnote near the subgroup results (text in §3.1).**
9. Lee-bounds trim proportion for the plain DiD (**≈1.9%** post-harmonization, inferred) and N of the three hours-DDD
   Lee-bounds fits — not exported (§1.2, §1.4). **2026-09-15: the ≈1.5% is used in the paper as a
   derived, footnoted figure; the DDD Lee-bounds N is exported since 2026-09-24 (`n_obs` column of `outputs/hours_lee_bounds_table.csv`: 242,552 / 241,166 / 241,167).**
10. Citation gaps — **resolved 2026-09-15 (§6):** Goldin locked to 2014 AER; Harrington & Kahn
    confirmed two-author, marked central/required; Olden & Møen DOI 10.1093/ectj/utac010 verified against Crossref 2026-09-19 (see `paper/references.bib` header)
    (non-blocking); Correll, Cohen & Manor, and Bloom placed out of scope; Lee (2009) and
    Imbens & Manski (2004) reclassified as methods citations. Remaining: Olden & Møen DOI; Lee and
    Imbens–Manski page ranges not web-checked. D&N crosswalk provenance closed 2026-09-23 (§6.1
    item 5).

---

## 8. 2026-09-22 grade-report response — new artifacts and numbers

Added by `docs/decisions/grade-report-response.md` (Checkpoint 14). Every number below is read
from the named `outputs/` file written by the same default `Rscript main.R` run; the paper's
tables are now generated from that run (`paper/tables/*.tex`, via `build_paper_tables()`), so
Tables 1–7 and A1 are not transcribed at all. Significance codes as in the header.

### 8.1 [PRIMARY] Hours DDD, saturated fixed effects — `outputs/ddd_hours_saturated.csv`
`WorkHoursCont ~ Mother:Post:WFH_Exposure + controls | occ^ShnatSeker + occ^Mother + Mother^ShnatSeker`,
clustered by occupation. **Mother × Post × WFH_Exposure = 2.876\*\* (0.9495)**, N = 246,324,
R² 0.13512 (within 0.02453). Paper: Table 2 column (3), §5.2.

### 8.2 [PRIMARY] Hours DDD, exposure quartiles — `outputs/ddd_hours_binned_coefs.csv`, `_quartile_sizes.csv`, `_table.csv`
Bins are Figure 2's pre-period quartile edges (`hours_dose_response$breaks`). Relative to Q1:
Q2 0.7529 (0.4827), Q3 0.5998 (0.4847), **Q4 1.844\*\* (0.5946)**, p = 0.0036; Mother × Post
(Q1) −0.4720 (0.3459); N = 246,326. Occupations per bin 16 / 7 / 11 / 6; rows 61,571 / 66,612 /
74,911 / 48,874. Paper: Table 2 column (4), §5.2.

### 8.3 [PRIMARY] Hours DiD with survey-year effects — `outputs/intensive_margin_yearfe.csv`
Mother × Post = 0.2310 (0.1808), N = 251,857. Paper: §5.1, one sentence.

### 8.4 [PRIMARY] Outcome-coding sensitivity — `outputs/ddd_hours_noimputed.csv`, `ddd_hours_fulltime.csv`, `ddd_hours_longhours.csv`, `hours_outcome_shares.csv`
Triple interaction: irregular-hours codes 11/12 dropped **3.056\*\* (1.059)**, N = 232,785;
full-time (≥35 h) LPM **0.0964\*\* (0.0291)**; long-hours (≥40 h) LPM **0.1073\*\* (0.0380)**,
both N = 246,326. Per SD of exposure (0.1986): 1.9 and 2.1 pp. Baseline shares by Mother × Post
in `hours_outcome_shares.csv`. Paper: Table 4 "Outcome coding", §5.4.

### 8.5 [PRIMARY] Wild cluster bootstrap — `outputs/hours_wild_bootstrap.csv`
`fwildclusterboot::boottest()`, Rademacher, null imposed, B = 9,999, 40 clusters, seed 20260922
(`dqrng::dqset.seed` + `set.seed`). Headline Mother × Post × WFH_Exposure: t = 3.154,
**p_boot = 0.0558**, bootstrap 95% CI [−0.2644, 5.8433]. DDD event-study pre-period terms:
2017 p = 0.8381, 2018 p = 0.8837, sum p = 0.8523. Paper: Table 4 "Inference", §5.3 notes,
§4.4, §5.4, Abstract.

### 8.6 [PRIMARY] Permutation test — `outputs/hours_permutation_table.csv`, `hours_permutation_draws.csv`
999 reassignments of the 40 calibrated scores across occupation codes, seed 20260922, refit with
occupation clustering. Observed t = 3.1538; **p_perm = 0.032** on |t| (31 of 999 draws ≥ |t_obs|;
Phipson–Smyth count), 0.026 on |coef|; t_perm 2.5/97.5% quantiles −2.9607 / 2.6021, max |t| 6.2099;
Monte-Carlo SE of p 0.0056. Figure: `outputs/figures/hours_permutation.pdf` (Figure 5). Paper:
§4.6, §5.4, §5.5, Abstract.

### 8.7 [PRIMARY] Hours DiD/DDD by youngest child's age — `outputs/hours_ddd_by_child_age_table.csv`, `_comparison_data.csv`
Each bin's mothers + all 133,646 childless women. DiD (SE, N): 0–4 0.1267 (0.2111, 158,424);
5–9 0.1621 (0.2533, 130,782); 10–14 0.1593 (0.2780, 123,280); 15–17 0.5613 (0.3483, 107,061) —
all ns. DDD: **0–4 3.656\*\* (1.079, 154,499)**; 5–9 3.211\* (1.311, 127,419); 10–14 2.741·
(1.525, 120,084; p 0.0803); 15–17 1.862· (0.9354, 104,079; p 0.0537). Mothers per bin 109,220 /
56,897 / 47,378 / 25,600. Figure: `outputs/figures/hours_ddd_by_child_age.pdf` (Figure 6). Paper:
Table 6, §5.6, Discussion.

### 8.8 Occupation-level first stage — `outputs/wfh_occupation_first_stage_stats.csv`, `_table.csv`
Per-occupation realized WFH shares over 2021–23, men and women pooled, both the reference-week
item and the usual-place item; correlations and n-weighted (occupation cell size, not a survey
weight) slopes on the calibrated and external scores. Reference-week: corr(calibrated) 0.529,
slope 0.400 (0.087), R² 0.249; corr(external) 0.739, slope 0.374 (0.097), R² 0.585. Usual-place (2021–23): corr(calibrated) 0.481, slope 0.255 (0.054), R² 0.285; corr(external) 0.588, slope 0.205 (0.062), R² 0.502 — the external index fits better on both measures because the threshold swap mixes two scales (paper §3.2, Limitations). Usual-place
figures: see the CSV (`realized_usual` rows). The 40-row table is Appendix Table A1; the scatter
`outputs/figures/wfh_first_stage_occupation.pdf` is Figure A1. Paper: §3.2, Appendix.

### 8.9 Subgroup z-tests — `outputs/hours_subgroup_ztests.csv`
Previously console-only (§3.3). Jewish vs Arab: DiD z = 0.720 (p 0.471), DDD z = −0.942 (p 0.346).
Women vs men: DiD z = 2.406 (p 0.016), DDD z = 3.461 (p 0.0005). Paper: Table 5.

### 8.10 Table 1 inference — `outputs/descriptive_table_continuous.csv` (`se_difference`), `_categorical.csv` (`se_pct_difference`)
IDPUF-clustered SE of every mothers-minus-childless difference, plus an hours-N row
(93,982 childless / 164,193 mothers with observed usual hours). Paper: Table 1.

### 8.11 Generated tables — `paper/tables/*.tex`, `paper/tables/auto_notes.tex`
`tab_descriptives`, `tab_hours` (4 columns), `tab_lee_selection`, `tab_lee_bounds`, `tab_robust`
(now with a p column and the outcome-coding and inference blocks), `tab_subgroup`, `tab_childage`,
`tab_extensive`, `tab_exposure_scores`. The note macros record, per table, which columns dropped a
coefficient for collinearity (only the Arab-women rows drop religion `other`). This is what
retires the stale Table 2 note the grade report flagged (T1).
