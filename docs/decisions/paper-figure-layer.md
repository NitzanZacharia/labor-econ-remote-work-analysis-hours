# Decision Memo: Paper Figure Layer (Descriptive Statistics Section, Vector Export, Shared Theme)

**Status: IMPLEMENTED** (2026-09-20). `paper/paper.tex` gains a standalone §4 "Descriptive
Statistics" carrying figures (six on creation; the hours 2x2 was cut in 2026-09-21 -- see the note at the end of this memo); the pipeline gains a vector-PDF export path, a shared plot theme,
and three new hours-margin descriptive builders.

## Motivation

After the hours pivot (`docs/decisions/hours-ddd-pivot.md`, Checkpoint 11) the plot inventory never
followed the analysis. Of the six PNGs the pipeline produced, four described the now-**secondary**
employment margin, two were regression-coefficient forest plots, and **none was a descriptive
picture of the primary outcome**. The paper carried exactly one figure in 1,177 lines (the hours
event study) and confined its descriptive material to §3.1 around a single table.

The concrete cost: the paper's headline quantity — the raw hours DiD — existed only as a four-row
CSV, and its largest stated limitation (the 2017 pre-trend violation) was visible only through a
regression-adjusted event study, never in raw means. Both claims were asserted numerically and
never shown.

## What was decided

**1. A standalone §4, not a subsection of §3.** Descriptives are now a section in their own right,
between Data and Empirical Strategy; §4–§8 renumbered to §5–§9. Safe because no prose in
`paper.tex` hardcodes a section number — all ~30 cross-references use `\label`/`\ref`. Table 1 and
its discussion **moved** from §3.1 into §4.1 (a pure cut-and-paste; no label changed), so the
section named after the summary statistics actually contains them. §3 keeps source, sample,
variable definitions and the controls/weights statement.

**2. A second exporter rather than an option on `export_all_results()`.** `scripts/export_results.R`
hard-codes `ggsave(width = 8, height = 5, dpi = 150)` and derives filenames from the nesting path of
whatever list it is handed. Both are right for a browsing dump and wrong for paper figures:
150 dpi raster looks soft beside the vector event-study PDF already in the paper, and a
nesting-derived filename means an innocuous refactor of a return list silently renames a file that
`paper.tex` hard-codes. `scripts/export_paper_figures.R` therefore takes a **flat** named list —
the key *is* the filename — and writes vector PDFs at per-figure dimensions.
`export_all_results()` is untouched, so every plot still reaches `outputs/` as a PNG. **Figures are
deliberately written twice**: the PNG is the browsing copy, the PDF is what compiles.

**3. `cairo_pdf`, with a loud fallback.** Plot labels carry U+2013 en-dashes ("Women aged 25–59",
the bin labels "0–1") and U+00D7. Base `pdf()` has no UTF-8 support — U+2013 is outside every
built-in AFM encoding, so it emits a wrong glyph or throws `invalid multibyte string`. The fallback
to `grDevices::pdf` is a message rather than a `stop()` so a co-author on a cairo-less build still
gets figures, with the caveat logged.

**4. Paper figures are stripped of their in-plot title/subtitle/caption at export
(`strip_titles = TRUE`).** In a LaTeX float that text is the job of `\caption` and the `Notes`
minipage, typeset in the document's font at the document's measure. Leaving ggplot's versions in
duplicates the text *and* clips it: ggplot does not reflow, so a string laid out for the 8in PNG is
simply cut off at the ~5in print width. Stripping happens in the exporter, not in each builder, so
the PNG browsing copies keep their titles. Authoring width is 5.0in because `paper.tex` is A4 with
2.5cm margins (`\textwidth ≈ 6.3in`) and the float convention is `width=0.8\textwidth ≈ 5.04in`,
so scale ≈ 1.0 and 12pt plot text prints at the size it was drawn.

**5. A shared theme and palette (`scripts/paper_theme.R`).** The same
`theme_minimal(base_size = 12)` + `theme()` body was pasted five times across three files, and —
the reason this is correctness, not tidiness — `#D85A30`/`#378ADD` meant *Mothers/Non-mothers* in
`comparative_statistics.R` but *Post-2021/Pre-2021* in `employment_by_child_age.R`. With both
figures in one paper, orange would have meant "mothers" on one page and "post-period" on the next.
`mother_status` keeps the original hues; `period` is re-hued to a **sequential grey→green ramp**,
which is also the semantically correct choice for an *ordered* pair. `PAPER_PALETTE` is a top-level
constant, not a function, so the file still honours one-function-per-file — same idiom as
`DEFAULT_CONTROLS` and `MIN_CELL_WARN`.

**6. Dose-response bins come from the occupation-level measure.**
`scripts/hours_dose_response.R` bins on `wfh_exposure_calibrated` — the same regressor the hours
DDD uses — not the demographic-cell index. `hours_ddd_lee_bounds.R` bins on the cell measure for a
specific reason stated in its own header (its selection counterfactual needs an exposure defined
for the *non-employed*); a descriptive hours figure lives entirely inside `Employed == 1`, so that
reason evaporates, and mixing the two would re-create precisely the conflation
`results_digest.md` warns against. The figure is raw cell arithmetic with no regression, which also
keeps the file free of any `controls` argument that could drift from `DEFAULT_CONTROLS`.

## The mechanism scatter: data exported, figure withheld

`scripts/build_mechanism_scatter.R` draws each occupation's own `Mother:Post` estimate against its
WFH exposure. **It is deliberately absent from `paper.tex`.** `paper/notes/results_digest.md` §1.5
records a decision dated 2026-09-15 that the second-stage mechanism regression is
"[PRIMARY — OUT OF SCOPE, DO NOT DRAFT]", on two grounds: it is not one of the three core models,
and its underlying data was not verifiably exported. This work removes the second ground but not
the first, so the decision stands and the figure remains a repo-level diagnostic.

What it does close is the separate open item at §7 item 1. `main.R` previously passed only
`hours_ddd$table`, so the 37-occupation frame behind the slope reached no file and the narrative
doc cited a **stale** `outputs/archive/ddd_calibrated_mechanism_data.csv` whose `beta_j` values are
in employment-probability units, not hours. `outputs/hours_mechanism_data.csv` now carries the real
frame, and refitting from it reproduces **slope 2.6386 (SE 0.8993), n = 37** against the digest's
recorded 2.639 (SE 0.899, n 37).

One implementation note worth preserving: the drawn line comes from the passed `fit`, never from
`geom_smooth(method = "lm")`. The second stage is precision-weighted (`weights = 1/se_j^2`) because
`beta_j`'s precision varies enormously across occupations; an unweighted smooth would draw a
visibly different line from the slope in the text, with nothing to flag the disagreement. A test
pins the drawn slope to `coef(fit)[2]` and asserts it differs from the unweighted fit. For the same
reason point size encodes precision `1/se_j` and not `n` — `main.R` builds `hours_exposure_index`
with two columns only, and the `n` available elsewhere is the 2022–23 calibration-anchor count,
which is the wrong number for this purpose.

## Plot triage

| Plot | Outcome |
|---|---|
| mobility | Kept, → §4.4. Fixed: the line interpolated straight across the excluded 2020 year. |
| employment by child age, pre/post | Kept, → §4.5. Fixed: fragile `c(min*0.92, max*1.06)` limits replaced with `expansion()`; binomial CIs added. |
| employment by child age, raw vs adjusted | Kept, → §4.5. Fixed: `geom_col` → dumbbell. Bars must be anchored at zero, which squeezed the whole ~5pp raw-vs-adjusted divergence into the top fifth of the panel; a point-and-segment chart carries no such obligation. Legend order pinned (was alphabetical, putting "Adjusted" first). |
| employment by child age, raw bars | **Out of the paper**, kept in the repo. Subsumed by the pre/post panel and Table 1. |
| hours DiD / DDD subgroup forest plots | Kept in the repo; these are *Results* figures, not descriptives, and `tab:subgroup` already reports the numbers. Fixed anyway: the Arab-women DDD CI (11.19) ran to the panel edge and read as truncated; the placebo row is now styled apart as a different population; a caption names the estimand, since the DiD and DDD panels were visually interchangeable on different scales. |

## Interpretive hazard recorded

`paper/archive/old_paper.tex` reported child-age × `Post` *regression* coefficients (−0.0146,
−0.0155, joint F(5,79069) = 2.02) — significant post-2021 **declines** for the 0–1 and 2–4 bins
relative to childless women, with controls. The restored figures are **raw rates with no control
group and no reference category**, and they show post-2021 rates *higher* at nearly every bin.
These are not contradictory, but narrated carelessly they read as such, and nothing in the current
pipeline estimates the old interaction (`employment_by_child_age.R` fits
`Employed ~ ChildAgeBin + controls`, no `Post` term). §4.5 therefore states explicitly that the
figures describe levels and must not be read against the employment DiD of `tab:emp-did`.

## Verification

- `Rscript run_tests.R` — 732 passing, 0 failures (was 721 before this work; 5 new test files plus
  amendments to 3 existing ones).
- `Rscript main.R` — exit 0; writes six `outputs/figures/*.pdf` and
  `outputs/hours_mechanism_data.csv` (37 rows).
- `pdflatex`/`bibtex`/`pdflatex`×2 from inside `paper/` — 34 pages, no "file not found", no
  undefined citations or references, 0 BibTeX warnings, and the same 4 overfull hboxes the paper
  had before this change (all in §6, none in the new section).

Real-data values now shown in the paper: raw hours DiD **+0.878 (SE 0.099)** against the estimated
0.8261; per-quartile raw DiDs **0.39 / 0.75 / 0.47 / 2.24**; raw mother-minus-non-mother hours gap
**−3.30 (2017), −1.57 (2018), −1.68 (2019), −1.46 (2021), −1.56 (2022), −0.83 (2023)**.

---

## Follow-up: the hours 2×2 figure was cut (2026-09-21)

`fig:hours-2x2` has been removed from `paper.tex` and from `main.R`'s `paper_figures` list; the
paper now carries five figures from this layer plus the event study. `outputs/figures/hours_2x2.pdf`
is deleted. The plot itself is unchanged and still reaches `outputs/` as a PNG via
`export_all_results()` — it is a fine browsing artifact, just not a paper figure.

**Two reasons, the second being the decisive one.**

**It was informationally redundant.** Both it and `fig:hours-by-year` plot the same variable, the
same two groups, over the same span; the by-year figure is the same data at six time points instead
of two. The DiD itself is recoverable from the by-year figure's lower panel: pre-period mean gap
−1.509, post-period −1.232, difference **+0.277** against the 2×2's n-weighted **+0.266**. The only
things unique to the 2×2 were the n-weighted pooled means as plotted quantities (the by-year panel
shows no cell sizes) and the canonical two-line DiD visual.

**It contradicted the paper's own conclusion on significance.** Its caption reported the raw DiD as
$0.266$ (SE $0.098$) — *t* = 2.72, CI $[0.074, 0.458]$, excluding zero. The paper's DiD is
$0.2280$ (SE $0.1809$) — *t* = 1.26, CI $[-0.127, 0.583]$, including zero. Same coefficient to
within four hundredths of an hour, opposite inference: the raw standard error treats 251,857
observations as independent, while the regression clusters by individual and returns very nearly
double. So the descriptive section was showing, as its first figure, a version of the secondary
result that reads as significant four pages before §6.3 concludes it is a null.

This was not a pre-existing flaw. Before the hours harmonization (Checkpoint 13) the DiD was
$0.8261$\sym{***} and both the raw and clustered versions agreed it was significant; the figure and
the paper said the same thing. The mismatch appeared only once the estimate became a null, which is
a good argument for re-reading descriptive figures after any change to the estimate they describe.

§4.2 survives as prose and now states the precision difference explicitly, rather than — as it did
briefly — emphasising that "the controls move it by less than four hundredths of an hour", which is
true of the coefficient and silent about the standard error that determines the conclusion.
