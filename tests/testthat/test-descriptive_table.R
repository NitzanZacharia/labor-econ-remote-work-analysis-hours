# test-descriptive_table.R
# build_descriptive_table() feeds Table 1 of the paper directly, so these guard the arithmetic a
# reader would try to check by hand: the two mother groups partition the sample, each group's
# categorical composition sums to 100%, and the headline rates match a direct calculation.

cleaned <- load_and_clean_data(fixtures_dir)

test_that("build_descriptive_table returns the documented structure on fixture data", {
  out <- capture.output(res <- build_descriptive_table(cleaned))

  expect_type(res, "list")
  expect_true(all(c("continuous", "categorical") %in% names(res)))
  expect_s3_class(res$continuous, "data.frame")
  expect_s3_class(res$categorical, "data.frame")
  expect_true(all(c("measure", "childless", "mothers", "difference") %in% names(res$continuous)))
  expect_true(all(c("variable", "level") %in% names(res$categorical)))
})

test_that("the two mother groups partition the sample", {
  out <- capture.output(res <- build_descriptive_table(cleaned))

  n_row <- res$continuous[res$continuous$measure == "Observations", ]
  expect_equal(nrow(n_row), 1)
  expect_equal(n_row$childless + n_row$mothers, nrow(cleaned))
  # A difference of row counts is not a comparison and is deliberately left blank.
  expect_true(is.na(n_row$difference))
})

test_that("the employment rate matches a direct calculation for each group", {
  out <- capture.output(res <- build_descriptive_table(cleaned))

  emp_row <- res$continuous[res$continuous$measure == "Employment rate", ]
  expect_equal(
    emp_row$childless,
    mean(cleaned$Employed[cleaned$Mother == 0], na.rm = TRUE)
  )
  expect_equal(
    emp_row$mothers,
    mean(cleaned$Employed[cleaned$Mother == 1], na.rm = TRUE)
  )
})

test_that("mean weekly hours conditions on the employed only", {
  out <- capture.output(res <- build_descriptive_table(cleaned))

  hours_row <- res$continuous[res$continuous$measure == "Usual weekly hours (employed), mean", ]
  expected <- mean(
    cleaned$WorkHoursCont[cleaned$Mother == 1 & cleaned$Employed == 1],
    na.rm = TRUE
  )
  expect_equal(hours_row$mothers, expected)
})

test_that("the age-group mean is numeric, not NA from the factor cast", {
  # Regression guard: data_processing.R casts GilNK to a factor, so mean() on it silently returns
  # NA with a warning unless the ordinal code is restored first.
  out <- capture.output(res <- build_descriptive_table(cleaned))

  age_row <- res$continuous[res$continuous$measure == "Age-group code (CBS 3-7), mean", ]
  expect_false(is.na(age_row$childless))
  expect_false(is.na(age_row$mothers))
  expect_equal(
    age_row$mothers,
    mean(as.numeric(as.character(cleaned$GilNK[cleaned$Mother == 1])), na.rm = TRUE)
  )
})

test_that("each group's categorical composition sums to 100 percent within a variable", {
  out <- capture.output(res <- build_descriptive_table(cleaned))

  for (v in unique(res$categorical$variable)) {
    rows <- res$categorical[res$categorical$variable == v, ]
    for (col in c("pct_mother0", "pct_mother1")) {
      if (!col %in% names(rows)) next
      total <- sum(rows[[col]], na.rm = TRUE)
      # A variable absent for one group sums to 0 rather than 100; only check a populated column.
      if (total > 0) {
        expect_equal(total, 100, tolerance = 1e-8, info = paste(v, col))
      }
    }
  }
})

test_that("coded controls carry the confirmed CBS codebook labels", {
  out <- capture.output(res <- build_descriptive_table(cleaned))
  ct <- res$categorical

  expect_true("level_label" %in% names(ct))
  expect_true(all(nzchar(ct$level_label)))
  expect_false(any(is.na(ct$level_label)))

  labs <- function(v) unique(ct$level_label[ct$variable == v])
  expect_true(all(labs("MatzavMishpachti") %in%
    c("Married", "Married, living separately", "Divorced", "Widowed", "Single, never married")))
  expect_true(all(labs("Dat") %in% c("Jewish", "Christian", "Muslim", "Druze", "Other")))
  expect_true(all(labs("MachozMegurim") %in%
    c("Jerusalem", "North", "Haifa", "Center", "Tel Aviv", "South", "Judea and Samaria")))

  # Spot-check the two codes whose sample shares corroborate the mapping independently.
  m1 <- ct$level_label[ct$variable == "MatzavMishpachti" & ct$level == "1"]
  if (length(m1)) expect_equal(m1, "Married")
  d1 <- ct$level_label[ct$variable == "Dat" & ct$level == "1"]
  if (length(d1)) expect_equal(d1, "Jewish")

  # Education is labelled upstream by data_processing.R: its label is its level.
  edu <- ct[ct$variable == "TeudaGvoha", ]
  expect_equal(edu$level_label, edu$level)
})

test_that("the categorical panel covers the control set minus GilNK", {
  out <- capture.output(res <- build_descriptive_table(cleaned))

  expect_setequal(unique(res$categorical$variable), setdiff(DEFAULT_CONTROLS, "GilNK"))
  expect_false("GilNK" %in% res$categorical$variable)
})
