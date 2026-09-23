# hours_ddd_leave_one_out.R
# Leave-one-occupation-out sensitivity of the hours DDD's triple interaction, added in response to
# the 2026-09-23 grade report (Robustness deduction 1; docs/decisions/grade-report-2-response.md).
#
# Why. The regressor varies across forty occupations, the top exposure quartile holds six of them,
# and two of those (ICT professionals, science and engineering professionals) are among the
# largest cells in the sample. A coefficient that rests on one occupation is a different finding
# from one that survives the removal of any. This refits run_hours_ddd_regression() forty times,
# each time without one occupation, and records the triple interaction. The summary the paper
# prints is the range of the forty estimates and the occupations whose removal moves the estimate
# by more than one headline standard error (an influence rule, not a significance test).
#
# Each refit is the primary function on the filtered frame -- the same pattern main.R uses for the
# Jewish/Arab and child-age rows -- with the per-occupation mechanism stage switched off. Forty
# feols fits on ~240k rows take about a minute.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "hours_ddd_regression.R"))

run_hours_ddd_leave_one_out <- function(cleaned_df, exposure_index, controls = DEFAULT_CONTROLS,
                                        labels_path = file.path("data", "isco08_2digit_labels.csv"),
                                        term = "Mother:Post:WFH_Exposure") {
  quiet <- function(expr) {
    invisible(capture.output(res <- suppressWarnings(suppressMessages(expr))))
    res
  }

  headline <- quiet(run_hours_ddd_regression(cleaned_df, exposure_index, controls, run_mechanism = FALSE))
  m0 <- headline$model
  if (!term %in% names(coef(m0))) {
    stop("run_hours_ddd_leave_one_out: '", term, "' is not in the headline model.")
  }
  b0  <- unname(coef(m0)[[term]])
  se0 <- unname(se(m0)[[term]])

  # Only occupations that actually enter the headline fit are dropped in turn.
  matched_codes <- cleaned_df %>%
    filter(Employed == 1, MishlachYad_ISCO_08_2 %in% exposure_index$occupation_code) %>%
    pull(MishlachYad_ISCO_08_2) %>%
    unique() %>%
    sort()
  if (length(matched_codes) < 3) {
    stop("run_hours_ddd_leave_one_out: fewer than three matched occupations; nothing to leave out.")
  }

  labels <- if (!is.null(labels_path) && file.exists(labels_path)) {
    read_csv(labels_path, show_col_types = FALSE) %>%
      transmute(occupation_code = as.numeric(isco_2digit), label = as.character(label))
  } else {
    if (!is.null(labels_path)) {
      message("run_hours_ddd_leave_one_out: '", labels_path, "' not found -- occupations are labelled by code.")
    }
    tibble(occupation_code = numeric(0), label = character(0))
  }

  message(sprintf("run_hours_ddd_leave_one_out: headline %s = %.4f (SE %.4f); refitting without each of %d occupations...",
                  term, b0, se0, length(matched_codes)))
  started <- Sys.time()
  rows <- map(matched_codes, function(code) {
    sub_df <- filter(cleaned_df, is.na(MishlachYad_ISCO_08_2) | MishlachYad_ISCO_08_2 != code)
    fit <- tryCatch(
      quiet(run_hours_ddd_regression(sub_df, exposure_index, controls, run_mechanism = FALSE)),
      error = function(e) {
        message("  refit without occupation ", code, " failed: ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(fit) || !term %in% names(coef(fit$model))) {
      return(tibble(occupation_code = code, estimate = NA_real_, std_error = NA_real_,
                    p_value = NA_real_, n = NA_integer_, n_clusters = NA_integer_,
                    n_rows_dropped = sum(cleaned_df$MishlachYad_ISCO_08_2 == code &
                                         cleaned_df$Employed == 1, na.rm = TRUE)))
    }
    m <- fit$model
    tibble(
      occupation_code = code,
      estimate        = unname(coef(m)[[term]]),
      std_error       = unname(se(m)[[term]]),
      p_value         = unname(pvalue(m)[[term]]),
      n               = as.integer(nobs(m)),
      n_clusters      = as.integer(fit$n_clusters),
      n_rows_dropped  = as.integer(headline$n_matched - fit$n_matched)
    )
  }) %>%
    bind_rows() %>%
    left_join(labels, by = "occupation_code") %>%
    mutate(
      label          = if_else(is.na(label), paste("ISCO", occupation_code), label),
      delta          = estimate - b0,
      delta_in_se    = delta / se0,
      moves_over_1se = is.finite(delta_in_se) & abs(delta_in_se) > 1
    ) %>%
    relocate(label, .after = occupation_code)

  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  ok <- rows %>% filter(is.finite(estimate))
  summary_tbl <- tibble(
    term               = term,
    headline_estimate  = b0,
    headline_se        = se0,
    n_refits           = nrow(rows),
    n_refits_valid     = nrow(ok),
    min_estimate       = min(ok$estimate),
    max_estimate       = max(ok$estimate),
    min_estimate_code  = ok$occupation_code[which.min(ok$estimate)],
    max_estimate_code  = ok$occupation_code[which.max(ok$estimate)],
    max_abs_delta_in_se = max(abs(ok$delta_in_se)),
    n_moves_over_1se   = sum(ok$moves_over_1se),
    all_same_sign      = all(sign(ok$estimate) == sign(b0)),
    min_p_value        = min(ok$p_value),
    max_p_value        = max(ok$p_value),
    seconds            = elapsed
  )

  message(sprintf(
    paste0("run_hours_ddd_leave_one_out: %d valid refits in %.0f s; estimates range %.4f to %.4f ",
           "(headline %.4f); largest move %.2f headline SEs; %d occupation(s) move it by more than one SE."),
    nrow(ok), elapsed, summary_tbl$min_estimate, summary_tbl$max_estimate, b0,
    summary_tbl$max_abs_delta_in_se, summary_tbl$n_moves_over_1se
  ))
  if (summary_tbl$n_moves_over_1se > 0) {
    print(as.data.frame(rows %>% filter(moves_over_1se) %>%
                          select(occupation_code, label, estimate, std_error, delta_in_se, n_rows_dropped)),
          digits = 4)
  }

  invisible(list(
    table    = rows,
    summary  = summary_tbl,
    headline = list(estimate = b0, se = se0, model = m0),
    term     = term
  ))
}
