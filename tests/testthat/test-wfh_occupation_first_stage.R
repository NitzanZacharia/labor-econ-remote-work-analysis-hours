# test-wfh_occupation_first_stage.R
# build_wfh_occupation_first_stage(): per-occupation realized WFH vs the calibrated score, the
# correlation/slope statistics, the appendix table and the scatter. Synthetic frame with a
# planted relation between the score and realized WFH.

make_first_stage_fixture <- function(seed = 61, n_occ = 12, per_occ = 120) {
  set.seed(seed)
  codes <- 10 + seq_len(n_occ)
  score <- seq(0.05, 0.95, length.out = n_occ)
  women <- tibble::tibble(
    MishlachYad_ISCO_08_2 = rep(codes, each = per_occ),
    ShnatSeker = sample(c(2021, 2022, 2023), n_occ * per_occ, replace = TRUE),
    Employed   = 1L,
    IDPUF      = seq_len(n_occ * per_occ)
  )
  women$WFH_RefWeek <- rbinom(nrow(women), 1, prob = 0.8 * score[match(women$MishlachYad_ISCO_08_2, codes)])
  women$WFH <- women$WFH_RefWeek
  men <- dplyr::mutate(women, IDPUF = IDPUF + 100000L)

  exposure_external <- tibble::tibble(ISCO2 = codes, tele_ext = score)
  exposure_calibrated <- tibble::tibble(
    ISCO2 = codes, tele_ext = score, n = per_occ * 2, realized_wfh = 0.8 * score,
    swap = c(TRUE, rep(FALSE, n_occ - 1)),
    wfh_exposure_calibrated = ifelse(c(TRUE, rep(FALSE, n_occ - 1)), 0.8 * score, score)
  )
  exposure_realized <- tibble::tibble(occupation_code = codes, wfh_exposure = 0.75 * score, n = per_occ)

  labels_path <- tempfile(fileext = ".csv")
  readr::write_csv(tibble::tibble(isco_2digit = codes, label = paste("Occupation", codes)), labels_path)

  list(women = women, men = men, ext = exposure_external, cal = exposure_calibrated,
       real = exposure_realized, labels_path = labels_path)
}

test_that("build_wfh_occupation_first_stage returns the table, stats and plot with the documented columns", {
  f <- make_first_stage_fixture()
  on.exit(unlink(f$labels_path), add = TRUE)
  out <- capture.output(res <- suppressMessages(build_wfh_occupation_first_stage(
    f$women, f$men, f$cal, f$ext, f$real, labels_path = f$labels_path
  )))

  expect_true(all(c("table", "stats", "plot") %in% names(res)))
  expect_s3_class(res$plot, "ggplot")
  expect_equal(nrow(res$table), 12)
  expect_true(all(c("ISCO2", "label", "external", "calibrated", "swap", "realized_refweek",
                    "n_refweek", "realized_usual", "n_usual", "realized_anchor") %in% names(res$table)))
  expect_equal(res$table$label[1], "Occupation 11")
  # One row per (score, realized measure): calibrated/external x reference-week/usual.
  expect_equal(nrow(res$stats), 4)
  expect_setequal(res$stats$score, c("calibrated", "external"))
  expect_setequal(res$stats$realized, c("realized_refweek", "realized_usual"))
  expect_true(all(res$stats$n_occupations == 12))
  expect_true(all(res$stats$n_swapped == 1))
})

test_that("the first stage recovers the planted positive relation and pools men and women", {
  f <- make_first_stage_fixture()
  on.exit(unlink(f$labels_path), add = TRUE)
  out <- capture.output(res <- suppressMessages(build_wfh_occupation_first_stage(
    f$women, f$men, f$cal, f$ext, f$real, labels_path = f$labels_path
  )))
  cal_ref <- res$stats[res$stats$score == "calibrated" & res$stats$realized == "realized_refweek", ]
  expect_gt(cal_ref$correlation, 0.8)
  expect_gt(cal_ref$slope, 0)
  expect_true(all(res$table$n_refweek == 240))
})

test_that("a missing labels file degrades to code-only labels rather than erroring", {
  f <- make_first_stage_fixture()
  unlink(f$labels_path)
  expect_message(
    out <- capture.output(res <- build_wfh_occupation_first_stage(
      f$women, f$men, f$cal, f$ext, f$real, labels_path = f$labels_path
    )),
    "not found"
  )
  expect_equal(res$table$label[1], "11")
})
