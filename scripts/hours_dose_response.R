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
#   2. RAW CELL ARITHMETIC, NO REGRESSION. Keeping this descriptive is the point of the figure --
#      it also means the file carries no `controls` argument to get out of step with
#      DEFAULT_CONTROLS, and adds no feols() runtime to the pipeline.
#
# Quartiles are fixed at four rather than parameterised, because the reused assign_wfh_quartile()
# (robustness/age_balance_robustness.R) hardcodes labels = 1:4, and because quartiles are what the
# Lee-bounds and age-balance specs already use.
library(tidyverse)
source(file.path("scripts", "paper_theme.R"))
source(file.path("robustness", "age_balance_robustness.R"))

build_hours_dose_response <- function(cleaned_df, exposure_index,
                                      measure_label = "occupation-level calibrated WFH exposure") {
  # Same join as run_hours_ddd_regression.R:39-44, so this figure and the DDD are computed on the
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
  pre_exposure <- df %>% filter(ShnatSeker < 2020) %>% pull(WFH_Exposure)
  breaks <- quantile(pre_exposure, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
  if (any(duplicated(breaks))) {
    stop("build_hours_dose_response: duplicate quartile breakpoints (a mass point sits exactly on ",
         "a boundary) -- cut() would silently produce fewer than 4 bins. Inspect the pre-period ",
         "WFH_Exposure distribution before proceeding.")
  }

  df <- assign_wfh_quartile(df, breaks)

  cell_means <- df %>%
    group_by(WFH_Exposure_Q, Mother, Post) %>%
    summarise(
      mean_hours = mean(WorkHoursCont, na.rm = TRUE),
      sd         = sd(WorkHoursCont, na.rm = TRUE),
      n          = sum(!is.na(WorkHoursCont)),
      .groups    = "drop"
    ) %>%
    mutate(se = sd / sqrt(n)) %>%
    arrange(WFH_Exposure_Q, Mother, Post)

  # (mothers post - mothers pre) - (non-mothers post - non-mothers pre), within quartile. The four
  # cell means are independent subsamples, so the DiD's SE is the root sum of their squared SEs.
  dose_data <- cell_means %>%
    mutate(cell_key = paste0("m", Mother, "p", Post)) %>%
    select(WFH_Exposure_Q, cell_key, mean_hours, se, n) %>%
    pivot_wider(names_from = cell_key, values_from = c(mean_hours, se, n)) %>%
    transmute(
      WFH_Exposure_Q,
      # unname(): quantile() labels its result "0%", "25%", ... and those names would otherwise
      # ride along as names on these columns.
      q_low  = unname(breaks)[WFH_Exposure_Q],
      q_high = unname(breaks)[WFH_Exposure_Q + 1],
      did    = (mean_hours_m1p1 - mean_hours_m1p0) - (mean_hours_m0p1 - mean_hours_m0p0),
      se     = sqrt(se_m1p1^2 + se_m1p0^2 + se_m0p1^2 + se_m0p0^2),
      n      = n_m1p1 + n_m1p0 + n_m0p1 + n_m0p0
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
      subtitle = "Employed women aged 25-59; mothers relative to childless women, post-2021 vs pre-2021",
      x = "Quartile of occupation-level WFH exposure",
      y = "Raw DiD (hours per week)",
      # Wrapped by hand: an unwrapped caption overruns the panel at the ~5in width these figures
      # are printed at, and ggplot clips rather than reflowing it.
      caption = paste0(
        "Bars are 95% confidence intervals. Cell means only: no controls, no regression.\n",
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
