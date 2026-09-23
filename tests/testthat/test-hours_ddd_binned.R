# test-hours_ddd_binned.R
# run_hours_ddd_binned(): the primary hours DDD with the continuous exposure score replaced by
# the quartile it falls in (Figure 2's bins). Coefficients are extracted by NAME, which is what
# these tests pin.

make_binned_fixtures <- function(seed = 31, delta = 6, n = 2400, n_occ = 12) {
  set.seed(seed)
  fx <- make_hours_ddd_panel(delta = delta, n = n, n_occ = n_occ, with_years = TRUE)
  df <- fx$panel %>%
    dplyr::inner_join(
      fx$exposure_index %>% dplyr::select(MishlachYad_ISCO_08_2 = occupation_code,
                                         WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )
  list(fx = fx, breaks = compute_occupation_exposure_breaks(df))
}

test_that("run_hours_ddd_binned returns three named quartile triple terms and their sizes", {
  b <- make_binned_fixtures()
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_binned(b$fx$panel, b$fx$exposure_index, breaks = b$breaks)
  ))

  expect_true(all(c("table", "model", "coefs", "quartile_sizes", "breaks") %in% names(res)))
  expect_s3_class(res$model, "fixest")
  expect_equal(res$coefs$quartile, 2:4)
  expect_equal(res$coefs$term, sprintf("Mother:Post:WFH_Exposure_Q::%d", 2:4))
  expect_true(all(res$coefs$term %in% names(coef(res$model))))
  expect_equal(nrow(res$quartile_sizes), 4)
  expect_true(all(res$quartile_sizes$n_occupations >= 1))
  expect_equal(sum(res$quartile_sizes$n_rows), nobs(res$model))
})

test_that("the top-quartile contrast carries the planted effect's sign and dominates the bottom", {
  b <- make_binned_fixtures(delta = 6)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_binned(b$fx$panel, b$fx$exposure_index, breaks = b$breaks)
  ))
  q4 <- res$coefs$estimate[res$coefs$quartile == 4]
  q2 <- res$coefs$estimate[res$coefs$quartile == 2]
  expect_gt(q4, 0)
  expect_gt(q4, q2)
})

test_that("run_hours_ddd_binned refuses malformed breaks", {
  b <- make_binned_fixtures()
  expect_error(run_hours_ddd_binned(b$fx$panel, b$fx$exposure_index, breaks = b$breaks[1:4]),
               "five strictly increasing")
})
