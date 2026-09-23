# test-build_leave_one_out_plot.R
# build_leave_one_out_plot() is pure post-processing over the leave-one-out table, so the tests
# feed it a hand-built frame and check the plot object and the influence flag.

make_loo_table <- function() {
  tibble::tibble(
    occupation_code = c(11, 23, 25, 41, 53),
    label = c("Chief executives and legislators", "Teaching professionals", "ICT professionals",
              "General and keyboard clerks", "Personal care workers, an intentionally long label to truncate"),
    estimate  = c(3.1, 4.6, 2.0, 3.3, 3.2),
    std_error = c(1.0, 1.2, 0.9, 1.0, 1.0)
  )
}

test_that("build_leave_one_out_plot returns a ggplot with one row per refit and flags influential drops", {
  res <- build_leave_one_out_plot(make_loo_table(), headline_estimate = 3.2, headline_se = 1.0)
  expect_type(res, "list")
  expect_s3_class(res$plot, "ggplot")
  expect_equal(nrow(res$data), 5)
  expect_true(all(c("axis_label", "ci_low", "ci_high", "influential") %in% names(res$data)))
  # Only the refits more than one headline SE from the headline are flagged: 4.6 and 2.0.
  expect_equal(sort(res$data$occupation_code[res$data$influential]), c(23, 25))
  expect_equal(res$band$xmin, 2.2)
  expect_equal(res$band$xmax, 4.2)
  # Long labels are truncated with an ellipsis; short ones are untouched.
  expect_true(any(grepl("…", res$data$label_short)))
  expect_true("ICT professionals" %in% res$data$label_short)
  # The axis is ordered by the estimate each drop leaves.
  ordered_codes <- res$data$occupation_code[order(as.integer(res$data$axis_label))]
  expect_equal(ordered_codes, res$data$occupation_code[order(res$data$estimate)])
})

test_that("build_leave_one_out_plot drops non-finite rows, labels by code when no label column, and returns NULL when empty", {
  tbl <- make_loo_table()
  tbl$estimate[2] <- NA
  res <- build_leave_one_out_plot(tbl, 3.2, 1.0)
  expect_equal(nrow(res$data), 4)

  no_label <- dplyr::select(tbl, -label)
  res2 <- build_leave_one_out_plot(no_label, 3.2, 1.0)
  expect_true(all(grepl("^[0-9]+  ISCO [0-9]+$", as.character(res2$data$axis_label))))

  empty <- tbl; empty$estimate <- NA_real_
  expect_message(out <- build_leave_one_out_plot(empty, 3.2, 1.0), "no finite estimates")
  expect_null(out)

  expect_error(build_leave_one_out_plot(dplyr::select(tbl, -std_error), 3.2, 1.0), "std_error")
})
