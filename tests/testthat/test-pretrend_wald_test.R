# test-pretrend_wald_test.R
# Unit tests for run_pretrend_joint_test() (Phase 1c), against a small synthetic fixest model
# fit directly with i(ShnatSeker, ref=2019) + i(ShnatSeker, Mother, ref=2019) -- the exact
# specification run_diagnostics() uses -- rather than depending on run_diagnostics() itself or the
# project's fixture CSVs.

make_pretrend_model <- function() {
  set.seed(3)
  n <- 2000
  df <- data.frame(
    ShnatSeker = sample(c(2017, 2018, 2019, 2021, 2022, 2023), n, replace = TRUE),
    Mother     = sample(0:1, n, replace = TRUE),
    Employed   = sample(0:1, n, replace = TRUE),
    IDPUF      = sample(1:500, n, replace = TRUE)
  )
  fixest::feols(
    Employed ~ Mother + i(ShnatSeker, ref = 2019) + i(ShnatSeker, Mother, ref = 2019),
    data = df, cluster = ~IDPUF
  )
}

test_that("run_pretrend_joint_test returns a Wald test restricted to exactly the 2 pre-2020 terms", {
  m <- make_pretrend_model()
  w <- suppressMessages(run_pretrend_joint_test(m))

  expect_true(all(c("stat", "p", "df1", "df2", "vcov") %in% names(w)))
  expect_equal(w$df1, 2)  # exactly ShnatSeker::2017:Mother and ShnatSeker::2018:Mother
  expect_true(w$p >= 0 && w$p <= 1)
})

test_that("run_pretrend_joint_test's keep pattern does not pick up post-2020 Mother:year terms", {
  m <- make_pretrend_model()
  coefs <- names(coef(m))
  post_period_terms <- grep("ShnatSeker::(2021|2022|2023):Mother", coefs, value = TRUE)
  expect_true(length(post_period_terms) == 3)  # sanity: these terms do exist in the model

  w <- suppressMessages(run_pretrend_joint_test(m))
  expect_equal(w$df1, 2)  # confirms none of the 3 post-period terms leaked into the joint test
})

# ── The DDD event study's triple-interaction restriction set ─────────────────────────────────
# run_pretrend_joint_test() gained keep/label parameters when scripts/hours_ddd_event_study.R added
# a third pretrend model. These tests pin the two properties that made the change necessary, both of
# which are silent-wrong-answer bugs rather than errors if they regress.

make_ddd_pretrend_model <- function() {
  set.seed(4)
  n <- 3000
  df <- data.frame(
    ShnatSeker = sample(c(2017, 2018, 2019, 2021, 2022, 2023), n, replace = TRUE),
    Mother     = sample(0:1, n, replace = TRUE),
    occ        = sample(sprintf("%02d", 11:40), n, replace = TRUE)
  )
  df$WFH_Exposure <- as.numeric(factor(df$occ)) / 30
  df$MotherWFH    <- df$Mother * df$WFH_Exposure
  df$WorkHoursCont <- rnorm(n, 40)
  fixest::feols(
    WorkHoursCont ~ Mother * WFH_Exposure + i(ShnatSeker, ref = 2019) +
      i(ShnatSeker, Mother, ref = 2019) + i(ShnatSeker, WFH_Exposure, ref = 2019) +
      i(ShnatSeker, MotherWFH, ref = 2019),
    data = df, cluster = ~occ
  )
}

test_that("the default keep pattern is anchored, so a DDD event-study model's MotherWFH terms cannot leak in", {
  m <- make_ddd_pretrend_model()
  coefs <- names(coef(m))

  # Sanity: this model has BOTH families of pre-period terms, which is the whole hazard.
  expect_length(grep("^ShnatSeker::(2017|2018):Mother$", coefs), 2)
  expect_length(grep("^ShnatSeker::(2017|2018):MotherWFH$", coefs), 2)

  # Unanchored, "ShnatSeker::(2017|2018):Mother" matches all 4 -- so the pre-change function would
  # have tested two different estimands at once while still looking like a well-formed pre-trend
  # test. The anchor is what keeps the default restricted to the DiD-level terms.
  expect_length(grep("ShnatSeker::(2017|2018):Mother", coefs), 4)
  w <- suppressMessages(run_pretrend_joint_test(m))
  expect_equal(w$df1, 2)
})

test_that("a caller-supplied keep selects exactly the pre-period triple-interaction terms", {
  m <- make_ddd_pretrend_model()
  w <- suppressMessages(run_pretrend_joint_test(
    m,
    keep  = "ShnatSeker::(2017|2018):MotherWFH$",
    label = "Joint Wald, H0: pre-2020 Mother:year:WFH_Exposure coefficients = 0"
  ))

  expect_equal(w$df1, 2)
  # 30 occupation clusters => G - 1 = 29 denominator df. Asserted because the DDD event study's
  # clustering level is what makes this a small-G test, and a silent switch to IDPUF-style clustering
  # would change the inference without changing df1.
  expect_equal(w$df2, 29)
  expect_true(w$p >= 0 && w$p <= 1)
  expect_true(is.finite(w$stat))
})

test_that("label is what reaches the exported one-row table", {
  m <- make_ddd_pretrend_model()
  lab <- "Joint Wald, H0: pre-2020 Mother:year:WFH_Exposure coefficients = 0"
  w <- suppressMessages(run_pretrend_joint_test(
    m, keep = "ShnatSeker::(2017|2018):MotherWFH$", label = lab
  ))

  # Three Wald F-statistics now land in outputs/ as one-row frames. If the label did not follow the
  # restriction set, the DDD's row would be filed under the DiD's hypothesis and the CSVs would be
  # indistinguishable.
  expect_s3_class(w$table, "data.frame")
  expect_equal(nrow(w$table), 1)
  expect_equal(w$table$statistic, lab)
  expect_equal(w$table$df1, 2)

  # And the default keeps the historical label, so the two existing exported rows are unchanged.
  w_default <- suppressMessages(run_pretrend_joint_test(make_pretrend_model()))
  expect_equal(w_default$table$statistic,
               "Joint Wald, H0: pre-2020 Mother:year coefficients = 0")
})

# ── Integration: couple this to the REAL run_diagnostics()-produced model ────────────────────
# The two tests above are valuable for their exact, hand-verifiable df/regex checks, but they run
# entirely against make_pretrend_model()'s own independently hand-built formula -- if
# Diagnostics.R's actual pretrend_model formula ever changes (different controls, a different ref
# year, an added Mother-interacted term), these tests would keep passing against their own frozen
# copy while run_pretrend_joint_test() could silently mis-specify the Wald restriction set in
# production. This test closes that gap by feeding the REAL run_diagnostics() output in.
#
# Deliberately NOT built from the shared fixtures_dir CSVs: those only cover survey years
# 2019/2021-2023 (no 2017/2018 at all -- confirmed empirically), so wald()'s pre-2020 regex
# matches zero terms against them and degenerates to a bare NA rather than a proper Wald object.
# This builds its own minimal temp-CSV fixture spanning 2017/2018/2019/2021, following the same
# self-contained-temp-fixture convention test-data_processing.R's "differs by Post period" test
# already uses for the same class of reason (the shared fixtures don't cover what's needed here).
test_that("run_pretrend_joint_test works against the real run_diagnostics()-produced model, not just a hand-built one", {
  range_boundary_cols <- c(
    "Yeladim0_1Prat", "Yeladim15_17Prat", "MisparHachlafa", "YachasKirvaNK",
    "MisparNefashotGilAvodaV2007", "MisparPrat", "ChipusAvodaSherutTaasuka",
    "ChipusAvodaOfenAcher", "EizeChozemechushav", "ChodeshKodemShaa",
    "MimaHaMigbala", "PniyaLmaasik", "RamatDat", "BituachLeumi"
  )
  # run_diagnostics()'s own NA-audit "peek" section select()s these raw columns unconditionally
  # (even though the peek itself filters to 0 rows here) -- they must exist or select() errors.
  diagnostics_peek_cols <- c(
    "Oved35Shaot", "MisraMelea", "SibaLeAvodaChelkit", "AvadShanaAchrona",
    "KamaChodashimAvadBashana", "SibaLoAvadHashana", "ShaotIkarit"
  )
  make_diag_row <- function(IDPUF, ShnatSeker, mother, employed, ctrl_alt) {
    row <- tibble::tibble(
      IDPUF = IDPUF, ShnatSeker = ShnatSeker, Min = 2, GilNK = if (ctrl_alt) 4 else 5,
      MisparYeladimAd17MB = if (mother) 1 else 0, GilYeledTzairMBNK = if (mother) 2 else 0,
      Muasak = if (employed) 1 else 2, AvodaMeHaBayit = NA,
      ShaotAvodaBederechKlalNK = 3, TeudaGvoha = if (ctrl_alt) 1 else 2,
      SemelEretzLeda = 10, DargatNayadut = 1, MishlachYad_ISCO_08_2 = "100", MachozYishuvAvoda = 1,
      Leom = 1, MatzavMishpachti = if (ctrl_alt) 1 else 2, Dat = if (ctrl_alt) 1 else 2,
      MachozMegurim = if (ctrl_alt) 1 else 2, MisparHorimYechidim = 0,
      # WorkHoursCont is gated on having worked the reference week; this test's outcome is
      # Employed, but load_and_clean_data() builds the hours column regardless and needs the field.
      AvadBeshavua = 1,
      AvadMeHaBayit = NA, KamaShaot = NA, ShaotAvodaLeMaase = 40, MishkalSofi = 1
    )
    for (col in range_boundary_cols) row[[col]] <- 0
    for (col in diagnostics_peek_cols) row[[col]] <- 0
    row
  }

  set.seed(1)
  idpuf <- 90001
  rows <- list()
  for (yr in c(2017, 2018, 2019, 2021)) {
    mother_pat <- rep(c(0, 1), length.out = 16)
    emp_pat    <- sample(c(0, 1), 16, replace = TRUE, prob = c(0.4, 0.6))
    for (i in 1:16) {
      rows[[length(rows) + 1]] <- make_diag_row(idpuf, yr, mother_pat[i], emp_pat[i], i %% 2 == 0)
      idpuf <- idpuf + 1
    }
  }
  synth <- dplyr::bind_rows(rows)

  tmp_dir <- tempfile("pretrend_fixture_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
  readr::write_csv(synth, file.path(tmp_dir, "synth.csv"))

  cleaned <- load_and_clean_data(tmp_dir)
  with_null_device({
    out <- capture.output(diag_res <- run_diagnostics(cleaned))
  })

  w <- suppressMessages(run_pretrend_joint_test(diag_res$pretrend_model))

  expect_true(all(c("stat", "p", "df1", "df2", "vcov") %in% names(w)))
  expect_equal(w$df1, 2)
  expect_true(is.finite(w$stat))
  expect_true(w$p >= 0 && w$p <= 1)
})
