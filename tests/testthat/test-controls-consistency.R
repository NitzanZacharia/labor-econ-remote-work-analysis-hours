# test-controls-consistency.R
# Since Checkpoint 3, every script that takes a control set references the single DEFAULT_CONTROLS
# constant defined in data_processing.R rather than defining (or inlining) its own copy. This test
# guards against a future edit reintroducing a local copy anywhere under scripts/ or robustness/
# (the third block globs both, rather than naming files) -- exactly the kind of
# duplication that had to be kept in sync by hand across earlier rounds of changes to this
# codebase, before Checkpoint 3. validation.R was itself a live violation of this rule (a
# hardcoded `regression_controls <- c(...)` literal, undetected because this test previously
# didn't scan it) until it was fixed to reference DEFAULT_CONTROLS.

test_that("DEFAULT_CONTROLS has the expected 5 controls, in the documented order", {
  expect_identical(
    DEFAULT_CONTROLS,
    c("MatzavMishpachti", "Dat", "GilNK", "MachozMegurim", "TeudaGvoha")
  )
})

test_that("controls vector is identical (== DEFAULT_CONTROLS) across the three files that define it", {
  c1 <- extract_controls_vector(file.path(project_root, "scripts", "basic_regression.R"))
  c2 <- extract_controls_vector(file.path(project_root, "scripts", "basic_reg_compared_data.R"))
  c3 <- extract_controls_vector(file.path(project_root, "scripts", "employment_by_child_age.R"))

  expect_identical(c1, DEFAULT_CONTROLS)
  expect_identical(c2, DEFAULT_CONTROLS)
  expect_identical(c3, DEFAULT_CONTROLS)
})

test_that("no file reintroduces a local `*controls <- c(...)` literal instead of referencing DEFAULT_CONTROLS", {
  # Matches both `controls <- c(...)` (basic_regression.R etc.) and `regression_controls <- c(...)`
  # (validation.R) -- the pattern has no anchor, so it matches the substring "controls <- c(...)"
  # regardless of what precedes "controls" in the variable name.
  #
  # Globbed rather than listed. This block used to name four files by hand while 17 referenced
  # DEFAULT_CONTROLS, so a local copy reintroduced in any of the other 13 -- both Lee-bounds files,
  # both placebos, hours_ddd_regression.R, everything under robustness/ -- would have gone
  # undetected, which is the single failure mode the test exists to prevent.
  files <- c(
    list.files(file.path(project_root, "scripts"),    pattern = "[.]R$", full.names = TRUE),
    list.files(file.path(project_root, "robustness"), pattern = "[.]R$", full.names = TRUE),
    file.path(project_root, "main.R")
  )
  expect_gt(length(files), 20)  # guards the glob itself: an empty/short list would pass vacuously

  for (f in files) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_false(grepl("controls\\s*<-\\s*c\\(", txt), info = basename(f))
  }
})

test_that("Diagnostics.R's event-study formula is built from DEFAULT_CONTROLS, not a hardcoded list", {
  txt <- paste(readLines(file.path(project_root, "scripts", "Diagnostics.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("DEFAULT_CONTROLS", txt, fixed = TRUE))
  # and no leftover hardcoded control names inlined directly into the formula string
  expect_false(grepl("MatzavMishpachti \\+ Dat \\+ TeudaGvoha", txt))
})

test_that("validation.R's regression_controls references DEFAULT_CONTROLS, not a local literal", {
  txt <- paste(readLines(file.path(project_root, "scripts", "validation.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("regression_controls\\s*<-\\s*DEFAULT_CONTROLS", txt))
})
