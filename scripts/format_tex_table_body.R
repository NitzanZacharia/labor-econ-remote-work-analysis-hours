# format_tex_table_body.R
# Turns a character matrix of already-formatted cells into a booktabs `tabular` block. Part of the
# generated-table layer (docs/decisions/grade-report-response.md, item C1).
#
# Deliberately dumb: it knows nothing about regressions, only about rows, columns and rules. The
# content decisions (which coefficient goes where, how numbers are rounded) live in
# build_paper_tables.R; the LaTeX float, caption, label and notes stay hand-written in
# paper/paper.tex, which \input{}s only the tabular block this emits. That split is what lets a
# pipeline re-run refresh every number without touching a sentence of prose.
#
#   cells        character matrix or data frame, one table row per row; NA prints as empty. A
#                cell beginning with "\multicolumn{k}" spans k columns: the k-1 cells after it
#                must be NA and are consumed (panel headings, spanning CI cells).
#   colspec      the tabular column specification, e.g. "lccc".
#   header       a list of header rows. Each element is either a character vector (joined with
#                " & ", terminated with " \\") or a single string beginning with "\" (emitted as a
#                raw line, e.g. a \cmidrule). NULL for no header block.
#   midrule_after, addlinespace_after
#                body row indices after which a \midrule or \addlinespace is inserted.
format_tex_table_body <- function(cells, colspec, header = NULL,
                                  midrule_after = integer(0), addlinespace_after = integer(0)) {
  cells <- as.matrix(cells)
  if (is.null(dim(cells)) || length(dim(cells)) != 2) {
    stop("format_tex_table_body: `cells` must be a matrix or data frame.")
  }
  n_col <- ncol(cells)
  n_spec <- nchar(gsub("[^lcrp]", "", gsub("p\\{[^}]*\\}", "p", colspec)))
  if (n_spec != n_col) {
    stop(sprintf("format_tex_table_body: colspec '%s' declares %d columns but `cells` has %d.",
                 colspec, n_spec, n_col))
  }

  # A cell beginning with \multicolumn{k} consumes the k-1 cells after it (which the caller leaves
  # NA), so spanning cells can sit anywhere in a row without the caller hand-joining the line.
  join_row <- function(x) {
    x <- as.character(x)
    out <- character(0)
    i <- 1
    while (i <= length(x)) {
      cell <- if (is.na(x[i])) "" else x[i]
      out <- c(out, cell)
      k <- 1
      if (grepl("^\\\\multicolumn\\{[0-9]+\\}", cell)) {
        k <- as.integer(sub("^\\\\multicolumn\\{([0-9]+)\\}.*$", "\\1", cell))
        consumed <- x[seq_len(k - 1) + i][!is.na(x[seq_len(k - 1) + i])]
        if (k > 1 && length(consumed) > 0 && any(nzchar(consumed))) {
          stop("format_tex_table_body: a \\multicolumn{", k, "} cell is followed by non-empty cells ",
               "it would overwrite: ", paste(consumed, collapse = ", "))
        }
      }
      i <- i + k
    }
    paste0(paste(out, collapse = " & "), " \\\\")
  }

  lines <- c(sprintf("\\begin{tabular}{%s}", colspec), "\\toprule")

  if (!is.null(header)) {
    if (is.character(header)) header <- list(header)
    for (h in header) {
      if (length(h) == 1 && grepl("^\\\\", h) && n_col > 1) {
        lines <- c(lines, h)
      } else {
        if (length(h) != n_col) {
          stop("format_tex_table_body: a header row has ", length(h), " cells, expected ", n_col, ".")
        }
        lines <- c(lines, join_row(h))
      }
    }
    lines <- c(lines, "\\midrule")
  }

  for (i in seq_len(nrow(cells))) {
    lines <- c(lines, join_row(cells[i, ]))
    if (i %in% midrule_after)      lines <- c(lines, "\\midrule")
    if (i %in% addlinespace_after) lines <- c(lines, "\\addlinespace")
  }

  c(lines, "\\bottomrule", "\\end{tabular}")
}
