# intensive_margin_lee_bounds.R
# DiD-adapted Lee (2009) trimming bounds for the intensive-margin (WorkHoursCont) regression --
# the project's PRIMARY dependent-variable regression as of the hours pivot
# (docs/decisions/hours-ddd-pivot.md). See docs/decisions/intensive-margin-lee-bounds.md for the
# full decision memo (problem statement, alternatives considered, and this adaptation's stated
# limitations); this same machinery is later generalized to the triple-interaction DDD by
# hours_ddd_lee_bounds.R.
#
# run_intensive_margin_reg() (intensive_margin_regression.R) estimates WorkHoursCont ~ Mother*Post
# + controls on the Employed == 1 subsample. Employed is itself the outcome of the project's
# secondary, extensive-margin DiD (basic_regression.R) -- if WFH availability differentially pulls
# marginal mothers into employment post-2021 (exactly the mechanism this project is testing for),
# the post-period employed-mother sample is compositionally different from the pre-period one for
# reasons unrelated to hours, biasing the intensive-margin Mother:Post coefficient in an unknown
# direction. This is a textbook selection-on-a-mediator problem -- see Lee (2009), "Training,
# Wages, and Sample Selection: Estimating Sharp Bounds on Treatment Effects", Review of Economic
# Studies 76(3).
#
# ── The bound construction ───────────────────────────────────────────────────
# Classic Lee bounds compare one treated group to one control group with a fixed selection rate,
# trimming the treated group's outcome distribution down to match. This project's design has two
# dimensions (Mother, Post), so "treatment" here is specifically Post's *differential* effect on
# Mother==1's selection into employment, relative to what Mother==0's own pre/post change in
# selection implies (a parallel-trends-in-selection counterfactual):
#
#   s_ab = P(hours observed | Mother==a, Post==b)       for a,b in {0,1}
#          (i.e. employed AND worked the reference week -- the estimation sample, not the employed;
#           see docs/decisions/hours-population-harmonization.md)
#   s11_counterfactual = s10 + (s01 - s00)               (implied Post effect for mothers, absent
#                                                          any differential WFH-driven entry)
#
# If the *actual* s11 exceeds this counterfactual, mothers' employment rose by more than the
# parallel-trends benchmark after 2021 -- there are "excess" employed mothers in the post period
# whose hours are not comparable to the pre-period sample. The excess share
# p = 1 - s11_counterfactual / s11 is trimmed from the Mother==1 & Post==1 cell's WorkHoursCont
# distribution -- from the top for the lower bound, from the bottom for the upper bound (Lee's
# standard monotone-selection assumption: the marginal entrants have either the highest or the
# lowest hours of anyone in the cell) -- and Mother:Post is re-estimated on each trimmed sample.
# Every other cell is left untouched.
#
# If s11 does NOT exceed the counterfactual, there is nothing to trim under this construction and
# the bounds collapse to the untrimmed point estimate (see "Limitations" below).
#
# Deliberately consistent with this project's documented decision (README.md's Known Limitations,
# CLAUDE.md) not to apply MishkalSofi survey weights anywhere: the selection rates s_ab below are
# unweighted, matching every other regression in this repo.
#
# ── Limitations of this adaptation, stated explicitly ───────────────────────
# - Only handles excess selection in the Mother==1,Post==1 cell -- the direction this project's own
#   hypothesis predicts (WFH narrowing the penalty by pulling marginal mothers into work). If the
#   data instead showed *under*-selection in that cell relative to the counterfactual, this
#   construction does not produce a bound: under-selection is a missing-data problem, not an
#   excess-observed-data problem, and Lee-style trimming doesn't address it.
# - Relies on the same parallel-trends assumption already underlying the extensive-margin DiD
#   itself (see Diagnostics.R's pretrend check) to define the selection counterfactual s11*.
# - Assumes monotone selection (WFH availability weakly increases, never decreases, a mother's
#   probability of employment) to justify trimming from a single tail rather than modeling the
#   selection mechanism directly.
# - Ties in WorkHoursCont (common -- it's a bin-median lookup, so many rows share exact values)
#   are broken by row order after arrange(), not randomized. With a large trimmed count this
#   averages out; with a small one it's a minor source of bound imprecision worth noting if the
#   trimmed n is small.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "imbens_manski_ci.R"))

run_intensive_margin_lee_bounds <- function(cleaned_df, controls = DEFAULT_CONTROLS) {

  # ── Selection rates by (Mother, Post) cell, and the implied counterfactual ──
  # The rate is the share whose OUTCOME IS OBSERVED, not the share employed. Lee bounds correct for
  # selection into the sample the outcome is measured on, and since the hours population was
  # harmonized to reference-week workers (docs/decisions/hours-population-harmonization.md) that is
  # no longer the same set as the employed: ~10% of employed rows in every year have no usual-hours
  # value. Using mean(Employed == 1) would derive the trim proportion on one denominator and apply
  # it to another. Written as !is.na(WorkHoursCont) rather than by naming the gate conditions, so it
  # keeps tracking whatever defines the estimation sample.
  sel_rates <- cleaned_df %>%
    group_by(Mother, Post) %>%
    summarise(selection_rate = mean(!is.na(WorkHoursCont)), n = n(), .groups = "drop")

  get_rate <- function(m, p) {
    rate <- sel_rates$selection_rate[sel_rates$Mother == m & sel_rates$Post == p]
    if (length(rate) == 0) {
      stop("run_intensive_margin_lee_bounds: no rows found for Mother == ", m, ", Post == ", p,
           " -- all four (Mother, Post) cells must be present to compute the selection ",
           "counterfactual.")
    }
    rate
  }
  s00 <- get_rate(0, 0); s01 <- get_rate(0, 1); s10 <- get_rate(1, 0); s11 <- get_rate(1, 1)
  s11_counterfactual <- s10 + (s01 - s00)

  excess    <- s11 > s11_counterfactual
  trim_prop <- if (excess) 1 - s11_counterfactual / s11 else 0

  message(sprintf(
    paste0(
      "run_intensive_margin_lee_bounds: selection (observed-hours) rates -- ",
      "Mother=0,Post=0: %.4f | Mother=0,Post=1: %.4f | Mother=1,Post=0: %.4f | ",
      "Mother=1,Post=1: %.4f (parallel-trends counterfactual: %.4f).\n  %s"
    ),
    s00, s01, s10, s11, s11_counterfactual,
    if (excess) {
      sprintf("Excess selection detected in Mother=1,Post=1: trimming %.2f%% of that cell.",
              100 * trim_prop)
    } else {
      paste("No excess selection in Mother=1,Post=1 relative to the parallel-trends",
            "counterfactual -- bounds collapse to the untrimmed point estimate.")
    }
  ))

  rhs           <- paste("Mother + Post + Mother:Post", paste(controls, collapse = " + "), sep = " + ")
  formula_hours <- as.formula(paste("WorkHoursCont ~", rhs))
  fit_on        <- function(df) feols(formula_hours, data = df, cluster = ~IDPUF)

  # !is.na(WorkHoursCont) restricts this to the ESTIMATION sample, which matters for the trimming
  # below rather than for point_reg (feols already listwise-deletes, so the point estimate is
  # identical either way). Since the hours population was harmonized to reference-week workers
  # (docs/decisions/hours-population-harmonization.md) the Mother==1,Post==1 cell contains ~12%
  # NA-hours rows, and dplyr's arrange() sorts NA LAST regardless of direction -- so without this
  # filter the lower bound would trim unobserved rows as though they were the highest-hours ones,
  # and n_cell would be an inflated denominator for n_trim. Before harmonization there were zero
  # NA-hours rows in that cell, which is why this was latent rather than wrong.
  employed_df <- filter(cleaned_df, Employed == 1, !is.na(WorkHoursCont))
  point_reg   <- fit_on(employed_df)

  if (!excess || trim_prop <= 0) {
    lower_reg <- point_reg
    upper_reg <- point_reg
    n_trimmed <- 0L
  } else {
    treated_cell <- filter(employed_df, Mother == 1, Post == 1)
    other_cells  <- filter(employed_df, !(Mother == 1 & Post == 1))
    n_cell        <- nrow(treated_cell)
    n_trim        <- floor(trim_prop * n_cell)

    ranked <- arrange(treated_cell, WorkHoursCont)
    # Lower bound: drop the highest-hours n_trim rows (marginal entrants assumed to work the most).
    # seq_len(), not "1:(n_cell - n_trim)" -- the latter produces a reversed 2-element sequence
    # (e.g. 1:0 == c(1, 0)) rather than zero rows when n_trim == n_cell (100% trim); seq_len(0)
    # correctly yields an empty selection. See hours_ddd_lee_bounds.R's identical fix.
    trimmed_for_lower <- if (n_trim > 0) slice(ranked, seq_len(max(n_cell - n_trim, 0))) else ranked
    # Upper bound: drop the lowest-hours n_trim rows (marginal entrants assumed to work the least).
    trimmed_for_upper <- if (n_trim > 0) {
      slice(ranked, if (n_trim < n_cell) (n_trim + 1):n_cell else integer(0))
    } else {
      ranked
    }

    lower_reg <- fit_on(bind_rows(other_cells, trimmed_for_lower))
    upper_reg <- fit_on(bind_rows(other_cells, trimmed_for_upper))
    n_trimmed <- n_trim
  }

  # At trim_prop == 1 (100% of the Mother=1,Post=1 cell trimmed away), neither trimmed sample has
  # any row with Mother==1 & Post==1 left, so the Mother:Post column is constant zero across the
  # whole fitting sample and fixest drops it for collinearity rather than leaving it as NA (see
  # test-ddd_collinearity_diagnostics.R) -- coef(m)[["Mother:Post"]]/se(m)[["Mother:Post"]] would
  # otherwise fail with a bare "subscript out of bounds". Fail informatively instead: this reflects
  # a real identification failure (no data left to bound), not a bug.
  extract <- function(m, fn) {
    val <- fn(m)["Mother:Post"]
    if (is.na(val)) {
      stop("run_intensive_margin_lee_bounds: Mother:Post is not estimable in this bound's trimmed ",
           "sample (dropped for collinearity) -- this happens when the entire Mother=1,Post=1 cell ",
           "has been trimmed away (trim_prop == 1), leaving no data to identify the interaction.")
    }
    unname(val)
  }
  co    <- function(m) extract(m, coef)
  se_of <- function(m) extract(m, se)

  se_lower <- se_of(lower_reg)
  se_point <- se_of(point_reg)
  se_upper <- se_of(upper_reg)

  z <- qnorm(0.975)
  bounds_table <- tibble(
    bound            = c("lower", "point (untrimmed)", "upper"),
    mother_post_coef = c(co(lower_reg), co(point_reg), co(upper_reg)),
    se               = c(se_lower, se_point, se_upper),
    ci_low           = c(co(lower_reg) - z * se_lower, co(point_reg) - z * se_point,
                          co(upper_reg) - z * se_upper),
    ci_high          = c(co(lower_reg) + z * se_lower, co(point_reg) + z * se_point,
                          co(upper_reg) + z * se_upper)
  )
  print(as.data.frame(bounds_table), digits = 4)

  # Imbens & Manski (2004) CI for the true parameter under partial identification -- treating
  # trim_prop as a fixed, known constant (as lower_reg/upper_reg above do) ignores that it is
  # itself estimated from s00/s01/s10/s11; part of the identified interval's own width is sampling
  # noise, not a real feature of the trimming. See imbens_manski_ci.R (shared with
  # hours_ddd_lee_bounds.R) for the closed-form solver and its derivation.
  im_ci <- imbens_manski_ci(co(lower_reg), co(upper_reg), se_lower, se_upper)
  message(sprintf(
    "run_intensive_margin_lee_bounds: 95%% Imbens-Manski CI for the identified set = [%.4f, %.4f] (c_alpha = %.3f).",
    im_ci$lower, im_ci$upper, im_ci$c_alpha
  ))

  return(invisible(list(
    table       = bounds_table,
    models      = list(point = point_reg, lower = lower_reg, upper = upper_reg),
    diagnostics = list(
      selection_rates    = sel_rates,
      s11_counterfactual = s11_counterfactual,
      excess_selection   = excess,
      trim_prop          = trim_prop,
      n_trimmed          = n_trimmed
    ),
    imbens_manski_ci = im_ci
  )))
}
