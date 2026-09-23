# wfh_occupation_first_stage.R
# First-stage relevance of the OCCUPATION-LEVEL exposure score, plus the per-occupation table the
# paper's appendix prints. Added in response to the 2026-09-22 grade report (item R3, and the
# appendix-table half of item C1; docs/decisions/grade-report-response.md).
#
# wfh_first_stage_check.R answers the relevance question for the CELL-based index the employment
# DDD uses. Nothing did so for the calibrated occupation-level score that the headline hours DDD
# is estimated on: the paper named the calibration examples (teaching, clerical support, ICT) but
# never reported whether the score predicts where remote work actually happened. This function
# computes, for each two-digit occupation, the realized reference-week WFH share over 2021-2023 on
# men and women pooled (the same pooling rule the calibration uses, so an occupation's score is
# not tested against exactly the women who enter the regression), and reports the correlation and
# the n-weighted slope of realized WFH on the calibrated score, with the external and realized
# indices alongside.
#
# The weights in the slope regression are occupation cell sizes, not CBS survey weights -- a
# precision weight on forty aggregate points, consistent with README.md's "Known limitations".
library(tidyverse)
library(fixest)
source(file.path("scripts", "clustered_se.R"))
source(file.path("scripts", "paper_theme.R"))

build_wfh_occupation_first_stage <- function(cleaned_women, cleaned_men = NULL,
                                             exposure_calibrated, exposure_external,
                                             exposure_realized = NULL,
                                             labels_path = file.path("data", "isco08_2digit_labels.csv"),
                                             ref_years = c(2021, 2022, 2023),
                                             wfh_col = "WFH_RefWeek") {
  pooled_all <- bind_rows(cleaned_women, cleaned_men) %>%
    filter(ShnatSeker %in% ref_years, Employed == 1, !is.na(MishlachYad_ISCO_08_2)) %>%
    mutate(ISCO2 = MishlachYad_ISCO_08_2)

  # Per-occupation realized share of one WFH item, with an IDPUF-clustered SE and the cell size.
  realized_share_by_occupation <- function(col, suffix) {
    df <- filter(pooled_all, !is.na(.data[[col]]))
    share_formula <- as.formula(paste(col, "~ 1"))
    out <- df %>%
      group_by(ISCO2) %>%
      group_modify(~ {
        fit <- clustered_se(.x, share_formula, "(Intercept)")
        tibble(share = mean(.x[[col]]), se = fit$se, n = nrow(.x))
      }) %>%
      ungroup()
    names(out) <- c("ISCO2", paste0("realized_", suffix), paste0("se_", suffix), paste0("n_", suffix))
    out
  }

  # Two realized measures, because the calibration targets the "usual place of work" item (WFH)
  # while the reference-week item (WFH_RefWeek) is the better-behaved series (data_processing.R).
  # A score can track one and not the other; both are reported so the reader sees which.
  realized_refweek <- realized_share_by_occupation(wfh_col, "refweek")
  realized_usual   <- if ("WFH" %in% names(pooled_all) && wfh_col != "WFH") {
    realized_share_by_occupation("WFH", "usual")
  } else NULL

  labels <- if (file.exists(labels_path)) {
    read_csv(labels_path, show_col_types = FALSE) %>%
      transmute(ISCO2 = as.numeric(isco_2digit), label = as.character(label))
  } else {
    message("build_wfh_occupation_first_stage: '", labels_path, "' not found -- occupations will be ",
            "listed by code only.")
    tibble(ISCO2 = numeric(0), label = character(0))
  }

  table <- exposure_external %>%
    transmute(ISCO2, external = tele_ext) %>%
    left_join(labels, by = "ISCO2") %>%
    left_join(
      exposure_calibrated %>%
        transmute(ISCO2, calibrated = wfh_exposure_calibrated, swap = as.logical(swap),
                  realized_usual_calibration = realized_wfh, n_calibration = n),
      by = "ISCO2"
    ) %>%
    left_join(realized_refweek, by = "ISCO2")

  if (!is.null(realized_usual)) {
    table <- table %>% left_join(realized_usual, by = "ISCO2")
  }

  if (!is.null(exposure_realized)) {
    table <- table %>%
      left_join(
        exposure_realized %>% transmute(ISCO2 = occupation_code, realized_anchor = wfh_exposure),
        by = "ISCO2"
      )
  }

  table <- table %>%
    mutate(label = if_else(is.na(label), as.character(ISCO2), label)) %>%
    relocate(label, .after = ISCO2) %>%
    arrange(ISCO2)

  # First stage on the occupations that carry both a score and a realized share. One row per
  # (score, realized measure) pair: calibrated and external against the reference-week share,
  # and against the usual-place-of-work share when it is available.
  fs <- table %>% filter(!is.na(calibrated), !is.na(realized_refweek), n_refweek > 0)
  slope_of <- function(y_col, x_col, w_col) {
    d <- fs %>% filter(!is.na(.data[[y_col]]))
    m <- tryCatch(
      feols(as.formula(paste(y_col, "~", x_col)), data = d, weights = as.formula(paste("~", w_col)),
            vcov = "hetero", notes = FALSE),
      error = function(e) NULL
    )
    if (is.null(m) || !x_col %in% names(coef(m))) return(c(NA_real_, NA_real_, NA_real_, nrow(d)))
    c(unname(coef(m)[[x_col]]), unname(se(m)[[x_col]]), unname(r2(m, "r2")), nrow(d))
  }
  one_stat <- function(score, realized, w_col) {
    s <- slope_of(realized, score, w_col)
    tibble(
      score          = score,
      realized       = realized,
      n_occupations  = as.integer(s[4]),
      n_swapped      = sum(fs$swap[!is.na(fs[[realized]])], na.rm = TRUE),
      correlation    = suppressWarnings(cor(fs[[score]], fs[[realized]], use = "complete.obs")),
      slope          = s[1],
      slope_se       = s[2],
      r2             = s[3],
      ref_years      = paste(ref_years, collapse = "-")
    )
  }
  stats <- bind_rows(
    one_stat("calibrated", "realized_refweek", "n_refweek"),
    one_stat("external",   "realized_refweek", "n_refweek")
  )
  if (!is.null(realized_usual)) {
    stats <- bind_rows(
      stats,
      one_stat("calibrated", "realized_usual", "n_usual"),
      one_stat("external",   "realized_usual", "n_usual")
    )
  }

  for (i in seq_len(nrow(stats))) {
    message(sprintf(
      "build_wfh_occupation_first_stage: %s vs %s (%s): %d occupations, corr = %.3f, n-weighted slope = %.3f (SE %.3f, R2 %.3f).",
      stats$score[i], stats$realized[i], stats$ref_years[i], stats$n_occupations[i],
      stats$correlation[i], stats$slope[i], stats$slope_se[i], stats$r2[i]
    ))
  }

  plot_df <- fs %>% mutate(swap_label = if_else(swap, "Swapped to realized value", "External score kept"))
  p <- ggplot(plot_df, aes(x = calibrated, y = realized_refweek)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = PAPER_PALETTE$reference) +
    geom_point(aes(colour = swap_label, shape = swap_label, size = n_refweek), alpha = 0.85) +
    geom_text(
      data = filter(plot_df, swap),
      aes(label = ISCO2), nudge_y = 0.03, size = 3, colour = PAPER_PALETTE$annotation
    ) +
    scale_colour_manual(values = c("External score kept" = PAPER_PALETTE$estimate,
                                   "Swapped to realized value" = PAPER_PALETTE$gap)) +
    scale_shape_manual(values = c("External score kept" = 16, "Swapped to realized value" = 17)) +
    scale_size_continuous(range = c(1.5, 5), guide = "none") +
    scale_x_continuous(limits = c(0, 1)) +
    scale_y_continuous(limits = c(0, max(0.6, max(plot_df$realized_refweek, na.rm = TRUE) + 0.05))) +
    labs(
      title    = "First stage: calibrated exposure score vs realized remote work, by occupation",
      subtitle = sprintf("Two-digit ISCO-08 occupations; realized %s share, %s, men and women pooled",
                         wfh_col, stats$ref_years[1]),
      x        = "Calibrated WFH exposure score",
      y        = sprintf("Realized reference-week WFH share, %s", stats$ref_years[1]),
      colour   = NULL, shape = NULL,
      caption  = "Point size is proportional to the occupation's pooled employed sample. Labels are the ISCO-08 codes of the ten swapped occupations."
    ) +
    theme_paper()

  invisible(list(table = table, stats = stats, plot = p))
}
