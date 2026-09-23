# Decision Memo: Structural Cut of the Manuscript (2026-09-23)

**Status: IMPLEMENTED (2026-09-23).** Follows the same-day concision pass recorded in
[`grade-report-2-response.md`](grade-report-2-response.md). No R code, no pipeline run, no
generated table changed; `paper/paper.tex`, the new `paper/appendix.tex`, `paper/paper.pdf` and
four documentation files are the only edits.

## Motivation

After the concision pass the PDF was 38 pages: title 1, contents 1, main text (Abstract through
Limitations) 27, Conclusion skeleton and references 3, appendix 6. The 2026-09-23 grading report
counted total pages as the length problem, so the target was the total, with the main text
carrying most of the cut. Word-level editing had run out; the remaining slack was structural:
a sequential literature review, CBS coding mechanics in the Data section, textbook DiD/DDD
exposition in the Strategy section, and seven main-text floats of which several were secondary
evidence or duplicated a table.

## What changed

**Result.** 38 pages to **33**; main text 27 pages to **20** (printed pages 2–21); appendix 6
pages to 9; Conclusion and references unchanged in content, references single-spaced. Main-text
prose (Introduction through Limitations) 8,478 words at the committed baseline, 7,804 after the
concision pass, **6,681** now; appendix prose 127 to 1,148 (the moved passages). Abstract 190.

**New `paper/appendix.tex`**, `\input{}` after the `\appendix` counter lines, with four sections:

- *A. Data and sample details* — hours bin coding and the 2017 zero-recording correction, the
  reference-week absence shares by exposure quartile (formerly a Limitations footnote), the
  rotating-panel counts and the rejected individual-fixed-effects design (formerly §5.4), the
  year-by-year raw gaps, the commuting descriptives.
- *B. Exposure construction* — the external score and its teaching example, the calibration
  rule's thresholds and the three example swaps, the realized index's anchoring, the fit
  statistics and the scale-mixing explanation, Table A1 (forty scores).
- *C. The selection correction* — the full Lee-bounds construction (formerly §5.5), the DiD
  selection rates and the DDD trim shares, Table A2 (formerly Table 3).
- *D. Additional results* — Table A3 extensive margin (formerly Table 7), Table A4 balance by
  quartile, the permutation histogram (formerly Figure 5), the leave-one-out figure.

**Floats.** Figure 1 (hours by year) and the first-stage figure share one two-panel appendix
float; the DiD and DDD event studies share one two-panel main-text float (`fig:pretrend`, with
`fig:pretrend-ddd` labelling the same float so existing cross-references resolve). The
child-age forest plot (`fig:childage`, `outputs/figures/hours_ddd_by_child_age.pdf`) is no
longer in the paper: it plotted exactly the DDD column of Table 4 and its confidence intervals.
It is still produced by `main.R`. Figure 2 (dose response) is at 0.6 text-width.

**Text.** The Literature Review is three thematic paragraphs (the penalty and the flexibility
mechanism; what remote work does to hours and to gender gaps; measurement and identification)
with every citation kept. The Data section states definitions only. The Strategy section keeps
the three equations, the reading of each triple-differences coefficient, the Olden–Møen and
Callaway–Goodman-Bacon–Sant'Anna conditions, the clustering and bootstrap choices and the
permutation and sorting designs, and points to the appendix for mechanics. The Hypothesis
subsection is folded into the triple-differences subsection; the Falsification subsection is
folded into the Robustness *Inference and falsification* paragraph; Limitations has four
paragraphs instead of six. Section 6.2 (the headline result) is unchanged apart from its figure
pointer.

**Layout.** Float-placement parameters (`topfraction` 0.9, `bottomfraction` 0.8, `textfraction`
0.07, `floatpagefraction` 0.7, up to three top floats) so that two half-page floats can share a
page; figure notes single-spaced like the table notes already were; the two appendix result
tables at `\scriptsize` like Tables 2 and 4; the reference list single-spaced. Font size, line
spacing of the body text and margins are unchanged.

## Preservation checks (against `git show HEAD:paper/paper.tex`, over `paper.tex` ∪ `appendix.tex`)

- Citation keys: identical set. Equations: identical count. `\input{tables/…}`: identical
  multiset. Tables: identical count.
- Labels: removed `sec:desc-pretrend`, `sec:desc-exposure`, `sec:res-falsification` (merged
  subsections, no remaining references) and `fig:childage`; added `sec:app-data`, `sec:app-lee`,
  `sec:app-results`. No dangling `\ref`.
- Figures: two fewer `figure` environments (the two pairings) plus the cut forest plot; every
  other `\includegraphics` path survives.
- Numbers: the only numeric tokens new to the source are LaTeX widths (0.48, 0.62, 0.95). The
  only numbers that left the document are the rounded bootstrap p-values 0.84 and 0.88, which
  the event-study note still carries as 0.838 and 0.884. The footnote in Limitations became a
  paragraph in Appendix A with the same figures.
- The Conclusion block and the preamble's first 130 lines (title page, contents) are
  byte-identical to the committed file apart from the float-parameter lines added after
  `\onehalfspacing`.
- Compile: `pdflatex; bibtex; pdflatex; pdflatex` from `paper/` with no BibTeX warnings, no
  undefined references or citations, no overfull boxes; the six underfull notices from the
  generated exposure table pre-date this work.

## What a reader loses

Nothing quantitative. The main text no longer walks through the CBS hours bins, the 2017
recording fix, the panel counts, the calibration thresholds, the fit statistics, the trimming
algebra or the permutation histogram; each is one `Appendix~\ref{}` away and stated once there.
The child-age forest plot is gone; its table remains.
