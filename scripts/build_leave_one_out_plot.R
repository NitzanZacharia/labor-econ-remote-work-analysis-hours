# build_leave_one_out_plot.R
# Influence plot for run_hours_ddd_leave_one_out(): one point per refit (the triple interaction
# with the named occupation removed), sorted by estimate, against the headline estimate and a
# band of one headline standard error either side of it (docs/decisions/grade-report-2-response.md,
# Robustness 1). Pure post-processing over the leave-one-out table, in the
# style of build_hours_subgroup_comparison(): no data cleaning or regression logic of its own.
library(tidyverse)
source(file.path("scripts", "paper_theme.R"))

build_leave_one_out_plot <- function(loo_table, headline_estimate, headline_se,
                                     title = "Leave-one-occupation-out: hours DDD triple interaction",
                                     subtitle = NULL, x_label = NULL, max_label_chars = 42) {
  needed <- c("occupation_code", "estimate", "std_error")
  if (!all(needed %in% names(loo_table))) {
    stop("build_leave_one_out_plot: loo_table needs columns ", paste(needed, collapse = ", "), ".")
  }
  rows <- loo_table %>%
    filter(is.finite(estimate), is.finite(std_error))
  if (nrow(rows) == 0) {
    message("build_leave_one_out_plot: no finite estimates -- returning NULL.")
    return(NULL)
  }
  if (!"label" %in% names(rows)) rows$label <- paste("ISCO", rows$occupation_code)

  rows <- rows %>%
    mutate(
      label_short = if_else(nchar(label) > max_label_chars,
                            paste0(substr(label, 1, max_label_chars - 1), "…"), label),
      axis_label  = sprintf("%s  %s", occupation_code, label_short),
      ci_low      = estimate - 1.96 * std_error,
      ci_high     = estimate + 1.96 * std_error,
      # "Dropped: <occupation>" is the reading, so the axis is ordered by the estimate it leaves.
      axis_label  = fct_reorder(axis_label, estimate),
      influential = abs(estimate - headline_estimate) > headline_se
    )

  band <- tibble(xmin = headline_estimate - headline_se, xmax = headline_estimate + headline_se)

  p <- ggplot(rows, aes(x = estimate, y = axis_label)) +
    geom_rect(data = band, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
              inherit.aes = FALSE, fill = PAPER_PALETTE$estimate, alpha = 0.12) +
    geom_vline(xintercept = 0, linetype = "dotted", colour = PAPER_PALETTE$reference) +
    geom_vline(xintercept = headline_estimate, linetype = "dashed", colour = PAPER_PALETTE$reference) +
    geom_errorbar(aes(xmin = ci_low, xmax = ci_high), width = 0, linewidth = 0.4,
                  orientation = "y", colour = PAPER_PALETTE$estimate, alpha = 0.6) +
    geom_point(aes(shape = influential), size = 1.9, colour = PAPER_PALETTE$estimate) +
    scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 17), guide = "none") +
    labs(
      title    = title,
      subtitle = subtitle,
      # Short enough to fit under a 5-inch panel with forty labelled rows.
      x = if (is.null(x_label)) "Triple interaction without the named occupation" else x_label,
      y = NULL
    ) +
    theme_paper() +
    theme(axis.text.y = element_text(size = 6.5), plot.title = element_text(size = 11))

  invisible(list(data = rows, plot = p, band = band))
}
