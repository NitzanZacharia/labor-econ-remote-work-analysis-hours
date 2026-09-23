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
library(fixest)
source(file.path("scripts", "paper_theme.R"))
source(file.path("scripts", "clustered_se.R"))

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
  #
  # se is CLUSTER-ROBUST (by IDPUF), not sd/sqrt(n). See scripts/clustered_se.R for why: the LFS
  # repeats individuals ~4 times, so the independent-observations SE is roughly half the right one.
  # feols(WorkHoursCont ~ 1) returns the cell mean exactly, so this changes no point estimate.
  dispersion <- hours_df %>%
    group_by(Mother, Post) %>%
    group_modify(~ {
      fit <- clustered_se(.x, WorkHoursCont ~ 1, "(Intercept)")
      tibble(sd = sd(.x$WorkHoursCont, na.rm = TRUE),
             se = fit$se,
             n_nonmiss = sum(!is.na(.x$WorkHoursCont)))
    }) %>%
    ungroup() %>%
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
  # Cluster-robust, from the saturated 2x2. The Mother:Post coefficient of feols(y ~ Mother*Post)
  # IS (m11-m10)-(m01-m00) exactly, so this is the same number as did_value with a correct SE --
  # not the root-sum-of-squares of four independent cell SEs, which assumed away the panel.
  did_fit <- clustered_se(hours_df, WorkHoursCont ~ Mother * Post, "Mother:Post")
  did_se  <- did_fit$se

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
  # Cluster-robust cell means, as above.
  by_year <- hours_df %>%
    group_by(ShnatSeker, Mother) %>%
    group_modify(~ {
      fit <- clustered_se(.x, WorkHoursCont ~ 1, "(Intercept)")
      tibble(mean_hours = fit$estimate,
             sd = sd(.x$WorkHoursCont, na.rm = TRUE),
             n  = sum(!is.na(.x$WorkHoursCont)),
             se = fit$se)
    }) %>%
    ungroup()

  # The gap's SE comes from a within-year feols(WorkHoursCont ~ Mother) rather than
  # sqrt(se_1^2 + se_0^2). That formula is only valid when the two group means are independent,
  # and they are not: the same individuals recur within a survey year (2.7-2.9 rows per IDPUF), so
  # it understated the gap SE by roughly 1.6x. This is the change that makes §4.3's
  # "each within the others' confidence bounds" true rather than false.
  gap_se_by_year <- hours_df %>%
    group_by(ShnatSeker) %>%
    group_modify(~ tibble(gap_se = clustered_se(.x, WorkHoursCont ~ Mother, "Mother")$se)) %>%
    ungroup()

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
      n      = n_1 + n_0
    ) %>%
    left_join(gap_se_by_year, by = "ShnatSeker") %>%
    rename(se = gap_se)

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
    # The levels panel used to span only the data (about 38 to 41 hours), which made movements
    # of under half an hour fill the panel. A blank layer pins its range to at least 36-42 hours
    # so the gap panel beneath, not the axis, carries the visual claim (2026-09-23 grade-report-2
    # item on Figure 1). The gap panel is unaffected: its own data define its range.
    geom_blank(
      data = tibble(panel = factor(panel_levels[1], levels = panel_levels),
                    ShnatSeker = year_levels[1], value = c(36, 42), series = names(year_palette)[1]),
      aes(x = ShnatSeker, y = value), inherit.aes = FALSE
    ) +
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
