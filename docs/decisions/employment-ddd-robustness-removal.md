# Decision Memo: Removal of the Secondary (Employment) DDD's Occupation-Level Robustness Variants and `phase2_robustness.R`

**Status: DECIDED AND EXECUTED (2026-09-12).** `scripts/ddd_regression.R` and `robustness/phase2_robustness.R` were deleted, along with their pipeline wiring in `main.R` and their dedicated test files. This memo records the decision and its scope for anyone who finds a stale reference to either file.

## Background

Following the hours pivot (`docs/decisions/hours-ddd-pivot.md`), the project's primary dependent variable is weekly work hours (`WorkHoursCont`, intensive margin); the binary employment DDD (`Employed`, `main.R` §8b) is now the secondary specification. Two pieces of code existed purely in service of the secondary DDD's own robustness coverage:

1. **`scripts/ddd_regression.R`** (`run_ddd_regression()`) — implemented the secondary DDD's three occupation-level robustness variants (calibrated/external/realized exposure), called from `main.R`'s former §8c-8e, plus a second-stage occupation-by-occupation mechanism regression.
2. **`robustness/phase2_robustness.R`** — three further specification-robustness checks on the secondary DDD (two-way clustering, an education-sector transparency check, a survey-weight comparison), never wired into `main.R` by default (blocked on a `MishkalSofi`-as-weight sign-off question, unrelated to this decision). Following the hours pivot's gender/robustness-parity pass, this file had also grown hours-outcome analogs of all three checks (`run_hours_ddd_twoway_cluster()`, `run_hours_ddd_education_checks()`, `run_hours_ddd_weights_check()`), likewise never wired in.

## Decision

The user decided to deprecate and remove both, in favor of a codebase focused on the intensive-margin (hours) analysis as primary, without carrying forward secondary-margin robustness infrastructure that was no longer central to the project's research focus. Removed:

- `scripts/ddd_regression.R` in full, and its three call sites in `main.R` (the calibrated/external/realized occupation-level robustness DDDs for the *secondary* employment specification, plus their `results_to_export` keys `ddd_calibrated`/`ddd_external`/`ddd_realized`).
- `robustness/phase2_robustness.R` in full — both the original three employment-outcome checks and the three hours-outcome analogs added afterward. Since this file was never wired into `main.R`, its removal has no effect on the default pipeline run.
- `tests/testthat/test-ddd_regression.R`, `test-phase2_robustness.R`, and `test-hours_phase2_robustness.R`.
- The corresponding `source()` lines in `main.R` and `tests/testthat/helper-setup.R`.

**What stays:** the secondary (employment) DDD itself (`main.R` §8b, `ddd_employment_additive`/`ddd_employment_fe`) is unaffected — it is still the project's secondary specification, still unconditional. `robustness/age_balance_robustness.R` and `robustness/balance_test.R`/`robustness/pretrend_wald_test.R` are unaffected — the age-balance/reweighting chain (including its hours-outcome analogs, `run_hours_ddd_age_interacted()`/`run_hours_ddd_reweighted()`) remains wired behind `RUN_AGE_BALANCE_ROBUSTNESS`.

**Consequence for the primary (hours) DDD's own robustness coverage:** `run_hours_ddd_regression()` already takes a generic `exposure_index` parameter (like the removed `run_ddd_regression()` did), so its own three occupation-level robustness variants (calibrated/external/realized) did **not** require the removed file at all — they are three plain call sites in `main.R` §8a and remain in place. The primary DDD's robustness coverage is therefore unaffected by this removal; only the secondary DDD's robustness coverage (and the never-wired `phase2_robustness.R` checks on both margins) was removed.

## Documentation follow-up

Docs referencing the removed files/variants (`README.md`, `docs/HLD.md`, `docs/LLD.md`, `docs/ROADMAP.md`, `docs/decisions/calibrated-exposure-and-cell-ddd.md`, `docs/decisions/age-balance-robustness-chain.md`, `CLAUDE.md`) were updated alongside this memo to remove or forward-point stale mentions, rather than describing now-deleted code as current.
