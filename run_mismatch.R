library(tidyverse)

# Standalone, descriptive-only exhibit: how far Israeli realized WFH (2022-23) diverged from the
# Dingel & Neiman theoretical teleworkability score, by occupation. Not part of main.R's pipeline.
#
# Cache path fixed 2026-09-19: this script previously read "csvs/cleaned_df.rds", a directory that
# does not exist in this repo, so it could not run on any machine. main.R writes its cache beside
# the raw CBS CSVs, so the path is derived from the same folder_path main.R uses. Keep the two in
# sync if main.R's folder_path changes.
folder_path   <- "G:/My Drive/Uni/econ/csv_data"
rds_file_path <- file.path(folder_path, "cleaned_df.rds")

if (!file.exists(rds_file_path)) {
  stop(
    "run_mismatch.R: no cleaned-data cache at ", rds_file_path, ".\n",
    "  Run `Rscript main.R` first (it builds and saves the cache), or edit folder_path above ",
    "to point at your local CBS data folder."
  )
}

message("Loading pre-cleaned data from ", rds_file_path, " ...")
cleaned_df <- readRDS(rds_file_path)

source(file.path("scripts", "israeli_market_mismatch.R"))
mismatch_table <- check_market_mismatch(cleaned_df)

if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
write_csv(mismatch_table, file.path("outputs", "israeli_market_mismatch.csv"))
message("Mismatch table saved to outputs/israeli_market_mismatch.csv")
