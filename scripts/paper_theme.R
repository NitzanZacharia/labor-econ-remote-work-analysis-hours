# paper_theme.R
# Shared ggplot theme + colour palette for every figure this project draws, added with the
# Descriptive Statistics section (docs/decisions/paper-figure-layer.md). Before it existed, the
# same theme_minimal(base_size = 12) + theme(title/subtitle/minor-grid) block was pasted five times
# across comparative_statistics.R, employment_by_child_age.R (x3) and hours_subgroup_comparison.R,
# and -- the reason this file exists rather than being a tidiness exercise -- the same two hexes
# carried two different meanings: #D85A30/#378ADD meant Mothers/Non-mothers in one script and
# Post-2021/Pre-2021 in another. With both figures in one paper an orange line would have meant
# "mothers" on one page and "post-period" on the next.
#
# PAPER_PALETTE is a constant, not a function, so this file still honours the one-function-per-file
# rule (CLAUDE.md) -- same idiom as DEFAULT_CONTROLS in data_processing.R and MIN_CELL_WARN in
# hours_ddd_lee_bounds.R. Deliberately no paper_palette() accessor: that would be a second function
# in this file, for no benefit over `PAPER_PALETTE$role`.
library(ggplot2)

# Names on the categorical scales are NOT cosmetic -- they must match the literal factor labels the
# plot scripts already emit ("Mothers"/"Non-mothers" from comparative_statistics.R's MotherLabel,
# "Pre-2021"/"Post-2021" from employment_by_child_age.R's Period, "Raw"/"Adjusted (controls)" from
# its pivot_longer recode). A mismatch renders as silent grey NA swatches rather than an error,
# which is why test-paper_theme.R pins these names explicitly.
PAPER_PALETTE <- list(
  # Treatment/control contrast. Two distinct hues, because mother status is unordered.
  mother_status = c("Mothers" = "#D85A30", "Non-mothers" = "#378ADD"),

  # Pre/Post is an ORDERED pair, so it gets a sequential grey -> green ramp rather than the
  # categorical hue pair it used to share with mother_status. This is what resolves the collision
  # described in the header; mother_status keeps the original hues because it appears in more
  # figures and re-hueing it would churn more artifacts.
  period = c("Pre-2021" = "#B9B7B0", "Post-2021" = "#1D6F55"),

  # Raw vs covariate-adjusted rates (employment_by_child_age.R's dumbbell).
  adjustment = c("Raw" = "#1D9E75", "Adjusted (controls)" = "#7F77DD"),

  gap        = "#6B4E9E",  # mother-minus-non-mother difference series
  estimate   = "#1D9E75",  # point estimates / fitted values
  placebo    = "#8C8C88",  # male placebo rows -- a different population, so a muted hue
  reference  = "grey50",   # zero lines, reference rules
  annotation = "#5F5E5A"   # on-plot value / n labels
)

theme_paper <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title       = element_text(size = 13, face = "bold"),
      plot.subtitle    = element_text(size = 10, colour = "grey40"),
      plot.caption     = element_text(size = 8.5, colour = "grey40"),
      axis.title       = element_text(size = 10),
      legend.position  = "top",
      panel.grid.minor = element_blank()
    )
}
