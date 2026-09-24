# test-wfh_crosswalk_integrity.R
# In-place integrity checks on data/israeli_cbs_wfh_2digit.csv, the external teleworkability
# score that build_exposure_isco2() (wfh_exposure_cells.R) reads and that every occupation-level
# exposure measure -- and so the headline hours DDD -- is built from. The file was committed by
# hand (2026-09-09) and nothing in the pipeline regenerates it, so these assertions are the guard
# against a silent edit putting it in a shape the regressions would mis-handle without a word
# (build_exposure_cells() drops unmatched ISCO2 codes with a bare filter(!is.na(tele_ext))).
#
# What the file is (established and reproduced exactly on 2026-09-23; the record is in
# docs/decisions/wfh-crosswalk-provenance.md): the Dingel & Neiman (2020) binary
# `teleworkable` flag from their published O*NET-SOC occupations file (968 rows), mapped to
# ISCO-08 through the BLS 2012 "ISCO-08 to 2010 SOC" crosswalk workbook (the author's copy came
# via the Israeli CBS; it is the same workbook D&N's own country-level code reads), and averaged
# WITHOUT weights over every matched (ISCO unit group x O*NET-SOC row) pair within each two-digit
# sub-major group. The last block below re-runs that derivation from the two source files and
# asserts it reproduces the committed CSV to 1e-12; it is skipped unless both files are supplied
# through environment variables (they are public but not committed: D&N's repository is GPLv3,
# and the BLS sheet is an .xls). Inputs it accepts, pinned by SHA-256 so the proof is tied to the
# exact published versions:
#   WFH_DN_OCCUPATIONS_CSV  occupations_workathome.csv from
#     https://github.com/jdingel/DingelNeiman-workathome (occ_onet_scores/output/)
#     42ff3ae084478b554526671710b53a16d39f88c3eebb24f56f46372d7243bd40
#   WFH_BLS_ISCO_SOC_XLS    ISCO_SOC_Crosswalk.xls from https://www.bls.gov/soc/soccrosswalks.htm
#     6d376cdc29e7b52e10e420644f46d7be69a1c48be1b3c650c290f21b4db3dd41
# That block is the only place the repo touches `readxl`; it is reached through
# skip_if_not_installed(), never library(), so the suite runs without the package (CLAUDE.md's
# dependency rule). The six blocks before it need no source files and run everywhere: they pin
# the structural signatures of the derivation that are visible in the file itself -- (i) score x
# matched count is an integer, as a mean of a 0/1 flag must be; (ii) the per-group code counts
# equal the ISCO-08 standard except for groups 21 and 31, which carry one extra code each, the two
# minor-group codes (211, 315) the BLS sheet assigns to SOC 19-2099 and 53-2022; (iii) the binary
# column is a 0.5 cutoff on the score.

crosswalk_path <- file.path(project_root, "data", "israeli_cbs_wfh_2digit.csv")
cw <- readr::read_csv(crosswalk_path, show_col_types = FALSE)

# The 43 ISCO-08 sub-major groups: armed forces 01-03 (written 1, 2, 3 -- the file stores the
# code numerically, as MishlachYad_ISCO_08_2 is after data_processing.R) plus the 40 civilian
# groups 11-96. The CBS occupation variable takes no other value, so a file covering exactly this
# set gives every unmasked row a score.
isco08_submajor <- c(1, 2, 3, 11:14, 21:26, 31:35, 41:44, 51:54, 61:63, 71:75, 81:83, 91:96)
scored <- dplyr::filter(cw, !is.na(wfh_probability_2d))

test_that("wfh crosswalk: schema and keys -- five named columns, 43 rows, exactly the ISCO-08 sub-major groups", {
  expect_identical(
    names(cw),
    c("isco_2digit", "wfh_probability_2d", "matched_soc_count_2d", "total_4digit_codes", "is_wfh_binary_2d")
  )
  expect_equal(nrow(cw), 43)
  expect_true(all(cw$isco_2digit == round(cw$isco_2digit)))
  expect_false(anyDuplicated(cw$isco_2digit) > 0)
  expect_equal(sort(cw$isco_2digit), isco08_submajor)
})

test_that("wfh crosswalk: score domain -- NA only for the armed forces, [0, 1] elsewhere, NA iff zero matches", {
  expect_equal(cw$isco_2digit[is.na(cw$wfh_probability_2d)], c(1, 2, 3))
  expect_equal(nrow(scored), 40)   # the "forty occupations" the paper counts
  expect_true(all(scored$wfh_probability_2d >= 0 & scored$wfh_probability_2d <= 1))
  expect_equal(is.na(cw$wfh_probability_2d), cw$matched_soc_count_2d == 0)
  expect_equal(is.na(cw$is_wfh_binary_2d), is.na(cw$wfh_probability_2d))
  expect_true(all(cw$matched_soc_count_2d >= 0 & cw$matched_soc_count_2d == round(cw$matched_soc_count_2d)))
  expect_true(all(cw$total_4digit_codes >= 1 & cw$total_4digit_codes == round(cw$total_4digit_codes)))
})

test_that("wfh crosswalk: every score is a mean of a 0/1 flag over its matched count (score x count is an integer)", {
  products <- scored$wfh_probability_2d * scored$matched_soc_count_2d
  expect_true(all(abs(products - round(products)) < 1e-9))
})

test_that("wfh crosswalk: the binary column is the score at a 0.5 cutoff, and no score sits on the cutoff", {
  expect_false(any(scored$wfh_probability_2d == 0.5))
  expect_equal(scored$is_wfh_binary_2d, as.numeric(scored$wfh_probability_2d >= 0.5))
})

test_that("wfh crosswalk: per-group code counts match the ISCO-08 unit-group structure, plus the two BLS minor-group codes", {
  # Unit groups per sub-major group in ISCO-08 (436 in total). Groups 21 and 31 carry one code
  # more in the file because the BLS crosswalk maps SOC 19-2099 (Physical Scientists, All Other)
  # and 53-2022 (Airfield Operations Specialists) to the minor groups 211 and 315, having no
  # unit-group counterpart (ISCO_SOC_Crosswalk_process.pdf, BLS, August 2012). 436 + 2 = 438,
  # the number of distinct ISCO codes in that workbook.
  isco08_unit_groups <- c(
    `1` = 1, `2` = 1, `3` = 1,
    `11` = 5, `12` = 7, `13` = 14, `14` = 5,
    `21` = 24, `22` = 15, `23` = 12, `24` = 11, `25` = 9, `26` = 21,
    `31` = 26, `32` = 17, `33` = 24, `34` = 11, `35` = 6,
    `41` = 4, `42` = 12, `43` = 6, `44` = 7,
    `51` = 17, `52` = 13, `53` = 5, `54` = 5,
    `61` = 9, `62` = 5, `63` = 4,
    `71` = 16, `72` = 13, `73` = 12, `74` = 5, `75` = 20,
    `81` = 26, `82` = 3, `83` = 11,
    `91` = 6, `92` = 6, `93` = 9, `94` = 2, `95` = 2, `96` = 8
  )
  expect_equal(sum(isco08_unit_groups), 436)
  bls_minor_group_extra <- ifelse(cw$isco_2digit %in% c(21, 31), 1, 0)
  expected <- unname(isco08_unit_groups[as.character(cw$isco_2digit)]) + bls_minor_group_extra
  expect_equal(cw$total_4digit_codes, expected)
  expect_equal(sum(cw$total_4digit_codes), 438)
})

test_that("wfh crosswalk: the three external scores the paper quotes for its calibration examples reproduce", {
  score_of <- function(code) cw$wfh_probability_2d[cw$isco_2digit == code]
  expect_equal(score_of(23), 0.9661017, tolerance = 1e-6)   # teaching: 0.966 in the paper
  expect_equal(score_of(41), 1)                              # clerical support: 1.000
  expect_equal(score_of(25), 1)                              # ICT professionals: 1.000
})

test_that("wfh crosswalk: rebuilding from Dingel-Neiman plus the BLS crosswalk reproduces the committed file exactly", {
  # The provenance proof. Skipped, not failed, when the two public source files are not supplied
  # (see the header for where to get them); a green run with both set is the evidence that the
  # committed scores are Dingel & Neiman's and not a reconstruction that resembles them.
  dn_path  <- Sys.getenv("WFH_DN_OCCUPATIONS_CSV", unset = "")
  bls_path <- Sys.getenv("WFH_BLS_ISCO_SOC_XLS",  unset = "")
  skip_if(!nzchar(dn_path) || !file.exists(dn_path),
          "Dingel-Neiman occupations_workathome.csv not supplied (set WFH_DN_OCCUPATIONS_CSV)")
  skip_if(!nzchar(bls_path) || !file.exists(bls_path),
          "BLS ISCO_SOC_Crosswalk.xls not supplied (set WFH_BLS_ISCO_SOC_XLS)")
  skip_if_not_installed("readxl")

  expect_equal(unname(as.character(tools::sha256sum(dn_path))),
               "42ff3ae084478b554526671710b53a16d39f88c3eebb24f56f46372d7243bd40")
  expect_equal(unname(as.character(tools::sha256sum(bls_path))),
               "6d376cdc29e7b52e10e420644f46d7be69a1c48be1b3c650c290f21b4db3dd41")

  # D&N: one row per O*NET-SOC code (e.g. "11-1011.03"); the 6-digit SOC is the 7-character prefix.
  dn <- readr::read_csv(dn_path, show_col_types = FALSE)
  expect_equal(nrow(dn), 968)
  expect_true(all(dn$teleworkable %in% c(0, 1)))
  dn$soc6 <- substr(dn$onetsoccode, 1, 7)

  # BLS sheet: header on row 7, 1,125 (ISCO-08 code, 2010 SOC code) pairs, many-to-many.
  bls <- readxl::read_excel(bls_path, sheet = "ISCO-08 to 2010 SOC", range = "A7:E1132")
  names(bls) <- c("isco08_code", "isco08_title", "part", "soc2010_code", "soc2010_title")
  bls <- dplyr::mutate(bls,
    isco08_code  = trimws(isco08_code),
    soc2010_code = trimws(soc2010_code),
    isco_2digit  = as.numeric(substr(isco08_code, 1, 2))
  )
  expect_equal(nrow(bls), 1125)

  # Every (ISCO code x O*NET row) pair, averaged without weights within the two-digit group; code
  # counts come from the unjoined sheet so groups with no D&N match (armed forces) still appear.
  pairs <- dplyr::inner_join(bls, dn, by = c("soc2010_code" = "soc6"), relationship = "many-to-many")
  by_group <- pairs %>%
    dplyr::group_by(isco_2digit) %>%
    dplyr::summarise(wfh_probability_2d = mean(teleworkable),
                     matched_soc_count_2d = as.numeric(dplyr::n()), .groups = "drop")
  rebuilt <- bls %>%
    dplyr::group_by(isco_2digit) %>%
    dplyr::summarise(total_4digit_codes = as.numeric(dplyr::n_distinct(isco08_code)), .groups = "drop") %>%
    dplyr::left_join(by_group, by = "isco_2digit") %>%
    dplyr::mutate(
      matched_soc_count_2d = dplyr::coalesce(matched_soc_count_2d, 0),
      is_wfh_binary_2d     = as.numeric(wfh_probability_2d >= 0.5)
    ) %>%
    dplyr::select(isco_2digit, wfh_probability_2d, matched_soc_count_2d, total_4digit_codes, is_wfh_binary_2d) %>%
    dplyr::arrange(isco_2digit)

  expect_equal(sum(rebuilt$matched_soc_count_2d), 1439)
  expect_equal(as.data.frame(rebuilt), as.data.frame(cw), tolerance = 1e-12, ignore_attr = TRUE)
})
