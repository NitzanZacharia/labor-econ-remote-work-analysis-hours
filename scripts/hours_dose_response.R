# hours_dose_response.R
# Non-parametric dose-response descriptive for the hours pivot: the raw hours DiD computed
# separately within each quartile of occupational WFH exposure. Added with the paper's Descriptive
# Statistics section (docs/decisions/paper-figure-layer.md).
#
# This is the picture the headline DDD asserts. run_hours_ddd_regression() reports a single
# Mother:Post:WFH_Exposure coefficient; this shows the same dose-response in four cell-mean
# differences, with no regression, no controls and no functional-form assumption. If the DDD is
# real, the per-quartile DiD should rise with exposure.
#
# Two deliberate design choices, both of which are easy to get wrong:
#
#   1. BINS COME FROM THE OCCUPATION-LEVEL MEASURE, the same one the DDD uses -- not from the
#      demographic-cell index. hours_ddd_lee_bounds.R bins on the cell measure for a specific
#      reason stated in its header: its selection counterfactual needs an exposure that is defined
#      for the NON-employed. This figure lives entirely inside Employed == 1, so that reason does
#      not apply, and binning on one measure while illustrating a coefficient estimated on the
#      other would re-create exactly the conflation results_digest.md warns against. The two
#      measures are on different scales and their coefficients are never comparable.
#
#   2. NO CONTROLS. Keeping this descriptive is the point of the figure, and it means the file
#      carries no `controls` argument to get out of step with DEFAULT_CONTROLS. The per-quartile
#      DiD and its SE are obtained from a saturated feols(y ~ Mother*Post) clustered by IDPUF --
#      whose Mother:Post coefficient IS the four-cell arithmetic, so the quantity is unchanged --
#      rather than from hand-computed cell SEs, which assumed the four cells were independent
#      subsamples and understated the SE by roughly 1.6-1.85x. See scripts/clustered_se.R.
#
# Quartiles are fixed at four rather than parameterised, because the reused assign_wfh_quartile()
# (robustness/age_balance_robustness.R) hardcodes labels = 1:4, and because quartiles are what the
# Lee-bounds and age-balance specs already use.
library(tidyverse)
library(fixest)
source(file.path("scripts", "paper_theme.R"))
source(file.path("scripts", "clustered_se.R"))
source(file.path("scripts", "occupation_exposure_breaks.R"))
source(file.path("robustness", "age_balance_robustness.R"))

# `breaks` (added 2026-09-22): quartile edges to reuse instead of recomputing. When NULL the edges
# are computed here by compute_occupation_exposure_breaks(), the rule this function used to carry
# inline; main.R takes the returned `breaks` and hands them to the binned DDD
# (scripts/hours_ddd_binned.R) and the absence footnote so all three share one set of bins.
build_hours_dose_response <- function(cleaned_df, exposure_index,
                                      measure_label = "occupation-level calibrated WFH exposure",
                                      breaks = NULL) {
  # Same join as run_hours_ddd_regression(), so this figure and the DDD are computed on the
  # same rows: inner_join drops the non-employed and disclosure-masked/unmapped ISCO codes.
  df <- cleaned_df %>%
    filter(Employed == 1) %>%
    inner_join(
      exposure_index %>% select(MishlachYad_ISCO_08_2 = occupation_code,
                                WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    ) %>%
    filter(!is.na(WFH_Exposure), !is.na(WorkHoursCont))

  # Breakpoints from the PRE-period distribution, then applied to all rows -- the philosophy stated
  # at age_balance_robustness.R:22-27. Computing them separately on pre- and full-period rows would
  # silently misalign the quartile labels between the two.
  if (is.null(breaks)) {
    breaks <- compute_occupation_exposure_breaks(df, caller = "build_hours_dose_response")
  }

  df <- assign_wfh_quartile(df, breaks)

  # Cluster-robust cell means (scripts/clustered_se.R). feols(WorkHoursCont ~ 1) returns the cell
  # mean exactly, so mean_hours is unchanged; only se moves.
  cell_means <- df %>%
    group_by(WFH_Exposure_Q, Mother, Post) %>%
    group_modify(~ {
      fit <- clustered_se(.x, WorkHoursCont ~ 1, "(Intercept)")
      tibble(mean_hours = fit$estimate,
             sd = sd(.x$WorkHoursCont, na.rm = TRUE),
             n  = sum(!is.na(.x$WorkHoursCont)),
             se = fit$se)
    }) %>%
    ungroup() %>%
    arrange(WFH_Exposure_Q, Mother, Post)

  # (mothers post - mothers pre) - (non-mothers post - non-mothers pre), within quartile.
  #
  # The DiD and its SE both come from a saturated within-quartile feols(y ~ Mother*Post) clustered
  # by IDPUF. The Mother:Post coefficient of that model IS the four-cell arithmetic above, so this
  # remains a purely descriptive quantity -- no controls, no identifying assumption, exactly as
  # this file's header intends. What it is not any more is the root sum of four squared cell SEs:
  # that treated the four cells as independent subsamples, which they are not, since the same
  # individuals recur across waves. It understated these SEs by roughly 1.6-1.85x.
  did_by_q <- df %>%
    group_by(WFH_Exposure_Q) %>%
    group_modify(~ {
      fit <- clustered_se(.x, WorkHoursCont ~ Mother * Post, "Mother:Post")
      # mean_exposure: the quartile's average regressor value on the estimation rows, so the DDD's
      # per-unit coefficient can be turned into an implied top-minus-bottom-quartile effect
      # (coef x (mean_Q4 - mean_Q1)) and set beside the raw per-quartile DiD -- the paper's one
      # functional-form check on the linear-in-exposure specification.
      tibble(did = fit$estimate, se = fit$se, n = fit$n,
             mean_exposure = mean(.x$WFH_Exposure, na.rm = TRUE))
    }) %>%
    ungroup()

  dose_data <- did_by_q %>%
    transmute(
      WFH_Exposure_Q,
      # unname(): quantile() labels its result "0%", "25%", ... and those names would otherwise
      # ride along as names on these columns.
      q_low  = unname(breaks)[WFH_Exposure_Q],
      q_high = unname(breaks)[WFH_Exposure_Q + 1],
      mean_exposure,
      did, se, n
    ) %>%
    mutate(
      ci_low  = did - 1.96 * se,
      ci_high = did + 1.96 * se,
      q_label = sprintf("Q%d\n%.2f-%.2f", WFH_Exposure_Q, q_low, q_high)
    ) %>%
    arrange(WFH_Exposure_Q)

  p <- ggplot(dose_data, aes(x = factor(WFH_Exposure_Q), y = did)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = PAPER_PALETTE$reference) +
    geom_pointrange(
      aes(ymin = ci_low, ymax = ci_high),
      colour = PAPER_PALETTE$estimate, linewidth = 0.7, size = 0.6, na.rm = TRUE
    ) +
    scale_x_discrete(labels = setNames(dose_data$q_label, as.character(dose_data$WFH_Exposure_Q))) +
    labs(
      title    = "Raw hours difference-in-differences by WFH exposure quartile",
      subtitle = "Reference-week workers aged 25-59; mothers vs childless women, post-2021 vs pre-2021",
      x = "Quartile of occupation-level WFH exposure",
      y = "Raw DiD (hours per week)",
      # Wrapped by hand: an unwrapped caption overruns the panel at the ~5in width these figures
      # are printed at, and ggplot clips rather than reflowing it.
      caption = paste0(
        "Bars are 95% confidence intervals, clustered by individual. No controls.\n",
        "Bins are quartiles of the ", measure_label, ", the same measure the DDD uses.\n",
        "Breakpoints are computed on pre-period rows and applied to all years."
      )
    ) +
    theme_paper() +
    theme(panel.grid.major.x = element_blank())

  invisible(list(
    cell_means = cell_means,
    data       = dose_data,
    breaks     = breaks,
    plot       = p
  ))
}
