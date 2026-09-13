# hours_subgroup_comparison.R
# Forest-plot comparison of one regression coefficient across the intensive-margin (hours)
# subgroup specifications -- main.R's demographic-heterogeneity check for the hours DiD
# (Mother:Post) and DDD (Mother:Post:WFH_Exposure) terms across ethnicity (Jewish/Arab women) and
# the male gender-placebo. One parameterized function rather than two near-identical copies, since
# the only difference between the DiD and DDD comparison plots is which coefficient is pulled from
# each already-fitted model.
library(tidyverse)
library(fixest)

build_hours_subgroup_comparison <- function(models, term, title, subtitle = NULL) {
  # models: a named list of already-fitted fixest models, one per subgroup. A NULL entry (e.g. a
  # subgroup regression that failed to fit -- too few observations, a degenerate formula) or one
  # missing `term` (dropped by collinearity) is skipped rather than erroring, matching this
  # project's existing non-destructive convention (e.g. calibrate_isco_exposure()).
  rows <- imap_dfr(models, function(m, label) {
    if (is.null(m) || !(term %in% names(stats::coef(m)))) return(NULL)
    tibble(
      subgroup = label,
      estimate = unname(stats::coef(m)[[term]]),
      se       = unname(fixest::se(m)[[term]])
    )
  })

  if (nrow(rows) == 0) {
    message("build_hours_subgroup_comparison: no model had a fitted '", term,
            "' coefficient -- returning NULL.")
    return(NULL)
  }

  rows <- rows %>%
    mutate(
      ci_low   = estimate - 1.96 * se,
      ci_high  = estimate + 1.96 * se,
      subgroup = factor(subgroup, levels = rev(names(models)))
    )

  p <- ggplot(rows, aes(x = estimate, y = subgroup)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
    geom_pointrange(
      aes(xmin = ci_low, xmax = ci_high),
      colour = "#1D9E75", linewidth = 0.7, size = 0.6, na.rm = TRUE
    ) +
    labs(
      title    = title,
      subtitle = subtitle,
      x        = paste0(term, " (95% CI)"),
      y        = NULL
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title       = element_text(size = 13, face = "bold"),
      plot.subtitle    = element_text(size = 10, colour = "grey40"),
      panel.grid.minor = element_blank()
    )

  invisible(list(data = rows, plot = p))
}
