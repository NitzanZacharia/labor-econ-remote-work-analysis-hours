# Decision Memo: Harmonizing the Hours Population Across Survey Years

**Status: IMPLEMENTED** (2026-09-21, branch `2017-fix`). `WorkHoursCont` is now defined only for
rows that are both `Employed == 1` and `AvadBeshavua == 1` (worked the reference week), in every
survey year.

**Headline consequence: the paper's parallel-trends test now passes.** The hours pre-trend Wald
statistic falls from *F*(2, 65,088) = 23.69, *p* = 5.2×10⁻¹¹ to *F*(2, 63,198) = 0.95,
*p* = 0.387. The 2017 event-study coefficient goes from **−1.524\*\*\* (0.2766) to +0.3515
(0.2570)**. The headline DDD survives at **3.2240 (SE 1.0223)**; the secondary hours DiD does not —
it falls from 0.8261\*\*\* (0.1830) to **0.2280 (0.1809)**, no longer significant.

## The defect

`hour_bin_median` (`scripts/data_processing.R:34`) maps hours-bin code `0` to a literal `0`. In
2017, **5,169 employed women and 2,342 employed men** carried that code and were assigned zero
usual weekly hours. No other survey year has a single employed row in bin 0.

The first reading — "a 2017 coding artifact producing garbage zeros" — was **wrong**, and the
correction changed the fix:

- **Bin 0 is used in every year**, among the **non-employed**: 16,821 rows in 2017, 15,601 in 2018,
  14,960 in 2019, 14,078 in 2021, 11,219 in 2022, 11,639 in 2023. They are already `NA` via the
  `Employed != 1` branch, which is why they are invisible. Bin 0 means "no usual hours / did not
  work" and CBS uses it consistently.
- **`AvadBeshavua` partitions 2017's employed perfectly.** All 5,169 bin-0 rows are code 4 (did not
  work in the reference week); all 47,729 other employed rows are code 1. Zero overlap.
- **That population is stable across years.** The employed-but-absent share is
  9.8 / 10.3 / 10.6 / 12.0 / 9.9 / 10.4 % for 2017→2023.

So the defect is a **population-definition inconsistency, not corrupt data**: in the 2017 file the
employed-but-absent had usual hours recorded as `0`; from 2018 onward the same people received a
real usual-hours code. And the affected group is mother-skewed by construction — absentees are
**12.4% of employed mothers against 7.3% of non-mothers** — so the 2017 pre-period systematically
understated mothers' hours, which is exactly a spurious `Mother × year` effect.

Note `hour_bin_median`'s `` `0` = 0 `` is not wrong in itself. Zero is the right *actual* hours for
someone who did not work. It is wrong only as a *usual*-hours value, which is what this variable is.

## Why `bin 0 -> NA` alone was rejected

It would have left 2017 conditioning on "worked that reference week" while the other five years did
not — deleting an outcome whose missingness correlates with `Mother`, in a design whose estimand is
a `Mother × year` contrast. It also **overshoots**: the 2017 raw gap lands at −1.373, *past* 2018's
−1.571 and 2019's −1.678 rather than onto them, so the event-study coefficient would flip positive
rather than resolve.

| year | current | bin0→NA only | **harmonized (adopted)** |
|---|---|---|---|
| 2017 | −3.302 | −1.373 | −1.373 |
| 2018 | −1.571 | −1.571 | −1.482 |
| 2019 | −1.678 | −1.678 | −1.672 |
| 2021 | −1.455 | −1.455 | −1.368 |
| 2022 | −1.560 | −1.560 | −1.533 |
| 2023 | −0.826 | −0.826 | −0.796 |

Restricting every year to reference-week workers instead makes the hours population identical
across years, at the cost of ~10% of each year's hours sample and a slightly narrower estimand:
**usual hours among those who worked the reference week.** That narrowing belongs in the paper's
data section, not only here.

## What changed in the code

| File | Change |
|---|---|
| `scripts/data_processing.R:186-196` | Two new `case_when` branches before `%in% 0:10`: `AvadBeshavua != 1 ~ NA_real_` (the gate) and `ShaotAvodaBederechKlalNK == 0 ~ NA_real_` (defensive — redundant today, since every 2017 bin-0 row is `AvadBeshavua == 4`, but a bin-0 row that *did* work would otherwise still be handed a literal 0) |
| `scripts/intensive_margin_lee_bounds.R` | Trim on the estimation sample (`!is.na(WorkHoursCont)`) |
| `scripts/hours_ddd_lee_bounds.R` | Same |
| `scripts/hours_diagnostics.R:25` | `n = n()` → `n = sum(!is.na(WorkHoursCont))` |
| `scripts/validation.R` | New soft-fail check: per-year share of employed rows with an unascertained usual-hours code |
| `tests/testthat/fixtures/generate_fixtures.R` | `AvadBeshavua` column + three coverage rows |

**The Lee-bounds change is required by the harmonization, not optional.** Both files build
`treated_cell` from all employed rows and `arrange(..., WorkHoursCont)`, and dplyr sorts `NA`
**last**. Before harmonization the `Mother==1 & Post==1` cells held zero NA-hours rows, so this was
latent. Afterwards they hold ~12%, at which point the lower bound would trim *unobserved* rows as
though they were the highest-hours ones, on an inflated `n_cell` denominator. This is a real bug
that the harmonization would have activated silently.

The code-11/12 imputation is untouched: the donor pools at `:191-192` select `%in% 1:5` / `6:10` and
read `.hour_bin_val`, not `WorkHoursCont`, so bin 0 is in neither pool. The pinned expectation in
`test-data_processing.R` still passes unchanged, which is an independent check of that claim.

## Results

Verified with a no-op baseline run first (`Rscript main.R` on the unchanged tree), which established
that **all 8 PDFs are nondeterministic** — the six `cairo_pdf` figures as well as the two base-`pdf()`
ones — while every CSV and PNG regenerates byte-identically. PDF churn is therefore noise; any
CSV/PNG movement is signal.

**31 CSVs and 6 PNGs changed. Every one is in the hours chain.** All control artifacts are
byte-identical: the four `wfh_exposure_*.csv`, both Lee-bounds selection-rate files, the entire
employment margin (`basic_reg_*`, `ddd_employment.csv`, `diagnostics_*`,
`pretrend_wald_employment.csv`, `gender_placebo_*`, `employment_by_child_age_*`,
`null_vs_power_audit_*`), `descriptive_table_categorical.csv` and the mobility figure.

### Headline

| Quantity | Before | After |
|---|---|---|
| Pre-trend Wald (hours) | *F* = 23.69, *p* = 5.2e-11 | ***F* = 0.95, *p* = 0.387** |
| Event study, 2017 | −1.524\*\*\* (0.2766) | **+0.3515 (0.2570)** |
| Event study, 2018 | 0.1222 (0.2140) | 0.2013 (0.2191) |
| Event study, 2023 | 0.7435\*\* (0.2609) | 0.7517\*\* (0.2650) |
| Raw 2×2 DiD | +0.8783 (0.0994) | +0.2658 (0.0978) |
| **Hours DiD** | 0.8261\*\*\* (0.1830) | **0.2280 (0.1809)** — insignificant |
| **Hours DDD** | 3.4073\*\*\* (0.9302) | **3.2240\*\* (1.0223)** — survives |
| MDE (hours DDD) | 2.6059 | 2.8640 |
| Hours NA rate | 22.628% | 30.736% |

### Secondary

| Quantity | Before | After |
|---|---|---|
| Lee bounds, DiD | [+0.2133, +1.3132] | **[−0.3783, +0.7095]** |
| Lee bounds, DDD | [+3.4414, +3.4570] | [+3.3076, +3.3059] |
| Jewish DDD | 2.9238 (0.8901) | 2.8465 (0.9125) |
| Arab DDD | 6.0062 (2.6426) | 5.5069 (2.6741) |
| Placebo DDD (men) | −1.8806 (1.1226) | −1.7620 (1.0153) |
| Jewish DiD | 0.9029 (0.2047) | 0.3021 (0.2027) |
| Placebo DiD (men) | −0.3860 (0.1909) | −0.4002 (0.1883) |
| Mechanism slope | 2.6386 (0.8993), n 37 | 2.1977 (0.9068), n 37 |
| Table 1 hours mean (childless / mothers) | 39.38 / 37.63 | 40.06 / 38.68 |
| Table 1 hours SD | 12.87 / 12.77 | 12.12 / 11.62 |

The mechanism loop retains **the same 37 occupations** (drops 62, 63, 95 before and after), so the
two slopes are comparable.

### Dose-response — not like-for-like

`hours_dose_response.R:43` filters `!is.na(WorkHoursCont)` *before* computing quartile breaks, so
the breakpoints move and the bins are not the same bins:

| | before | after |
|---|---|---|
| Q1 | [0.000, 0.097] +0.386 | [0.000, 0.097] −0.317 |
| Q2 | [0.097, 0.123] +0.751 | [0.097, 0.143] +0.270 |
| Q3 | [0.123, 0.300] +0.468 | [0.143, 0.300] −0.019 |
| Q4 | [0.300, 0.750] +2.244 | [0.300, 0.750] +1.551 |

The pattern is *cleaner* afterwards — the bottom three quartiles now sit at or below zero and the
effect is concentrated entirely in Q4 — but the Q2/Q3 boundary moved and one occupation changed
quartile, so the two columns must not be read as a like-for-like comparison.
`compute_pre_period_quartile_breaks()` is hours-independent and its quartiles *are* stable; the two
must not be conflated.

### Sensitivity: is 2017 rehabilitated?

Re-fitting post-harmonization on `ShnatSeker != 2017`:

| | with 2017 | without 2017 | difference |
|---|---|---|---|
| Hours DiD | +0.2280 (0.1809), N 251,857 | +0.3072 (0.1976), N 204,871 | +0.079 (0.44 SE) |
| Hours DDD | +3.2240 (1.0223), N 246,326 | +3.3769 (0.8899), N 200,252 | +0.153 (0.15 SE) |

Both well within noise. **2017 now behaves like any other pre-period year**, which is the evidence
needed to drop the paper's 2018–2019 restriction on the identifying assumption.

## What this means for the paper

1. **§8's "Parallel trends and the 2017 anomaly" paragraph is obsolete.** The limitation was a data
   defect, and it is fixed. It should be replaced by a short note that the hours population is
   harmonized on reference-week work and why.
2. **The identifying assumption no longer needs narrowing to 2018–2019** — §6.3, §5.4 (Lee bounds),
   §8 and conclusion-skeleton item 9 all inherit that restriction and can drop it.
3. **§4.3 "Hours year by year" exists solely to narrate the 2017 anomaly** and must be rewritten.
4. **The hours DiD is no longer significant.** The paper already demoted it to "suggestive" because
   its Lee bounds crossed zero; it is now insignificant on its own terms, and the bounds
   [−0.3783, +0.7095] straddle zero more clearly. Note the male placebo DiD (−0.4002) is now
   *larger in magnitude* than the women's estimate — that should be stated rather than left for a
   reader to notice.
5. **The headline DDD survives** at 3.2240 (SE 1.0223), still outside its own MDE of 2.8640, with
   Lee bounds well clear of zero. The paper's central claim stands.
6. **The estimand narrows** to "usual hours among those who worked the reference week." This belongs
   in §3.1's outcome definition.

## Known gaps

- `main.R:176-179` never calls `validate_cleaned_df()` on the men's frame, so the new coverage check
  does not run against the 2,342 affected male rows in the default pipeline.
- `paper/paper.pdf` (tracked) is now inconsistent with `outputs/`. The paper transcription is a
  separate pass — ~150 hours-derived numbers across `paper.tex`, `results_digest.md`,
  `docs/hours-intensive-margin-analysis.md`, two decision memos, `README.md:132` and
  `docs/HLD.md:98`.
- Latent, pre-existing: both Lee-bounds files sort `NA` last in `arrange()`. The Step-2 filter
  removes the exposure today, but the ordering itself is still NA-naive if a future extract
  reintroduces code 99 in a post-period year.

---

## Follow-up: the Lee-bounds selection rate (2026-09-21)

Harmonization introduced a mismatch in both Lee-bounds constructions. `s_ab` was
`mean(Employed == 1)` on the full frame, but the hours distribution it trims now excludes
reference-week absentees — so the trim proportion was derived on one denominator and applied to
another. `s_ab` is now the share whose **outcome is observed**, `mean(!is.na(WorkHoursCont))`,
written that way rather than by naming the gate conditions so it keeps tracking whatever defines
the estimation sample.

**This also resolved a live defect.** Before the change the DDD bounds *inverted* — lower 3.30763
above upper 3.30592, an empty identified set — which tripped the degenerate branch in
`imbens_manski_ci()` and returned a plain 1.96 critical value rather than a root-found one. The
bounds are now properly ordered and the critical value is genuine.

| | before this follow-up | after |
|---|---|---|
| DiD bounds | [−0.3783, +0.7095] | **[−0.5166, +0.8017]** |
| DiD Imbens–Manski | [−0.6720, 1.0043] | **[−0.8095, 1.0959]** |
| DDD bounds | [3.3076, **3.3059**] — inverted | **[3.1255, 3.4434]** — ordered |
| DDD Imbens–Manski | [1.2100, 5.2205] (*c*α 1.960, degenerate) | **[1.0208, 5.3237]** (*c*α 1.840) |
| Selection rates (DiD) | 0.7518 / 0.7639 / 0.7717 / 0.7961 | **0.7010 / 0.7058 / 0.6786 / 0.6964** |
| Trim by quartile | 632 / 56 / 117 / 263 (1,068) | **548 / 197 / 202 / 449 (1,396)** |

The headline DDD still excludes zero under the corrected bounds. Five CSVs moved — both bounds
tables, both selection-rate files, and `hours_lee_bounds_n_trimmed.csv`; the first two of those
were byte-identical under the original harmonization and move only now.

Recomputed *z*-tests (unchanged by this follow-up, since the subgroup point estimates do not depend
on the bounds): Arab vs Jewish DiD −0.720 (0.471), DDD +0.942 (0.346); women vs men DiD +2.406
(0.0161), DDD +3.461 (0.0005).
