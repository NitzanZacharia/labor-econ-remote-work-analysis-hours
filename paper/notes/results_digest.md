# Results Digest — WFH and the Motherhood Penalty (Israel, CBS LFS 2017–19 / 2021–23)

> ## ⚠️ STALE FOR EVERY HOURS-DERIVED NUMBER — read this first
>
> Checkpoint 13 (2026-09-21, [`docs/decisions/hours-population-harmonization.md`](../../docs/decisions/hours-population-harmonization.md))
> harmonized the hours population across survey years, and a follow-up redefined the Lee-bounds
> selection rate on the observed-hours sample. **Every hours figure below predates both.** The
> employment margin, the WFH-exposure construction and Table 1's non-hours rows are unaffected and
> remain valid.
>
> `paper/paper.tex` has already been updated directly from the regenerated `outputs/` CSVs, so for
> hours numbers **the paper is currently ahead of this digest**, inverting the usual
> source-of-truth relationship. Do not transcribe an hours number from here into the paper.
> Headline changes: pre-trend Wald *F* = 23.69 → **0.949** (*p* = 0.387, now passing); hours DiD
> 0.8261\*\*\* → **0.2280** (null); hours DDD 3.4073\*\*\* → **3.224**\*\*; Imbens–Manski on the DDD
> [1.5035, 5.2091] → **[1.021, 5.324]**. §5.4's parallel-trends caveat and §7's open items 3–4 are
> obsolete. This digest needs a full hours pass before it is cited again.

**Purpose.** Fact-extraction pass for the seminar paper. No prose, no LaTeX. Every number is
tagged with the exact file it was read from. Where the only source is a console message quoted in
a decision memo (never exported to `outputs/`), that is stated explicitly. Anything not confirmable
from a repo artifact is marked `[TODO: confirm]`; citation fields not verified are marked `[VERIFY]`.

**Authors (paper byline):** Inbal Moryles and Nitzan Zacharia. (The research doc's byline spells
the first author "Inbal Muriel" — that spelling is wrong; do not copy it into the paper.)

**Digest date:** 2026-09-15. **Repo state:** branch `main`, HEAD `f6e64bc`. Live `outputs/*.csv`
files were regenerated 2026-09-13 (commit `6043755`) unless noted as stale below.

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

**Stale / trap artifacts in `outputs/` — do NOT cite:**
- `outputs/ddd_calibrated_table.csv`, `ddd_external_table.csv`, `ddd_realized_table.csv`
  (+ their `_mechanism_data.csv` / `_dropped_occupations_data.csv`): committed 2026-09-11, produced
  by the since-**removed** `ddd_regression.R` (occupation-level DDD on the *employment* outcome,
  `Mother x Post x WFH_Exposure` = −0.0248* (0.0092), N = 297,878). Not part of any current
  specification (`docs/decisions/employment-ddd-robustness-removal.md`). `main.R` no longer
  exports anything under these names.
- `outputs/ddd_primary.csv` (2026-09-11): pre-rename copy of `ddd_employment.csv`; numbers identical.
- `outputs/hours_ddd_pivot_*.csv` (2026-09-11): pre-rename copies of `ddd_hours_table.csv` /
  `hours_lee_bounds_*.csv`; numbers identical.

---

## 1. PRIMARY — Intensive margin (hours)

### 1.1 [PRIMARY] Hours DiD

- **Function / file:** `run_intensive_margin_reg()`, `scripts/intensive_margin_regression.R`
- **Formula (verbatim from script):** `WorkHoursCont ~ Mother + Post + Mother:Post + MatzavMishpachti + Dat + GilNK + MachozMegurim + TeudaGvoha`
- **Sample:** `filter(cleaned_df, Employed == 1)`; **cluster:** `~IDPUF`
- **Source table:** `outputs/intensive_margin_table.csv`

| Term | Coef | SE | Sig. |
|---|---|---|---|
| `Mother x Post` | **0.8261** | 0.1830 | *** |
| `Mother` | −2.223 | 0.1485 | *** |
| `Post` | 0.7289 | 0.1503 | *** |
| Constant | 30.90 | 0.3198 | *** |

- **N = 281,750**; R² = 0.03836.
- Full-precision estimate (from `outputs/hours_did_subgroup_comparison_data.csv`, row "All women
  (primary)"): 0.826065, SE 0.182951, 95% CI [0.4675, 1.1846].
- **Baseline means** (`outputs/hours_diagnostics_hours_by_period.csv`, employed only):
  non-mothers pre 39.01 (n 53,779) / post 39.80 (n 47,447); mothers pre 36.85 (n 100,210) /
  post 38.52 (n 86,964). Pooled employed mean = 38.24 hours (n = 288,400) — computed from that
  file; matches the "38.24" in `docs/decisions/hours-ddd-pivot.md` "Real-data results".
- Raw 2×2 DiD from those means: (38.52−36.85) − (39.80−39.01) = 1.67 − 0.79 = 0.88 (unadjusted;
  regression-adjusted is 0.83).

### 1.2 [PRIMARY] Lee (2009) bounds on the hours DiD

- **Function / file:** `run_intensive_margin_lee_bounds()`, `scripts/intensive_margin_lee_bounds.R`;
  method memo `docs/decisions/intensive-margin-lee-bounds.md`.
- **Construction:** `s_ab = P(Employed==1 | Mother=a, Post=b)`; counterfactual
  `s11* = s10 + (s01 − s00)`; if `s11 > s11*`, trim share `p = 1 − s11*/s11` from the
  `Mother=1,Post=1` cell's `WorkHoursCont` distribution (top-trim → lower bound, bottom-trim →
  upper bound); refit the DiD on each trimmed sample.
- **Selection rates** (`outputs/intensive_margin_lee_bounds_diagnostics_selection_rates.csv`):

| Mother | Post | selection rate | n |
|---|---|---|---|
| 0 | 0 | 0.7518 | 71,532 |
| 0 | 1 | 0.7639 | 62,114 |
| 1 | 0 | 0.7717 | 129,856 |
| 1 | 1 | 0.7961 | 109,239 |

  → `s11* = 0.7717 + (0.7639 − 0.7518) = 0.7838`; `s11 = 0.7961 > s11*` ⇒ excess selection;
  implied trim ≈ 1 − 0.7838/0.7961 ≈ 1.5% — **derived from the selection rates above, not
  directly exported by the pipeline**; cite it as a derived figure (footnoted), not a sourced one.

- **Bounds table** (`outputs/intensive_margin_lee_bounds_table.csv`):

| Bound | `Mother:Post` | SE | 95% CI |
|---|---|---|---|
| Lower | 0.2133 | 0.1808 | [−0.1411, 0.5678] |
| Point (untrimmed) | 0.8261 | 0.1830 | [0.4675, 1.1846] |
| Upper | 1.3132 | 0.1814 | [0.9576, 1.6688] |

- **95% Imbens–Manski CI for the identified set: [−0.084, 1.612]** — crosses zero. Source:
  `docs/hours-intensive-margin-analysis.md` §3 (console output of `imbens_manski_ci()`; **not in
  any CSV**). Sanity check: with `c_α ≈ 1.645` (bounds far apart relative to SE), 0.2133 −
  1.645×0.1808 = −0.084 and 1.3132 + 1.645×0.1814 = 1.612 — consistent.
- **Reading (per the narrative doc):** the plain hours DiD does **not** survive the selection
  correction; it is "suggestive but fragile". The DDD (§1.3) is the substantive result.

### 1.3 [PRIMARY — HEADLINE] Hours DDD (occupation-level calibrated exposure)

- **Function / file:** `run_hours_ddd_regression()`, `scripts/hours_ddd_regression.R`; called in
  `main.R` §8a with `hours_exposure_index = exposure_calibrated %>% select(occupation_code = ISCO2, wfh_exposure = wfh_exposure_calibrated)`.
- **Formula (verbatim from script):** `WorkHoursCont ~ Mother*Post*WFH_Exposure + MatzavMishpachti + Dat + GilNK + MachozMegurim + TeudaGvoha`
- **Sample:** `Employed == 1`, inner-joined to the occupation exposure index on
  `MishlachYad_ISCO_08_2` (drops disclosure-masked / unmapped ISCO codes).
  Per `docs/decisions/hours-ddd-pivot.md`: 281,622 of 288,400 employed rows (97.6%) matched an
  exposure; 275,708 after listwise deletion on controls.
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
| **`Mother x Post x WFH_Exposure`** | **3.407** | **0.9302** | **\*\*\*** |
| `Mother x Post` | 0.0153 | 0.2893 | (ns) |
| `Mother x WFH_Exposure` | −1.429 | 1.143 | (ns) |
| `Post x WFH_Exposure` | −0.8668 | 0.8280 | (ns) |
| `WFH_Exposure` | 1.831 | 4.153 | (ns) |
| `Mother` | −1.897 | 0.3650 | *** |
| `Post` | 0.9153 | 0.2746 | ** |

- **N = 275,708**; R² = 0.03906.
- Full-precision triple interaction (`outputs/hours_ddd_subgroup_comparison_data.csv`, "All women
  (primary)"): 3.407286, SE 0.930163, 95% CI [1.5842, 5.2304].
- **Interpretation note (narrative doc §2):** once exposure interactions enter, the bare
  `Mother x Post` collapses from 0.826 to 0.015 (ns) — the DiD's average effect is "fully absorbed
  into exposure heterogeneity".
- **MDE** (`compute_ddd_mde()`, `scripts/ddd_mde_diagnostics.R`, formula
  `MDE = SE × (qnorm(0.975) + qnorm(0.80)) = SE × 2.8016`): **2.6059**, "6.8% of mean weekly hours
  (38.24)". Source: `docs/decisions/hours-ddd-pivot.md` "Real-data results" (console message; the
  `mde_hours` list is in `main.R`'s export list but no `mde_hours*.csv` exists in `outputs/` —
  scalar lists are not written by `export_all_results()`). Arithmetic check: 0.9302 × 2.8016 =
  2.606 ✓; 2.606/38.24 = 6.8% ✓.
  - ⚠ `docs/hours-intensive-margin-analysis.md` §3 and §4 say the MDE is "68% of the 3.41 point
    estimate". That is **wrong**: 2.606/3.407 = **76.5%**. The "6.8%" figure is of *mean hours*,
    not of the point estimate. Use 76.5% (or "MDE = 2.61, point estimate 3.41 exceeds it").

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
| 1 | 0.6284 | 0.6419 | 0.6045 | 0.6478 | 0.6180 | 21,655 | TRUE | 4.61% |
| 2 | 0.7624 | 0.7867 | 0.7773 | 0.8037 | 0.8016 | 28,540 | TRUE | 0.25% |
| 3 | 0.8167 | 0.8099 | 0.8651 | 0.8619 | 0.8584 | 34,293 | TRUE | 0.41% |
| 4 | 0.8674 | 0.8514 | 0.8538 | 0.8501 | 0.8377 | 21,815 | TRUE | 1.45% |

- **Rows trimmed** (`outputs/hours_lee_bounds_n_trimmed.csv`): Q1 632 of 13,718; Q2 56 of 22,490;
  Q3 117 of 29,022; Q4 263 of 18,106 (total 1,068 of 83,336 employed, occupation-matched
  post-period mothers).
- **Bounds table** (`outputs/hours_lee_bounds_table.csv`), term `Mother:Post:WFH_Exposure`:

| Bound | Coef | SE | 95% CI |
|---|---|---|---|
| Lower | 3.4414 | 0.9927 | [1.4958, 5.3870] |
| Point (untrimmed) | 3.4077 | 0.9564 | [1.5331, 5.2823] |
| Upper | 3.4570 | 0.8975 | [1.6979, 5.2161] |

  Note the "point" here (3.4077, SE 0.9564) differs slightly from §1.3's 3.407 (SE 0.9302) because
  this function additionally requires a matched *cell*-based exposure (~1.3% of rows dropped) —
  stated in the script header. N for these three fits is not exported `[TODO: confirm]`.
- **95% Imbens–Manski CI for the identified set: [1.5035, 5.2091]** — excludes zero. Source:
  `docs/decisions/hours-ddd-pivot.md` "Real-data results" and `docs/hours-intensive-margin-analysis.md`
  §3 (console message from `imbens_manski_ci()`, `scripts/imbens_manski_ci.R`; **not in any CSV**).
  Sanity check: bounds nearly coincide so `c_α ≈ 1.95`; 3.4414 − 1.952×0.9927 = 1.504 ✓;
  3.4570 + 1.952×0.8975 = 5.209 ✓.

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
- **Result:** slope = **2.639 (SE 0.899), p = 0.006**, R² = 0.197, n = 37 occupations (3 of 40
  dropped for degenerate fits). Source: `docs/hours-intensive-margin-analysis.md` §2 (console
  output only).
  - ✅ **Resolved 2026-09-20 (Checkpoint 12).** `main.R` §8e now exports the real frame as
    `outputs/hours_mechanism_data.csv`, and refitting from it gives **slope 2.6386, SE 0.8993,
    n = 37** — the recorded figures, now verifiable from disk. The previously-cited
    `outputs/archive/ddd_calibrated_mechanism_data.csv` was **stale** (committed 2026-09-11 by the
    removed employment-outcome `ddd_regression.R`; its `beta_j` values are in
    employment-probability units, −0.19 to +0.13, not hours) and should not be used. Note this
    closes the *data* gap only: the scope decision above is unchanged, and this regression is
    still not to be drafted into the paper.

### 1.6 [PRIMARY] Exposure-measure sensitivity (same formula, different occupation index)

| Exposure measure | `Mother x Post x WFH_Exposure` | SE | Sig. | N | Source |
|---|---|---|---|---|---|
| Calibrated (primary) | 3.407 | 0.9302 | *** | 275,708 | `outputs/ddd_hours_table.csv` |
| External (Dingel–Neiman, `tele_ext`) | 0.9404 | 0.8649 | (ns) | 275,708 | `outputs/ddd_hours_external.csv` |
| Realized (2021-anchored, `min_n = 200`) | 6.416 | 2.454 | * | 275,390 | `outputs/ddd_hours_realized.csv` |

Narrative doc §3 framing: "directionally robust, not point-estimate robust."

### 1.7 [PRIMARY] Age-balance robustness (hours DDD)

Source: `outputs/age_balance_robustness_hours_ddd_age_interacted.csv`,
`outputs/age_balance_robustness_hours_ddd_reweighted.csv` (produced with
`RUN_AGE_BALANCE_ROBUSTNESS <- TRUE`, flag reverted; `docs/hours-intensive-margin-analysis.md` §3).

| Spec | `Mother x Post x WFH_Exposure` | SE | Sig. | N |
|---|---|---|---|---|
| Primary | 3.407 | 0.9302 | *** | 275,708 |
| Age-interacted (`+ Mother:GilNK`) | 3.367 | 0.9553 | ** | 275,708 |
| Reweighted (pre-period `GilNK` raking) | 2.836 | 0.9055 | ** | 271,621 |

Incidental finding (age-interacted spec): `Mother x GilNK4` = −2.083*** (0.4874); `GilNK5` −0.4644
(ns); `GilNK6` 1.063* (0.5247); `GilNK7` 1.337* (0.5957).

Underlying imbalance (`outputs/age_balance_robustness_age_imbalance_by_quartile.csv`, pre-period
mean `GilNK` gap Mother − non-Mother by cell-exposure quartile): Q1 −0.974 (t = −94.0), Q2 −0.735
(t = −62.8), Q3 −0.169 (t = −12.0), Q4 +0.057 (t = 5.0).
⚠ `docs/hours-intensive-margin-analysis.md` §1 quotes "−0.797 … to +0.239" and `docs/HLD.md` §4.2
quotes "~0.8, t≈−81"; the current CSV says −0.974 / +0.057. The docs appear to predate the
`BirthContinent` change to the exposure cells (which shifts quartile membership). Cite the CSV.

### 1.8 [PRIMARY] Pre-trend / event study (hours)

`outputs/hours_diagnostics_pretrend_table.csv` (`WorkHoursCont`, `Employed==1`, `Mother x ShnatSeker`,
ref = 2019, cluster `IDPUF`, N = 281,750):

| Year | Coef | SE | Sig. |
|---|---|---|---|
| 2017 | −1.524 | 0.2766 | *** |
| 2018 | 0.1222 | 0.2140 | (ns) |
| 2021 | 0.3069 | 0.2567 | (ns) |
| 2022 | 0.1080 | 0.2620 | (ns) |
| 2023 | 0.7435 | 0.2609 | ** |

Joint Wald test on 2017+2018: **F(2, 65,088) = 23.7, p = 5.2e-11**. Same test on the employment
outcome: F(2, 79,069) = 0.63, p = 0.53. **Update 2026-09-19: both are now exported** as
`outputs/pretrend_wald_hours.csv` and `outputs/pretrend_wald_employment.csv`, and
`run_pretrend_joint_test()` runs unconditionally in `main.R` §7 rather than behind
`RUN_AGE_BALANCE_ROBUSTNESS`. Exported values: 23.6854674914169 (p 5.21523147138e-11) and
0.630649732652335 (p 0.532248548305119). Previously console-only. Implication stated there:
parallel trends should be claimed on 2018–2019 only; 2017 disclosed as a limitation.

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
| All women (primary) | 0.8261*** | 0.1830 | [0.4675, 1.1846] | 281,750 | 3.4073*** | 0.9302 | [1.5842, 5.2304] | 275,708 |
| Jewish women | 0.9029*** | 0.2047 | [0.5017, 1.3041] | 241,738 | 2.9238** | 0.8901 | [1.1792, 4.6683] | 236,554 |
| Arab women | 0.1267 (ns) | 0.4798 | [−0.8137, 1.0671] | 26,876 | 6.0062* | 2.6426 | [0.8267, 11.1857] | 26,164 |
| Men (placebo) | −0.3860* | 0.1909 | [−0.7600, −0.0119] | 276,343 | −1.8806 (ns) | 1.1226 | [−4.0810, 0.3197] | 266,087 |

Per-group table sources: `outputs/intensive_margin_jewish_table.csv`,
`outputs/intensive_margin_arab_table.csv`, `outputs/ddd_hours_jewish_table.csv`,
`outputs/ddd_hours_arab_table.csv`, `outputs/hours_gender_placebo_did_table.csv`,
`outputs/hours_gender_placebo_ddd_table.csv`. Other notable terms: Arab hours DiD `Post` =
−1.579*** (0.3940) (Arab women's hours fell post-2021 overall); Arab hours DDD `Mother x WFH_Exposure`
= −4.761* (1.902).

**Sample-size gap:** Jewish 236,554 vs Arab 26,164 in the DDD (≈ 9.0×); 241,738 vs 26,876 in the
DiD (≈ 9.0×). Arab DDD SE (2.643) is ≈ 3× the Jewish SE (0.890).

### 3.3 What `docs/hours-intensive-margin-analysis.md` §5.2 concludes about Arab (6.006) vs Jewish (2.924)

Verdict: **small-sample / thin-occupational-coverage fragility, NOT a documented heterogeneous
treatment effect.** Three arguments, all from §5.2:

(a) **Not statistically distinguishable.** Two-sample z (disjoint samples, covariance exactly zero):
`z = (6.0062 − 2.9238) / sqrt(2.6426² + 0.8901²) = 3.0824 / 2.7885 = 1.105, p = 0.269`. Same test on
the DiD: z = 1.488, p = 0.137. Arab DiD itself is indistinguishable from zero (0.1267, SE 0.4798).
(Arithmetic re-checked from the CSV values: ✓.)

(b) **The Arab DDD's own mechanism check contradicts its sign.** Second-stage occupation regression
for Arab women: slope = **−19.29 (SE 7.04), t = −2.74, p = 0.011**, R² = 0.238, **n = 26 occupations
(14 of 40 dropped, 35%)**. Jewish women: slope = 2.148 (SE 1.136), p = 0.067, R² = 0.093, n = 37 (3
dropped). Full sample: 2.639 (SE 0.899), p = 0.006, n = 37. All console-only (not exported).

(c) **Mechanical cause — occupational concentration.** The 35% occupation dropout for Arab women vs
7.5% for Jewish/full sample is consistent with Arab women's employment being concentrated in
education and health-aide occupations; with only 26 informative occupations, a few high-leverage
ones can flip the mechanism slope.

Verbatim conclusion (§5.2): "Report the Arab DDD point estimate (6.006*, nominally significant on
its own one-sample test: z = 2.273, p = 0.023) transparently, but do **not** characterize it as
evidence that the WFH-exposure mechanism is stronger for Arab women than for Jewish women. … The
Jewish-women estimate (2.924**, corroborated directionally by its own mechanism regression) is the
more credible of the two ethnicity-specific results and should anchor any subgroup claim the paper
makes."

### 3.4 Gender placebo (hours) — §5.3 of the same doc

Women-vs-men z-tests (console arithmetic, re-checked): DDD all women vs men z = 3.627, p = 0.0003;
DiD z = 4.584, p < 0.0001. Jewish vs men: DDD z = 3.354 (p = 0.0008), DiD z = 4.605. Arab vs men:
DDD z = 2.747 (p = 0.006). Men's DiD `Father:Post` = −0.3860* (0.1909): small, significant, negative.
Men's DDD −1.881 (ns, SE 1.123): negative point estimate. Stated placebo limitations (§5.3): no
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

### 5.1 `README.md` — "Known limitations" (verbatim, complete)

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

### 5.2 `docs/HLD.md` §4.2 "Known limitations & deliberate decisions" (verbatim table rows, Notes column)

| Item | Notes (verbatim) |
|---|---|
| Survey weights (`MishkalSofi`, etc.) are not applied in any outcome regression | Deliberate, not an oversight — do not add without raising it first. `build_exposure_cells()` is the one exception (weights the exposure regressor's own construction, not a survey-representativeness correction). A second, not-yet-approved exception (`robustness/phase2_robustness.R`'s `run_ddd_weights_check()`) was removed along with that file — see `docs/decisions/employment-ddd-robustness-removal.md`. |
| Lee (2009) bounds only handle excess selection in one direction | Under-selection in the `Mother==1,Post==1` cell isn't addressed by this construction. As of the 2026-09-09 audit fix, the bounds also report a per-model SE/CI and an Imbens-Manski (2004) CI for the identified set, not just bare point estimates. The hours-DDD pivot generalizes this same machinery to the triple-interaction (`Mother x Post x WFH_Exposure`) specification, stratifying the selection counterfactual by cell-based exposure quartile. |
| Calibrated-exposure / cell-based-DDD methodology | Records why an earlier ad hoc gap-threshold rule was replaced with a statistical test, and why the DDD's primary spec is now cell-based rather than occupation-level. As of the 2026-09-09 audit fix, the calibrated/realized measures are built from a population that also includes men (`exposure_population_df`), not the women-only analysis sample. |
| `GilNK` (age-group) imbalance between Mother and non-Mother, concentrated in the lowest `WFH_Exposure` quartile | Confirmed against real data (2026-09-09): the gap is largest in Q1 (~0.8 age-group units, t≈-81) and shrinks/reverses by Q4. Comparison specs exist for both the secondary DDD (age-interacted; `GilNK`-reweighted) and the primary hours DDD (same two comparison specs, occupation-level exposure) but none has replaced either DDD's own primary spec — that's a separate, still-open decision. |
| ISCO disclosure-masking's effect on the exposure index | A proxy check via the coarser `ISCO1`, not a full resolution — a fully-masked ("XX") row still carries zero occupation signal at any resolution. |
| `IDPUF` cross-period repetition | Reported, not corrected — the same person can in principle contribute to both `Post==0` and `Post==1` rows. |
| Secondary (extensive-margin) DDD's null `Mother:Post:WFH_Exposure` was underpowered — root cause diagnosed and partially fixed | Root cause: `WFH_Exposure` was built from exactly the same 3 variables used as the regression's own controls/FE, so its minimum detectable effect was ~51% of baseline employment — far larger than the actual point estimates. Fixed by building `WFH_Exposure` on a finer partition (+`MatzavMishpachti`, +`Dat`) than the regression's controls/FE, verified against real data to cut the MDE by ~37% (to ~32% of baseline) with negligible cell-size cost. Still underpowered at that level, but no longer aliased with its own controls by construction. `RUN_NULL_VS_POWER_AUDIT` flag, default `FALSE`. |

(Note: the last row's "~32% of baseline" predates the `BirthContinent` addition; current is ~26% —
see §2.3. The `GilNK` row's "~0.8, t≈−81" likewise predates it; current CSV says −0.974, t = −94.)

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

### 5.4 Parallel-trends caveat — `docs/hours-intensive-margin-analysis.md` §1 and §3 (verbatim)

> **Implication for identification**: the paper's parallel-trends assumption should be stated as
> resting on the 2018-2019 comparison, not the full 2017-2019 window, and the 2017 anomaly should
> be disclosed as a limitation rather than smoothed over.

> - The Lee-bounds counterfactual itself relies on the same parallel-trends assumption already
>   dented by the 2017 finding in §1.

Numbers: §1.8 above (2017 coefficient −1.524***, joint Wald F = 23.7, p = 5.2e-11 on hours;
F = 0.63, p = 0.53 on employment).

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
   teleworkability score in `data/israeli_cbs_wfh_2digit.csv` / `build_exposure_isco2()`
   `[VERIFY: that the crosswalk file is derived from D&N's published occupational classification —
   the repo says so but the provenance of the SOC→ISCO mapping is not documented]`.)

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

1. ~~Hours mechanism regression slope (2.639, SE 0.899, p 0.006, n 37) and its Jewish/Arab analogs —
   console only; the CSV the narrative doc cites is a stale employment-outcome artifact (§1.5).~~
   **Resolved 2026-09-15: §1.5 is out of scope — not to be drafted.**
   **Export gap closed 2026-09-20** (Checkpoint 12, `docs/decisions/paper-figure-layer.md`):
   `main.R` now exports `hours_ddd$mechanism_data` as `outputs/hours_mechanism_data.csv` (37 rows:
   `occupation_code, wfh_exposure, beta_j, se_j` + CI columns). Refitting
   `lm(beta_j ~ wfh_exposure, weights = 1/se_j^2)` from that file reproduces **slope 2.6386,
   SE 0.8993, n 37**, confirming the recorded 2.639/0.899/37 from disk rather than console
   scrollback, and superseding the stale `outputs/archive/ddd_calibrated_mechanism_data.csv`
   (employment-probability units). The §1.5 scope decision is unaffected — the data is now
   verifiable, but the regression is still not drafted into the paper. The Jewish/Arab analogs
   remain console-only.
2. Imbens–Manski CIs for both Lee-bounds tables — console only, arithmetically consistent with the
   exported per-bound SEs (§1.2, §1.4).
3. ~~Hours-DDD MDE (2.6059) — console only; arithmetically verified from the exported SE (§1.3).~~
   **Resolved 2026-09-19:** `compute_ddd_mde()` now returns a one-row data frame, so all three
   MDEs are exported: `outputs/mde_hours.csv` (2.60593, 6.81% of the 38.24 mean weekly hours,
   `within_mde` FALSE — the effect is detectable) and, under `RUN_NULL_VS_POWER_AUDIT`,
   `null_vs_power_audit_mde_{additive,fe}.csv` (0.20312 and 0.20224, 26.25% and 26.14% of the
   0.7737 baseline, `within_mde` TRUE for both — the employment design cannot detect its own point
   estimate). The `within_mde` column makes the paper's "underpowered, not null" argument
   machine-checkable rather than a claim a reader has to recompute.
   The narrative doc's "68% of the point estimate" was a mis-statement (76.5%), corrected in
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
9. Lee-bounds trim proportion for the plain DiD (≈1.5%, inferred) and N of the three hours-DDD
   Lee-bounds fits — not exported (§1.2, §1.4). **2026-09-15: the ≈1.5% is used in the paper as a
   derived, footnoted figure; the DDD Lee-bounds N stays `[TODO: confirm]` — do not infer it.**
10. Citation gaps — **resolved 2026-09-15 (§6):** Goldin locked to 2014 AER; Harrington & Kahn
    confirmed two-author, marked central/required; Olden & Møen kept with DOI `[VERIFY]`
    (non-blocking); Correll, Cohen & Manor, and Bloom placed out of scope; Lee (2009) and
    Imbens & Manski (2004) reclassified as methods citations. Remaining: Olden & Møen DOI; Lee and
    Imbens–Manski page ranges not web-checked; D&N crosswalk provenance.
