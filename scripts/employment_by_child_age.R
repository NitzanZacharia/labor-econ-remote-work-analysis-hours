# employment_by_child_age.R
# Analyses employment rates for mothers by age group of their youngest child.
# Secondary/extensive-margin (Employed) outcome, post-hours-pivot (docs/decisions/hours-ddd-pivot.md).
# GilYeledTzairMBNK coding: 0 = no children, 1 = age 0–1, 2 = age 2–4,
#                            3 = age 5–9, 4 = age 10–14, 5 = age 15–17
library(tidyverse)
library(fixest)
source(file.path("scripts", "paper_theme.R"))
source(file.path("scripts", "clustered_se.R"))

employment_by_child_age <- function(cleaned_df) {

  # ── 1. Prepare youngest-child age variable ───────────────────────────────
  # GilYeledTzairMBNK is already a categorical code:
  #   0 = no children, 1 = age 0–1, 2 = age 2–4,
  #   3 = age 5–9,     4 = age 10–14, 5 = age 15–17
  # Restrict to mothers (Mother == 1) with a valid code (1–5)
  child_age_labels <- c(
    "1" = "0–1",
    "2" = "2–4",
    "3" = "5–9",
    "4" = "10–14",
    "5" = "15–17"
  )

  df_mothers <- cleaned_df %>%
    filter(
      Mother == 1,
      !is.na(GilYeledTzairMBNK),
      GilYeledTzairMBNK %in% 1:5,      # exclude code 0 (no children)
      !is.na(Employed)
    ) %>%
    mutate(
      ChildAgeBin = factor(
        GilYeledTzairMBNK,
        levels = 1:5,
        labels = child_age_labels
      )
    )

  # ── 2. Raw employment rates by child-age bin ─────────────────────────────
  message("=== Raw employment rates by youngest-child age ===")
  emp_raw <- df_mothers %>%
    group_by(ChildAgeBin) %>%
    summarise(
      emp_rate = mean(Employed, na.rm = TRUE),
      n        = n(),
      .groups  = "drop"
    )
  print(emp_raw)

  # ── 3. Pre/Post breakdown ────────────────────────────────────────────────
  message("=== Employment rates by youngest-child age × Pre/Post ===")
  emp_by_period <- df_mothers %>%
    group_by(ChildAgeBin, Post) %>%
    summarise(
      emp_rate = mean(Employed, na.rm = TRUE),
      n        = n(),
      .groups  = "drop"
    ) %>%
    mutate(Period = if_else(Post == 1, "Post-2021", "Pre-2021"))

  # Cluster-robust standard error for the plotted rate, NOT the binomial sqrt(p(1-p)/n). The
  # binomial formula assumes independent draws and the LFS repeats individuals across waves, so it
  # understated these by roughly the same 1.6x factor as the hours figures (see
  # scripts/clustered_se.R). feols(Employed ~ 1) returns the cell rate exactly, so emp_rate is
  # unchanged. Added so the pre/post profiles carry honest uncertainty: without bars, two lines a
  # percentage point apart read as a finding.
  emp_by_period <- emp_by_period %>%
    left_join(
      df_mothers %>%
        group_by(ChildAgeBin, Post) %>%
        group_modify(~ tibble(se = clustered_se(.x, Employed ~ 1, "(Intercept)")$se)) %>%
        ungroup(),
      by = c("ChildAgeBin", "Post")
    ) %>%
    mutate(
      ci_low  = pmax(0, emp_rate - 1.96 * se),
      ci_high = pmin(1, emp_rate + 1.96 * se)
    )
  print(emp_by_period)

  # ── 4. Regression: employment ~ child-age bin (with controls) ───────────
  controls <- DEFAULT_CONTROLS

  formula_age <- as.formula(paste(
    "Employed ~ ChildAgeBin",
    paste(controls, collapse = " + "),
    sep = " + "
  ))

  reg_age <- feols(formula_age, data = df_mothers, cluster = ~IDPUF)

  message("=== Regression: employment ~ youngest-child age (controlled) ===")
  print(etable(reg_age, digits = 4))

  # ── 5. Adjusted employment rates (margins from regression) ──────────────
  # Recycled predictions: for each bin, set every mother's ChildAgeBin to that
  # bin while keeping her own actual control values, predict, then average the
  # predictions (never average the covariates themselves — several controls
  # are nominal categorical codes with no meaningful "mean").
  adj_emp_by_bin <- map_dfr(levels(df_mothers$ChildAgeBin), function(bin) {
    df_temp <- df_mothers
    df_temp$ChildAgeBin <- factor(bin, levels = levels(df_mothers$ChildAgeBin))
    tibble(
      ChildAgeBin = bin,
      adj_emp     = mean(predict(reg_age, newdata = df_temp), na.rm = TRUE)
    )
  }) %>%
    mutate(ChildAgeBin = factor(ChildAgeBin, levels = levels(df_mothers$ChildAgeBin)))

  plot_df <- emp_raw %>%
    left_join(adj_emp_by_bin, by = "ChildAgeBin")

  # ── 6. Plot ──────────────────────────────────────────────────────────────

  p_raw <- ggplot(emp_raw, aes(x = ChildAgeBin, y = emp_rate)) +
    geom_col(fill = PAPER_PALETTE$estimate, alpha = 0.85, width = 0.65) +
    geom_text(
      aes(label = paste0(round(emp_rate * 100, 1), "%")),
      vjust = -0.5, size = 3.2, colour = "#2C2C2A"
    ) +
    geom_text(
      aes(label = paste0("n=", scales::comma(n))),
      vjust = 1.6, size = 2.8, colour = PAPER_PALETTE$annotation
    ) +
    scale_y_continuous(
      labels = scales::percent_format(accuracy = 1),
      limits = c(0, max(emp_raw$emp_rate) * 1.12),
      expand = expansion(mult = c(0, 0.02))
    ) +
    labs(
      title    = "Employment rate by age of youngest child",
      subtitle = "Mothers aged 25–59, survey years 2017–2023 (excl. 2020)",
      x        = "Age group of youngest child",
      y        = "Employment rate",
      caption  = "Source: LFS data. Bars show raw employment rates; n = cell size."
    ) +
    theme_paper() +
    theme(panel.grid.major.x = element_blank())

  p_period <- ggplot(
    emp_by_period,
    aes(x = ChildAgeBin, y = emp_rate, colour = Period, group = Period)
  ) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.5) +
    geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.08, linewidth = 0.4) +
    scale_colour_manual(values = PAPER_PALETTE$period) +
    # Padded around the plotted range rather than the former c(min*0.92, max*1.06): those
    # multiplicative limits silently clip a point once a rate approaches 0 or 1, and they ignored
    # the confidence bars entirely. expansion() cannot clip.
    scale_y_continuous(
      labels = scales::percent_format(accuracy = 1),
      expand = expansion(mult = 0.10)
    ) +
    labs(
      title    = "Employment rate by youngest-child age: Pre vs Post-2021",
      subtitle = "Mothers aged 25–59",
      x        = "Age group of youngest child",
      y        = "Employment rate",
      colour   = NULL,
      caption  = paste(
        "Bars are 95% confidence intervals. Post-2021 covers 2021–2023; Pre-2021 covers 2017–2019.",
        "\nRaw rates among mothers only: no control group and no covariate adjustment, so the",
        "pre/post distance is not an estimated effect."
      )
    ) +
    theme_paper()

  # 6c. Raw vs adjusted, as a dumbbell rather than dodged bars.
  # The whole point of this figure is the ~5pp divergence between the raw and adjusted profiles in
  # the older-child bins. Bars must be anchored at zero, which squeezed every one of those
  # differences into the top fifth of the panel and made the figure unreadable. A point-and-segment
  # chart carries no such obligation, so the y-axis can zoom to the range the data actually
  # occupies, and the connecting segment states the raw-to-adjusted distance directly.
  adj_levels <- names(PAPER_PALETTE$adjustment)   # "Raw", then "Adjusted (controls)"
  p_adj_long <- plot_df %>%
    pivot_longer(cols = c(emp_rate, adj_emp),
                 names_to = "type", values_to = "rate") %>%
    mutate(type = factor(
      recode(type, emp_rate = "Raw", adj_emp = "Adjusted (controls)"),
      levels = adj_levels
    ))

  p_adj <- ggplot(p_adj_long, aes(x = ChildAgeBin, y = rate)) +
    geom_line(aes(group = ChildAgeBin), colour = PAPER_PALETTE$annotation, linewidth = 0.6) +
    geom_point(aes(colour = type), size = 3.2) +
    scale_colour_manual(values = PAPER_PALETTE$adjustment, breaks = adj_levels) +
    scale_y_continuous(
      labels = scales::percent_format(accuracy = 1),
      expand = expansion(mult = 0.12)
    ) +
    labs(
      title    = "Raw vs adjusted employment rate by youngest-child age",
      subtitle = "Controls: marital status, religion, age group, district, education",
      x        = "Age group of youngest child",
      y        = "Employment rate",
      colour   = NULL,
      caption  = paste(
        "Adjusted rates: OLS predictions with controls held at sample means.",
        "\nNote the y-axis does not start at zero; segments show the raw-to-adjusted distance."
      )
    ) +
    theme_paper() +
    theme(
      plot.subtitle      = element_text(size = 9.5, colour = "grey40"),
      panel.grid.major.x = element_blank()
    )

  # ── 7. Print plots ───────────────────────────────────────────────────────
  # Interactive convenience only. Under a headless `Rscript main.R` a print() here would open R's
  # default device and leak an Rplots.pdf into the repo root (see .gitignore). The three plots reach
  # disk as PNGs via export_all_results() regardless, so skipping them loses nothing.
  if (interactive()) {
    print(p_raw)
    print(p_period)
    print(p_adj)
  }

  # ── 8. Return results invisibly ─────────────────────────────────────────
  invisible(list(
    emp_raw      = emp_raw,
    emp_by_period = emp_by_period,
    # Raw and covariate-adjusted rates side by side. Exported because the paper quotes the adjusted
    # 15-17 figure in §4.5 and, until this was added, that was the only number in the Descriptive
    # Statistics section with no reproducible source on disk -- the adjusted profile existed only
    # as an in-script prediction feeding the plot.
    adjusted_rates = plot_df,
    model        = reg_age,
    plots        = list(raw = p_raw, period = p_period, adjusted = p_adj)
  ))
}