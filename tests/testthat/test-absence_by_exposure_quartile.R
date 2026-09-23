# test-absence_by_exposure_quartile.R
# Unit tests for build_absence_by_exposure_quartile(): the reference-week absence share among the
# employed by quartile of occupation-level WFH exposure.

make_absence_panel <- function(seed = 31, n_occ = 12, per_cell = 30) {
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
    IDPUF                 = grid$occ * 100000L + grid$Mother * 10000L + as.integer(grid$rep)
  )
  # Plant absence that rises with exposure: the most teleworkable occupations have the most
  # employed-but-absent rows. CBS codes 1 = worked in the reference week, 4 = did not.
  p_absent <- 0.05 + 0.3 * exposure[df$MishlachYad_ISCO_08_2]
  df$AvadBeshavua <- ifelse(stats::runif(nrow(df)) < p_absent, 4L, 1L)

  list(
    cleaned_df = df,
    exposure_index = tibble::tibble(occupation_code = occ_codes, wfh_exposure = exposure)
  )
}

test_that("build_absence_by_exposure_quartile returns per-quartile and per-cell shares", {
  fx  <- make_absence_panel()
  res <- build_absence_by_exposure_quartile(fx$cleaned_df, fx$exposure_index)

  expect_true(all(c("by_quartile", "by_cell", "breaks") %in% names(res)))
  expect_equal(nrow(res$by_quartile), 4)
  expect_equal(nrow(res$by_cell), 16)
  expect_length(res$breaks, 5)
  expect_true(all(res$by_quartile$absent_share >= 0 & res$by_quartile$absent_share <= 1))
  expect_true(all(is.finite(res$by_quartile$se)))
})

test_that("the share is the raw cell mean of AvadBeshavua != 1 and recovers a planted gradient", {
  fx  <- make_absence_panel()
  res <- build_absence_by_exposure_quartile(fx$cleaned_df, fx$exposure_index)

  # Hand-computed share for quartile 1 on the same rows.
  joined <- fx$cleaned_df %>%
    dplyr::inner_join(
      dplyr::select(fx$exposure_index, MishlachYad_ISCO_08_2 = occupation_code,
                    WFH_Exposure = wfh_exposure),
      by = "MishlachYad_ISCO_08_2"
    )
  joined <- assign_wfh_quartile(joined, res$breaks)
  expected_q1 <- mean(joined$AvadBeshavua[joined$WFH_Exposure_Q == 1] != 1)
  expect_equal(res$by_quartile$absent_share[res$by_quartile$WFH_Exposure_Q == 1], expected_q1)

  d <- dplyr::arrange(res$by_quartile, WFH_Exposure_Q)
  expect_gt(d$absent_share[4], d$absent_share[1])
})

test_that("supplied breaks are used verbatim and rows without an exposure match are dropped", {
  fx <- make_absence_panel()
  own_breaks <- c(0, 0.2, 0.4, 0.6, 1)
  res <- build_absence_by_exposure_quartile(fx$cleaned_df, fx$exposure_index, breaks = own_breaks)
  expect_equal(unname(res$breaks), own_breaks)

  orphan <- fx$cleaned_df[1:10, ]
  orphan$MishlachYad_ISCO_08_2 <- 999L
  res2 <- build_absence_by_exposure_quartile(dplyr::bind_rows(fx$cleaned_df, orphan),
                                             fx$exposure_index)
  expect_equal(sum(res2$by_quartile$n), nrow(fx$cleaned_df))
})

test_that("a frame without AvadBeshavua errors clearly", {
  fx <- make_absence_panel()
  expect_error(
    build_absence_by_exposure_quartile(dplyr::select(fx$cleaned_df, -AvadBeshavua), fx$exposure_index),
    "AvadBeshavua"
  )
})
