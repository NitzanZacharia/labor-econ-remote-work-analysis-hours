# Low-Level Design: Motherhood Penalty / WFH Analysis Pipeline

Derived from [`docs/HLD.md`](HLD.md) and the actual current state of the repository. The original 81-column table below was pulled directly from a real cached `cleaned_df.rds` (372,741 rows × 81 columns) as it stood at the time — not reconstructed from reading code — see the Verification note at the end. `data_processing.R` has since grown 6 more derived columns (`WFH_RefWeek`, `WFH_Hours`, `WFH_Share`, `WFH_Arrangement`, `ISCO_masked`, `ISCO1`), documented in a follow-on subsection below the original table; those 6 were reconciled directly from the current code, **not** from a fresh live pull, so their exact final column position (as opposed to their existence, type, and derivation) is not independently re-verified the way rows 1-81 were. The dataset is currently **372,741 rows × 87 columns**.

## Data Schema

`cleaned_df` (the output of `load_and_clean_data()`) is a flat tibble, currently 372,741 rows × 87 columns (81 as of the original live pull below, plus 6 documented in the follow-on subsection). Columns fall into three classes:

- **Derived (new)** — created by `data_processing.R`, not present in the raw CBS extract.
- **Type-transformed** — a raw CBS column, converted to `factor` or recoded/grouped in place (same column name, new representation).
- **Raw passthrough** — an untouched raw CBS column (Hebrew-named, numeric or character), surviving the drop step unchanged.

### Full column list (original 81-column live pull)

| # | Column | Type | Class |
|---|---|---|---|
| 1 | `file_source` | character | Derived (added at ingestion) |
| 2 | `IDPUF` | numeric | Raw passthrough (cluster ID) |
| 3 | `ShnatSeker` | numeric | Raw passthrough (survey year) |
| 4 | `MachozMegurim` | factor | Type-transformed |
| 5 | `MisparYeladimAd14MB` | numeric | Raw passthrough |
| 6 | `Yeladim0_1MB` | numeric | Raw passthrough |
| 7 | `Yeladim2_4MB` | numeric | Raw passthrough |
| 8 | `Yeladim5_9MB` | numeric | Raw passthrough |
| 9 | `Yeladim10_14MB` | numeric | Raw passthrough |
| 10 | `Yeladim15_17MB` | numeric | Raw passthrough |
| 11 | `ShaotOzeretNK` | numeric | Raw passthrough |
| 12 | `GilYeledTzairMBNK` | numeric | Raw passthrough (used by `employment_by_child_age.R`) |
| 13 | `YeladimAd17MBNK` | numeric | Raw passthrough |
| 14 | `MisparMuasakim` | numeric | Raw passthrough |
| 15 | `MisparMuasakimChelki` | numeric | Raw passthrough |
| 16 | `MisparYeladimAd17MB` | numeric | Raw passthrough (source of `Mother`) |
| 17 | `MisparHorimYechidim` | factor | Type-transformed |
| 18 | `MisparYeladimAd17LeHoreYachidMB` | numeric | Raw passthrough |
| 19 | `GilYeledTzairHoreYachidMB` | numeric | Raw passthrough |
| 20 | `Min` | numeric | Raw passthrough (sex; always `2` post-filter) |
| 21 | `MatzavMishpachti` | factor | Type-transformed |
| 22 | `SemelEretzLeda` | numeric | Raw passthrough (source of `BirthContinent`) |
| 23 | `Dat` | factor | Type-transformed |
| 24 | `TeudaGvoha` | factor | Type-transformed & grouped (11 raw codes → 6 labels) |
| 25 | `AvadBeshavua` | numeric | Raw passthrough |
| 26 | `ShaotBederechKlal` | numeric | Raw passthrough |
| 27 | `Oved35Shaot` | numeric | Raw passthrough |
| 28 | `MisraMelea` | numeric | Raw passthrough |
| 29 | `SibaLeAvodaChelkit` | numeric | Raw passthrough |
| 30 | `MeunyanLaavod` | numeric | Raw passthrough |
| 31 | `AvadShanaAchrona` | numeric | Raw passthrough |
| 32 | `NayadutYishuvAvoda` | numeric | Raw passthrough |
| 33 | `SemelAnafKalkali` | character | Raw passthrough |
| 34 | `SemelMishlachYad` | character | Raw passthrough |
| 35 | `MaamadAvoda` | numeric | Raw passthrough |
| 36 | `KamaChodashimAvadBashana` | numeric | Raw passthrough (unused since the `Employed` redefinition) |
| 37 | `SibaLoAvadHashana` | numeric | Raw passthrough |
| 38 | `Leom` | numeric | Raw passthrough — **not** factor-converted (used as a filter value, not a regression factor) |
| 39 | `GilNK` | factor | Type-transformed |
| 40 | `ShaotAvodaBederechKlalNK` | numeric | Raw passthrough (source of `WorkHoursCont`) |
| 41 | `ChodsheiAvodaNK` | numeric | Raw passthrough |
| 42 | `MachozYishuvAvoda` | numeric | Raw passthrough |
| 43 | `DargatNayadut` | numeric | Raw passthrough (source of `WorksOutsideLocality`) |
| 44 | `TchunatAvodaShvuit` | numeric | Raw passthrough |
| 45 | `Muasak` | numeric | Raw passthrough (source of `Employed`) |
| 46 | `TchunatAvodaBederechKlal` | numeric | Raw passthrough |
| 47 | `TchunatAvodaShnatit` | numeric | Raw passthrough |
| 48 | `AnafKalkaliNK` | character | Raw passthrough |
| 49 | `MishkalSofi` | numeric | Raw passthrough (survey weight — unused anywhere) |
| 50 | `MishkalSofiAlafim` | numeric | Raw passthrough (survey weight — unused) |
| 51 | `MishkalShnati` | numeric | Raw passthrough (survey weight — unused) |
| 52 | `MishkalShnatiAlafim` | numeric | Raw passthrough (survey weight — unused) |
| 53 | `TchunatAvodaShvuitBZ` | numeric | Raw passthrough |
| 54 | `AnafKalkali_ISIC_R4_1` | character | Raw passthrough |
| 55 | `AnafKalkali_ISIC_R4_2` | character | Raw passthrough |
| 56 | `MishlachYad_ISCO_08_1` | character | Raw passthrough |
| 57 | `MishlachYad_ISCO_08_2` | numeric | Type-transformed (`as.numeric()` coerced; join key for the WFH-exposure index and DDD regressions — see the follow-on subsection below for `ISCO_masked`/`ISCO1`, added alongside it since this pull) |
| 58 | `MishlachYadBenZug` | character | Raw passthrough |
| 59 | `MishlachYadNK` | character | Raw passthrough |
| 60 | `NayadutYishuvAvodaMechushav` | numeric | Raw passthrough |
| 61 | `SemelAnafKalkaliMechushav` | character | Raw passthrough |
| 62 | `SemelMishlachYadMechushav` | character | Raw passthrough |
| 63 | `MaamadAvodaMechushav` | numeric | Raw passthrough |
| 64 | `KamaChodashimAvadBashanaMechusha` | numeric | Raw passthrough |
| 65 | `AvadBaaretsMityaesh` | numeric | Raw passthrough |
| 66 | `HitchilLaavod` | numeric | Raw passthrough |
| 67 | `KamaYamim` | numeric | Raw passthrough |
| 68 | `ShaotIkarit` | numeric | Raw passthrough |
| 69 | `Siba35` | numeric | Raw passthrough |
| 70 | `YoterShaot` | numeric | Raw passthrough |
| 71 | `AvodaMeHaBayit` | numeric | Raw passthrough (source of `WFH`) |
| 72 | `AvadMeHaBayit` | numeric | Raw passthrough (source of `WFH_RefWeek`) |
| 73 | `KamaShaot` | numeric | Raw passthrough (source of `WFH_Hours` / `WFH_Share`) |
| 74 | `HichlifAvoda` | numeric | Raw passthrough |
| 75 | `Mother` | integer | Derived |
| 76 | `Post` | integer | Derived |
| 77 | `Employed` | integer | Derived |
| 78 | `WFH` | numeric | Derived |
| 79 | `WorkHoursCont` | numeric | Derived |
| 80 | `BirthContinent` | factor | Derived |
| 81 | `WorksOutsideLocality` | integer | Derived |

**Schema-quality gap**: the ~65 raw-passthrough columns above have no explicit final-format contract — no renaming, no type normalization (numeric vs. character is whatever `read_csv()` guessed), no documented meaning beyond the original CBS codebook. Only the columns actually consumed downstream (§ below) have a defined contract. This is a real gap if the dataset is ever handed to someone without codebook access.

### Columns added since the original 81-column pull

Reconciled directly from the current `data_processing.R` (not a fresh live pull — see the note at the top of this document). All 6 are genuinely new columns (not present in the original pull), so they sit after column 81 in creation order; their exact final index is not independently re-verified.

| Column | Type | Class | Derivation |
|---|---|---|---|
| `WFH_RefWeek` | numeric | Derived | Reference-week WFH behaviour, from `AvadMeHaBayit` (same 1/2/9→1/0/NA mapping as `WFH`). Created immediately after `WFH` in `data_processing.R`'s WFH block. |
| `WFH_Hours` | numeric | Derived | Hours worked from home in the reference week, from `KamaShaot` (only defined when `WFH_RefWeek == 1`). |
| `WFH_Share` | numeric | Derived | `WFH_Hours / ShaotAvodaLeMaase`, capped at 1. |
| `WFH_Arrangement` | factor (3 levels) | Derived | Binned from `WFH_Share`: On-site / Hybrid / Fully remote. |
| `ISCO_masked` | logical | Derived | `TRUE` where the raw `MishlachYad_ISCO_08_2` held a CBS disclosure mask (`XX`, `7X`, …) rather than a numeric code. Created in the ISCO block, immediately after column 57's type transform. |
| `ISCO1` | numeric | Derived | 1-digit ISCO-08 major group, recovered from the first character of the raw code (survives partial masking, e.g. `7X` → `7`). |

See the "Analysis-critical derived columns" table below for each column's exact NA-rate contract and derivation logic.

### Analysis-critical derived columns (exact contract)

| Column | Type | Values / levels | NA rate | Derivation |
|---|---|---|---|---|
| `Employed` | integer | `{0, 1}` | **0.000%** | `1` iff `Muasak == 1`, else `0` (unemployed + not-in-labor-force both → `0`). **Secondary outcome variable** (and the selection variable for `WorkHoursCont`'s Lee-bounds correction) — see `docs/decisions/hours-ddd-pivot.md`. |
| `Mother` | integer | `{0, 1}` | **0.000%** | `1` iff `MisparYeladimAd17MB > 0` |
| `Post` | integer | `{0, 1}` | **0.000%** | `1` iff `ShnatSeker >= 2021` |
| `WFH` | numeric | `{0, 1}` | 64.726% | Usual work location, from `AvodaMeHaBayit`: `1`→`1`, `2`→`0`, `9` ("unknown")→**`NA`**, blank→`NA`. Only defined for `ShnatSeker >= 2021`; `NA` for all pre-2021 rows *by design* (question wasn't asked). The NA rate rose from 63.938% when code `9` stopped being silently recoded as `0` |
| `WFH_RefWeek` | numeric | `{0, 1}` | 68.629% | Reference-week behaviour, from `AvadMeHaBayit`, same code mapping. Asked only of the employed who worked that week (`AvadBeshavua == 1`), so the employed-but-absent are `NA`, not `0`. Disagrees with `WFH` in both directions — 6,182 rows in 2021 answer "no" to usual and "yes" to reference-week |
| `WFH_Hours` | numeric | `[0, 84]` | 68.648% | Hours worked from home in the reference week, from `KamaShaot` (asked only when `WFH_RefWeek == 1`). `0` when `WFH_RefWeek == 0`; `NA` when either hour item carries a CBS code in the 90s ("irregular"/"unknown") |
| `WFH_Share` | numeric | `[0, 1]` | 68.659% | `WFH_Hours / ShaotAvodaLeMaase`, capped at 1. `0` when `WFH_RefWeek == 0`; `NA` whenever `WFH_RefWeek` is `NA` or either hour item is a 90s code. Verified `KamaShaot <= ShaotAvodaLeMaase` in 18,619/18,619 valid 2021 cases |
| `WFH_Arrangement` | factor (3 levels) | `On-site` (91,480), `Hybrid` (15,685), `Fully remote` (9,655) | 68.659% | Binned from `WFH_Share`: `0` → On-site, `(0, 0.9)` → Hybrid, `>= 0.9` → Fully remote |
| `ISCO_masked` | logical | `{TRUE, FALSE}` | **0.000%** | `TRUE` where the raw `MishlachYad_ISCO_08_2` held a CBS disclosure mask (`XX`, `7X`, …) rather than a code. 2.365% of the analysis sample; 7.5% of all employed in the raw 2021 file, since masking concentrates in thin occupation cells |
| `ISCO1` | numeric | `[1, 9]` | 18.052% | 1-digit ISCO-08 major group, recovered from the first character of the raw code so partially-masked values (`7X` → `7`) survive. Non-`NA` for 231 employed 2021 rows that `MishlachYad_ISCO_08_2` loses entirely |
| `WorkHoursCont` | numeric | `[4, 78.5]` | 30.736% | Bin-median lookup for `ShaotAvodaBederechKlalNK` codes 1–10; codes 11/12 imputed from the median of the matching bin range, computed separately within each `Post` period (not pooled across 2017–2023 — pooling would blend the pre/post hour distributions and dampen any real period-specific intensity shift); `NA` for codes 0 and 99. **Primary outcome variable** (project-wide, as of `docs/decisions/hours-ddd-pivot.md`) — defined only for rows that are both `Employed == 1` **and** `AvadBeshavua == 1` (worked the reference week). That second gate harmonizes the hours population across survey years: the 2017 file coded the employed-but-absent as bin 0 ("no usual hours") while 2018+ gave them a real code, and since absenteeism is mother-skewed that produced a spurious 2017 pre-period gap. See `docs/decisions/hours-population-harmonization.md`. The NA rate is therefore ~23% non-employed plus ~8% employed-but-absent, in every year by design — not missingness to investigate. |
| `TeudaGvoha` | factor (6 levels) | `Below High School`, `High School (no matriculation)`, `Matriculation (Bagrut)`, `Post-secondary, non-academic`, `Academic Degree (BA/MA/PhD)`, `Other/No Certificate` | 2.135% | Collapsed from 11 raw codes; `NA` reserved for raw code 99 ("unknown") |
| `BirthContinent` | factor (6 levels) | `Africa`, `Asia`, `Europe`, `Israel`, `North America`, `Other` | 0.218% | Collapsed from 16 raw `SemelEretzLeda` codes; `NA` reserved for raw code 16 (ambiguous "unknown"/"other" in CBS's own codebook) |
| `WorksOutsideLocality` | integer | `{0, 1}` | 16.552% | From `DargatNayadut`: `1`→`0`, `2`–`7`→`1`, `0`/`8`/`NA`→`NA` |

Regression-control columns (`MatzavMishpachti`, `Dat`, `GilNK`, `MachozMegurim`, `MisparHorimYechidim`) are all `factor`, all **0.000% NA** (confirmed from the live data).

## Validation & Thresholds

### Hard-fail checks (pipeline should stop; implemented in `validation.R`'s `validate_cleaned_df()`)

| Check | Rule | Rationale |
|---|---|---|
| Sex filter invariant | `all(cleaned_df$Min == 2)` | `Min==2` is applied once at filter time; any other value surfacing downstream means the filter itself broke |
| Age filter invariant | `all(as.integer(as.character(cleaned_df$GilNK)) %in% 3:7)` | Same reasoning for the age-group filter |
| Year filter invariant | `all(cleaned_df$ShnatSeker %in% c(2017,2018,2019,2021,2022,2023))` | 2020 must never appear |
| `Employed`/`Mother`/`Post` NA rate | must equal exactly `0` | All three are `if_else()`-derived from always-defined inputs (`Muasak`, `MisparYeladimAd17MB`, `ShnatSeker`); *any* NA appearing means a regression in the derivation logic, not real-world missingness |
| Row count sanity | `nrow(cleaned_df) > 0` after each filter stage | Catches a filter that accidentally empties the frame |

### Soft-fail / warn thresholds (calibrated against the real observed rates above)

| Rule | Threshold | Basis |
|---|---|---|
| Any *regression control's* NA rate | warn if `> 5%` | None currently exceed this — `TeudaGvoha` at 2.1% is the highest control-level NA rate observed; a control crossing 5% would meaningfully shrink the regression's effective sample via `fixest`'s listwise deletion |
| Any *comparative-stats-only* variable's NA rate | warn if `> 70%` (informational only below that) | `WFH` at 63.9% is structurally expected (pre-2021 undefined by design), not a data-quality problem — the threshold should sit above it so `WFH` doesn't false-positive, while still catching a genuinely broken variable |
| `WorksOutsideLocality` NA rate | no warn below `~20%` | Its 16.6% NA is structurally expected (`DargatNayadut` codes 0/8 = didn't work / unknown), consistent across years |
| Unascertained usual-hours codes, **per survey year** | warn if any year has `> 2%` of `Employed == 1` rows at raw code 0 or 99, excluding the documented 2017 exception | The signature of the defect fixed in `docs/decisions/hours-population-harmonization.md`: 2017 sat at 9.77% against ~0% everywhere else, because that file coded the employed-but-absent as bin 0. Keyed on the **raw** code, not `is.na(WorkHoursCont)` — post-harmonization the NA rate is ~10%/year by design, so an NA-based rule would be both noisy and blind to the thing it is meant to catch. A *new* year crossing the threshold means the coding changed again |

### Null-handling logic, by variable class

1. **Derived binary outcomes** (`Employed`, `Mother`, `Post`) — never `NA` by construction; treat any `NA` as a hard failure, not data to impute. `Employed` is now the secondary outcome variable; the primary outcome, `WorkHoursCont`, is continuous and handled separately (see the "Analysis-critical derived columns" table above).
2. **Category-grouping variables** (`TeudaGvoha`, `BirthContinent`) — `NA` is reserved *specifically* for the raw "unknown" code (99 / 16 respectively), never introduced by the grouping logic itself for a valid code. `fixest::feols()` silently listwise-deletes these rows; that's acceptable given the low rates above, but should be watched if raw data quality changes.
3. **Structurally-conditional variables** (`WFH`) — `NA` encodes "question not applicable this year," not missingness. Must never be imputed or treated as `0`.
4. **Mobility/commute variables** (`WorksOutsideLocality`) — `NA` covers both "didn't work" and "unknown," which are semantically different but not currently distinguished; flagged as a modeling simplification, not a defect.

### Schema-drift check (implemented in `validation.R`'s `check_schema_drift()`)

`data_processing.R` drops column ranges positionally (`select(-(a:b))`), which depend on the raw CSV's column *order*, not names — originally 7 ranges, now 5 (2 were converted to explicit `any_of()`-based name drops after `2017_Data.csv` turned out to lack all 4 of those boundary columns entirely, which made the positional check fail on a file that was never going to contain them in the first place). `check_schema_drift(folder_path)` asserts, for every year's raw CSV independently, that the named boundary columns of each of the 5 remaining ranges (`Yeladim0_1Prat`/`Yeladim15_17Prat`, `MisparHachlafa`/`YachasKirvaNK`, `MisparNefashotGilAvodaV2007`/`MisparPrat`, `ChipusAvodaSherutTaasuka`/`ChipusAvodaOfenAcher`, `RamatDat`/`BituachLeumi`) occupy the same relative column position across every file, throwing a clear error rather than silently dropping the wrong columns if a future CBS release reorders them. Called from `main.R` before every fresh (non-cached) `load_and_clean_data()` run.

## Core Function Signatures

### Existing (verified against current source; all previously-"Proposed" functions in this section have since been built)

```r
# ── data_processing.R ──────────────────────────────────────────────────────
load_and_clean_data(folder_path: character(1),
                     sex_filter: character = c("women", "men")) -> tibble  # 87 cols, see Data Schema
# sex_filter defaults to "women" (Min==2); "men" selects Min==1 (the Gender Placebo Test).
# Side effects: reads every *.csv in folder_path; stop()s if folder_path doesn't exist.

# ── validation.R ────────────────────────────────────────────────────────────
validate_cleaned_df(cleaned_df: tibble, sex_filter: character = c("women", "men")) -> invisible(TRUE)
# stop()s on hard-fail checks (see Validation & Thresholds); warning()s on soft-fail thresholds.

check_schema_drift(folder_path: character(1)) -> invisible(TRUE)
# stop()s if any of the 5 positional-range boundary columns has moved between yearly CSVs.

check_idpuf_panel_structure(cleaned_df: tibble) ->
  invisible(list(
    n_idpuf = integer(1), multi_year_n = integer(1), cross_period_n = integer(1),
    idpuf_years = tibble, idpuf_periods = tibble
  ))
# Reporting-only: how much IDPUF repeats across ShnatSeker years / the Post==0-vs-1 divide.

check_wfh_refweek_avadbeshavua(cleaned_df: tibble) ->
  invisible(list(available = logical(1), n = integer(1),
                  consistent = integer(1), inconsistent = integer(1), indeterminate = integer(1)))
# Verifies (doesn't assume) that WFH_RefWeek's blank-AvadMeHaBayit rows coincide with
# AvadBeshavua != 1, among employed Post==1 rows. Degrades to available=FALSE if AvadBeshavua
# isn't present in cleaned_df. warning()s if any row contradicts the claim.

# ── comparative_statistics.R ────────────────────────────────────────────────
run_comparative_stats(cleaned_df: tibble) ->
  invisible(list(
    missing_pct = tibble, emp_by_mother = tibble, mobility_by_year = tibble,
    plots = list(mobility = ggplot)
  ))

# ── basic_regression.R / basic_reg_compared_data.R ──────────────────────────
# Secondary (extensive-margin) regressions -- see intensive_margin_regression.R below for the
# primary (hours) regression, per docs/decisions/hours-ddd-pivot.md.
basic_reg(cleaned_data: tibble) ->
  invisible(list(table = etable_df, models = list(employed = fixest)))
# Employed ~ Mother + Post + Mother:Post + DEFAULT_CONTROLS, cluster = ~IDPUF.

basic_reg_comp(cleaned_data: tibble) ->
  invisible(list(table = etable_df, models = list(employed = fixest, employed_muasak = fixest)))
# Same formula as basic_reg(), fit on the full sample and on filter(!is.na(Muasak)).
# Not called from main.R by default.

# ── intensive_margin_regression.R / intensive_margin_lee_bounds.R ──────────
# Primary (intensive-margin, hours) regressions -- see docs/decisions/hours-ddd-pivot.md.
run_intensive_margin_reg(cleaned_df: tibble, controls: character = DEFAULT_CONTROLS) ->
  invisible(list(table = etable_df, models = list(hours = fixest)))
# WorkHoursCont ~ Mother + Post + Mother:Post + controls, cluster = ~IDPUF, Employed==1 only.

run_intensive_margin_lee_bounds(cleaned_df: tibble, controls: character = DEFAULT_CONTROLS) ->
  invisible(list(
    table = tibble,   # bound (lower/point/upper), mother_post_coef
    models = list(point = fixest, lower = fixest, upper = fixest),
    diagnostics = list(selection_rates = tibble, s11_counterfactual = numeric(1),
                        excess_selection = logical(1), trim_prop = numeric(1), n_trimmed = integer(1))
  ))
# Lee (2009) trimming bounds for run_intensive_margin_reg()'s Employed==1 selection risk —
# see docs/decisions/intensive-margin-lee-bounds.md.

# ── hours_ddd_regression.R / hours_ddd_lee_bounds.R / imbens_manski_ci.R ────
# Primary DDD (intensive margin, hours) -- generalizes run_intensive_margin_lee_bounds() (above)
# to a single triple-interaction hours regression with pure occupation-level exposure, plus a
# second-stage occupation-by-occupation mechanism regression. See docs/decisions/hours-ddd-pivot.md
# for full design and results. Wired into main.R section 8a, unconditional (no feature flag), run
# three times -- once each for the calibrated/external/realized occupation-level exposure measures.
# The secondary DDD's own equivalent (ddd_regression.R's run_ddd_regression()) was removed -- see
# docs/decisions/employment-ddd-robustness-removal.md.
run_hours_ddd_regression(cleaned_df: tibble, exposure_index: tibble,
                          controls: character = DEFAULT_CONTROLS) ->
  invisible(list(
    table = etable_df, model = fixest, n_employed = integer(1), n_matched = integer(1),
    models = list(ddd = fixest, mechanism = lm), mechanism_data = tibble,
    dropped_occupations = list(data = tibble, n_dropped = integer(1),
                                mean_exposure_dropped = numeric(1), mean_exposure_retained = numeric(1))
  ))
# WorkHoursCont ~ Mother*Post*WFH_Exposure + controls (pure occupation-level WFH_Exposure, joined
# by MishlachYad_ISCO_08_2), cluster = ~MishlachYad_ISCO_08_2, Employed==1 only. Second-stage
# mechanism regression: per-occupation Mother:Post estimates from run_intensive_margin_reg(),
# precision-weighted (1/se_j^2) against occupation-level exposure -- mirrors the removed
# run_ddd_regression()'s Model 2.

# ── hours_ddd_event_study.R / tidy_event_study_coefs.R / build_event_study_plot.R ──────────
# Year-by-year event-study version of the primary DDD above, plus its ggplot builder. Exists because
# the two pretrend models under Diagnostics.R / hours_diagnostics.R are both DiD-level
# (Mother x year): the DDD's identifying assumption is that the mother/non-mother gap trended
# together ACROSS exposure levels, which a test averaging over exposure cannot detect a violation of.
# Wired into main.R section 8a (not section 7 -- it needs section 8's exposure measure),
# unconditional. See docs/decisions/ddd-event-study.md.
run_hours_ddd_event_study(cleaned_df: tibble, exposure_index: tibble,
                          controls: character = DEFAULT_CONTROLS,
                          ref_year: numeric(1) = 2019) ->
  invisible(list(
    table = etable_df, model = fixest,
    coefs = tibble,   # term, year, estimate, std_error, t_stat, p_value, ci_low, ci_high, period
    ref_year = numeric(1), term_suffix = character(1),   # "MotherWFH"
    n_employed = integer(1), n_matched = integer(1)
  ))
# WorkHoursCont ~ Mother*WFH_Exposure + i(ShnatSeker, ref) + i(ShnatSeker, Mother, ref)
#   + i(ShnatSeker, WFH_Exposure, ref) + i(ShnatSeker, MotherWFH, ref) + controls,
# cluster = ~MishlachYad_ISCO_08_2, Employed==1 only, same occupation-level exposure join as
# run_hours_ddd_regression(). MotherWFH is a materialized Mother*WFH_Exposure column because
# fixest's i(f, var) takes a variable, not an expression. Coefficients of interest are named
# "ShnatSeker::<year>:MotherWFH"; all three lower-order year interactions are required for the
# estimate to be a triple difference at all. p_value/ci_* use t on degrees_freedom(model, "t")
# (G-1 ~ 40 clusters), matching etable()'s own printed values rather than a normal approximation.
# term_suffix is returned so main.R can build run_pretrend_joint_test()'s `keep` regex from it
# instead of re-typing the literal at the call site.

tidy_event_study_coefs(model: fixest, term_suffix: character(1), ref_year: numeric(1),
                        factor_var: character(1) = "ShnatSeker") -> tibble
# One row per non-reference year: term, year, estimate, std_error, t_stat, p_value, ci_low, ci_high,
# period ("Pre"/"Post" relative to ref_year). Selects terms by the ANCHORED pattern
# ^<factor_var>::(\d{4}):<term_suffix>$ -- unanchored, term_suffix "Mother" would also collect
# ":MotherWFH", silently mixing two estimands (same hazard as pretrend_wald_test.R's `keep`).
# p_value/ci_* use t on degrees_freedom(model, "t"), reproducing etable()'s printed values.
# stop()s if no term matches, rather than returning a 0-row frame that exports an empty CSV.
# Shared by run_hours_ddd_event_study() (term_suffix "MotherWFH") and run_hours_diagnostics()
# (term_suffix "Mother"), so the two event studies cannot drift apart in their inference.

build_event_study_plot(coefs: tibble, ref_year: numeric(1) = 2019,
                       treatment_year: numeric(1) = 2021,
                       title: character(1) = NULL, subtitle: character(1) = NULL,
                       y_label: character(1) = "Mother x Year x WFH Exposure (95% CI)",
                       se_note: character(1) = "occupation-clustered standard errors") ->
  invisible(list(data = tibble, plot = ggplot))   # NULL if coefs is NULL/0-row
# Draws BOTH of the paper's event studies: Figure 6 (DiD, from run_hours_diagnostics()'s
# pretrend_coefs, se_note "standard errors clustered by individual") and Figure 7 (DDD, from
# run_hours_ddd_event_study()'s coefs, default se_note). se_note is a parameter because the two
# cluster at different levels and the caption states which.
# Pointrange + 95% CI by year, geom_hline(0), dotted vertical rule at the (ref_year+treatment_year)/2
# midpoint so it lands in the empty 2020 gap rather than on a plotted estimate. ref_year is
# re-inserted as a hollow, zero-width zero (it has no row in coefs -- it is the omitted category).
# x breaks are restricted to observed years so the axis does not invent a 2020 tick. stop()s if coefs
# lacks a required column; returns NULL (with a message) if coefs is absent -- matching
# build_hours_subgroup_comparison()/build_mechanism_scatter().

run_hours_ddd_lee_bounds(cleaned_df: tibble, exposure_index: tibble, exposure_cells: tibble,
                          controls: character = DEFAULT_CONTROLS) ->
  invisible(list(
    table = tibble,   # bound (lower/point (untrimmed)/upper), coef, se, ci_low, ci_high
    models = list(point = fixest, lower = fixest, upper = fixest),
    diagnostics = list(quartile_selection_rates = tibble, n_trimmed_by_quartile = tibble,
                        n_trimmed_total = integer(1)),
    imbens_manski_ci = list(c_alpha = numeric(1), lower = numeric(1), upper = numeric(1))
  ))
# Generalized Lee (2009) bounds for run_hours_ddd_regression()'s Employed==1 selection risk:
# selection-rate counterfactual (s11_counterfactual = s10 + (s01 - s00)) stratified by quartile of
# the cell-based WFH_Exposure (build_exposure_cells(), defined for employed and non-employed
# alike -- reuses robustness/age_balance_robustness.R's compute_pre_period_quartile_breaks()/
# assign_wfh_quartile()), while the outcome regression itself uses the occupation-level
# WFH_Exposure. warning()s when a quartile's Mother==1,Post==1 cell has fewer than
# MIN_CELL_WARN (30) rows (noisy trim_prop). See docs/decisions/hours-ddd-pivot.md.

imbens_manski_ci(theta_L: numeric(1), theta_U: numeric(1), se_L: numeric(1), se_U: numeric(1),
                  conf_level: numeric(1) = 0.95) ->
  list(c_alpha = numeric(1), lower = numeric(1), upper = numeric(1))
# Imbens & Manski (2004) confidence interval for a partially-identified [theta_L, theta_U] bound
# (not just each endpoint's own sampling interval), extracted from intensive_margin_lee_bounds.R
# so both Lee-bounds files (intensive-margin and hours-DDD) share the same closed-form solver.
# Collapses to the ordinary +-1.96*se interval when theta_U == theta_L. See
# docs/decisions/hours-ddd-pivot.md.

# ── employment_by_child_age.R ────────────────────────────────────────────────
employment_by_child_age(cleaned_df: tibble) ->
  invisible(list(
    emp_raw = tibble, emp_by_period = tibble, model = fixest,
    plots = list(raw = ggplot, period = ggplot, adjusted = ggplot)
  ))

# ── Diagnostics.R / hours_diagnostics.R ────────────────────────────────────
run_diagnostics(cleaned_df: tibble) ->
  invisible(list(
    did_table = tibble, na_summary = tibble, miss_pattern = tibble,
    pretrend_table = etable_df, pretrend_model = fixest
    # Employed ~ Mother + i(ShnatSeker,ref=2019) + i(ShnatSeker,Mother,ref=2019) + controls
  ))
# Side effects: iplot(reg_pretrend, i.select = 2, ...) draws to whatever device is active (no
# dev.new()) -- needs an explicit device (main.R) or a null-device wrapper (tests) around the call.
# Secondary (employment) outcome.

run_hours_diagnostics(cleaned_df: tibble) ->
  invisible(list(
    hours_by_period = tibble, pretrend_table = etable_df, pretrend_model = fixest
    # WorkHoursCont ~ Mother + i(ShnatSeker,ref=2019) + i(ShnatSeker,Mother,ref=2019) + controls,
    # data = filter(cleaned_df, Employed == 1)
  ))
# Primary (hours) outcome analog. Also returns pretrend_coefs (tidy_event_study_coefs() on the
# Mother x year terms) -- main.R draws it with build_event_study_plot() as the paper's Figure 6.
# Unlike run_diagnostics(), this function has NO graphics side effect: the iplot() call it used to
# make was removed with that port, so main.R wraps it in no device. Omits run_diagnostics()'s
# Employed-NA-specific missingness audits (no hours analog).

# ── gender_placebo.R / hours_gender_placebo.R ─────────────────────────────────
run_gender_placebo(folder_path: character(1), cleaned_men: tibble = NULL, cleaned_women: tibble = NULL,
                    exposure_calibrated: tibble = NULL,
                    exposure_csv_path: character(1) = "data/israeli_cbs_wfh_2digit.csv") ->
  invisible(list(cleaned_men = tibble, result = list(...), ddd_placebo = list(...) | NULL))
  # result is basic_reg()'s own return; ddd_placebo is run_gender_ddd_placebo()'s return (NULL if
  # no exposure_calibrated could be obtained/supplied). Secondary (employment) outcome.
run_gender_ddd_placebo(cleaned_men: tibble, exposure_calibrated: tibble,
                        controls: character = DEFAULT_CONTROLS) ->
  list(exposure_cells_men = tibble, models = list(additive = fixest | NULL, fe = fixest | NULL))
# Called from main.R via run_gender_placebo(). Both feols() calls cluster on the (GilNK, TeudaGvoha,
# MachozMegurim) cell, matching main.R's secondary DDD -- WFH_Exposure is cell-constant here too.

run_hours_gender_placebo(folder_path: character(1), cleaned_men: tibble = NULL,
                          exposure_index: tibble = NULL,
                          exposure_csv_path: character(1) = "data/israeli_cbs_wfh_2digit.csv") ->
  invisible(list(cleaned_men = tibble, result = list(...), ddd_placebo = list(...) | NULL))
  # result is run_intensive_margin_reg()'s own return; ddd_placebo is
  # run_hours_gender_ddd_placebo()'s return (NULL if no exposure_index could be obtained/supplied).
  # Primary (hours) outcome analog.
run_hours_gender_ddd_placebo(cleaned_men: tibble, exposure_index: tibble,
                              controls: character = DEFAULT_CONTROLS) ->
  list(n_employed = integer(1), n_matched = integer(1), model = fixest | NULL)
# Called from main.R via run_hours_gender_placebo(). Occupation-level exposure_index (not cell-based) -- no need
# to rebuild a cell-based exposure measure for men, since occupation-level exposure is sex-agnostic.
# Employed==1 subsample, cluster = ~MishlachYad_ISCO_08_2, matching hours_ddd_regression.R.

# ── wfh_exposure_index.R / wfh_exposure_cells.R / isco_masking_diagnostics.R /
#    ddd_collinearity_diagnostics.R ────────────────────────────────────────
build_wfh_exposure_index(cleaned_df: tibble,
                          isco_col: character(1) = "MishlachYad_ISCO_08_2",
                          wfh_col: character(1) = "WFH",
                          ref_year: numeric = 2021,
                          weight_col: character(1) = NULL, min_n: numeric(1) = 0) -> tibble
# occupation_code, wfh_exposure, n. ref_year anchored to 2021, not the research doc's literal 2020
# (excluded from this project's sample) -- see docs/decisions/checkpoint6-wfh-anchor-year.md.

build_exposure_isco2(path: character(1) = "data/israeli_cbs_wfh_2digit.csv") -> tibble  # ISCO2, tele_ext
# Reads the external Dingel & Neiman teleworkability score. `path` exists so callers/tests can
# point elsewhere; the default file isn't present in every environment.

calibrate_isco_exposure(cleaned_df: tibble, exposure_isco2: tibble, wfh_col: character(1) = "WFH",
                         ref_year: numeric = c(2022, 2023), gap_threshold: numeric(1) = 0.5,
                         conf_level: numeric(1) = 0.95) -> tibble
# ISCO2, tele_ext, n, realized_wfh, se_clustered, se_na_reason, gap, margin, swap,
# wfh_exposure_calibrated. One-sided cluster-robust test of whether realized WFH exceeds the
# external score by more than gap_threshold, at conf_level confidence — see
# docs/decisions/calibrated-exposure-and-cell-ddd.md.

build_exposure_cells(raw_all: tibble, exposure_isco2: tibble,
                      cell_vars: character = c("Min", "GilNK", "TeudaGvoha", "MachozMegurim")) -> tibble
# Pre-period (2017-2019) shift-share exposure by demographic cell, weighted by MishkalSofi. The
# primary DDD's exposure regressor -- unlike the other 3 measures, defined for non-employed rows too.
# The function's default cell_vars (above) is unchanged, but main.R's real call site now passes an
# explicit, finer cell_vars (adds MatzavMishpachti, Dat) -- deliberately different from
# cell_fe_vars (the regression's own controls/FE) to restore identifying power for
# Mother:Post:WFH_Exposure. See docs/decisions/exposure-cell-granularity-fix.md.

check_isco_masking_sensitivity(cleaned_df: tibble, wfh_col: character(1) = "WFH",
                                ref_year: numeric = c(2022, 2023)) ->
  invisible(list(by_group = tibble, comparison_wide = tibble, model = fixest))
# Proxy check: realized WFH, masked vs. unmasked, within each ISCO1 major group.

check_spec1_collinearity(ddd_df: tibble, cell_fe_vars: character, controls: character) ->
  invisible(list(r2_wfh_exposure_on_cells = numeric(1), vif_wfh_exposure = numeric(1),
                  condition_number = numeric(1)))
# Runtime collinearity diagnostic for the secondary (employment) DDD's Spec 1. Base R only (lm(), kappa()) --
# deliberately no car dependency.

check_wfh_first_stage_relevance(ddd_df: tibble, controls: character = DEFAULT_CONTROLS) ->
  invisible(list(level_reg = fixest, dynamic_reg = fixest, table = etable))
# First-stage relevance check: does WFH_Exposure predict realized WFH_RefWeek (Post==1 only)? See
# docs/decisions/null-vs-power-audit.md.

compute_ddd_mde(model: fixest, coef_name: character(1) = "Mother:Post:WFH_Exposure",
                 sig_level: numeric(1) = 0.05, power: numeric(1) = 0.8,
                 baseline_rate: numeric(1) = NULL) ->
  invisible(list(coef_name, point_estimate, se, sig_level, power, mde, within_mde))
# Closed-form minimum detectable effect for a fitted model's coefficient. Base R only (qnorm()) --
# see docs/decisions/null-vs-power-audit.md.

# ── robustness/balance_test.R / age_balance_robustness.R / pretrend_wald_test.R ─────────────
# Secondary DDD's own occupation-level robustness regression (ddd_regression.R's
# run_ddd_regression()) was removed -- see docs/decisions/employment-ddd-robustness-removal.md.
run_balance_test(cleaned_df: tibble, controls: character = DEFAULT_CONTROLS,
                  exposure_cells: tibble = NULL, exposure_calibrated: tibble = NULL,
                  exposure_csv_path: character(1) = "data/israeli_cbs_wfh_2digit.csv") ->
  invisible(list(pre_df = tibble, gilnk_balance = tibble, gilnk_ttests = tibble,
                  cat_distributions = tibble, cat_chisq = tibble))
# Pre-period (ShnatSeker < 2020) covariate balance, Mother vs. non-Mother, by WFH_Exposure
# quartile. pre_df is row-level -- excluded from export_all_results() (disclosure risk).

diagnose_gilnk_by_quartile(cleaned_df: tibble, exposure_cells: tibble) ->
  invisible(list(gap_by_quartile = tibble, breaks = numeric(5), pre_df = tibble))
# gap_by_quartile: mean_GilNK_Mother0/1, gap_Mother1_minus_0, t_stat, p_value, n, per quartile.
# Verified against real data; refreshed 2026-09-19: gap is largest in Q1 (-0.974 GilNK units, t = -94.0) and
# shrinks/reverses by Q4 -- see docs/decisions/age-balance-robustness-chain.md.

run_ddd_age_interacted(cleaned_df: tibble, exposure_cells: tibble,
                        controls: character = DEFAULT_CONTROLS) ->
  invisible(list(additive = fixest, fe = fixest))
# Secondary DDD formulas (main.R §8b) + Mother:GilNK. Comparison spec, not a main.R replacement.

build_gilnk_rake_weights(cleaned_df: tibble, exposure_cells: tibble) ->
  list(weights = tibble(WFH_Exposure_Q, Mother, GilNK, rake_weight), breaks = numeric(5))
run_ddd_reweighted(cleaned_df: tibble, exposure_cells: tibble,
                    controls: character = DEFAULT_CONTROLS, rake: list = NULL) ->
  invisible(list(rake = list(...), additive = fixest, fe = fixest))
# Pre-period GilNK-raking weights (by WFH_Exposure quartile x Mother), applied via weights=
# to the full-period regression. Comparison spec, not a main.R replacement.

# Hours-outcome (primary DDD) analogs -- occupation-level exposure_index (not cell-based
# exposure_cells) is the actual regressor, matching hours_ddd_regression.R's own specification;
# see docs/decisions/hours-ddd-pivot.md.
run_hours_ddd_age_interacted(cleaned_df: tibble, exposure_index: tibble,
                              controls: character = DEFAULT_CONTROLS) ->
  invisible(list(model = fixest))
# WorkHoursCont ~ Mother*Post*WFH_Exposure + Mother:GilNK + controls, Employed==1, occupation-level
# exposure, cluster = ~MishlachYad_ISCO_08_2. Single spec (no cell-FE alternative -- a cell FE would
# be orthogonal to, not collinear with, an occupation-level regressor).

run_hours_ddd_reweighted(cleaned_df: tibble, exposure_cells: tibble, exposure_index: tibble,
                          controls: character = DEFAULT_CONTROLS, rake: list = NULL) ->
  invisible(list(rake = list(...), model = fixest))
# Reuses build_gilnk_rake_weights()'s cell-based quartile grouping unchanged for the weight
# computation, then joins occupation-level exposure_index for the actual regression --
# WorkHoursCont ~ Mother*Post*WFH_Exposure + controls, weights = rake_weight,
# cluster = ~MishlachYad_ISCO_08_2.

run_pretrend_joint_test(pretrend_model: fixest,
                         keep: character(1) = "ShnatSeker::(2017|2018):Mother$",
                         label: character(1) = "Joint Wald, H0: pre-2020 Mother:year coefficients = 0")
  -> invisible(wald_result + list(table = data.frame))
# Joint Wald test, H0: a fitted pretrend model's pre-2020 interactions of interest are jointly zero.
# Fully generic -- run three times: the secondary DDD's DiD pretrend model (Diagnostics.R), the
# primary outcome's DiD pretrend model (hours_diagnostics.R), and the primary DDD's own
# triple-interaction event study (hours_ddd_event_study.R, which passes
# keep = "ShnatSeker::(2017|2018):MotherWFH$" and its own label).
# The default `keep` is ANCHORED with `$` on purpose: unanchored, "...:Mother" also matches
# "...:MotherWFH", so a DDD event-study model would silently be tested on 4 restrictions spanning
# two estimands while still looking like a well-formed 2-restriction pretrend test. `label` is
# parameterized because it is written into the exported one-row table, and three F-statistics now
# reach outputs/. See docs/decisions/ddd-event-study.md.

# All wired into main.R behind RUN_AGE_BALANCE_ROBUSTNESS (default TRUE as of 2026-09-19) -- see
# docs/decisions/age-balance-robustness-chain.md.

# ── israeli_market_mismatch.R ────────────────────────────────────────────────
check_market_mismatch(cleaned_df: tibble, exposure_path: character(1) = "data/israeli_cbs_wfh_2digit.csv",
                       ...) -> tibble
# calibrate_isco_exposure()'s output plus israel_vs_us_gap, abs_mismatch; sorted desc(abs_mismatch).
# Descriptive-only; not sourced by main.R (invoked via run_mismatch.R).

# ── export_results.R ──────────────────────────────────────────────────────
export_all_results(results_list: list, output_dir: character(1) = "outputs") -> invisible(character)
# Recursively walks results_list: data frames -> CSV, ggplots -> PNG, fixest/lm objects skipped.
# Returns the vector of file paths written.

# ── descriptive_table.R ───────────────────────────────────────────────────
build_descriptive_table(cleaned_df: tibble) -> list(continuous: tibble, categorical: tibble)
# The paper's Table 1. cat_vars = setdiff(DEFAULT_CONTROLS, "GilNK") -- GilNK is reported
# continuously alongside age. Level labels are the CBS codebook's, confirmed with the authors.

# ── clustered_se.R ────────────────────────────────────────────────────────
clustered_se(df: data.frame, outcome: character(1), cluster: character(1) = "IDPUF") -> tibble
# Cluster-robust SE/CI for a cell mean, via feols(y ~ 1). Returns NA-filled row for <2 rows.
# Point estimates are unchanged by construction -- any movement in one is a bug.

# ── ddd_mde_diagnostics.R ─────────────────────────────────────────────────
compute_ddd_mde(model: fixest, coef_name: character(1), baseline: numeric(1),
                 power: numeric(1) = 0.80, alpha: numeric(1) = 0.05) -> tibble
# Closed-form MDE = (z_{1-a/2} + z_power) * SE, reported both absolutely and as a share of
# baseline, on the scale the regressor actually varies over (not a unit change).

# ── wfh_first_stage_check.R ───────────────────────────────────────────────
check_wfh_first_stage_relevance(panel: tibble, controls: character = DEFAULT_CONTROLS) -> list
# Shift-share relevance test: does WFH_Exposure predict realized WFH_RefWeek once Post == 1?
# Static + year-interacted specs. Requires data_processing.R and ddd_collinearity_diagnostics.R.

# ── hours_subgroup_comparison.R ───────────────────────────────────────────
build_hours_subgroup_comparison(estimates: tibble, placebo: logical(1) = FALSE,
                                 x_label: character(1) = NULL) -> list(data: tibble, plot: ggplot)
# Coefficient-comparison figure for the Jewish/Arab and gender-placebo splits.

# ── paper_theme.R ─────────────────────────────────────────────────────────
theme_paper(base_size: numeric(1) = 11) -> theme        # + PAPER_PALETTE, a constant
# One theme/palette for every figure. PAPER_PALETTE separates the mother_status and period hues
# that previously collided across scripts.

# ── hours_descriptive_plots.R ─────────────────────────────────────────────
build_hours_descriptive_plots(cleaned_df: tibble, hours_by_period: tibble = NULL)
  -> list(hours_by_year, hours_by_period, raw_did, plots)
# hours_by_period is passed, not recomputed, so the figure and
# outputs/hours_diagnostics_hours_by_period.csv are physically the same numbers.

# ── hours_dose_response.R ─────────────────────────────────────────────────
build_hours_dose_response(cleaned_df: tibble, exposure_index: tibble,
                           measure_label: character(1) = "...") -> list(data, cell_means, breaks, plot)
# Raw hours DiD within each quartile of OCCUPATION-level exposure -- the DDD's own regressor,
# deliberately not the cell-based index. Cell arithmetic only, no regression. `data` carries
# each quartile's mean_exposure (added 2026-09-22) so the DDD's per-unit coefficient can be
# turned into an implied top-minus-bottom-quartile effect.

# ── wfh_share_by_year.R ───────────────────────────────────────────────────
build_wfh_share_by_year(cleaned_df: tibble,
                        wfh_cols: character = c("WFH", "WFH_RefWeek")) -> tibble
# One row per (measure, ShnatSeker) with share, IDPUF-clustered se and n among Employed == 1.
# Both CBS items begin in 2021, so pre-period years produce no row. Added 2026-09-22 (audit B2).

# ── absence_by_exposure_quartile.R ────────────────────────────────────────
build_absence_by_exposure_quartile(cleaned_df: tibble, exposure_index: tibble,
                                   breaks: numeric(5) = NULL) -> list(by_quartile, by_cell, breaks)
# Share of Employed == 1 rows with AvadBeshavua != 1 by occupation-exposure quartile (and by
# quartile x Mother x Post), IDPUF-clustered. Pass build_hours_dose_response()$breaks so the
# quartiles match Figure 2; NULL recomputes the same pre-period edges. Added 2026-09-22 (audit I1).

# ── build_mechanism_scatter.R ─────────────────────────────────────────────
build_mechanism_scatter(mechanism_data: tibble, fit: lm = NULL) -> list(data, fit_line, plot)
# Per-occupation beta_j vs. exposure. The drawn line comes from the passed precision-weighted
# `fit`, never geom_smooth(). Repo diagnostic only -- deliberately NOT in paper.tex.

# ── export_paper_figures.R ────────────────────────────────────────────────
export_paper_figures(figures: list, output_dir: character(1) = "outputs/figures",
                      strip_titles: logical(1) = TRUE, device = cairo_pdf) -> invisible(character)
# Second export pass: vector PDFs at print size for the figures paper.tex includes.
# Flat, non-recursive, keyed by filename -- paper.tex hard-codes ../outputs/figures/<key>.pdf,
# so renaming a key breaks the LaTeX build.
```

## HLD Gap Analysis & Implementation Roadmap — both closed

Every gap this document originally tracked is implemented, and the 9-step build order it specified
has shipped in full. `docs/HLD.md` §4.1 holds the current file list; `docs/ROADMAP.md` holds the
checkpoint history; `docs/decisions/` holds the rationale for work that went beyond the original
spec (the calibrated exposure measure and cell-based DDD, the Lee-bounds corrections, the runtime
diagnostics). **There is no pending roadmap item** — new work should get its own checkpoint entry
or decision memo per `CLAUDE.md`'s convention rather than being implemented ad hoc.

The one original gap that was a genuine data-availability blocker rather than an engineering one:
continuous `Age`/`Age²` controls are absent from the raw CBS extract entirely (no
`Gil`/`ShnatLeda`-equivalent column exists). Resolved as a recorded decision —
`docs/decisions/checkpoint8-age-age2-controls.md` replaces the control with the categorical `GilNK`
already in use everywhere, matching Part 3 §3's own advisor feedback for categorical dummies.

For the current list of documented limitations and deliberate decisions (survey weights not
applied, the Lee bounds' one-directional limitation, etc.), see `docs/HLD.md` §4.2.

## Verification

The original 81-column Data Schema and Validation sections were generated by loading the actual `cleaned_df.rds` cache (372,741 × 81, as it stood at the time) and dumping real column names, types, factor levels, and NA rates via `Rscript` — not reconstructed from reading source code. The Age/Age² data-availability claim was confirmed by grepping every raw CSV header for age- and birth-year-related column names before writing it down as absent — this remains true; it's the reason `docs/decisions/checkpoint8-age-age2-controls.md` exists. The 6 columns added since (see "Columns added since the original 81-column pull") and the "Core Function Signatures" section were reconciled directly against the current `.R` files in this repo, not from a fresh `Rscript` data pull — flagged wherever that distinction matters. `Validation & Thresholds`' hard/soft-fail checks and the schema-drift check are no longer a design spec; both are implemented in `validation.R` and can be read directly from source.
