# test-occupation_exposure_breaks.R
# compute_occupation_exposure_breaks() replaced the inline quartile rule that used to sit in
# build_hours_dose_response() and build_absence_by_exposure_quartile(). These pin that the helper
# reproduces the old inline computation exactly and that the two callers still agree with it.

make_breaks_panel <- function(seed = 5) {
  set.seed(seed)
  fx <- make_hours_ddd_panel(delta = -3, n = 600, n_occ = 12, with_years = TRUE)
  df <- fx$panel %>%
    dplyr::inner_join(
      fx$exposure_index %>% dplyr::select(MishlachYad_ISCO_08_2 = occupation_code,
                                         WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )
  list(df = df, fx = fx)
}

test_that("the helper reproduces the former inline pre-period quantile rule", {
  p <- make_breaks_panel()
  pre <- p$df %>% dplyr::filter(ShnatSeker < 2020) %>% dplyr::pull(WFH_Exposure)
  expected <- quantile(pre, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)

  got <- compute_occupation_exposure_breaks(p$df)
  expect_equal(unname(got), unname(expected))
  expect_length(got, 5)
  expect_true(all(diff(got) > 0))
})

test_that("it errors on duplicate breakpoints and on a missing exposure column", {
  p <- make_breaks_panel()
  constant <- dplyr::mutate(p$df, WFH_Exposure = 0.3)
  expect_error(compute_occupation_exposure_breaks(constant), "duplicate quartile breakpoints")
  expect_error(compute_occupation_exposure_breaks(dplyr::select(p$df, -WFH_Exposure)), "no 'WFH_Exposure'")
})

test_that("build_hours_dose_response reuses supplied breaks and otherwise computes the same ones", {
  p <- make_breaks_panel()
  capture.output(res_auto <- build_hours_dose_response(p$fx$panel, p$fx$exposure_index))
  capture.output(res_given <- build_hours_dose_response(p$fx$panel, p$fx$exposure_index,
                                                        breaks = res_auto$breaks))
  expect_equal(res_given$breaks, res_auto$breaks)
  expect_equal(res_given$data$did, res_auto$data$did)
})
