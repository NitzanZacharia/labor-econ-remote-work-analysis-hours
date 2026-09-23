# test-hours_ddd_leave_one_out.R
# run_hours_ddd_leave_one_out(): one refit of the primary hours DDD per occupation, that
# occupation removed. The properties to pin: one row per matched occupation, each refit on one
# fewer cluster, the headline reproduced from the primary function, and the influence summary
# consistent with the rows.

test_that("run_hours_ddd_leave_one_out refits once per occupation and summarises the range", {
  set.seed(81)
  fx <- make_hours_ddd_panel(delta = -3, n = 2000, n_occ = 8)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_leave_one_out(fx$panel, fx$exposure_index, labels_path = NULL)
  ))

  expect_true(all(c("table", "summary", "headline", "term") %in% names(res)))
  expect_equal(nrow(res$table), 8)
  expect_setequal(res$table$occupation_code, fx$exposure_index$occupation_code)
  expect_true(all(res$table$n_clusters == 7L))
  expect_true(all(is.finite(res$table$estimate)))
  expect_true(all(res$table$label == paste("ISCO", res$table$occupation_code)))
  # Each refit drops exactly that occupation's rows.
  counts <- table(fx$panel$MishlachYad_ISCO_08_2)
  expect_equal(res$table$n_rows_dropped, as.integer(counts[as.character(res$table$occupation_code)]))
  expect_equal(res$table$n + res$table$n_rows_dropped, rep(nrow(fx$panel), 8))

  # Headline is the primary function's estimate on the full panel.
  out <- capture.output(full <- suppressWarnings(run_hours_ddd_regression(fx$panel, fx$exposure_index, run_mechanism = FALSE)))
  expect_equal(res$headline$estimate, unname(coef(full$model)[["Mother:Post:WFH_Exposure"]]))
  expect_equal(res$headline$se, unname(se(full$model)[["Mother:Post:WFH_Exposure"]]))

  s <- res$summary
  expect_equal(s$n_refits_valid, 8)
  expect_equal(s$min_estimate, min(res$table$estimate))
  expect_equal(s$max_estimate, max(res$table$estimate))
  expect_equal(s$n_moves_over_1se, sum(abs(res$table$estimate - s$headline_estimate) > s$headline_se))
  expect_equal(res$table$delta_in_se, (res$table$estimate - s$headline_estimate) / s$headline_se)
  expect_true(s$all_same_sign)
})

test_that("occupation labels are attached from a labels file when one is supplied", {
  set.seed(82)
  fx <- make_hours_ddd_panel(delta = -3, n = 900, n_occ = 4)
  labels_file <- tempfile(fileext = ".csv")
  on.exit(unlink(labels_file), add = TRUE)
  readr::write_csv(tibble::tibble(isco_2digit = fx$exposure_index$occupation_code[1:2],
                                  label = c("First trade", "Second trade")), labels_file)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_leave_one_out(fx$panel, fx$exposure_index, labels_path = labels_file)
  ))
  lab <- setNames(res$table$label, res$table$occupation_code)
  expect_equal(unname(lab[as.character(fx$exposure_index$occupation_code[1])]), "First trade")
  expect_equal(unname(lab[as.character(fx$exposure_index$occupation_code[3])]),
               paste("ISCO", fx$exposure_index$occupation_code[3]))
})

test_that("too few occupations is an error, not a one-row table", {
  fx <- make_hours_ddd_panel(delta = -3, n = 200, n_occ = 2)
  expect_error(suppressWarnings(run_hours_ddd_leave_one_out(fx$panel, fx$exposure_index, labels_path = NULL)),
               "fewer than three")
})
