library(tidyverse)
library(fixest)

run_diagnostics <- function(cleaned_df) {

  # 1. Employment rate by Mother/Post cell
  message("=== 2x2 DiD employment rates ===")
  did_table <- cleaned_df %>%
    group_by(Mother, Post) %>%
    summarise(emp_rate = mean(Employed, na.rm = TRUE), n = n(), .groups = "drop")
  print(did_table)

  # 2. Employed counts
  message("=== Employed variable counts ===")
  print(cleaned_df %>% count(Employed))

  # 3. Event study: i(ShnatSeker, ref = 2019) supplies the year effects; 2019 is the reference in
  # both i() terms.
  message("=== Pre-trend test (event study) ===")

  reg_pretrend <- feols(
    as.formula(paste(
      "Employed ~ Mother + i(ShnatSeker, ref = 2019) + i(ShnatSeker, Mother, ref = 2019) +",
      paste(DEFAULT_CONTROLS, collapse = " + ")
    )),
    data = cleaned_df, cluster = ~IDPUF
  )
  pretrend_table <- etable(reg_pretrend, digits = 4)
  print(pretrend_table)
  # Draws to the active device; the caller manages the device.
  tryCatch({
    # i.select = 2 picks the Mother x year interaction, not the year main effects.
    iplot(reg_pretrend, i.select = 2, main = "Event-study: Mother x Year (ref = 2019)")
  }, error = function(e) {
    message("iplot failed: ", e$message)
  })

  # 4. NA counts
  message("=== NA counts for regression variables ===")
  na_summary <- cleaned_df %>%
    select(Employed, Mother, Post, MatzavMishpachti, Dat, GilNK,
           MachozMegurim, TeudaGvoha) %>%
    summarise(across(everything(), ~sum(is.na(.))))
  print(na_summary)

  # 5. Missingness pattern for Employed
  message("=== Missingness pattern for Employed ===")
  miss_pattern <- cleaned_df %>%
    mutate(emp_missing = is.na(Employed)) %>%
    group_by(emp_missing) %>%
    summarise(
      pct_mother = mean(Mother, na.rm = TRUE),
      mean_age   = mean(as.numeric(as.character(GilNK)), na.rm = TRUE),
      n          = n(),
      .groups    = "drop"
    )
  print(miss_pattern)

  # 6. Sample rows with Employed missing
  message("=== Sample rows with Employed = NA ===")
  cleaned_df %>%
    filter(is.na(Employed)) %>%
    select(
      ShnatSeker, Oved35Shaot, MisraMelea, SibaLeAvodaChelkit,
      AvadShanaAchrona, KamaChodashimAvadBashana, SibaLoAvadHashana,
      ShaotAvodaBederechKlalNK, MachozYishuvAvoda, Muasak,
      ShaotIkarit, AvodaMeHaBayit, AvadMeHaBayit, KamaShaot, Employed
    ) %>%
    head(20) %>%
    print(width = Inf)

  invisible(list(
    did_table   = did_table,
    na_summary  = na_summary,
    miss_pattern = miss_pattern,
    pretrend_table = pretrend_table,
    pretrend_model = reg_pretrend
  ))
}
