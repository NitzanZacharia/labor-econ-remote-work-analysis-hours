# test-build_balance_by_exposure_quartile.R
# build_balance_by_exposure_quartile(): pre-period mother-minus-childless differences in each
# control, by quartile of the occupation-level exposure score, with IDPUF-clustered SEs. The
# fixture is the shared synthetic panel with real-looking education levels and a Leom column, so
# every measure has variation.

make_balance_fixture <- function(seed = 41, n = 4000, n_occ = 12) {
  set.seed(seed)
  fx <- make_hours_ddd_panel(delta = -3, n = n, n_occ = n_occ, with_years = TRUE)
  panel <- fx$panel %>%
    dplyr::mutate(
      TeudaGvoha = factor(sample(c("Below High School", "Matriculation (Bagrut)",
                                   "Academic Degree (BA/MA/PhD)"), dplyr::n(), replace = TRUE)),
      Leom = sample(c(1, 1, 1, 2), dplyr::n(), replace = TRUE)
    )
  joined <- panel %>% dplyr::inner_join(
    fx$exposure_index %>% dplyr::select(MishlachYad_ISCO_08_2 = occupation_code, WFH_Exposure = wfh_exposure),
    by = "MishlachYad_ISCO_08_2")
  list(panel = panel, index = fx$exposure_index, breaks = compute_occupation_exposure_breaks(joined))
}

test_that("build_balance_by_exposure_quartile returns one row per quartile and measure on the pre-period sample", {
  d <- make_balance_fixture()
  out <- capture.output(res <- suppressWarnings(
    build_balance_by_exposure_quartile(d$panel, d$index, breaks = d$breaks)
  ))

  expect_true(all(c("table", "breaks", "n_rows", "measures") %in% names(res)))
  tbl <- res$table
  expect_setequal(unique(tbl$WFH_Exposure_Q), 1:4)
  expect_setequal(res$measures, c("age_code", "married", "academic", "below_hs", "jewish_head", "center_tlv", "arab"))
  expect_equal(nrow(tbl), 4 * length(res$measures))
  expect_true(all(c("label", "unit", "mean_childless", "mean_mothers", "difference", "se",
                    "n_childless", "n_mothers", "n_occupations", "exposure_low", "exposure_high") %in% names(tbl)))

  # Pre-period rows only, and the per-quartile counts add up to that sample.
  pre <- d$panel %>% dplyr::filter(ShnatSeker < 2020)
  expect_equal(res$n_rows, nrow(pre))
  first <- tbl[tbl$variable == "age_code", ]
  expect_equal(sum(first$n_mothers + first$n_childless), nrow(pre))

  # The difference is the difference in means (clustered_se only changes the SE), shares in points.
  q1_married <- tbl[tbl$variable == "married" & tbl$WFH_Exposure_Q == 1, ]
  expect_equal(q1_married$difference, q1_married$mean_mothers - q1_married$mean_childless, tolerance = 1e-8)
  expect_true(all(tbl$mean_mothers[tbl$unit == "pct"] >= 0 & tbl$mean_mothers[tbl$unit == "pct"] <= 100))
  expect_true(all(is.finite(tbl$se)))
  expect_true(all(tbl$exposure_low <= tbl$exposure_high))
})

test_that("the Arab share is omitted without a Leom column, and inputs are validated", {
  d <- make_balance_fixture(seed = 42, n = 1500)
  expect_message(
    out <- capture.output(res <- suppressWarnings(
      build_balance_by_exposure_quartile(dplyr::select(d$panel, -Leom), d$index, breaks = d$breaks))),
    "Arab share is omitted"
  )
  expect_false("arab" %in% res$measures)
  expect_error(build_balance_by_exposure_quartile(d$panel, d$index, breaks = c(0, 1)), "breaks")
  expect_error(build_balance_by_exposure_quartile(dplyr::select(d$panel, -ShnatSeker), d$index, breaks = d$breaks),
               "ShnatSeker")
})
