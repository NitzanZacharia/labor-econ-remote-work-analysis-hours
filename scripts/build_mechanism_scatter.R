# build_mechanism_scatter.R
# Scatter of each occupation's own hours DiD (beta_j) against that occupation's WFH exposure --
# the identifying variation behind the hours DDD, drawn directly.
#
# SCOPE NOTE, read before wiring this into the paper. paper/notes/results_digest.md section 1.5
# records a decision dated 2026-09-15 that the second-stage mechanism regression is
# "[PRIMARY -- OUT OF SCOPE, DO NOT DRAFT]" into the paper's results. That decision stands. This
# file exists to (a) draw the figure as a repo-level diagnostic and (b) put mechanism_data on disk,
# which closes the separate open item recorded at results_digest.md section 7 item 1 -- the
# underlying data having never been exported was one of the two reasons 1.5 was ruled out of scope.
# The figure is deliberately NOT included in paper/paper.tex.
library(tidyverse)
source(file.path("scripts", "paper_theme.R"))

build_mechanism_scatter <- function(mechanism_data,
                                    fit      = NULL,
                                    title    = "Per-occupation hours DiD against WFH exposure",
                                    subtitle = NULL) {
  # Non-destructive guard matching hours_subgroup_comparison.R:25-29: an absent or empty frame is
  # a skip with a message, not an error, so one missing input cannot abort a pipeline run.
  if (is.null(mechanism_data) || nrow(mechanism_data) == 0) {
    message("build_mechanism_scatter: no mechanism data supplied -- returning NULL.")
    return(NULL)
  }

  rows <- mechanism_data %>%
    mutate(
      ci_low  = beta_j - 1.96 * se_j,
      ci_high = beta_j + 1.96 * se_j,
      # Precision, which is exactly the weight the second-stage regression uses. Note this frame
      # has no per-occupation sample-size column to size points by: main.R builds
      # hours_exposure_index with select(occupation_code, wfh_exposure) only, and the n that
      # build_wfh_exposure_index() would supply is the 2022-23 calibration-anchor count, not the
      # estimation-sample count -- the wrong number for this purpose.
      precision = 1 / se_j
    )

  # The fitted line must come from `fit`, never from geom_smooth(method = "lm"). The second stage
  # is PRECISION-WEIGHTED (lm(beta_j ~ wfh_exposure, weights = 1/se_j^2) at
  # hours_ddd_regression.R:109) because beta_j's precision varies enormously across occupations;
  # an unweighted smooth would draw a visibly different line from the slope reported in the text.
  fit_line <- NULL
  if (!is.null(fit)) {
    cf <- stats::coef(fit)
    x_range <- range(rows$wfh_exposure, na.rm = TRUE)
    fit_line <- tibble(
      wfh_exposure = x_range,
      beta_j       = cf[[1]] + cf[[2]] * x_range
    )
    if (is.null(subtitle)) {
      subtitle <- sprintf(
        "Precision-weighted slope %.3f (SE %.3f); %d occupations",
        cf[[2]], summary(fit)$coefficients[2, 2], nrow(rows)
      )
    }
  }

  p <- ggplot(rows, aes(x = wfh_exposure, y = beta_j)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = PAPER_PALETTE$reference) +
    geom_linerange(aes(ymin = ci_low, ymax = ci_high),
                   colour = PAPER_PALETTE$estimate, alpha = 0.25, na.rm = TRUE) +
    geom_point(aes(size = precision), colour = PAPER_PALETTE$estimate,
               alpha = 0.8, na.rm = TRUE) +
    scale_size_continuous(range = c(1, 5), guide = "none") +
    labs(
      title    = title,
      subtitle = subtitle,
      x = "Occupation-level calibrated WFH exposure",
      y = "Occupation's own Mother x Post estimate (hours)",
      caption = paste(
        "One point per ISCO-2 occupation; vertical ranges are 95% confidence intervals.",
        "Point size is precision (1/SE),\nthe weight the second-stage regression uses."
      )
    ) +
    theme_paper()

  if (!is.null(fit_line)) {
    p <- p + geom_line(data = fit_line, aes(x = wfh_exposure, y = beta_j),
                       colour = PAPER_PALETTE$gap, linewidth = 0.9, inherit.aes = FALSE)
  } else {
    # Same estimator as above, for standalone use when the fitted model was not passed through.
    p <- p + geom_smooth(aes(weight = 1 / se_j^2), method = "lm", formula = y ~ x,
                         se = FALSE, colour = PAPER_PALETTE$gap, linewidth = 0.9)
  }

  invisible(list(data = rows, fit_line = fit_line, plot = p))
}
