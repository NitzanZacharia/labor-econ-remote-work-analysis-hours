# test-hours_dose_response.R
# Local synthetic panel with enough distinct occupation codes to populate four exposure quartiles.

make_dose_panel <- function(seed = 1, n_occ = 12, per_cell = 40) {
  set.seed(seed)
  occ_codes <- seq_len(n_occ)
  exposure  <- seq(0.05, 0.95, length.out = n_occ)

  grid <- expand.grid(
    occ        = occ_codes,
    ShnatSeker = c(2017, 2018, 2019, 2021, 2022, 2023),
    Mother     = c(0, 1),
    rep        = seq_len(per_cell)
  )

  df <- tibble::tibble(
    MishlachYad_ISCO_08_2 = grid$occ,
    ShnatSeker            = grid$ShnatSeker,
    Mother                = grid$Mother,
    Post                  = as.integer(grid$ShnatSeker >= 2021),
    Employed              = 1L,
    # Required since the per-quartile DiD SE is now clustered by IDPUF; see the note in
    # test-hours_descriptive_plots.R's generator. A synthetic person stays in one occupation
    # across years, which is also what keeps clusters nested inside quartiles.
    IDPUF                 = grid$occ * 100000L + grid$Mother * 10000L + as.integer(grid$rep)
  )
  occ_exposure <- exposure[df$MishlachYad_ISCO_08_2]

  # A dose-response planted by construction: mothers' post-2021 hours gain scales with exposure,
  # so the per-quartile DiD should rise from Q1 to Q4.
  df$WorkHoursCont <- 38 - 2 * df$Mother + 1 * df$Post +
    6 * df$Mother * df$Post * occ_exposure + rnorm(nrow(df), sd = 2)

  list(
    cleaned_df = df,
    exposure_index = tibble::tibble(
      occupation_code = occ_codes,
      wfh_exposure    = exposure
    )
  )
}

test_that("build_hours_dose_response returns cell means, per-quartile DiDs, breaks and a plot", {
  fx <- make_dose_panel()
  capture.output(res <- build_hours_dose_response(fx$cleaned_df, fx$exposure_index))

  expect_true(all(c("cell_means", "data", "breaks", "plot") %in% names(res)))
  expect_s3_class(res$plot, "ggplot")
  expect_equal(nrow(res$data), 4)          # one row per quartile
  expect_equal(nrow(res$cell_means), 16)   # 4 quartiles x Mother x Post
  expect_length(res$breaks, 5)
  expect_true(all(diff(res$breaks) > 0))
})

test_that("the per-quartile DiD is the raw four-cell arithmetic", {
  fx <- make_dose_panel()
  capture.output(res <- build_hours_dose_response(fx$cleaned_df, fx$exposure_index))

  q <- res$data$WFH_Exposure_Q[1]
  cm <- dplyr::filter(res$cell_means, WFH_Exposure_Q == q)
  cell <- function(m, p) cm$mean_hours[cm$Mother == m & cm$Post == p]
  expected <- (cell(1, 1) - cell(1, 0)) - (cell(0, 1) - cell(0, 0))

  expect_equal(res$data$did[res$data$WFH_Exposure_Q == q], expected)
})

test_that("a planted dose-response is recovered in the right direction", {
  # Direction only. Strict monotonicity across all four quartiles is the empirical question this
  # figure exists to ask, so asserting it here would be testing the data, not the code.
  fx <- make_dose_panel()
  capture.output(res <- build_hours_dose_response(fx$cleaned_df, fx$exposure_index))

  d <- dplyr::arrange(res$data, WFH_Exposure_Q)
  expect_gt(d$did[4], d$did[1])
})

test_that("confidence intervals bracket the point estimate and all values are finite", {
  fx <- make_dose_panel()
  capture.output(res <- build_hours_dose_response(fx$cleaned_df, fx$exposure_index))

  expect_true(all(is.finite(res$data$did)))
  expect_true(all(is.finite(res$data$se)))
  expect_true(all(res$data$ci_low < res$data$did))
  expect_true(all(res$data$ci_high > res$data$did))
})

test_that("bin edges come from the pre-period distribution and label each quartile", {
  fx <- make_dose_panel()
  capture.output(res <- build_hours_dose_response(fx$cleaned_df, fx$exposure_index))

  pre <- fx$cleaned_df %>%
    dplyr::filter(ShnatSeker < 2020) %>%
    dplyr::inner_join(
      dplyr::select(fx$exposure_index,
                    MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )
  expected <- quantile(pre$WFH_Exposure, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)

  expect_equal(unname(res$breaks), unname(expected))
  expect_equal(res$data$q_low, unname(expected)[1:4])
  expect_equal(res$data$q_high, unname(expected)[2:5])
})

test_that("rows with no occupation match are dropped by the inner join", {
  fx <- make_dose_panel()
  orphan <- fx$cleaned_df[1:10, ]
  orphan$MishlachYad_ISCO_08_2 <- 999L   # no such occupation in exposure_index
  augmented <- dplyr::bind_rows(fx$cleaned_df, orphan)

  capture.output(res <- build_hours_dose_response(augmented, fx$exposure_index))
  expect_equal(sum(res$cell_means$n), nrow(fx$cleaned_df))
})
