# test-assign_wfh_quartile.R
# The one cut() every quartile consumer shares. The break computation itself is pinned in
# test-occupation_exposure_breaks.R and test-age_balance_robustness.R.

test_that("assign_wfh_quartile cuts on the supplied edges, minimum included in bin 1", {
  df <- tibble::tibble(WFH_Exposure = c(0, 0.1, 0.25, 0.3, 0.5, 0.75, 1))
  br <- c(0, 0.25, 0.5, 0.75, 1)
  q  <- assign_wfh_quartile(df, br)$WFH_Exposure_Q
  expect_type(q, "integer")
  # Right-closed bins: (0, 0.25] is bin 1 (with 0 itself via include.lowest), (0.25, 0.5] bin 2 ...
  expect_equal(q, c(1L, 1L, 1L, 2L, 2L, 3L, 4L))
})

test_that("assign_wfh_quartile keeps the other columns and returns NA for a missing exposure", {
  df  <- tibble::tibble(id = 1:2, WFH_Exposure = c(NA_real_, 0.9))
  out <- assign_wfh_quartile(df, c(0, 0.25, 0.5, 0.75, 1))
  expect_identical(names(out), c("id", "WFH_Exposure", "WFH_Exposure_Q"))
  expect_true(is.na(out$WFH_Exposure_Q[1]))
  expect_equal(out$WFH_Exposure_Q[2], 4L)
})
