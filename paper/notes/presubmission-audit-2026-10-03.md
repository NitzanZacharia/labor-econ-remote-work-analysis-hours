# Pre-submission audit register, 2026-10-03

Branch `doc-audit` at `8f859dc`. Plan: `~/.claude/plans/pasted-content-id-524e-analyze-the-snappy-squirrel.md`.
Report-first: nothing in `paper/` was edited during a phase. Fixes are applied only after approval.
Status codes: `open` (awaiting decision), `fixed <hash>`, `wontfix`, `handed to Phase N`.

## Phase 1: Data and empirical verification (run 2026-10-03)

**Sources.** `paper/tables/*.tex` and `outputs/*.csv` both come from the run committed in `4f2e9fa`
(2026-09-29). Mapping used: `build_paper_tables()` input names (main.R:644–689) → `results_to_export`
names (main.R:694–812), which are the CSV filename prefixes. The numeral register
(`scratchpad/numerals.csv`, 453 tokens: 298 in `paper.tex`, 155 in `appendix.tex`, years and
counters excluded) was walked in document order; every token was traced.

### 1a. Tables versus outputs

| Table | Compared against | Result |
|---|---|---|
| `tab_hours` (Table 2) | `intensive_margin_table`, `ddd_hours_table`, `ddd_hours_saturated`, `ddd_hours_binned_*`, `mde_hours` | every cell, N, R², MDE, SD and per-SD row match at printed precision; stars match CSV p |
| `tab_robust` (Table 3) | the 26 `ddd_hours_*` / `age_balance_*` / `exposure_sorting_*` CSVs, `hours_wild_bootstrap`, `hours_permutation_table`, `hours_ddd_leave_one_out_summary` | every coefficient, SE, p, p(boot), N and cluster count match |
| `tab_subgroup` (Table 5) | `intensive_margin_{jewish,arab}_table`, `ddd_hours_{jewish,arab}_table`, `hours_gender_placebo_*`, `hours_subgroup_ztests` | match; the four normal-critical-value CIs recompute |
| `tab_childage` (Table 4) | `hours_ddd_by_child_age_table`, `hours_wild_bootstrap` | match |
| `tab_descriptives` (Table 1) | `descriptive_table_{continuous,categorical}` | all 35 rows match |
| `tab_extensive` (Table A2) | `basic_reg_table`, `ddd_employment`, `null_vs_power_audit_mde_additive` | match, incl. constant 0.4926 and the 1.85 % row |
| `tab_lee_selection`, `tab_lee_bounds` (quoted in Appendix C) | `hours_lee_bounds_{table,quartiles,n_trimmed,imbens_manski}` | match; trim count 1,396 and base 72,820 recompute |
| `tab_balance_quartile` (Table A3) | `balance_by_exposure_quartile` | all 28 cells, SEs, stars (normal reference) and counts match |
| `tab_calibration_sweep` (Table A4) | `calibration_threshold_sweep` | all 13 rows match; `<0.0001` rows have p ≤ 4.4e-5 |
| `tab_exposure_scores` (Table A1) | `wfh_exposure_{external,realized,calibrated}` | spot-checked (ISCO 11, 12, 23, 41); generated, not re-typed |

No table discrepancy. No pipeline or table-builder issue found.

### 1b. Prose versus sources: confirmed

Every numeral in the Abstract, Introduction, Sections 3–8, the Conclusion, Appendices A–D and all table
and figure notes matches its table cell or CSV field, and every derived quantity recomputes:

- 1.71 = 3.224 × (0.5917 − 0.0605); 1.4 = −0.54 + 3.22 × 0.59; −2.2 = −1.45 − 1.30 × 0.59; three fifths = 1.36 / 2.2; −0.35 at exposure 0.06.
- DiD MDE 0.51 = 2.80 × 0.181; DiD 95 % CI [−0.13, 0.58]; raw DiD 0.27 within four hundredths of 0.228; raw pre-period widening 0.3 (−1.37 → −1.67).
- Saturated column "falls by a tenth" (2.876 / 3.224 = 0.89) and p ≈ 0.004; external index "a fifth" (0.21); swap-control "nearly three quarters" (0.73); teaching-only "three fifths" (0.60); reweighting "about 19 %" (19.4 %); top-bin recode "a fifth" (19.7 %); bin-crossing "about 2 pp per SD" (1.9 and 2.1); 2.2–4.3 range and bootstrap 0.02–0.13 range over the calibrated-index rows; child-age "half the size" (1.862 / 3.656 = 0.51); Arab "nominally twice" (1.93) on a sample "nine times smaller" (8.6).
- Extensive margin: 2.0 pp per tenth of a unit = 0.2031 / 10; SD 0.0706; factor 2.6 = 2.03 / 0.78.
- Lee: s*₁₁ = 0.683, excess 1.9 %, bounds within a quarter of an SE (0.106 and 0.211 against 1.054).
- Permutation: 31 of 999 draws ⇔ p = 32 / 1000 = 0.032; central 95 % [−2.96, 2.60]; observed t 3.15.
- Leave-one-out: minimum 2.415 is ISCO 21, maximum 3.580 is ISCO 33, removing ISCO 25 gives 3.287; no refit outside the ±1 SE band [2.20, 4.25].
- Sorting: 0.0013 / 0.197 < 0.01 of an SD; event-study coefficients all p > 0.26 ("flat in every year").
- Sweep: thresholds 0.75–0.85 swap exactly ISCO 23 and 41; 0.90 swaps none and equals the external row.
- Appendix A absence shares by quartile and by cell (14.4/8.5/9.5/9.6; 12.1 → 10.4; 15.5 → 16.9; 6.1 both periods); commuting 48.2 vs 46.1 in 2019 and the 1.5 vs 3.9 fall (difference 2.39); 258,175 = 93,982 + 164,193; 6,318 = 258,175 − 251,857; 1,514 / 80,560 = 1.9 %; "roughly 5,200" zeros = 5,169 in the harmonization memo; "about 10 %" absent = 9.8–12.0 % by year in the same memo.
- Appendix B: 0.966 → 0.069; 0.29 vs 0.16 on 207 rows; 0.045 (0.021) on 85,454, within R² 9.5e-5; correlation 0.53, slope 0.40 (0.09), external correlation 0.74; `min_n = 200` (main.R:181).
- Figures (rendered and read): the event studies, permutation histogram and leave-one-out plot show what their notes say (hollow 2019 point, dashed ±3.15, shaded ±1 SE band, no triangles).

### 1c. Findings

| # | Location | As printed | Source and value | Type | Severity | Proposed fix | Status |
|---|---|---|---|---|---|---|---|
| P1-1 | `appendix.tex:51–52` (Appendix A, "Hours year by year") | "The post-period path is neither monotone nor individually distinguishable." | `hours_descriptives_hours_by_year.csv`: 2023 gap −0.80, 95 % CI [−1.17, −0.42]; 2022 gap −1.53, CI [−1.91, −1.16]; 2019 gap −1.67, CI [−2.03, −1.31]. The 2023 point lies outside both intervals, and Figure A1(a) shows it. Section 6.1 and the Limitations call 2023 "a larger 2023 coefficient" (0.752**). | claim contradicts data and main text | medium | "The post-period path is not monotone, and only its 2023 point, the year Section 6.1 flags, is distinguishable from the pre-period." | fixed 0148968 |
| P1-2 | `appendix.tex:184` (Figure A1(b) note) | "the thirty unswapped ones lie below it" | Table A1: 11 of the 30 unswapped occupations have reference-week share ≥ calibrated score (ISCO 72, 74, 81, 82, 91, 92, 94, 95 with score 0.000 and shares 0.011–0.043; ISCO 32 by 0.027; ISCO 75 by 0.036; ISCO 63, N = 8, at 0.375). The rendered figure shows them on or just above the line near the origin. | overstated claim | low | "most of the thirty unswapped ones lie below it; the exceptions are zero-scored manual occupations within a few hundredths of the line and one eight-person group (ISCO 63)" | fixed 0148968 |
| P1-3 | `paper.tex:451–452` (Section 4.2) versus Figure 1 tick label | prose: "the top quartile $0.36$ to $0.75$"; figure prints "Q4 0.30–0.75" | `hours_dose_response_data.csv` labels bins by breakpoint (q_low = 0.30); `ddd_hours_binned_quartile_sizes.csv` and Table A3 give the lowest Q4 score as 0.36. Both are true; the document prints both. | internal inconsistency | low | Prose: "the top quartile $0.36$ to $0.75$ (its bin boundary is $0.30$)". Alternative: change `q_label` in `scripts/hours_dose_response.R` to the observed range, which needs a pipeline run. | fixed 0148968 (prose) |
| P1-4 | `paper.tex:958–960` (Discussion) | "even there only a minority of workers are at home in the reference week (Appendix Table A1)" | Table A1, the six Q4 occupations: shares 0.349, 0.615 (ISCO 25), 0.371, 0.206, 0.380, 0.152; N-weighted 0.40. True for the quartile and five occupations, false for ICT professionals. | imprecise claim | low | "even there fewer than half of workers, ICT professionals excepted, are at home in the reference week" | fixed 0148968 |
| P1-5 | `appendix.tex:18–19` | "$12.4\%$ of employed mothers against $7.3\%$ of childless women" | Not in `outputs/`; quoted from `docs/decisions/hours-population-harmonization.md:34` (console output). Recomputing from Table 1 counts over all six years: 1 − 164,193 / 187,174 = 12.3 %; 1 − 93,982 / 101,225 = 7.2 %. | memo-sourced, differs by 0.1 pp | low | Keep if the memo's base is accepted as the source; otherwise "about $12\%$ … against $7\%$". | open |
| P1-6 | `appendix.tex:33–41, 58` | 64,602 respondents; 63,199 respondents; 96 % repeat rows; "two to three within a single survey year"; 80,560 women; factor "roughly 1.8"; commuting SE 1.17 | No artifact in `outputs/`. 64,602 appears in a comment at `scripts/clustered_se.R:7`; 80,560 and 1,514 in the comment at `appendix.tex:43–46` (from `check_idpuf_panel_structure()`, whose per-person tables are deliberately not exported); 1.8 in `paper/notes/results_digest.md` §1.8; the SE 1.17 nowhere (`comparative_stats_mobility_by_year.csv` carries no SE; the 2.39-point difference recomputes). | unverifiable from outputs | info | No text change proposed. Optional: export the panel-structure summary and the mobility SE in a future pipeline run so these have artifacts. | open |

### 1d. Handed to Phase 2 (numbers attributed to the literature, not checkable against outputs)

2.87 and 1.40 (oecd2025fertility, `paper.tex:219–220`); "over a third" of US employment (dingel2020, 303);
"roughly a quarter of US paid workdays" (barrero2021/2023, 281); 72 minutes and 40 % (aksoy2023, 955–957);
0.78 pp per 10 % rise in WFH (harrington2025, 919); the Israeli school-closure chronology (somekh2021, hale2021).

### Open items after Phase 1

P1-5 (low) and P1-6 (info) remain open; P1-1 to P1-4 were fixed in `0148968` (2026-10-03). No value,
sign or rounding error in any table or in any number the prose quotes from a table or CSV.

## Phase 3: Structural and reference integrity (run 2026-10-03, at `0148968`)

### 3a. Confirmed clean

- **Labels and references.** 43 labels, none defined twice; every `\ref`/`\eqref` resolves; `\eqref` only on
  equations and `\ref` never on one; every reference is preceded by a tie (`Table~`, `Figure~`, `Section~`,
  `Appendix~`, `equation~`, `Panel~`, `column~`) or a `--` range; every `\citep` is preceded by a tie, a
  space or an opening parenthesis; 47 `\citep`, no `\citet`/`\citeauthor` in code (the header comment's
  claim holds). Five section labels are never referenced (`sec:app-results`, `sec:desc-hours`,
  `sec:desc-table`, `sec:res-childage`, `sec:res-subgroup`); four sit on headings and are harmless, the
  fifth is P3-3.
- **Floats and inputs.** All 9 `\input` targets exist; all 12 `tables/*.tex` are input except the two Lee
  tables, documented at `appendix.tex:192–193`; all 7 `\includegraphics` files exist and all 7
  `outputs/figures/*.pdf` are used. Every float has a caption, a label and a note (5 figures with
  *Notes*, 9 tables with `tablenotes`). The four `\autonote*` macros are each used once, in their own
  table. Star tokens in every table body are within the global legend of the Results lead. Appendix
  numbering restarts at A1 for tables and figures; the TOC lists sections and subsections only, as set.
- **Placeholders.** None of `TODO|FIXME|XXX|XX|TBD|TK|cite here|add figure|add table|placeholder|??|
  \todo|\hl|\textcolor{red}|marginpar|DRAFT|forthcoming|lorem|VERIFY` in the three source files or the
  generated tables. Title, two authors, submission date (`\date` and title page agree on 2026-10-15),
  affiliation block and supervisor line present.
- **Compile.** Four-pass compile exits 0; `paper.log` has no undefined reference or citation, no
  multiply-defined label, no overfull box, no font substitution; `paper.blg` has 0 warnings; 36 pages, A4;
  all 31 fonts embedded (`pdffonts`). The only log warnings are the six underfull boxes of P3-4.
- **Rendered pages.** No `??` or `[?]` in the extracted text; no orphan heading at a page foot (the
  first pass flagged four, an artifact of splitting on form feeds); every float appears on or after the
  page of its first mention; pages 7, 14, 17, 29, 31 and 33 rendered and read: tables within the margin,
  figure text legible, two-panel figures aligned.
- **chktex / lacheck triage** (54 chktex warnings): 17 × W8 en-dash in author pairs (`Dingel--Neiman`,
  `Imbens--Manski`, correct); 14 × W13 and 10 × W12 sentence spacing, of which one is real (P3-5) and
  the rest fire on `(ID: …)`, `Columns (2)--(4)` and `\autonote*` at line end; 6 × W1 macro terminated
  by a newline (harmless); 3 × W24 spacing before `\label` (one is P3-3); 2 × W38 punctuation inside
  quotes (US style, correct); 2 × W36 `(2)--(4)` (false). lacheck reports only P3-5.

### 3b. Findings

| # | Location | As printed | Detail | Type | Severity | Proposed fix | Status |
|---|---|---|---|---|---|---|---|
| P3-1 | `paper.tex:510, 569, 629, 633, 764, 771, 824` | "Mother× year", "A Mother× age-group interaction", "marital status ×Post × WFH_Exposure", panel labels of Figure 2 | Math that ends with `\times` (`$\Mother \times$ year`) or starts with it (`$\times \Post \times \WFH$`) loses the binary-operator spacing on the open side. Standalone `$\times$` (lines 701–702, appendix 258) is fine. | reader-visible typography | low | Give the operator an empty operand inside math: `$\Mother \times {}$ year` and `${} \times \Post \times \WFH$`, or move the word into math (`$\Mother \times \text{year}$`) for the two panel labels. | fixed 211135e |
| P3-2 | `paper.tex:103` (`\hypersetup`) | PDF metadata Title and Author empty (`pdfinfo`) | hyperref's `pdftitle`/`pdfauthor` are not set. | metadata | low | `\hypersetup{pdftitle={Did Remote Work Narrow the Motherhood Penalty? Evidence on the Intensive Margin from Israeli Labor Force Survey Microdata, 2017-2023}, pdfauthor={Inbal Moryles and Nitzan Zacharia}}` | fixed 211135e |
| P3-3 | `paper.tex:859` | `\label{sec:res-subgroup}Table~\ref{tab:subgroup} splits …` | A label at the start of a body paragraph, left from a removed subsection heading; never referenced; would resolve to "6.5". | leftover | cosmetic | Delete `\label{sec:res-subgroup}`. | fixed 211135e |
| P3-4 | Table A1 (`tables/tab_exposure_scores.tex`, column spec in `scripts/build_paper_tables.R`) | Six `Underfull \hbox` warnings, two at badness 10000 (rows 62 and 92): stretched word spacing in the 5.2 cm justified occupation column at 8 pt | Generated table; the `p{5.2cm}` column justifies two-line occupation names. | cosmetic (generated) | cosmetic | Pipeline: `>{\raggedright\arraybackslash}p{5.2cm}` in the builder (needs `array` and a `main.R` run). Paper-side alternative to test at apply time: `\raggedright\arraybackslash` inside the float group before the `\input`. | fixed 211135e (paper side: `\raggedright` before the tabular had no effect because `\@arrayparboxrestore` resets the paragraph shape in each p-cell; it is appended to that reset inside a group scoped to the tabular; 0 underfull boxes). Follow-up: move to the builder's column spec at the next `main.R` run. |
| P3-5 | `appendix.tex:93` | "…drop out of the hours DDD. A partially masked…" | A sentence ending in a capital abbreviation gets interword, not intersentence, spacing (no `\frenchspacing` in the preamble). The only instance in prose (`lacheck` and `chktex` agree). | typography | cosmetic | `DDD\@. A partially` | fixed 211135e |

### Open items after Phase 3

None. P3-1 to P3-5 were fixed in `211135e` (2026-10-03). One follow-up for the next pipeline run:
put `>{\raggedright\arraybackslash}p{5.2cm}` in `build_paper_tables.R` for `tab_exposure_scores`
(and `\usepackage{array}` if not loaded), after which the scoped group in `appendix.tex` can go.

## Phase 2: Citation and claim fact-checking (run 2026-10-03, at `211135e`)

Report only. **No change was made to `references.bib` or to any `\cite` command.** Routes used: Crossref
API for all 27 DOIs (abstracts returned for 18); NBER landing pages, the IZA page and the arXiv v3 PDF
for the working papers; the authors' NBER PDF for Harrington–Kahn (57 pp.); the BLS working-paper PDF for
Pabilonia–Vernon (65 pp.); the OECD SF2.1 PDF; the Taub Center English PDF (39 pp.); Bank of Israel
press release via search (the BoI site refused connections); CRAN and BLS pages.

### 2a. Bib hygiene: confirmed

32 entries, all cited, no key missing; no duplicate title or DOI; author format `Last, First` throughout,
institutional authors double-braced; DOIs bare and consistent; page ranges with `--`; every `@article` has
journal, volume, pages, year and DOI, and `number` is absent only where the journal has none (AEA P&P ×2,
JPubE ×2); every `@techreport` has institution, type, number and year. `aer-course.bst` keeps title case
as typed, so brace protection is moot. The rendered list is alphabetical, prints full author lists, no
truncated title, no `[?]`, 0 BibTeX warnings. All 47 in-text citations are `\citep` with a tie, space or
parenthesis before them.

### 2b–c. Citing sentences versus sources

Every one of the 47 citation instances was read against its source. 42 are supported as written; the
five below are not, or only partly. Items marked "body" rest on the paper's text rather than its abstract.

| Key | Sentence(s) | Verdict | Evidence |
|---|---|---|---|
| barrero2021 | 207 | supported | NBER w28731, "Why Working from Home Will Stick" |
| goldin2014 | 208, 271, 489, 936 | supported | abstract: gap "would be considerably reduced and might vanish altogether if firms did not … disproportionately reward … long hours and … particular hours" |
| harrington2025 | 216, 295–297, 921, 989 | supported | abstract: 0.78 pp per 10 % rise in WFH; "driven by majors linked to careers that have high returns to hours and inflexible demands"; income effect conditional on employment (p. 3, fn. 5: 1.3 %) |
| harrington2025 | 1046–1049 | **misattributed** | see P2-1 |
| oecd2025fertility | 219–220 | supported | SF2.1 PDF: "In 2024, at 2.87 children per woman, Israel had the highest TFR in the OECD"; OECD average 1.40 in 2024 |
| kleven2019denmark | 267, 988 | supported | abstract: long-run gap ≈20 % "driven by hours worked, participation, and wage rates"; occupation, sector and firm choices |
| kleven2019countries | 267 | supported (body) | abstract names family policies and gender norms as the candidates; the paper's conclusion favours norms |
| maspallais2017 | 277 | supported (body) | abstract: 8 % of wages for the WFH option; the gender pattern is in the heterogeneity section |
| cortespan2019 | 278 | supported | JOLE abstract via EconPapers |
| barrero2023 | 284 | supported (approx.) | abstract: 28 % of paid workdays mid-2023 ("roughly a quarter … since 2021") |
| aksoy2023 | 285, 955–957 | supported | abstract: 72 minutes; 40 % to jobs, 11 % to caregiving |
| bloom2015 | 287 | supported | abstract: 9 % of the 13 % gain from more minutes per shift |
| gibbs2023 | 287 | supported | IZA DP 14336 abstract: hours +30 %, output unchanged, productivity −20 % |
| pabilonia2022 | 289 | supported | GLO abstract: more leisure, household production and family time on WFH days; p. 26: female teleworkers +32 min home production; mothers 3.5 work episodes vs fathers 3.2 |
| pabilonia2022 | 978–980 | partly | see P2-4 |
| angelici2024 | 290 | supported | abstract: "men also increase the time dedicated to household and care activities" |
| alon2020, adamsprassl2020 | 292 | supported (prior audit) | abstracts not re-fetched today (none on Crossref); claim unchanged since 2026-09-26 |
| emanuelharrington2024 | 302 | supported | abstract: selection vs treatment decomposition |
| dingel2020 | 305, 371, 741, app. 69, 136 | supported | NBER w26948 abstract: 37 % of US jobs |
| madhala2020 | 312 | supported | Taub PDF p. 4: CBS Social Survey 2019, 4.4 % of workers usually work from home |
| callaway2024 | 310–314, 514–517 | partly | see P2-3 |
| buzaglo2023 | 316–320, 1013–1015 | **overstated** | see P2-2 |
| budig2023 | 322 | supported | abstract |
| yaish2021 | 323 | supported | abstract: women, especially with children, increase housework more than men |
| olden2022 | 507 | supported | abstract: "requires only one parallel trend assumption" |
| roodman2019, fischer2021 | 544 | supported | boottest abstract; package citation |
| lee2009, imbens2004 | 558, 562, app. 218 | supported | method as described |
| phipson2010 | 583, app. 255 | supported | abstract: understatement by 1/m; count the observed draw |
| bls2012crosswalk | app. 70 | supported | BLS page lists `ISCO_SOC_Crosswalk.xls` |
| somekh2021, hale2021 | app. 78 | supported | Somekh: 2020 closure and staged reopening; OxCGRT C1 indicator |

### 2d. Findings

| # | Location | As printed | Source says | Type | Severity | Proposed fix | Status |
|---|---|---|---|---|---|---|---|
| P2-1 | `paper.tex:1046–1049` | "The comparison group includes women whose children are grown and women who become mothers within the window, as in the US study \citep{harrington2025}." | Harrington–Kahn p. 9: "We focus on comparing women whose eldest child is under 15 to women with no children, while excluding women with older children." | misattributed | medium | "The comparison group includes women whose children are grown and women who become mothers within the window; the US study instead excludes women with older children \citep{harrington2025}." The following sentence ("If part of it responds …") still holds. | fixed a8367f4 |
| P2-2 | `paper.tex:316–318` and `1013–1015` | "The gender wage gap is driven mainly by women's sorting into lower-paying firms, even within industry, with pay differences within firms contributing little"; "sorting across firms, even within the same industry, is a first-order driver of Israeli gender gaps" | BoI DP 2023.17: firm premiums account for 29 % of the gap; 22 % is sorting across industries and 4 % sorting into lower-paying firms within industry; within-firm pay differences negligible. | overstated ("mainly", "first-order", "even within industry" is the 4 % part) | medium | 316–318: "Nearly a third of the gender wage gap is a firm-premium gap, mostly from women's sorting into lower-paying industries and, to a lesser extent, lower-paying firms within industry, with pay differences within firms contributing little \citep{buzaglo2023}." 1013–1015: "whereas sorting across industries and firms accounts for nearly a third of the Israeli gender wage gap \citep{buzaglo2023}." | fixed a8367f4 |
| P2-3 | `paper.tex:310–314`, `514–517` | "a single slope … need not weight those comparisons positively"; "a weighted average of such comparisons whose weights need not be positive" | Callaway–Goodman-Bacon–Sant'Anna, Thm 3.4: with causal responses as building blocks under strong parallel trends the TWFE weights "are positive for all values of the dose" but differ from the dose distribution and are sensitive to the untreated group; negative weights arise in the level and per-dose decompositions and with staggered timing. | partly supported | low | 314: "where a single slope compares outcomes across exposure levels with weights that need not match the distribution of exposure \citep{callaway2024}." 516–517: "and the slope is a weighted average of such comparisons whose weights differ from the distribution of exposure and, under some interpretations, are not all positive \citep{callaway2024}." | fixed a8367f4 |
| P2-4 | `paper.tex:978–980` | "Teleworking mothers of young children report more interruptions to the workday \citep{pabilonia2022}." | Pabilonia–Vernon p. 26: mothers have 3.5 work episodes on WFH days versus 3.2 for fathers and 2.6 for women without children, which the authors read as interruptions; diary-based, not self-reported, and not restricted to young children. | partly supported | low | "Teleworking mothers' workdays are more fragmented than fathers' or childless women's \citep{pabilonia2022}." The next sentence's "largest for mothers of infants" stays as the paper's own inference. | fixed a8367f4 |
| P2-5 | `references.bib` harrington2025 | `@techreport`, NBER WP 34147, 2025 | Published: *National Tax Journal* 79(2), 507–527, 2026. | published version exists | low | Convert to `@article{harrington2025, journal={National Tax Journal}, volume={79}, number={2}, pages={507--527}, year={2026}}` with the DOI from the NTJ page; in-text years become 2026 automatically. Or keep the WP and say so in the bib comment. | open |
| P2-6 | `references.bib` buzaglo2023 | BoI Discussion Paper 2023.17 | Published as "Firms, Industries and the Gender Wage Gap", *Labour Economics*, 2025 (ScienceDirect S0927537125001411). | published version exists | low | Optional: cite the journal version (verify DOI, volume and pages via Crossref before changing). | open |
| P2-7 | `references.bib` aksoy2023 | author "Barrero, Jose Maria" | barrero2021/2023 carry `Jos{\'e} Mar{\'i}a`; the reference list prints two spellings of one name (Crossref: unaccented for AEA P&P and NBER, accented for JEP). | inconsistency | low | Accent the aksoy2023 author to match. | open |
| P2-8 | `references.bib` fischer2021, oecd2025fertility | `url = {…}` | `aer-course.bst` does not print `url`; the OECD and CRAN links are invisible in the PDF (the BLS URL shows because it sits in `howpublished`). | rendering | low | Move each URL into `howpublished` (or `note`) with `\url{}`. | open |
| P2-9 | `references.bib` fischer2021 | "R package version 0.14.3", CRAN URL | CRAN: package archived 2024-05-29; the URL now resolves to an archive stub. | stale | low | Note: "R package version 0.14.3, archived from CRAN May 2024; \url{https://github.com/s3alfisc/fwildclusterboot}". | open |
| P2-10 | `references.bib` bls2012crosswalk | note "Updated June 2015" | BLS crosswalk page: last modified 2012-08-30, no June 2015 note online; the date may be inside the workbook the CBS supplied. | unverifiable online | info | Confirm against the workbook header or drop the note. | open |
| P2-11 | `references.bib` madhala2020, buzaglo2023 | no URL | Taub English PDF and BoI DP page exist. | completeness | info | Optional `howpublished = {\url{…}}`. | open |

### Open items after Phase 2

P2-1 to P2-4 were fixed in `a8367f4` (2026-10-03; prose only, every citation in place). Still open:
P2-5 to P2-9 (low, bib), P2-10, P2-11 (info). Each is applied only on explicit approval.

## Phase 4: Prose, flow and copyediting (run 2026-10-03, at `a8367f4`)

Report only; nothing edited. Conclusion excluded (co-author's text). Invariants for every proposal
below: no number, citation, label or reference changes; every `\citep` stays in its sentence.

### 4a. Sweeps

- **Sentence lengths** (`scratchpad/prose.R`, comments and math normalized): 597 sentences, mean 19.1
  words; 78 of 30+ words, 40 of 35+, 20 of 40+. Of the 20 longest, 11 are table or figure notes
  (semicolon lists, the longest 128 words in Table 3's note), one is the display equation, one is the
  Conclusion. Proposals below cover every prose sentence of 35+ words outside the Conclusion plus the
  three longest notes.
- **Spelling screen** (word list from the PDF body, 307 hapax words reviewed): no misspelling. Every
  hapax is a proper noun, a bib word, or a pdftotext artifact (truncated figure labels, rejoined hyphens).
- **Dialect**: American throughout ("labor", "behavior", "program") except `centre` (paper.tex ≈804) and
  `labelled` (appendix.tex ≈193). The ISCO-08 group titles keep their official British spellings
  ("specialised", "Labourers") and "Nature Human Behaviour" is a journal name: leave those.
- **Terminology**: "childless women" is the standard term; "non-mothers" survives in four prose places
  (paper.tex ≈505, ≈510, ≈1055; appendix.tex ≈49) and in the generated figure legends. "child care" /
  "child-care" / "childcare" each occur once. "ex ante" (adverb) vs "ex-ante" (adjective) is consistent.
  "forty" in prose and "40" in tables and notes is consistent. No filler words (very, quite, in order to,
  the fact that, note that), no "impact" as a verb, no loose "significant", no doubled words, no straight
  quotes, no space before punctuation.
- **Acronyms**: CBS, DiD, DDD, WFH, MDE expanded at first use; ISCO (paper.tex ≈310) and BLS
  (appendix.tex ≈70) are not. SE, CI, OECD, ICT are standard. O*NET and SOC appear only in Appendix B
  beside the crosswalk citation.
- **Headings**: the four main `\section` titles are Title Case ("Literature Review", "Data and
  Institutional Context", "Descriptive Statistics", "Empirical Strategy"); the four appendix `\section`
  titles are sentence case ("Data and sample details", "Exposure construction", "The selection
  correction", "Additional results"). Subsections are sentence case throughout, consistently.

### 4b. Global items (apply with any group)

| # | Location | Current | Proposed |
|---|---|---|---|
| G-1 | `appendix.tex` four `\section` lines | sentence case | Title Case to match the main sections: "Data and Sample Details", "Exposure Construction", "The Selection Correction", "Additional Results" (labels unchanged). |
| G-2 | `paper.tex` ≈804; `appendix.tex` ≈193 | "the centre of its range"; "labelled by ISCO-08 code" | "center"; "labeled" |
| G-3 | `paper.tex` ≈238, ≈292, ≈853 | "the child-care time constraint"; "childcare"; "binds through child care" | one form, "childcare": "the childcare time constraint"; "binds through childcare" |
| G-4 | `paper.tex` ≈310; `appendix.tex` ≈70 | "two-digit ISCO-08 codes"; "the BLS crosswalk" | "two-digit codes of the International Standard Classification of Occupations (ISCO-08)"; "the Bureau of Labor Statistics (BLS) crosswalk" |
| G-5 (optional) | `paper.tex` ≈505, ≈510, ≈1055; `appendix.tex` ≈49 | "non-mothers", "mother/non-mother gap", "mother-minus-non-mother gap" | "childless women", "mother/childless gap", "mother-minus-childless gap". The figure legends ("Non-mothers") are generated by `hours_descriptive_plots.R` and would need a pipeline run; leaving prose and legend as they are is also defensible. |

### 4c. Group (i): Abstract, Introduction, Literature Review

| # | Location | Current | Proposed |
|---|---|---|---|
| i-1 | Abstract, sentence 2 (41 w) | "We use Central Bureau of Statistics (CBS) Labor Force Survey microdata on women aged 25--59 in 2017--2019 and 2021--2023 to estimate difference-in-differences (DiD) and triple-differences (DDD) models of usual weekly hours, with an Israeli-calibrated occupational WFH-exposure index as the third difference." | "We use Central Bureau of Statistics (CBS) Labor Force Survey microdata on women aged 25--59 in 2017--2019 and 2021--2023. Difference-in-differences (DiD) and triple-differences (DDD) models of usual weekly hours take an Israeli-calibrated occupational WFH-exposure index as the third difference." |
| i-2 | Abstract, sentence 3 (50 w) | "…did not change on average ($0.23$ hours), but they rose where the work can be done from home: the triple interaction is $3.22$ hours…" | Split at the colon: "…but they rose where the work can be done from home. The triple interaction is $3.22$ hours per unit of exposure, or $1.71$ hours a week between the mean exposures of the most and least teleworkable quartiles of occupations." |
| i-3 | Introduction ¶1 (36 w) | "This paper asks whether the post-COVID shift to remote work altered the motherhood penalty in \emph{usual weekly work hours} among employed women in Israel, using Central Bureau of Statistics (CBS) Labor Force Survey microdata for 2017--2023." | "This paper asks whether the post-COVID shift to remote work altered the motherhood penalty in \emph{usual weekly work hours} among employed women in Israel. The data are Central Bureau of Statistics (CBS) Labor Force Survey microdata for 2017--2023." |
| i-4 | Literature Review opener (45 w) | "…and how exposure to remote work can be measured, and its effect identified, when no one is assigned to it at random." | "…and how exposure to remote work can be measured and its effect identified when no one is assigned to it at random." (two commas dropped; the list reads as three items) |
| i-5 | "What remote work does to hours" ¶ | "Time worked rose under randomized home working and in the pandemic move home, in the latter case without output keeping pace" | "Time worked rose under randomized home working and in the pandemic shift to home, in the latter case without output keeping pace" |
| i-6 | same ¶ (36 w) | "The one study of the motherhood penalty in that period \citep{harrington2025} finds that WFH raised US mothers' employment and income, with the employment effect concentrated in fields with high returns to hours and inflexible time demands." | "The one study of the motherhood penalty in that period \citep{harrington2025} finds that WFH raised US mothers' employment and income. The employment effect is concentrated in fields with high returns to hours and inflexible time demands." |
| i-7 | "Measuring exposure" ¶, last sentence | "Section~\ref{sec:strategy} takes up the two results that bear on reading our coefficient." | "Section~\ref{sec:strategy} takes up the two results from that family that bear on reading our coefficient." ("the two results" currently has no antecedent) |
| i-8 | "Israel" ¶ (37 w, from P2-2) | "Nearly a third of the gender wage gap is a firm-premium gap, mostly from women's sorting into lower-paying industries and, to a lesser extent, lower-paying firms within industry, with pay differences within firms contributing little \citep{buzaglo2023}." | "Nearly a third of the gender wage gap is a firm-premium gap. It arises mostly from women's sorting into lower-paying industries and, to a lesser extent, into lower-paying firms within industry, while pay differences within firms contribute little \citep{buzaglo2023}." |
| | plus G-3 (≈238, ≈292), G-4 (ISCO) | | |

Kept as they are: the 31-word opening sentence pair of the Introduction, the 38-word roadmap sentence
(conventional), the 31-word "This rules out a shock…" sentence.

### 4d. Group (ii): Data, Descriptive Statistics, Empirical Strategy

| # | Location | Current | Proposed |
|---|---|---|---|
| ii-1 | 3.1 ¶2 | "because the 2017 extract records zero hours differently (Appendix~\ref{sec:app-data})" | "because the 2017 extract records absentees' hours as zero (Appendix~\ref{sec:app-data})" (says what differs) |
| ii-2 | 3.2 ¶1 | "It must also not place in the treated tail occupations that Israeli institutions kept in person." | "Nor may it place in the treated tail any occupation that Israeli institutions kept in person." |
| ii-3 | 4.1 (47 w) | "Mothers work \emph{fewer} hours than childless women when they work ($38.68$ versus $40.06$) while being slightly \emph{more} likely to be employed ($0.78$ versus $0.76$), so the penalty's level is visible on the intensive margin; the table cannot show whether it changed after 2021." | "Mothers work \emph{fewer} hours than childless women when they work ($38.68$ versus $40.06$) while being slightly \emph{more} likely to be employed ($0.78$ versus $0.76$). The penalty's level is therefore visible on the intensive margin, but the table cannot show whether it changed after 2021." |
| ii-4 | 4.1 (50 w) | "The two groups are imbalanced in ways the controls must absorb: mothers are the better-educated group (…), overwhelmingly married (…), and about $0.44$ of an age-group code younger, an imbalance that tracks WFH exposure (Appendix Table~\ref{tab:balance-quartile})." | "The two groups are imbalanced in ways the controls must absorb. Mothers are the better-educated group ($48\%$ with an academic degree against $40\%$), overwhelmingly married ($85\%$ against $47\%$), and about $0.44$ of an age-group code younger. These imbalances vary with WFH exposure (Appendix Table~\ref{tab:balance-quartile})." |
| ii-5 | 4.2 (39 w) | "The difference between those two changes, $0.27$ hours, is the difference-in-differences of equation~\eqref{eq:did} without a single control, and the regression DiD of Table~\ref{tab:hours}, $0.228$ (SE $0.181$), is within four hundredths of an hour of it." | Split after "control.": "The regression DiD of Table~\ref{tab:hours}, $0.228$ (SE $0.181$), is within four hundredths of an hour of it." |
| ii-6 | 4.2 (45 w) | "The response is not linear in exposure: the bottom three quartiles span exposure values of $0.00$ to $0.30$ and the top quartile $0.36$ to $0.75$ (its bin boundary is $0.30$), so most of the regressor's dispersion, and the identifying contrast, sits in one tail." | "The response is not linear in exposure. The bottom three quartiles span exposure values of $0.00$ to $0.30$ and the top quartile $0.36$ to $0.75$ (its bin boundary is $0.30$), so most of the regressor's dispersion, and with it the identifying contrast, sits in one tail." |
| ii-7 | 5.2 (51 w, from P2-3) | "That requires the stronger condition that occupations at different exposure levels would have followed the same path under any common level of exposure, and the slope is a weighted average of such comparisons whose weights differ from the distribution of exposure and, under some interpretations, are not all positive \citep{callaway2024}." | "That requires the stronger condition that occupations at different exposure levels would have followed the same path under any common level of exposure. Even then the slope is a weighted average of such comparisons whose weights differ from the distribution of exposure and, under some interpretations, are not all positive \citep{callaway2024}." |
| ii-8 | 5.5 ¶2 (36 w) | "We therefore reassign them at random across the forty occupation codes $999$ times, holding every woman's occupation and the mother/period structure fixed, refit equation~\eqref{eq:ddd}, and record the cluster-robust $t$-statistic of the triple interaction." | "We therefore reassign them at random across the forty occupation codes $999$ times, holding every woman's occupation and the mother/period structure fixed. Each draw refits equation~\eqref{eq:ddd} and records the cluster-robust $t$-statistic of the triple interaction." |

Kept: 3.2's 33-word cell-definition sentence (a parenthetical list), 5.3's three 31–33-word sentences
(each one idea with a qualifier), 5.4's 35-word trimming sentence (a colon list), 5.5's 33-word sorting
sentence.

### 4e. Group (iii): Results (light pass; polished 2026-09-27/28 and in this session)

| # | Location | Current | Proposed |
|---|---|---|---|
| iii-1 | 6.2 ¶2 (40 w) | "With quartile indicators in place of the score, the second and third quartiles differ from the least teleworkable one by positive but insignificant amounts, and the top quartile by a significant amount close to the pooled model's $1.71$-hour contrast." | "With quartile indicators in place of the score, the second and third quartiles differ from the least teleworkable one by positive but insignificant amounts. The top quartile differs by a significant amount close to the pooled model's $1.71$-hour contrast." |
| iii-2 | Table 2 note (60 w) | "Column (4) replaces the score with indicators for its pre-period quartile (Figure~\ref{fig:dose-response}'s bins); its lower-order quartile terms are estimated but not shown, and the number of occupations per bin is listed because occupation is the cluster, counted on the full 2017--2023 estimation sample (Appendix Table~\ref{tab:balance-quartile} counts pre-period rows only, so its bottom quartile shows one occupation fewer)." | "Column (4) replaces the score with indicators for its pre-period quartile (Figure~\ref{fig:dose-response}'s bins); its lower-order quartile terms are estimated but not shown. The number of occupations per bin is listed because occupation is the cluster, counted on the full 2017--2023 estimation sample (Appendix Table~\ref{tab:balance-quartile} counts pre-period rows only, so its bottom quartile shows one occupation fewer)." |
| iii-3 | Table 3 note (128 w, seven row descriptions joined by semicolons) | "The men-only row calibrates …; the teaching-only row moves …; the married-only row drops …; the marital-interacted row adds …; the swapped-occupation rows keep …; the unswapped-occupations row drops those ten; the absentees row adds … as zero." | One sentence per row, same words: "The men-only row calibrates the index on men's realized 2022--23 WFH shares. The teaching-only row moves ISCO 23 alone from its external score to its realized share and leaves the other thirty-nine at the external score. The married-only row drops marital status from the controls. The marital-interacted row adds marital status ${} \times \Post \times \WFH$ and its two-way terms. The swapped-occupation rows keep the external index as regressor on all forty occupations and add a Swapped indicator for the ten calibrated occupations with the full $\Mother \times \Post$ structure, showing both triple interactions from that one model. The unswapped-occupations row drops those ten. The absentees row adds employed women absent from work in the reference week at their reported usual hours, on 2018--2023 only, since the 2017 file recorded absentees' hours as zero." |
| iii-4 | 6.5 ¶1 (36 w) | "The four regressions share a control group and the same forty clusters, so their intervals overlap and are not independent, and on the wild cluster bootstrap none of the four is significant at the 5\% level." | "The four regressions share a control group and the same forty clusters, so their intervals overlap and are not independent. On the wild cluster bootstrap none of the four is significant at the 5\% level." |
| iii-5 | 6.6 | "The shortfall is structural, a binary outcome and a regressor with little dispersion, and re-clustering, combining the two margins and refining the cell partition did not close it." | "The shortfall is structural: a binary outcome and a regressor with little dispersion. Re-clustering, combining the two margins and refining the cell partition did not close it." |
| | plus G-2 ("centre", 6.4), G-3 (≈853) | | |

Kept: the four 35-word sentences of 6.3 (each one claim plus its qualifier), the Results lead's
33-word stars sentence, 6.1's two 31–33-word sentences.

### 4f. Group (iv): Discussion and Limitations

No sentence-level change proposed. Both sections were rewritten on 2026-09-28 and corrected in this
session (P1-4, P2-1 to P2-4). The remaining 30+-word sentences (the fitted-change arithmetic, the
absentees row, the 2023 war sentence) each carry one idea with a figure or a date and read cleanly.
Only G-5 (optional, ≈1055) touches this group.

### 4g. Group (v): Appendices and the remaining notes

| # | Location | Current | Proposed |
|---|---|---|---|
| v-1 | Figure A1(a) note (60 w) | "Panel~(a): women aged 25--59 who worked in the reference week, unweighted means with no controls; the upper panel plots each group's mean weekly hours on an axis spanning 36 to 42 hours, the lower panel their difference, with 95\% confidence intervals clustered by individual; the dotted rule marks the excluded 2020 survey year, and the series break there." | "Panel~(a): women aged 25--59 who worked in the reference week, unweighted means with no controls. The upper panel plots each group's mean weekly hours on an axis spanning 36 to 42 hours, the lower panel their difference, with 95\% confidence intervals clustered by individual. The dotted rule marks the excluded 2020 survey year, and the series break there." |
| v-2 | Figure A1(b) note (59 w, from P1-2) | "The swapped occupations sit above it because their calibrated value is the usual-place share, which is lower than the reference-week share everywhere; most of the thirty unswapped ones lie below it, the visual form of the scale-mixing described above, and the exceptions are zero-scored manual occupations within a few hundredths of the line and one eight-person group (ISCO 63)." | "The swapped occupations sit above it because their calibrated value is the usual-place share, which is lower than the reference-week share everywhere. Most of the thirty unswapped ones lie below it, the visual form of the scale-mixing described above. The exceptions are zero-scored manual occupations within a few hundredths of the line and one eight-person group (ISCO 63)." |
| v-3 | Appendix D ¶1 (41 w) | "Figure~\ref{fig:permutation} plots the reference distribution of the permutation test: under the sharp null the central $95\%$ of cluster-robust $t$-statistics lie between $-2.96$ and $2.60$, and the observed $3.15$ is exceeded in absolute value by $31$ of $999$ draws." | "Figure~\ref{fig:permutation} plots the reference distribution of the permutation test. Under the sharp null the central $95\%$ of cluster-robust $t$-statistics lie between $-2.96$ and $2.60$, and the observed $3.15$ is exceeded in absolute value by $31$ of $999$ draws." |
| | plus G-1 (headings), G-2 ("labelled"), G-4 (BLS), G-5 optional (≈49) | | |

Kept: Table A2's 44-word and Table A4's 42-word note sentences (definitional lists), Appendix A's and
B's 30–32-word sentences (each one fact), Appendix C (rewritten in `8f859dc`).

### Expected effect

Prose sentences of 35+ words outside the Conclusion and the notes: 14 → 2 (the roadmap sentence and
5.4's colon list). Longest note sentence 128 → 57 words. Word count roughly unchanged (splits add a
subject here and there; the two comma drops and "ex ante" remove nothing). No number, citation,
label or reference touched.

### Status

- G-1 to G-4 and i-1 to i-8: fixed in `e546ff4` (2026-10-03). G-5 not applied (optional; figure
  legends are generated).
- ii-1 to ii-8: fixed in `a7c8a09` (2026-10-03).
- iii-1 to iii-5: fixed in `60f682b` (2026-10-03).
- v-1 to v-3: fixed in `b969f31` (2026-10-03). Phase 4 closed; group (iv) had no items.

## Audit summary (2026-10-03)

| Phase | Findings | Fixed | Still open |
|---|---|---|---|
| 1 Data | 6 | P1-1 to P1-4 (`0148968`) | P1-5 (memo-sourced absence shares), P1-6 (no artifact for seven panel/commuting numbers) |
| 3 Structure | 5 | P3-1 to P3-5 (`211135e`) | follow-up: ragged-right column spec in the table builder at the next pipeline run |
| 2 Citations | 11 | P2-1 to P2-4 (`a8367f4`); P2-5, P2-7, P2-8, P2-9 (`00dadf2`) | P2-6 (Labour Economics version of Buzaglo-Baris, user's call), P2-10 (BLS "Updated June 2015", check the workbook), P2-11 (optional Taub/BoI URLs) |
| 4 Prose | 29 | G-1 to G-4, i, ii, iii, v (`e546ff4`, `a7c8a09`, `60f682b`, `b969f31`) | G-5 (optional, needs a pipeline run) |

Six commits after `8f859dc`, all on `doc-audit`; the branch is ahead of origin by six. The paper
compiles clean at 36 pages with no LaTeX, box or BibTeX warnings. No citation command or bib
entry was changed in any phase.

### Execution (per group, on approval)

Edit; verify `\label|\ref|\eqref|\citep` multiset and math-mode numeral set identical to HEAD, `git
diff -U0` confined to prose; compile (manual four-pass for appendix edits, hook otherwise); commit one
group per commit; push on request.
