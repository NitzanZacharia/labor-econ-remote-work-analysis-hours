# hours_descriptive_plots.R
# Descriptive figures for the project's PRIMARY outcome, weekly hours. Added with the paper's
# Descriptive Statistics section (docs/decisions/paper-figure-layer.md).
#
# Motivation: after the hours pivot (docs/ROADMAP.md Checkpoint 11) every plot in this repo was
# still an employment-margin plot or a regression coefficient plot. The paper's headline quantity
# -- the raw hours DiD -- existed only as the four-row outputs/hours_diagnostics_hours_by_period.csv,
# and its largest stated limitation (the 2017 pre-trend violation) was visible only through a
# regression-adjusted event study, never in raw means. These two figures close both gaps.
#
# One function returning two plots rather than two files: both are the same filter(Employed == 1)
# frame summarised two ways, so splitting them would duplicate the subsample filter and the
# Mother-labelling in two places and invite them to drift. The one-function-per-file rule (CLAUDE.md)
# counts functions, and this is one -- same shape as employment_by_child_age.R, which returns three.
library(tidyverse)
source(file.path("scripts", "paper_theme.R"))

build_hours_descriptive_plots <- function(cleaned_df, hours_by_period = NULL) {
  # WorkHoursCont is defined only among the employed -- the same subsample
  # run_intensive_margin_reg() and run_hours_ddd_regression() estimate on.
  hours_df <- filter(cleaned_df, Employed == 1)

  year_levels   <- sort(unique(hours_df$ShnatSeker))
  period_levels <- c("Pre-2021", "Post-2021")

  # -- 1. The 2x2 -------------------------------------------------------------------------------
  # hours_by_period is a parameter rather than always recomputed so main.R can pass
  # run_hours_diagnostics()'s own frame. That frame is what reaches disk as
  # outputs/hours_diagnostics_hours_by_period.csv, so passing it makes it impossible for this
  # figure and that CSV to report different means. When absent (standalone/test use) it is
  # recomputed with the identical expression from hours_diagnostics.R:23-25.
  if (is.null(hours_by_period)) {
    hours_by_period <- hours_df %>%
      group_by(Mother, Post) %>%
      summarise(mean_hours = mean(WorkHoursCont, na.rm = TRUE), n = n(), .groups = "drop")
  }

  # Dispersion is joined on rather than folded into mean_hours, so a supplied mean_hours column is
  # returned exactly as it arrived.
  dispersion <- hours_df %>%
    group_by(Mother, Post) %>%
    summarise(
      sd        = sd(WorkHoursCont, na.rm = TRUE),
      n_nonmiss = sum(!is.na(WorkHoursCont)),
      .groups   = "drop"
    ) %>%
    mutate(se = sd / sqrt(n_nonmiss)) %>%
    select(Mother, Post, sd, se)

  hours_by_period <- hours_by_period %>%
    left_join(dispersion, by = c("Mother", "Post")) %>%
    mutate(
      MotherLabel = if_else(Mother == 1, "Mothers", "Non-mothers"),
      PeriodLabel = factor(period_levels[Post + 1], levels = period_levels),
      ci_low      = mean_hours - 1.96 * se,
      ci_high     = mean_hours + 1.96 * se
    )

  # The DiD in raw cell means, computed here rather than written into the subtitle by hand, so the
  # annotation cannot go stale if the sample definition changes.
  cell <- function(m, p) {
    hours_by_period$mean_hours[hours_by_period$Mother == m & hours_by_period$Post == p][1]
  }
  cell_se <- function(m, p) {
    hours_by_period$se[hours_by_period$Mother == m & hours_by_period$Post == p][1]
  }
  did_value <- (cell(1, 1) - cell(1, 0)) - (cell(0, 1) - cell(0, 0))
  did_se    <- sqrt(sum(vapply(
    list(c(1, 1), c(1, 0), c(0, 1), c(0, 0)),
    function(mp) cell_se(mp[1], mp[2])^2,
    numeric(1)
  ), na.rm = TRUE))

  raw_did <- tibble(
    did     = did_value,
    se      = did_se,
    ci_low  = did_value - 1.96 * did_se,
    ci_high = did_value + 1.96 * did_se
  )

  p_2x2 <- ggplot(
    hours_by_period,
    aes(x = PeriodLabel, y = mean_hours, colour = MotherLabel, group = MotherLabel)
  ) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.8) +
    geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.06, linewidth = 0.5) +
    scale_colour_manual(values = PAPER_PALETTE$mother_status) +
    labs(
      title    = "Mean weekly hours before and after 2021",
      subtitle = sprintf(
        "Employed women aged 25-59. Raw difference-in-differences: %+.3f hours (SE %.3f)",
        did_value, did_se
      ),
      x = NULL, y = "Mean usual weekly hours", colour = NULL,
      caption = "Bars are 95% confidence intervals. Pre-2021 covers 2017-2019; Post-2021 covers 2021-2023."
    ) +
    theme_paper()

  # -- 2. Year by year --------------------------------------------------------------------------
  by_year <- hours_df %>%
    group_by(ShnatSeker, Mother) %>%
    summarise(
      mean_hours = mean(WorkHoursCont, na.rm = TRUE),
      sd         = sd(WorkHoursCont, na.rm = TRUE),
      n          = sum(!is.na(WorkHoursCont)),
      .groups    = "drop"
    ) %>%
    mutate(se = sd / sqrt(n))

  panel_levels <- c("Mean weekly hours", "Mother minus non-mother gap")

  levels_panel <- by_year %>%
    transmute(
      ShnatSeker,
      series = if_else(Mother == 1, "Mothers", "Non-mothers"),
      panel  = panel_levels[1],
      value  = mean_hours,
      se,
      n
    )

  # The gap panel is the point of this figure: it is where the 2017 anomaly behind the paper's
  # failed parallel-trends Wald test becomes visible without any regression adjustment.
  gap_panel <- by_year %>%
    select(ShnatSeker, Mother, mean_hours, se, n) %>%
    pivot_wider(names_from = Mother, values_from = c(mean_hours, se, n)) %>%
    transmute(
      ShnatSeker,
      series = "Gap (mothers - non-mothers)",
      panel  = panel_levels[2],
      value  = mean_hours_1 - mean_hours_0,
      se     = sqrt(se_1^2 + se_0^2),
      n      = n_1 + n_0
    )

  # series is an explicit factor so the legend reads Mothers, Non-mothers, Gap rather than the
  # alphabetical order ggplot would otherwise impose, which led with the derived gap series.
  series_levels <- c("Mothers", "Non-mothers", "Gap (mothers - non-mothers)")

  hours_by_year <- bind_rows(levels_panel, gap_panel) %>%
    mutate(
      panel   = factor(panel, levels = panel_levels),
      series  = factor(series, levels = series_levels),
      ci_low  = value - 1.96 * se,
      ci_high = value + 1.96 * se
    ) %>%
    arrange(panel, series, ShnatSeker)

  year_palette <- c(
    PAPER_PALETTE$mother_status,
    "Gap (mothers - non-mothers)" = PAPER_PALETTE$gap
  )

  # group = interaction(series, ShnatSeker >= 2021) breaks each line at the excluded 2020 survey
  # year instead of drawing a straight segment across it, which would imply data that does not
  # exist. Same fix as comparative_statistics.R's mobility plot.
  p_year <- ggplot(
    hours_by_year,
    aes(x = ShnatSeker, y = value, colour = series,
        group = interaction(series, ShnatSeker >= 2021))
  ) +
    geom_hline(
      data = tibble(panel = factor(panel_levels[2], levels = panel_levels), y = 0),
      aes(yintercept = y), inherit.aes = FALSE,
      linetype = "dashed", colour = PAPER_PALETTE$reference
    ) +
    geom_vline(xintercept = 2020, linetype = "dotted", colour = PAPER_PALETTE$reference) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.2) +
    geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.12, linewidth = 0.4) +
    scale_colour_manual(values = year_palette) +
    scale_x_continuous(breaks = year_levels) +
    facet_wrap(~ panel, ncol = 1, scales = "free_y") +
    labs(
      title    = "Weekly hours by survey year",
      subtitle = "Employed women aged 25-59",
      x = "Survey year", y = NULL, colour = NULL,
      caption = paste(
        "Bars are 95% confidence intervals. The dotted rule marks the excluded 2020 survey year;",
        "lines break there rather than interpolating across it."
      )
    ) +
    theme_paper() +
    theme(strip.text = element_text(size = 10, face = "bold", hjust = 0))

  invisible(list(
    hours_by_period = hours_by_period,
    raw_did         = raw_did,
    hours_by_year   = hours_by_year,
    plots           = list(period_2x2 = p_2x2, by_year = p_year)
  ))
}
