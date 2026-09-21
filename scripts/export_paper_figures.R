# export_paper_figures.R
# Vector-PDF export for the hand-picked figures paper/paper.tex actually includes, added with the
# Descriptive Statistics section (docs/decisions/paper-figure-layer.md).
#
# Why this is a second exporter rather than an option on export_all_results():
#   1. Raster vs vector. export_results.R:19 hard-codes ggsave(width = 8, height = 5, dpi = 150).
#      A 150 dpi PNG is fine for browsing outputs/ but visibly soft in print next to the vector
#      event-study PDF the paper already includes (its \includegraphics of
#      event_study_pretrend_hours.pdf). Paper figures are vector.
#   2. Flat names, deliberately. export_all_results() recurses because it is handed whatever
#      heterogeneous shape the pipeline produced, and derives filenames from the nesting path.
#      These filenames are hard-coded inside paper.tex, so under recursion an innocuous refactor of
#      some function's return list would silently rename a figure file and break the LaTeX build.
#      A flat named list makes that impossible: the name you write here is the filename, full stop.
#   3. Per-figure sizing. A two-panel faceted figure and a four-point dot chart do not want the
#      same aspect ratio, and export_all_results() has no way to express that.
#
# export_all_results() is left byte-for-byte untouched, so every plot ALSO still reaches outputs/
# as an 8x5 PNG. That duplication is intended: the PNG is the browsing copy, the PDF is the one
# the paper compiles against.
library(ggplot2)

export_paper_figures <- function(figures,
                                 output_dir   = file.path("outputs", "figures"),
                                 width        = 5.0,
                                 height       = 3.3,
                                 device       = NULL,
                                 strip_titles = TRUE) {
  # recursive = TRUE matters: outputs/figures is two levels deep and outputs/ may itself be absent
  # in a fresh clone. Mirrors export_results.R:12.
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  # Device choice is a correctness matter, not a style one. Plot labels in this project carry
  # U+2013 en-dashes ("Women aged 25-59" with a real en-dash, the child-age bin labels "0-1",
  # "2-4") and U+00D7 multiplication signs (the forest-plot titles built in main.R). Base pdf()
  # has no UTF-8 support -- U+2013 falls outside every built-in AFM encoding, so it emits a wrong
  # glyph or throws "invalid multibyte string". cairo_pdf renders and embeds them correctly.
  # The fallback stays a warning rather than a stop() so a co-author on a cairo-less build still
  # gets figures, with the caveat logged loudly enough to notice.
  if (is.null(device)) {
    if (isTRUE(unname(capabilities("cairo")))) {
      device <- grDevices::cairo_pdf
    } else {
      message("export_paper_figures: cairo is unavailable, falling back to grDevices::pdf(). ",
              "Non-ASCII characters in plot labels (en-dashes, the multiplication sign) may render ",
              "incorrectly in outputs/figures/. Check the figures before compiling the paper.")
      device <- grDevices::pdf
    }
  }

  exported <- character(0)

  for (nm in names(figures)) {
    entry <- figures[[nm]]

    # Resolve an entry to (plot, width, height). An entry is either a bare ggplot -- take the
    # defaults -- or list(plot =, width =, height =) with either dimension optional.
    if (inherits(entry, "ggplot")) {
      p <- entry; w <- width; h <- height
    } else if (is.list(entry) && inherits(entry[["plot"]], "ggplot")) {
      p <- entry[["plot"]]
      w <- if (is.null(entry[["width"]]))  width  else entry[["width"]]
      h <- if (is.null(entry[["height"]])) height else entry[["height"]]
    } else {
      # NULL and non-ggplot entries are skipped, not fatal. build_hours_subgroup_comparison() and
      # build_mechanism_scatter() both return NULL by design when no model carries the requested
      # term, and this function runs at the very end of a multi-minute pipeline -- erroring here
      # would throw away every other figure over one absent one.
      message("export_paper_figures: skipping '", nm, "' -- not a ggplot (got ",
              class(entry)[1], ").")
      next
    }

    # In a LaTeX float the figure's title, subtitle and caption are the job of \caption and the
    # Notes block beneath it, which are typeset in the document's own font at the document's own
    # measure. Leaving ggplot's versions in place duplicates that text and, because ggplot clips
    # rather than reflowing, a string laid out for the 8in PNG is simply cut off at the ~5in width
    # these are printed at. Stripped here rather than in each builder so the PNG browsing copies
    # written by export_all_results() keep their titles.
    if (strip_titles) {
      p <- p + labs(title = NULL, subtitle = NULL, caption = NULL)
    }

    file <- file.path(output_dir, paste0(nm, ".pdf"))
    ggsave(file, plot = p, width = w, height = h, device = device)
    exported <- c(exported, file)
  }

  invisible(exported)
}
