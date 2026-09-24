# build_permutation_plot.R
# Histogram of the permutation distribution produced by run_hours_ddd_permutation_test()
# (robustness/hours_ddd_inference.R), with the observed cluster-robust t marked. Drawn for the
# paper's falsification-test subsection (docs/decisions/grade-report-response.md, item M2).
#
# Separate from the estimator for the same reason build_event_study_plot() is separate from the
# event studies: a builder that takes an already-computed frame is testable without running 999
# regressions, and main.R's two exporters treat it like every other plot.
library(tidyverse)
source(file.path("scripts", "paper_theme.R"))

build_permutation_plot <- function(draws, t_obs, p_perm = NA_real_, title = NULL, subtitle = NULL) {
  if (is.null(draws) || !is.data.frame(draws) || !"t_stat" %in% names(draws)) {
    message("build_permutation_plot: no permutation draws supplied -- returning NULL.")
    return(NULL)
  }
  plot_df <- draws %>% filter(is.finite(t_stat))
  if (nrow(plot_df) == 0) {
    message("build_permutation_plot: every draw is non-finite -- returning NULL.")
    return(NULL)
  }

  x_max <- max(abs(c(plot_df$t_stat, t_obs)), na.rm = TRUE) * 1.1
  label <- if (is.na(p_perm)) sprintf("observed t = %.2f", t_obs) else
    sprintf("observed t = %.2f, permutation p = %.3f", t_obs, p_perm)

  p <- ggplot(plot_df, aes(x = t_stat)) +
    geom_histogram(bins = 40, fill = PAPER_PALETTE$estimate, colour = "white", alpha = 0.85) +
    geom_vline(xintercept = c(-abs(t_obs), abs(t_obs)), linetype = "dashed",
               colour = PAPER_PALETTE$gap, linewidth = 0.7) +
    annotate("text", x = abs(t_obs), y = Inf, label = label, hjust = 1.05, vjust = 1.8,
             size = 3, colour = PAPER_PALETTE$annotation) +
    scale_x_continuous(limits = c(-x_max, x_max)) +
    labs(
      title    = title,
      subtitle = subtitle,
      x        = "Cluster-robust t of the triple interaction, permuted exposure",
      y        = "Draws",
      caption  = sprintf("%d permutations of the occupation-level exposure score across occupations. Dashed lines mark the observed statistic (two-sided).",
                         nrow(plot_df))
    ) +
    theme_paper()

  invisible(list(data = plot_df, plot = p))
}
