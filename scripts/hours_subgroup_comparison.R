# hours_subgroup_comparison.R
# Forest-plot comparison of one regression coefficient across the intensive-margin (hours)
# subgroup specifications -- main.R's demographic-heterogeneity check for the hours DiD
# (Mother:Post) and DDD (Mother:Post:WFH_Exposure) terms across ethnicity (Jewish/Arab women) and
# the male gender-placebo. One parameterized function rather than two near-identical copies, since
# the only difference between the DiD and DDD comparison plots is which coefficient is pulled from
# each already-fitted model.
library(tidyverse)
library(fixest)
source(file.path("scripts", "paper_theme.R"))

# `placebo` and `x_label` are trailing arguments with defaults so every existing call site --
# main.R's two, and the three cases in test-hours_subgroup_comparison.R -- keeps working unchanged.
build_hours_subgroup_comparison <- function(models, term, title, subtitle = NULL,
                                            placebo = character(0), x_label = NULL) {
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
      # A placebo row is a different population (men), not another slice of the study sample, so
      # it is styled apart rather than sitting in the same visual series as the women subgroups.
      is_placebo = subgroup %in% placebo,
      subgroup   = factor(subgroup, levels = rev(names(models)))
    )

  p <- ggplot(rows, aes(x = estimate, y = subgroup)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = PAPER_PALETTE$reference) +
    geom_pointrange(
      aes(xmin = ci_low, xmax = ci_high, colour = is_placebo, shape = is_placebo),
      linewidth = 0.7, size = 0.6, na.rm = TRUE
    ) +
    scale_colour_manual(
      values = c("FALSE" = PAPER_PALETTE$estimate, "TRUE" = PAPER_PALETTE$placebo),
      guide  = "none"
    ) +
    scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 21), guide = "none") +
    # A wide interval (the Arab-women DDD reaches 11.19) previously ran to the panel edge and read
    # as though it had been truncated. clip = "off" keeps the cap drawn even when it lands on the
    # boundary; the added expansion keeps it off the boundary in the first place.
    scale_x_continuous(expand = expansion(mult = 0.12)) +
    coord_cartesian(clip = "off") +
    labs(
      title    = title,
      subtitle = subtitle,
      x        = if (is.null(x_label)) paste0(term, " (95% CI)") else x_label,
      y        = NULL,
      # Without this, the DiD and DDD panels look interchangeable while sitting on entirely
      # different estimands and x-scales -- the DDD is per unit of exposure, the DiD is not.
      caption  = paste0("Estimand: ", term, ". Scales are not comparable across specifications.")
    ) +
    theme_paper() +
    theme(legend.position = "none")

  invisible(list(data = rows, plot = p))
}
