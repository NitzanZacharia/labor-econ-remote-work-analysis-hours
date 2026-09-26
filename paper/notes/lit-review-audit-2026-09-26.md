# Literature Review audit: `paper/paper.tex` §2 (pre-submission)

**Date:** 2026-09-26. **Scope:** every citation-bearing claim in Section 2 (`paper.tex:215-278`),
plus the two Harrington–Kahn numbers in the Introduction that §2 explicitly defers to. **Rule
applied (author's choice):** factual errors were fixed in place and the paper recompiled;
tone/flow rewordings are listed as proposals only and were NOT applied.

**Bottom line.** 21 claims checked against primary sources. 18 accurate. 3 wrong and fixed:
the Buzaglo-Baris mechanism was stated backwards (within-firm instead of across-firm sorting),
the Gibbs et al. hours figure was wrong (their published abstract gives no "18% total hours" and
output fell rather than staying flat), and the time-savings split was attributed to Barrero et al.
rather than to Aksoy et al. Bibliography: 32 keys cited, 32 defined, 0 BibTeX warnings before and
after; all fields for the 21 §2 entries confirmed; two consistency edits applied.

Compile after the edits: 0 errors, 0 undefined citations/references, `warning$ -- 0` in
`paper.blg`, 34 pages. The only log warnings are the pre-existing "PDF inclusion: found PDF
version 1.7, allowed max 1.5" notices on the figure files, which are unrelated to this audit.

---

## 1. Claim-by-claim verification

Verdicts: **OK** = source says what the paper says. **Imprecise** = not contradicted, but the
wording overstates or blurs; proposal in §3. **WRONG → fixed** = source contradicts the sentence;
edit applied (§4).

| # | Line (post-edit) | Key | Claim in paper | Verdict | What the source says (evidence) |
|---|---|---|---|---|---|
| 1 | 170–171 | harrington2025 | 10% rise in WFH → mothers' employment +0.78 pp relative to other women; employed mothers' income +1.3% | **OK** | Abstract: "for every 10% increase in WFH, mothers' employment rates increased by 0.78 percentage points (or 0.94%) relative to other women's." Body p. 3 fn. 5: "a ten percent increase in WFH was associated with a 1.3 percent increase in employed mothers' incomes relative to other employed women's (p-value = 0.043)." Sources: NBER abstract page https://www.nber.org/papers/w34147 ; authors' Sept-2025 PDF linked from https://sites.google.com/view/eharrington/research |
| 2 | 219–222 | kleven2019denmark | Danish admin data; ~20% long-run earnings gap after first birth; channels hours, participation, wage rates; occupation/sector/firm moves | **OK** | Abstract: "long-run gender gap in earnings of around 20 percent driven by hours worked, participation, and wage rates. We identify mechanisms … in terms of occupation, sector, and firm choices." https://www.aeaweb.org/articles?id=10.1257/app.20180010 |
| 3 | 222–223 | kleven2019countries | pattern "universal across countries", tied to gender norms more than family policy | **Imprecise** (wording) | Six countries (DK, SE, DE, AT, UK, US). Paper: "child penalties are not driven primarily by public policies"; Fig. 4 plots penalties against elicited gender norms (slope 1.01). "Universal" overstates a six-country study; the authors say "pervasive". NBER WP 25524 pp. 1, 5–6. |
| 4 | 225–228 | goldin2014 | remaining gap sits in job structure; nonlinear pay for long/particular hours; mothers penalised out of proportion | **OK** | Abstract: "The gender gap in pay would be considerably reduced and might vanish altogether if firms did not have an incentive to disproportionately reward individuals who labored long hours and worked particular hours." https://www.aeaweb.org/articles?id=10.1257/aer.104.4.1091 |
| 5 | 231–232 | maspallais2017 | workers, women in particular, give up wages for the WFH option | **OK** | NBER abstract: "workers are willing to pay the most (8% of wages) for the option of working from home. Women, particularly those with young children, have higher WTP for work from home." https://www.nber.org/papers/w22708 |
| 6 | 232–234 | cortespan2019 | skilled gender gap concentrated where long hours are rewarded; narrows where household-time substitutes are cheap | **OK** | Abstract: "increasing the supply of substitutes for household production … increases the relative earnings of women in occupations that disproportionately reward overwork." https://ideas.repec.org/a/ucp/jlabec/doi10.1086-700185.html |
| 7 | 237–240 | buzaglo2023 | (was) "within-firm sorting is a first-order driver of the gender wage gap" | **WRONG → fixed** | Abstract: "Sorting of women into lower wage-premium firms (also within the same industry) explains a significant part of the gap, while negligible part is due to within firm inequality." The mechanism is across-firm sorting; within-firm pay differences are negligible. https://ideas.repec.org/p/boi/wpaper/2023.17.html. Same error was in the Limitations section (line 937) and was fixed there too. |
| 8a | 241–242 | barrero2021, barrero2023 | WFH settled at roughly a quarter of paid US workdays after 2021 | **OK** | 2021 WP: "20 percent of full workdays will be supplied from home after the pandemic ends, compared with just 5 percent before." JEP 2023: "Full days worked at home account for 28 percent of paid workdays … as of mid-2023." https://www.nber.org/papers/w28731 ; https://www.aeaweb.org/articles?id=10.1257/jep.37.4.23 |
| 8b | 242–243 | (was uncited; now aksoy2023) | freed time is split between paid work, care and leisure | **WRONG attribution → fixed** | Neither Barrero et al. abstract reports the split. Aksoy et al. (2023): "Workers allocate 40 percent of their time savings to their jobs and about 11 percent to caregiving activities. People living with children allocate more of their time savings to caregiving." https://www.aeaweb.org/articles?id=10.1257/pandp.20231013. `aksoy2023` was already in the bib (cited in the Discussion). |
| 9 | 243–246 | gibbs2023 | (was) "total hours up by roughly 18% with output flat" | **WRONG → fixed** | Published abstract (JPE Micro 1(1)): "Hours worked increased, output declined slightly, and productivity fell 8%–19%." The 18% figure is the *after-hours* rise in the 2021 working-paper abstract, not total hours, and output fell rather than staying flat. https://ideas.repec.org/a/ucp/jpemic/doi10.1086-721803.html |
| 10 | 246–248 | pabilonia2022 | on remote days part of the saved time goes to household production and child care, most of all among parents | **Imprecise** | Abstract: "teleworkers spend less time on commuting and grooming activities but more time on leisure activities and with family on work-at-home days …, and female teleworkers spend more time sleeping and on household production activities"; "mothers experience more interruptions in their workdays." Family time and (for women) household production are supported; "child care" and "most of all among parents" are not stated in the abstract. https://ideas.repec.org/a/kap/reveho/v20y2022i3d10.1007_s11150-022-09601-1.html |
| 11 | 249–252 | emanuelharrington2024 | call-centre workers; who selects into remote work differs from what remote work does to them | **OK** | Abstract: pre-COVID remote workers 12% less productive; office closures narrowed the gap by 4%; "an 8 percent productivity gap persisted, indicating negative selection into remote jobs." Setting is a Fortune 500 firm's call centre. https://www.aeaweb.org/articles?id=10.1257/app.20230376 |
| 12 | 253–254 | bloom2015 | randomly assigned home working "raised work supplied without a fall in output" | **Imprecise** (understates) | Abstract: "Home working led to a 13% performance increase, of which 9% was from working more minutes per shift (fewer breaks and sick days) and 4% from more calls per minute." Output rose; "without a fall" is true but weaker than the finding. Crossref record for 10.1093/qje/qju032. |
| 13 | 254–255 | angelici2024 | randomly assigned flexibility shifted household-task division toward men | **OK** | Abstract: "we observe that men also increase the time dedicated to household and care activities." Crossref record for 10.1287/mnsc.2023.4767. |
| 14 | 255–257 | adamsprassl2020, alon2020 | in 2020, women in WFH-feasible jobs absorbed a larger share of the childcare from school closures | **OK for Adams-Prassl; Imprecise for Alon** | Adams-Prassl et al. (IZA DP 13183, p. 3 and §5): "amongst the population working from home, women spend significantly more time homeschooling and caring for children"; restricting to those working from home and controlling for characteristics, "women spent about one hour more on childcare and home schooling." Alon et al. (NBER 26947, April 2020) is a projection paper using pre-crisis ATUS/ACS data: it anticipates that closures raise childcare needs that fall on mothers, but does not observe 2020 outcomes. |
| 15 | 257–258 | yaish2021 | Israel's 2020 lockdown reallocated paid and unpaid labor within households in gender-unequal ways | **OK** | Abstract: "as demand for housework caused by the lockdown increases, women—especially with children—increase their housework much more than men do, particularly when they work from home." Crossref record for 10.1177/08912432211001297. |
| 16 | 259–264 | harrington2025 | employment effect driven by fields with high returns to hours and inflexible time demands; income result is intensive-margin | **OK** | Abstract: "driven by majors linked to careers that have high returns to hours and inflexible demands on workers' time." Body p. 3: "we see increases in incomes even conditional on employment." |
| 17 | 264–266 | budig2023 | Israeli motherhood penalties in employment and earnings differ across ethno-religious groups | **OK** | Abstract: "motherhood deters employment among Israeli-Palestinians more strongly than among Jews … motherhood wage penalties and ethno-religious disparities are greatest among the least-educated women." Crossref record for 10.1177/08912432231155913. |
| 18 | 266–268 | (none) | no published Israeli estimate of the penalty in hours conditional on working | **Not contradicted** | Two web searches (English) found Taub Center descriptive part-time shares by sex and Budig et al.'s employment/earnings penalties, but no Israeli hours-conditional-on-employment motherhood-penalty estimate. Budig et al. note "past research finds low motherhood penalties in Israel" (employment and wages). A Hebrew-language search was not run; the "to our knowledge" hedge is appropriate. |
| 19 | 270–271 | dingel2020 | occupations classified by whether tasks can be done entirely at home; 37% of US jobs | **OK** | Abstract: "37 percent of jobs in the United States can be performed entirely at home." https://www.nber.org/papers/w26948 |
| 20 | 273 | madhala2020 | descriptive baseline on WFH ability in Israel | **OK** | Taub Center research page: Shavit (Madhala) Ben-Porat and Benjamin Bental, November 2020, PIAAC-based description of which Israeli workers can work from home. https://www.taubcenter.org.il/en/research/the-ability-to-work-from-home-among-workers-in-israel/ |
| 21 | 274–277 | callaway2024 | continuous-treatment DiD; "two results for the reading of a single slope" taken up in §4 | **OK** | Abstract: ATT-type parameters identified under generalized parallel trends, but "interpreting differences in these parameters across different values of the treatment can be particularly challenging due to selection bias"; TWFE "parameters … can be hard to interpret". §4 (line 466–470) states exactly these two points: stronger assumption for across-level comparisons; slope is a weighted average with possibly negative weights. https://www.nber.org/papers/w32117 |

## 2. Bibliography validation

**Coverage.** `paper.blg`: "You've used 32 entries", `warning$ -- 0`, before and after the
edits. 32 distinct keys are cited across `paper.tex` and `appendix.tex`; 32 entries are defined;
no orphans, no missing keys.

**Fields.** Every DOI-bearing §2 entry was pulled from the Crossref API on 2026-09-26
(`https://api.crossref.org/works/<DOI>`) and compared field by field (authors, title, journal,
volume, issue, pages, year). All matched, including the five entries added on 2026-09-23. NBER
entries were checked against the NBER pages (numbers 34147, 28731, 26947, 32117). The Bank of
Israel and Taub entries were checked against IDEAS/RePEc (series 2023.17) and the Taub research
page (November 2020).

| Key | Result |
|---|---|
| goldin2014, kleven2019denmark, kleven2019countries, maspallais2017, cortespan2019, dingel2020, aksoy2023, bloom2015, angelici2024, adamsprassl2020, yaish2021, budig2023, barrero2023, emanuelharrington2024, gibbs2023, pabilonia2022 | All fields confirmed against Crossref. |
| harrington2025 | Confirmed against NBER. **Edit:** `doi = {10.3386/w34147}` added (the other NBER entries carry their DOI). Comment added noting the authors' Sept-2025 version is accepted at the *National Tax Journal*; NBER WP remains the citable version. |
| callaway2024 | Confirmed against NBER. **Edit:** `doi = {10.3386/w32117}` added. |
| barrero2021 | Confirmed. **Edit:** author changed from "Jose Maria" to "Jos{\'e} Mar{\'i}a" to match `barrero2023` and the JEP masthead. (apalike prints initials, so the rendered list is unchanged; the source is now consistent.) |
| alon2020, madhala2020, buzaglo2023 | Confirmed; no change. |
| bloom2015 | Crossref's issued date is the 2014 online-first date; the bib correctly uses the 2015 print volume (130(1)). Existing comment already records this. |

**Still-open presentational item (not changed, per register D4).** apalike labels
`kleven2019countries` "2019a" and `kleven2019denmark` "2019b"; §2 cites b before a. Left as is
because the paragraph is built around the Danish study.

## 3. Copyediting proposals (NOT applied)

Line numbers refer to the post-edit file. Each is a before → after with a one-line reason.

**Accuracy-tightening (from §1 "Imprecise" rows)**

- **Line 222–223.** "find the pattern universal across countries and tied to gender norms more
  than to family policy" → "find the same pattern in all six countries they study, with the size
  of the penalty tracking gender norms rather than family policy". Reason: six countries, and the
  authors' own word is "pervasive".
- **Line 253–254.** "randomly assigned home working raised work supplied without a fall in output
  \citep{bloom2015}" → "randomly assigned home working raised both minutes worked per shift and
  output \citep{bloom2015}". Reason: output rose 13%; the current wording understates.
- **Line 246–248.** "find in American time diaries that on remote days part of the time saved goes
  to household production and child care, most of all among parents" → "find in American time
  diaries that on remote days part of the time saved goes to family time and, for women, to
  household production, and that teleworking mothers report more interruptions to their workday".
  Reason: matches the abstract; "child care" and "most of all among parents" are not stated there.
- **Line 255–257.** "\citep{adamsprassl2020, alon2020}" → "\citep{adamsprassl2020}, as
  \citet{alon2020} anticipated". Reason: Alon et al. is an April-2020 projection, not evidence
  on what happened.

**Style and flow**

- **Line 250.** "call-centre" → "call-center". Reason: the paper otherwise uses US spelling
  ("labor", "center"); this is the only "centre" in the manuscript.
- **Line 230–231.** "The ingredients are real:" → "Both premises have empirical support:".
  Reason: colloquial in an otherwise formal paragraph.
- **Lines 252–259 (one 90-word sentence).** Split into three: (i) "The experimental evidence on
  gender gaps is encouraging: randomly assigned home working … \citep{bloom2015} and randomly
  assigned flexibility … \citep{angelici2024}." (ii) "The acute 2020 evidence is not: women in
  WFH-feasible jobs absorbed … \citep{adamsprassl2020}, and for Israel \citet{yaish2021} document
  … ." (iii) "This paper uses post-acute data (2021--2023) rather than data from the initial
  shock." Reason: five citations and a semicolon in one sentence; the contrast is lost.
- **Line 259.** "post-acute (2021--2023) data rather than the initial-shock period" →
  "post-acute data (2021--2023) rather than data from the initial shock". Reason: "data" and
  "period" are not parallel.
- **Line 276–277.** "whose two results for the reading of a single slope are taken up in
  Section~\ref{sec:strategy}" → "whose two results on how to read a single slope coefficient are
  taken up in Section~\ref{sec:strategy}". Reason: "for the reading of" is awkward.
- **Line 235–236.** "so the sign is an empirical question, and Goldin's framework says where to
  look for it: in the gradient …" → "so the sign is an empirical question. Goldin's framework
  says where to look for it: in the gradient …". Reason: the colon after a coordinated clause
  reads as run-on.

## 4. Edits applied

`paper/paper.tex`
1. Lines 237–240 (Literature Review): Buzaglo-Baris sentence rewritten to "the sorting of women
   into lower-paying firms, even within the same industry, is a first-order driver of the gender
   wage gap, while pay differences within firms contribute little". (§1 row 7)
2. Lines 936–937 (Limitations, outside §2 but same error): "within-firm sorting matters as much
   as occupation for Israeli gender gaps" → "sorting across firms, even within the same industry,
   is a first-order driver of Israeli gender gaps". (§1 row 7)
3. Line 243: "\citep{aksoy2023}" added after "paid work, care and leisure". (§1 row 8b)
4. Lines 244–246: Gibbs et al. sentence rewritten to "find hours worked up while output fell
   slightly, so that measured productivity dropped by $8$--$19\%$". (§1 row 9)

`paper/references.bib`
5. `harrington2025`: DOI added; provenance comment added.
6. `callaway2024`: DOI added.
7. `barrero2021`: author accents aligned with `barrero2023`; comment added.

`paper/paper.pdf` recompiled (pdflatex, bibtex, pdflatex, pdflatex from `paper/`); 34 pages;
no "labels may have changed" warning, so no fifth pass was needed.

## 5. Method note

Publisher pages for Elsevier, Sage, Springer, OUP, INFORMS and UChicago Press return 403 to
automated fetches. Abstracts were taken from the Crossref API record (which carries the
publisher abstract for AEA, OUP, Sage and INFORMS titles), from IDEAS/RePEc mirrors, or from
the NBER/IZA working-paper PDFs read directly. Working-paper abstracts differ from published
ones in at least one case (Gibbs et al.), which is why the published abstract was used for the
verdict.
