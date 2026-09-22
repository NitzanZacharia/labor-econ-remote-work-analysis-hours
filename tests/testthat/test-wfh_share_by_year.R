# test-wfh_share_by_year.R
# Unit tests for build_wfh_share_by_year(): the realized WFH share among the employed by survey
# year, with IDPUF-clustered standard errors.

make_wfh_share_panel <- function(seed = 21, per_year = 60) {
  set.seed(seed)
  years <- c(2017, 2018, 2019, 2021, 2022, 2023)
  grid  <- expand.grid(ShnatSeker = years, rep = seq_len(per_year))
  df <- tibble::tibble(
    ShnatSeker = grid$ShnatSeker,
    rep        = as.integer(grid$rep),
    IDPUF      = as.integer(grid$rep),            # each synthetic person recurs across years
    Employed   = rep(c(1L, 1L, 1L, 0L), length.out = nrow(grid))
  )
  # The CBS items begin in 2021, so the pre-period is NA by construction. 2022 is planted at a
  # known share among the employed (even-numbered persons); 2021 and 2023 are all-zero and all-one.
  df$WFH <- dplyr::case_when(
    df$ShnatSeker < 2021   ~ NA_real_,
    df$ShnatSeker == 2021  ~ 0,
    df$ShnatSeker == 2022  ~ as.numeric(df$rep %% 2L == 0L),
    df$ShnatSeker == 2023  ~ 1
  )
  df$WFH_RefWeek <- df$WFH
  df
}

test_that("build_wfh_share_by_year returns one row per measure and post-period year", {
  df <- make_wfh_share_panel()
  res <- build_wfh_share_by_year(df)

  expect_s3_class(res, "data.frame")
  expect_setequal(names(res), c("measure", "ShnatSeker", "share", "se", "n"))
  expect_setequal(unique(res$measure), c("WFH", "WFH_RefWeek"))
  # No pre-period rows: the items are NA before 2021 and NA years produce no row.
  expect_true(all(res$ShnatSeker >= 2021))
  expect_equal(nrow(res), 2 * 3)
})

test_that("shares are cell means among the employed and lie in [0, 1]", {
  df <- make_wfh_share_panel()
  res <- build_wfh_share_by_year(df) %>% dplyr::filter(measure == "WFH")

  expect_true(all(res$share >= 0 & res$share <= 1))
  expect_equal(res$share[res$ShnatSeker == 2021], 0)
  expect_equal(res$share[res$ShnatSeker == 2023], 1)
  # The planted 2022 share is one half among the employed rows only.
  expected_2022 <- df %>%
    dplyr::filter(Employed == 1, ShnatSeker == 2022) %>%
    dplyr::summarise(m = mean(WFH)) %>%
    dplyr::pull(m)
  expect_equal(res$share[res$ShnatSeker == 2022], expected_2022)
  expect_equal(res$n[res$ShnatSeker == 2022],
               sum(df$Employed == 1 & df$ShnatSeker == 2022))
})

test_that("a missing measure is skipped and an absent set of measures errors", {
  df <- make_wfh_share_panel() %>% dplyr::select(-WFH_RefWeek)
  res <- build_wfh_share_by_year(df)
  expect_setequal(unique(res$measure), "WFH")

  expect_error(build_wfh_share_by_year(dplyr::select(df, -WFH)), "none of the requested")
})
