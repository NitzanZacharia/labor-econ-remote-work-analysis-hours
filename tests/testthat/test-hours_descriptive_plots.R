# test-hours_descriptive_plots.R
# Synthetic panel built locally: the shared CSV fixtures are sized for schema/parsing checks, not
# for cell means over six survey years (see test-intensive_margin_lee_bounds.R for the same note).

make_hours_panel <- function(seed = 1, per_cell = 60) {
  set.seed(seed)
  years <- c(2017, 2018, 2019, 2021, 2022, 2023)
  grid <- expand.grid(ShnatSeker = years, Mother = c(0, 1), rep = seq_len(per_cell))
  df <- tibble::tibble(
    ShnatSeker = grid$ShnatSeker,
    Mother     = grid$Mother,
    Post       = as.integer(grid$ShnatSeker >= 2021),
    Employed   = 1L
  )
  # A planted DiD: mothers gain 2 hours post-2021 on top of a common 1-hour rise.
  df$WorkHoursCont <- 38 - 2 * df$Mother + 1 * df$Post + 2 * df$Mother * df$Post +
    rnorm(nrow(df), sd = 3)
  # Non-employed rows must be ignored entirely; give them a wild value so leakage would show.
  extra <- df[1:20, ]
  extra$Employed <- 0L
  extra$WorkHoursCont <- 999
  dplyr::bind_rows(df, extra)
}

test_that("build_hours_descriptive_plots returns both plots and their backing frames", {
  capture.output(res <- build_hours_descriptive_plots(make_hours_panel()))

  expect_true(all(c("hours_by_period", "raw_did", "hours_by_year", "plots") %in% names(res)))
  expect_s3_class(res$plots$period_2x2, "ggplot")
  expect_s3_class(res$plots$by_year, "ggplot")
  expect_equal(nrow(res$hours_by_period), 4)
})

test_that("raw_did equals the hand-computed 2x2 difference-in-differences", {
  df <- make_hours_panel()
  capture.output(res <- build_hours_descriptive_plots(df))

  emp <- dplyr::filter(df, Employed == 1)
  cell <- function(m, p) {
    mean(emp$WorkHoursCont[emp$Mother == m & emp$Post == p], na.rm = TRUE)
  }
  expected <- (cell(1, 1) - cell(1, 0)) - (cell(0, 1) - cell(0, 0))

  expect_equal(res$raw_did$did, expected)
  expect_true(res$raw_did$ci_low < res$raw_did$did)
  expect_true(res$raw_did$ci_high > res$raw_did$did)
})

test_that("non-employed rows are excluded from the cell means", {
  # The planted Employed == 0 rows carry WorkHoursCont = 999; any leakage blows the means up.
  capture.output(res <- build_hours_descriptive_plots(make_hours_panel()))
  expect_true(all(res$hours_by_period$mean_hours < 100))
})

test_that("a supplied hours_by_period is returned with its mean_hours untouched", {
  # The no-drift contract with outputs/hours_diagnostics_hours_by_period.csv: main.R passes
  # run_hours_diagnostics()'s own frame, and this function must not recompute over it.
  df <- make_hours_panel()
  supplied <- tibble::tibble(
    Mother     = c(0, 0, 1, 1),
    Post       = c(0, 1, 0, 1),
    mean_hours = c(11, 22, 33, 44),
    n          = c(1L, 2L, 3L, 4L)
  )
  capture.output(res <- build_hours_descriptive_plots(df, hours_by_period = supplied))

  joined <- dplyr::arrange(res$hours_by_period, Mother, Post)
  expect_equal(joined$mean_hours, c(11, 22, 33, 44))
  expect_equal(res$raw_did$did, (44 - 33) - (22 - 11))
})

test_that("omitting hours_by_period reproduces the diagnostics computation", {
  df <- make_hours_panel()
  capture.output(res <- build_hours_descriptive_plots(df))

  reference <- df %>%
    dplyr::filter(Employed == 1) %>%
    dplyr::group_by(Mother, Post) %>%
    dplyr::summarise(mean_hours = mean(WorkHoursCont, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(Mother, Post)

  expect_equal(dplyr::arrange(res$hours_by_period, Mother, Post)$mean_hours,
               reference$mean_hours)
})

test_that("hours_by_year covers every survey year, both panels, and no 2020", {
  capture.output(res <- build_hours_descriptive_plots(make_hours_panel()))

  expect_false(2020 %in% res$hours_by_year$ShnatSeker)
  expect_length(unique(res$hours_by_year$ShnatSeker), 6)
  expect_length(levels(res$hours_by_year$panel), 2)
  # Two mother-status series in the levels panel plus one gap series.
  expect_length(unique(res$hours_by_year$series), 3)
  expect_true(all(c("ci_low", "ci_high") %in% names(res$hours_by_year)))
})

test_that("the gap series is mothers minus non-mothers", {
  capture.output(res <- build_hours_descriptive_plots(make_hours_panel()))

  levels_panel <- dplyr::filter(res$hours_by_year, series != "Gap (mothers - non-mothers)")
  gap_panel    <- dplyr::filter(res$hours_by_year, series == "Gap (mothers - non-mothers)")

  yr <- gap_panel$ShnatSeker[1]
  mothers <- levels_panel$value[levels_panel$series == "Mothers" &
                                  levels_panel$ShnatSeker == yr]
  others  <- levels_panel$value[levels_panel$series == "Non-mothers" &
                                  levels_panel$ShnatSeker == yr]
  expect_equal(gap_panel$value[gap_panel$ShnatSeker == yr], mothers - others)
})
