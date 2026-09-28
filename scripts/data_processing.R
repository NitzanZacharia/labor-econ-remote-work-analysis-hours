library(tidyverse)

# DEFAULT_CONTROLS is the single source of truth for the regression controls.
DEFAULT_CONTROLS <- c("MatzavMishpachti", "Dat", "GilNK", "MachozMegurim", "TeudaGvoha")

load_and_clean_data <- function(folder_path, sex_filter = c("women", "men")) {

  sex_filter <- match.arg(sex_filter)
  min_code <- if (sex_filter == "women") 2 else 1

  # 1. Load raw data
  if (!dir.exists(folder_path)) stop("Target data folder not found.")

  data_raw <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE) %>%
    set_names() %>%
    map_df(~read_csv(.x, guess_max = 50000, show_col_types = FALSE), .id = "file_source")

  # 2. Filter: sex, ages 25-59 (GilNK 3-7), survey years excluding 2020
  filtered_df <- data_raw %>%
    filter(
      Min == min_code,
      between(GilNK, 3, 7),
      ShnatSeker %in% c(2017, 2018, 2019, 2021, 2022, 2023)
    )

  # 3. Derived variables
  # ShaotAvodaBederechKlalNK bin -> median usual weekly hours (codebook: bin bounds)
  hour_bin_median <- c(`0` = 0, `1` = 4, `2` = 11, `3` = 18, `4` = 25.5, `5` = 32,
                        `6` = 37, `7` = 42, `8` = 47, `9` = 54.5, `10` = 78.5)

  # Values in the 90s of the raw hour items are CBS codes, not hours; as.numeric() first because
  # an empty column reads as logical.
  hours_or_na <- function(x) {
    v <- suppressWarnings(as.numeric(x))
    if_else(!is.na(v) & v >= 1 & v <= 89, v, NA_real_)
  }

  mutated_df <- filtered_df %>%
    mutate(
      Mother                 = as.integer(MisparYeladimAd17MB > 0),
      Post                   = as.integer(ShnatSeker >= 2021),
      # Employed: Muasak == 1; unemployed and not-in-labor-force are both 0.
      Employed = if_else(!is.na(Muasak) & Muasak == 1, 1L, 0L),
      # WFH block, asked from 2021 only. CBS codes 1 = yes, 2 = no, 9 = unknown; 9 maps to NA, not 0.
      WFH = case_when(
        ShnatSeker < 2021   ~ NA_real_,
        AvodaMeHaBayit == 1 ~ 1,
        AvodaMeHaBayit == 2 ~ 0,
        .default = NA_real_          # code 9 ("unknown") and genuine missingness
      ),
      # Reference-week WFH is asked only of those who worked that week, so the absent are NA.
      WFH_RefWeek = case_when(
        ShnatSeker < 2021  ~ NA_real_,
        AvadMeHaBayit == 1 ~ 1,
        AvadMeHaBayit == 2 ~ 0,
        .default = NA_real_
      ),
      # Hours worked from home in the reference week; codes 90-97 are excluded.
      .hrs_home  = hours_or_na(KamaShaot),
      .hrs_total = hours_or_na(ShaotAvodaLeMaase),
      WFH_Hours = case_when(
        WFH_RefWeek == 0 ~ 0,
        WFH_RefWeek == 1 ~ .hrs_home,
        .default = NA_real_
      ),
      WFH_Share = case_when(
        WFH_RefWeek == 0                  ~ 0,
        WFH_RefWeek == 1 & .hrs_total > 0 ~ pmin(.hrs_home / .hrs_total, 1),
        .default = NA_real_
      ),
      WFH_Arrangement = factor(
        case_when(
          is.na(WFH_Share) ~ NA_character_,
          WFH_Share == 0   ~ "On-site",
          WFH_Share < 0.9  ~ "Hybrid",
          .default         = "Fully remote"
        ),
        levels = c("On-site", "Hybrid", "Fully remote")
      ),

      # CBS disclosure-masks the occupation code ("XX", "7X"); the mask is recorded and the 1-digit
      # major group recovered where possible.
      .isco_chr = as.character(MishlachYad_ISCO_08_2),
      MishlachYad_ISCO_08_2 = suppressWarnings(as.numeric(.isco_chr)),
      ISCO_masked = !is.na(.isco_chr) & is.na(MishlachYad_ISCO_08_2),
      ISCO1 = suppressWarnings(as.numeric(str_sub(.isco_chr, 1, 1))),

      # Bin median for the regular-hours codes 0-10; WorkHoursCont is completed below, by period.
      .hour_bin_val = unname(hour_bin_median[as.character(ShaotAvodaBederechKlalNK)]),

      # Education, grouped into broader categories (raw TeudaGvoha codes; 99 -> NA)
      TeudaGvoha = factor(
        case_when(
          TeudaGvoha %in% c(0, 1)    ~ "Below High School",
          TeudaGvoha == 2            ~ "High School (no matriculation)",
          TeudaGvoha == 3            ~ "Matriculation (Bagrut)",
          TeudaGvoha == 4            ~ "Post-secondary, non-academic",
          TeudaGvoha %in% c(5, 6, 7) ~ "Academic Degree (BA/MA/PhD)",
          TeudaGvoha %in% c(8, 9)    ~ "Other/No Certificate",
          .default = NA_character_
        ),
        levels = c("Below High School", "High School (no matriculation)",
                   "Matriculation (Bagrut)", "Post-secondary, non-academic",
                   "Academic Degree (BA/MA/PhD)", "Other/No Certificate")
      ),

      # Country of birth by continent; Israel kept separate; code 7 spans continents ("Other"),
      # code 16 is ambiguous (NA).
      BirthContinent = factor(case_when(
        SemelEretzLeda == 10                     ~ "Israel",
        SemelEretzLeda %in% c(1, 6, 11, 14)      ~ "Asia",
        SemelEretzLeda %in% c(2, 8, 12, 15)      ~ "Africa",
        SemelEretzLeda %in% c(3, 4, 5, 13)       ~ "Europe",
        SemelEretzLeda == 9                      ~ "North America",
        SemelEretzLeda == 7                      ~ "Other",
        .default = NA_character_
      )),

      # Commutes outside the locality of residence (DargatNayadut 2-7).
      WorksOutsideLocality = case_when(
        DargatNayadut == 1          ~ 0L,
        DargatNayadut %in% 2:7      ~ 1L,
        .default = NA_integer_
      )
    ) %>%
    # WorkHoursCont: bin medians for codes 0-10; the irregular-hours codes 11/12 are imputed from
    # the median of regular workers in the matching range, separately by period so a
    # period-specific shift is not blended away. Defined only for the employed who worked in the
    # reference week (AvadBeshavua == 1): the 2017 file recorded the employed-but-absent as zero
    # usual hours while later years gave them a real value, and absence is mother-skewed, so the
    # hours population is harmonized across years at the cost of about 10% of each year's
    # employed sample.
    group_by(Post) %>%
    mutate(
      WorkHoursCont = case_when(
        Employed != 1                      ~ NA_real_,
        AvadBeshavua != 1                  ~ NA_real_,
        ShaotAvodaBederechKlalNK == 0      ~ NA_real_,
        ShaotAvodaBederechKlalNK %in% 0:10 ~ .hour_bin_val,
        ShaotAvodaBederechKlalNK == 11      ~ median(.hour_bin_val[Employed == 1 & ShaotAvodaBederechKlalNK %in% 1:5], na.rm = TRUE),
        ShaotAvodaBederechKlalNK == 12      ~ median(.hour_bin_val[Employed == 1 & ShaotAvodaBederechKlalNK %in% 6:10], na.rm = TRUE),
        .default = NA_real_
      ),
      # Same coding without the reference-week gate: absentees keep their reported usual hours.
      # 2017 absentees carry code 0 and stay NA, so this column is comparable from 2018 on only
      # (robustness row, docs/admin/review.md item 11).
      WorkHoursUsualAll = case_when(
        Employed != 1                      ~ NA_real_,
        ShaotAvodaBederechKlalNK == 0      ~ NA_real_,
        ShaotAvodaBederechKlalNK %in% 0:10 ~ .hour_bin_val,
        ShaotAvodaBederechKlalNK == 11      ~ median(.hour_bin_val[Employed == 1 & ShaotAvodaBederechKlalNK %in% 1:5], na.rm = TRUE),
        ShaotAvodaBederechKlalNK == 12      ~ median(.hour_bin_val[Employed == 1 & ShaotAvodaBederechKlalNK %in% 6:10], na.rm = TRUE),
        .default = NA_real_
      )
    ) %>%
    ungroup() %>%
    select(-.hour_bin_val, -.hrs_home, -.hrs_total, -.isco_chr) %>%
    mutate(
      across(
        c(MatzavMishpachti, Dat, GilNK, MachozMegurim, MisparHorimYechidim),
        as.factor
      )
    )

  # 4. Drop unused raw columns
  cols_to_drop <- c(
    "ShnotLimud", "SugBeitSeferAcharon", "AvadBeshavua2", "ChipesChodesh",
    "KamaPachot", "SibaAvadPachot", "MisparShaotNosafot", "ShaotAvodaLeMaase",
    "ChozerLamasik", "KamaShavuotChipes", "ChipusAvodaMelea",
    "ZminutLeAvodaMechapsim", "SibatEyZminut", "AvadEyPaamBaaretz",
    "SibaHifsikLaavod", "MatayHifsikLaavod", "ChipesBeShanaAchrona",
    "SibaLoChipesAvoda", "ZminutLeAvodaMityaashim", "MimiMekabelSachar",
    "YeladimAd14PratNK", "GilYeledTzairPratNK", "ShaotAvodaLemaaseNK",
    "MeshechChipusAvodaNK", "ShnotLimudNK", "ShayachAvoda",
    "SibaAvadPachot10CHodashim", "LimudimVeAvoda", "MityaashimMechipusAvoda",
    "RamatHaskala_ISCED97", "RamatHaskala_ISCED2011", "ShaotOzeretMBMeubad",
    "Pratmugbalkashe", "ShnotLimudLeloYeshivotG", "KamaPachotmechushav",
    "SibaAvadPachotmechushav", "AvadEyPaam", "MimiMekabelSacharMechushav",
    "AavadIkarit", "AvodaAcheret", "BeeluShaot", "BeizoDerech", "Chaverim",
    "ChipesAvodaAcheret", "ChipesShavuot", "ChipesShavuotMityaesh",
    "ChipusAvodaDmeyAvtala", "ChipusAvodaMismachim", "ChipusAvodaShnatHafsaka",
    "ChipusAvodaYachalLehatchil30", "ChipusMeleaMityaesh", "ChipusShaot",
    "ChodeshHafsaka", "ChodeshHafsakaMityaesh", "ChodeshHatchala",
    "DmeyAvtalaMityaesh", "Esek", "HaskalaMatima", "HavtachatHachnasaMityaesh",
    "HifsikMigbala", "HifsikMigbalaMityaesh", "KamaAvodot", "KoachAdam",
    "LehachlifAvoda", "Lehatchil60", "LoChipesMigbala", "ShnatHafsakaMityaesh",
    "SibaHifsikLaavodMityaesh", "SofShavua", "SugMachala", "SugTeuna",
    "YachalLehatchil30Mityaesh", "YamimBashavua", "ZmanLaavoda",
    "KamaPachot_Unified",
    # Explicit names rather than positional ranges: the 2017 file lacks the boundary columns.
    "EizeChozemechushav", "HaimMemunemechushav", "HaimMenahelmechushav",
    "KamaKfufimmechushav", "KamaSchirimmechushav", "LoAvadMigbalamechushav",
    "MaasikSchirimmechushav", "MeshechChipusAvodaMityaeshNK", "MeshechChipusAvodaMuasakNK",
    "MigzarKalkalimechushav", "SacharMechushavmechushav", "SemelMikzoamechushav",
    "SemelMikzoank", "ShaotAvodaBederechKlalikaritNK", "ShaotAvodaLemaaseikaritNK",
    "SugChozemechushav", "SugMachalaPachotmechushav", "SugTeunaPachotmechushav",
    "MigzarTziburiAnafi", "TatTaasuka_Zman", "ChodeshKodem", "ChodeshKodemShaa",
    "MimaHaMigbala", "Mismachim", "Modaot", "OfenAcher", "Oved30", "PniyaLmaasik"
  )

  # Regex pattern matching any column that starts with these prefixes
  prefix_pattern <- paste0(
    "(",
    paste(c(
      "Kolel", "MisparMugbalim", "Yeshiva", "ChodeshSeker", "ShnatMidgam",
      "ChodeshMidgam", "MisparNefashotMB", "MisparNefashotNosafot",
      "YeladimAd14MBNK", "MisparNefashotMi15MB", "MisparBiltiMuasakim",
      "MisparMuasakimMale", "TtchunatAvoda", "Limudim",
      "MisparChadarimMB", "TzfifutDiyur", "ShayachimKoachAvoda", "YabeshetLeida",
      "VetekNisuinNK", "MaduaLehachlif", "SherutTaasuka", "IsukLifneyShechipes",
      "Needar", "Aliya", "Imut"
    ), collapse = "|"),
    ")"
  )

  df <- mutated_df %>%
    select(
      -any_of(cols_to_drop),
      -matches(prefix_pattern),
      -(Yeladim0_1Prat:Yeladim15_17Prat),
      -(MisparHachlafa:YachasKirvaNK),
      -(MisparNefashotGilAvodaV2007:MisparPrat),
      -(ChipusAvodaSherutTaasuka:ChipusAvodaOfenAcher),
      -(RamatDat:BituachLeumi)
    )

  return(df)
}
