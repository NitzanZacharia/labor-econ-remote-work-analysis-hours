# hours_ddd_by_child_age.R
# Hours DiD and DDD by the age of the mother's youngest child (GilYeledTzairMBNK bins). Each bin's
# mothers are compared with ALL childless women, so the control group is the same in every row.
# Both regressions are the primary functions on the filtered frame; the per-occupation second
# stage is skipped.
library(tidyverse)
library(fixest)
source(file.path("scripts", "data_processing.R"))
source(file.path("scripts", "intensive_margin_regression.R"))
source(file.path("scripts", "hours_ddd_regression.R"))

run_hours_ddd_by_child_age <- function(cleaned_df, exposure_index,
                                       bins = list("0-4" = 1:2, "5-9" = 3, "10-14" = 4, "15-17" = 5),
                                       controls = DEFAULT_CONTROLS) {
  if (!"GilYeledTzairMBNK" %in% names(cleaned_df)) {
    stop("run_hours_ddd_by_child_age: cleaned_df has no GilYeledTzairMBNK column.")
  }

  childless <- filter(cleaned_df, Mother == 0)
  mothers   <- filter(cleaned_df, Mother == 1)

  n_unbinned <- sum(!(mothers$GilYeledTzairMBNK %in% unlist(bins)))
  if (n_unbinned > 0) {
    message(sprintf(
      "run_hours_ddd_by_child_age: %d of %d mothers (%.2f%%) carry a youngest-child code outside the requested bins and enter no row.",
      n_unbinned, nrow(mothers), 100 * n_unbinned / nrow(mothers)
    ))
  }

  extract <- function(m, term) {
    if (is.null(m) || !term %in% names(coef(m))) {
      return(list(coef = NA_real_, se = NA_real_, p = NA_real_, n = NA_integer_))
    }
    list(
      coef = unname(coef(m)[[term]]),
      se   = unname(se(m)[[term]]),
      p    = unname(pvalue(m)[[term]]),
      n    = as.integer(nobs(m))
    )
  }

  did_models <- list()
  ddd_models <- list()
  rows <- list()

  for (label in names(bins)) {
    codes     <- bins[[label]]
    mothers_k <- filter(mothers, GilYeledTzairMBNK %in% codes)
    sub_df    <- bind_rows(childless, mothers_k)

    message(sprintf("run_hours_ddd_by_child_age: youngest child %s (codes %s): %d mothers + %d childless women.",
                    label, paste(codes, collapse = ","), nrow(mothers_k), nrow(childless)))

    did <- tryCatch({
      invisible(capture.output(res <- suppressWarnings(run_intensive_margin_reg(sub_df, controls))))
      res$models$hours
    }, error = function(e) {
      message("  hours DiD failed for bin ", label, ": ", conditionMessage(e))
      NULL
    })
    ddd <- tryCatch({
      invisible(capture.output(res <- suppressWarnings(
        run_hours_ddd_regression(sub_df, exposure_index, controls, run_mechanism = FALSE)
      )))
      res$model
    }, error = function(e) {
      message("  hours DDD failed for bin ", label, ": ", conditionMessage(e))
      NULL
    })

    did_models[[label]] <- did
    ddd_models[[label]] <- ddd

    d <- extract(did, "Mother:Post")
    t <- extract(ddd, "Mother:Post:WFH_Exposure")
    rows[[label]] <- tibble(
      child_age_bin = label,
      codes         = paste(codes, collapse = ","),
      n_mothers     = nrow(mothers_k),
      did_coef = d$coef, did_se = d$se, did_p = d$p, did_n = d$n,
      ddd_coef = t$coef, ddd_se = t$se, ddd_p = t$p, ddd_n = t$n
    )
  }

  table <- bind_rows(rows)
  message("=== Hours DiD and DDD by age of youngest child (each bin's mothers vs all childless women) ===")
  print(as.data.frame(table), digits = 4)

  invisible(list(
    table  = table,
    models = list(did = did_models, ddd = ddd_models),
    bins   = bins
  ))
}
