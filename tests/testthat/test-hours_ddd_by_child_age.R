# test-hours_ddd_by_child_age.R
# run_hours_ddd_by_child_age(): the hours DiD/DDD per youngest-child age bin, each bin's mothers
# against all childless women. The sample rule is the thing to pin: a bin restricted to its own
# mothers would leave Mother constant and Mother:Post unidentified.

test_that("run_hours_ddd_by_child_age fits one DiD and one DDD per bin on bin mothers plus all childless women", {
  set.seed(51)
  fx <- make_hours_ddd_panel(delta = -3, n = 2000, n_occ = 12, with_child_age = TRUE)
  out <- capture.output(res <- suppressWarnings(
    run_hours_ddd_by_child_age(fx$panel, fx$exposure_index)
  ))

  expect_true(all(c("table", "models", "bins") %in% names(res)))
  expect_equal(res$table$child_age_bin, c("0-4", "5-9", "10-14", "15-17"))
  expect_true(all(c("did_coef", "did_se", "did_n", "ddd_coef", "ddd_se", "ddd_n", "n_mothers") %in%
                    names(res$table)))
  expect_setequal(names(res$models$ddd), res$table$child_age_bin)

  n_childless <- sum(fx$panel$Mother == 0)
  for (i in seq_len(nrow(res$table))) {
    codes <- res$bins[[res$table$child_age_bin[i]]]
    n_mothers <- sum(fx$panel$Mother == 1 & fx$panel$GilYeledTzairMBNK %in% codes)
    expect_equal(res$table$n_mothers[i], n_mothers)
    expect_equal(res$table$ddd_n[i], n_childless + n_mothers)
    expect_s3_class(res$models$did[[i]], "fixest")
    expect_true("Mother:Post:WFH_Exposure" %in% names(coef(res$models$ddd[[i]])))
  }
})

test_that("custom bins are honoured and mothers outside them are reported, not silently dropped", {
  set.seed(52)
  fx <- make_hours_ddd_panel(delta = -3, n = 1500, n_occ = 12, with_child_age = TRUE)
  expect_message(
    out <- capture.output(res <- suppressWarnings(
      run_hours_ddd_by_child_age(fx$panel, fx$exposure_index, bins = list("young" = 1:2, "school" = 3:4))
    )),
    "enter no row"
  )
  expect_equal(res$table$child_age_bin, c("young", "school"))
})

test_that("a frame without the child-age column errors clearly", {
  fx <- make_hours_ddd_panel(delta = -3, n = 200)
  expect_error(run_hours_ddd_by_child_age(fx$panel, fx$exposure_index), "GilYeledTzairMBNK")
})
