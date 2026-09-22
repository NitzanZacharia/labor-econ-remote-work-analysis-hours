# build_event_study_plot.R
# ggplot event-study plot, given a tidy one-row-per-year coefficient frame from
# tidy_event_study_coefs(). Drives both of the paper's event studies: the DiD-level
# Mother x year one (run_hours_diagnostics()) and the triple-interaction
# Mother x year x WFH_Exposure one (run_hours_ddd_event_study()).
#
# Separate from the estimators for the same reason build_hours_subgroup_comparison() and
# build_mechanism_scatter() are separate from the models they draw: a builder that takes an
# already-tidied frame is testable without fitting anything, and main.R's two exporters can then
# treat it like every other plot in the pipeline.
#
# It replaced fixest's base-graphics iplot(), which draws to whatever device is active and returns
# nothing -- so its output could not be passed to export_all_results() or export_paper_figures(),
# and reached outputs/ only as a whole-device PDF wrapped in an explicit pdf()/dev.off() pair in
# main.R. Returning a ggplot means both event studies are exported by the same two code paths as
# every other figure, share the project's theme and palette, and carry no device management at the
# call site. iplot() also selected its series by positional index (i.select), which silently plots
# the wrong term when the formula is reordered.
#
# run_diagnostics()'s employment-outcome event study still uses iplot(): it is a repo diagnostic
# that the paper does not print, so it was left on the old path rather than ported for symmetry.
library(tidyverse)
source(file.path("scripts", "paper_theme.R"))

build_event_study_plot <- function(coefs,
                                   ref_year       = 2019,
                                   treatment_year = 2021,
                                   title          = NULL,
                                   subtitle       = NULL,
                                   y_label        = "Mother x Year x WFH Exposure (95% CI)",
                                   se_note        = "occupation-clustered standard errors") {
  if (is.null(coefs) || !is.data.frame(coefs) || nrow(coefs) == 0) {
    message("build_event_study_plot: no event-study coefficients supplied -- returning NULL.")
    return(NULL)
  }

  required <- c("year", "estimate", "std_error", "ci_low", "ci_high")
  missing_cols <- setdiff(required, names(coefs))
  if (length(missing_cols) > 0) {
    stop("build_event_study_plot: `coefs` is missing required column(s): ",
         paste(missing_cols, collapse = ", "))
  }

  # The reference year is omitted from the regression by construction, so it has no row in `coefs`
  # -- but leaving it off the plot entirely would show a gap where the normalization actually is,
  # and a reader would have no way to see which year the other estimates are differenced against.
  # It is re-inserted as an exact zero with a zero-width interval and drawn hollow, so it reads as
  # "pinned by construction" rather than "estimated at zero".
  ref_row <- tibble(
    year = as.integer(ref_year), estimate = 0, std_error = 0,
    ci_low = 0, ci_high = 0, is_reference = TRUE
  )

  plot_df <- coefs %>%
    select(all_of(required)) %>%
    mutate(year = as.integer(year), is_reference = FALSE) %>%
    bind_rows(ref_row) %>%
    arrange(year) %>%
    mutate(period = if_else(year < ref_year, "Pre", "Post"))

  # The treatment rule is ShnatSeker >= 2021 (data_processing.R's Post), and 2020 is excluded from
  # the sample entirely, so the boundary between the last pre-period year and the first treated year
  # falls in an empty gap. Drawing the rule at the midpoint puts it in that gap rather than on top of
  # a plotted estimate, which is what makes the pre/post split readable; annotating it with the
  # actual adoption year keeps the visual convention from implying that 2020 was estimated.
  boundary <- (ref_year + treatment_year) / 2

  p <- ggplot(plot_df, aes(x = year, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = PAPER_PALETTE$reference) +
    geom_vline(xintercept = boundary, linetype = "dotted", colour = PAPER_PALETTE$reference) +
    annotate(
      "text", x = boundary, y = Inf, label = paste0("Treatment: ", treatment_year),
      hjust = -0.08, vjust = 1.6, size = 3, colour = PAPER_PALETTE$annotation
    ) +
    geom_pointrange(
      aes(ymin = ci_low, ymax = ci_high, shape = is_reference),
      colour = PAPER_PALETTE$estimate, linewidth = 0.7, size = 0.55, na.rm = TRUE
    ) +
    # 21 (hollow) for the pinned reference year, 16 (solid) for the estimated ones. guide = "none":
    # the distinction is explained in the caption, and a two-entry legend reading TRUE/FALSE would
    # cost more vertical space than it conveys.
    scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 21), guide = "none") +
    # Only the years actually in the sample get a break -- the default continuous axis would invent
    # a 2020 tick for a year this project does not observe.
    scale_x_continuous(breaks = sort(unique(plot_df$year))) +
    labs(
      title    = title,
      subtitle = subtitle,
      x        = "Survey year",
      y        = y_label,
      # se_note is parameterized because the two event studies this builds cluster at different
      # levels -- occupation for the DDD (the level exposure varies at), individual for the DiD --
      # and a caption naming the wrong one would misdescribe the intervals it sits under.
      caption  = paste0(
        ref_year, " is the omitted reference year (pinned at zero, hollow point). ",
        "Intervals are 95% CIs from ", se_note, "."
      )
    ) +
    theme_paper()

  invisible(list(data = plot_df, plot = p))
}
