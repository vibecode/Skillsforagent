---
name: serp-google-scholar
display_name: Google Scholar
description: >
  Specialized skill for Google Scholar workflows via SerpApi — academic paper search,
  literature reviews, citation tracking, author profile analysis, citation exports, and
  legal case law lookup. Use when: (1) searching academic papers by topic, keyword, or
  author, (2) filtering results by publication year range, (3) finding papers that cite
  a given paper (citation tracking), (4) discovering all versions of a paper via cluster
  search, (5) looking up an author's profile, h-index, and publications, (6) building a
  literature review with sorted, deduplicated results, (7) exporting citations in BibTeX,
  APA, MLA, Chicago, Harvard, or Vancouver formats, (8) finding free PDFs from the
  `resources` field, (9) searching US case law and court decisions, (10) sorting by date
  vs relevance for recent vs seminal work, (11) any academic research task involving
  Google Scholar. This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "🎓"}}
---

# Google Scholar Workflows

Academic paper search, citation tracking, author profile lookup, literature review building, and citation export via the SerpApi Google Scholar family of engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_scholar`, `google_scholar_author`, `google_scholar_cite`, `google_scholar_case_law`, `google_scholar_profiles`)

## Core Concepts

### The Four Engines

| Engine | Purpose | Key Param |
|--------|---------|-----------|
| `google_scholar` | Search papers, case law, citing docs, versions | `q`, `cites`, or `cluster` |
| `google_scholar_author` | Pull an author's profile, articles, citation stats | `author_id` |
| `google_scholar_cite` | Export citations in standard formats (BibTeX, APA, etc.) | `q` (a `result_id`) |
| `google_scholar_case_law` | Fetch full metadata for a single case law decision | `case_id` |

Most workflows start with `google_scholar`, then chain into the others using IDs returned in `organic_results`.

### Three Search Modes (`google_scholar`)

The main engine has three mutually-exclusive query modes:

| Mode | Param | What It Returns |
|------|-------|-----------------|
| Keyword search | `q="machine learning"` | Standard topic search |
| Citing papers | `cites=ARTICLE_ID` | All papers that cite a given article ("Cited By") |
| All versions | `cluster=ARTICLE_ID` | Every version/host of the same paper |

For `cites` and `cluster`, `q` is optional and the article ID comes from `inline_links` on a previous result. **Do not combine `q` with `cluster`.**

### Response Structure (`google_scholar`)

Every search returns:

- **`organic_results[]`** — Papers, each with:
  - `position` — Result rank
  - `title`, `link` — Paper title and primary URL
  - `result_id` — Unique ID (pass to `google_scholar_cite` for citation export)
  - `snippet` — Excerpt
  - `publication_info.summary` — Single string like `"Author1, Author2 - Journal, Year - publisher"`
  - `publication_info.authors[]` — Structured authors with `author_id` for profile lookups
  - `resources[]` — Free PDF / HTML alternatives, each with `title` (host), `file_format` (`PDF`, `HTML`), and `link`
  - `inline_links.cited_by` — `{ total, link, cites_id, serpapi_scholar_link }` — `cites_id` is what you pass to `cites=` to fetch citing papers
  - `inline_links.versions` — `{ total, link, cluster_id, serpapi_scholar_link }` — `cluster_id` is what you pass to `cluster=` for all versions
  - `inline_links.related_pages_link` — "Related articles" link
  - `inline_links.html_version` — Alt HTML link when present
- **`related_searches[]`** — Suggested refinements
- **`pagination`** — `current`, `next`, `other_pages`
- **`search_metadata`**, **`search_parameters`**, **`search_information`**

### Key Filters

| Goal | Parameter | Value |
|------|-----------|-------|
| Year ≥ 2020 | `as_ylo` | `2020` |
| Year ≤ 2024 | `as_yhi` | `2024` |
| Recent papers, sort by date | `scisbd` | `2` (all content) or `1` (abstracts only) |
| Include patents | `as_sdt` | `7` |
| Exclude patents (default) | `as_sdt` | `0` |
| Case law only | `as_sdt` | `4` |
| Specific courts | `as_sdt` | `4,33,192` (court IDs after the `4`) |
| Review articles only | `as_rr` | `1` |
| Exclude citations | `as_vis` | `1` |
| Language restriction | `lr` | `lang_en\|lang_fr` |
| Interface language | `hl` | `en`, `es`, `fr`, etc. |
| Results per page | `num` | `1`–`20` (default `10`) |
| Pagination offset | `start` | `0`, `10`, `20`, ... |
| Disable similarity filter | `filter` | `0` |

### Query Operators

Inside `q`, Google Scholar supports advanced operators:
- `author:"Hinton"` — Restrict by author
- `source:"Nature"` — Restrict by journal/source
- `"exact phrase"` — Exact match
- `-term` — Exclude
- `intitle:keyword` — Title must contain the word

## Workflows

### 1. Topic Search (Literature Discovery)

Use the **serpapi** wrapper with engine `google_scholar`.

**Required:** `q`
**Common filters:** `as_ylo`, `as_yhi`, `as_rr=1` (reviews), `scisbd` (recent), `num=20`, `start`

**Strategy:**
1. Start with a focused `q` — quote multi-word phrases for precision
2. Add `as_ylo` if currency matters (e.g., last 5 years)
3. Use `as_rr=1` to find review papers — great seed material for a lit review
4. Paginate with `start` increments of `num` until coverage is sufficient

**Present each result as:**
```
🎓 [Title]
   [Authors] — [Venue], [Year]
   📊 Cited by [N] | 📄 Versions: [N]
   [Snippet excerpt...]
   🔗 [link]
   📥 PDF: [resources[].link if file_format=PDF]
```

### 2. Year-Range Filtering

For recent work or historical surveys, combine `as_ylo` and `as_yhi`:

| Goal | Setup |
|------|-------|
| Past 5 years | `as_ylo=<current_year - 5>` |
| Specific decade | `as_ylo=2010`, `as_yhi=2019` |
| Pre-2000 foundational work | `as_yhi=2000` |
| Just this year, by date | `scisbd=2` (overrides relevance sort) |

**Note:** `scisbd` only surfaces the past year. For older date ranges, rely on `as_ylo`/`as_yhi` (results stay relevance-sorted).

### 3. Citing-Papers Lookup (Forward Citation Search)

To find every paper that has cited a given article — useful for tracing influence and finding newer work building on a classic.

**Step 1:** Search for the target paper with `q`. Identify its `inline_links.cited_by.cites_id`.

**Step 2:** Run a new search with `cites=<cites_id>` (omit `q` or supply a refining query). Add `as_ylo` to restrict to recent citing papers if needed.

**Use cases:**
- "What recent work builds on the original Transformer paper?" → search Transformer paper → grab `cites_id` → re-query with `cites=...&as_ylo=2023`
- Find practitioners applying a foundational method in a new domain

### 4. All-Versions / Cluster Lookup

Papers often exist on multiple hosts (preprint server, journal, university repo). To deduplicate or to hunt for a free version:

**Step 1:** Search for the paper, capture `inline_links.versions.cluster_id`.

**Step 2:** Re-query with `cluster=<cluster_id>` (no `q`). Each version comes back with its own `resources` — scan for a PDF.

**Use case:** Finding a free, open-access PDF when the primary `link` is paywalled.

### 5. Author Profile Lookup

Switch to engine `google_scholar_author`.

**Required:** `author_id` — found in `organic_results[].publication_info.authors[].author_id` from any keyword search.

**Optional:** `sort` (`pubdate`, `title`, or omit for citation count), `start`, `num` (max `100`), `view_op` (`list_colleagues` for co-authors).

**Response highlights:**
- `author` — name, affiliations, verified email, interests, thumbnail
- `articles[]` — each with `title`, `authors`, `publication`, `cited_by.value`, `year`, `citation_id`
- `cited_by.table[]` — `citations` (all-time + since recent year), `h_index`, `i10_index`
- `cited_by.graph[]` — annual citation counts
- `co_authors[]` — name, affiliation, `author_id`, thumbnail
- `public_access` — counts of available vs unavailable open papers

**Presentation pattern:**
```
🎓 [Author Name]
   [Affiliation] | ✉️ [verified email]
   Interests: [interest1, interest2, ...]

📊 Citations: [total] (since [year]: [recent])
   h-index: [N] | i10-index: [N]

📚 Top Articles:
   1. [Title] — [Year] · cited [N]
   2. ...
```

### 6. Citation Export (BibTeX, APA, MLA, ...)

Switch to engine `google_scholar_cite`.

**Required:** `q` set to a `result_id` from a `google_scholar` organic result.

**Optional:** `hl` (language).

**Response:**
- `citations[]` — formatted strings in MLA, APA, Chicago, Harvard, Vancouver. Each has `title` (format name) and `snippet` (the citation text)
- `links[]` — download links for BibTeX, EndNote, RefMan, RefWorks. Each has `name` and `link`

**Workflow:** Show the user APA + BibTeX by default (most common). Offer the others on request.

**Use case:** Building a reference list for a paper — search, then loop over results calling cite for each `result_id`, collecting BibTeX entries.

### 7. Literature Review Pipeline

End-to-end workflow for assembling a reading list on a topic.

1. **Seed search** with `as_rr=1` to surface review papers (best entry points)
2. **Expand by citations:** for each high-value review, use `cites=` to find papers that built on it
3. **Restrict by year:** add `as_ylo` to drop stale work
4. **Deduplicate by `result_id`** — the same paper can appear across multiple `cites_id` queries
5. **Rank by citation count:** sort the collected results by `inline_links.cited_by.total`
6. **Pull free PDFs:** for each kept paper, check `resources[]` for `file_format=PDF`. If none, do a `cluster=` lookup to surface alternate versions
7. **Export citations:** loop over the final set calling `google_scholar_cite` to grab BibTeX

**Presentation:** Group by theme, then by year. For each, show: title, authors, venue/year, citation count, snippet, PDF link if found, and BibTeX entry.

### 8. Case Law Search

Two-step: discover, then fetch.

**Step 1 — Discover** with `google_scholar`:
- `q="search terms"`
- `as_sdt=4` for all US courts, or `as_sdt=4,<court_id>,<court_id>` to restrict (e.g., `as_sdt=4,33,192` for Supreme Court + specific federal courts)
- Add `as_ylo` / `as_yhi` for decision year range

The `organic_results[]` will contain `case_id` values for each decision.

**Step 2 — Fetch full case** with engine `google_scholar_case_law`, passing `case_id`. Returns:
- `case_results.title`, `name`, `court_name`
- `first_page`, `last_page`, page references
- `dates[]` — `Argued`, `Decided` events
- `short_citations[]`, `case_numbers[]` — docket numbers
- `cited_cases[]` — related precedent with links

**Use case:** Researching legal precedent on a topic, then pulling structured metadata for citation in a brief.

### 9. Sorting: Date vs Relevance

Google Scholar defaults to relevance. Switch based on intent:

| User Intent | Setup |
|-------------|-------|
| Foundational / seminal work | Default (relevance) — high citation counts surface first |
| Latest research, last 12 months | `scisbd=2` |
| Latest research, abstracts only | `scisbd=1` |
| Specific year range, relevance-sorted | `as_ylo` + `as_yhi`, leave `scisbd` off |

**Note:** `scisbd` is only useful for the most recent year. For older "latest first" needs, post-sort results by year client-side after pulling.

### 10. Finding Free PDFs

Many results are paywalled. SerpApi exposes the same "[PDF]" / "[HTML]" sidebar links Google Scholar shows on the right of each result, in `resources[]`.

**Strategy per result:**
1. Inspect `resources[]` — if any entry has `file_format=PDF`, that's the direct link
2. If none, run a `cluster=` lookup using `inline_links.versions.cluster_id`. Each cluster version has its own `resources` — preprint hosts (arXiv, SSRN, university repos) commonly include PDFs
3. If still none, the paper may be paywalled — flag to the user

## Common Patterns

### "Find recent papers on [topic]"
1. `google_scholar` with `q=[topic]`, `as_ylo=<recent year>`, `num=20`
2. Present top 5-10 with title, authors, venue, year, citation count, snippet
3. Offer to expand: more pages, citing papers for a specific result, or BibTeX export

### "Find review articles on [topic]"
1. `google_scholar` with `q=[topic]`, `as_rr=1`
2. Present results sorted by citation count
3. For the top review, offer "find papers that cite this" using `cites_id`

### "What cites [paper]?"
1. Search for the paper title with `google_scholar`
2. Identify `cites_id` from `inline_links.cited_by`
3. Re-query with `cites=<cites_id>`, optionally `as_ylo` for recency
4. Present citing papers ranked by their own citation count

### "Look up [author's] publications"
1. `google_scholar` with `q="author full name"` to surface a representative paper
2. Pull `author_id` from `publication_info.authors[]`
3. Call `google_scholar_author` with `author_id`, `sort=pubdate` for recent work
4. Present profile header + article list

### "Export this paper as BibTeX"
1. Search to confirm paper, grab `result_id`
2. Call `google_scholar_cite` with `q=<result_id>`
3. Find the BibTeX entry in `links[]`, return its `link` (or fetch the BibTeX directly if user wants the raw entry)

### "Find a free PDF of [paper]"
1. Search for paper, check `resources[]` on the top result for `file_format=PDF`
2. If none, use `cluster_id` to fetch all versions
3. Scan each version's `resources` — return the first PDF found
4. If none found, report the paper appears paywalled

### "Find US Supreme Court rulings on [topic]"
1. `google_scholar` with `q=[topic]`, `as_sdt=4,33` (33 = SCOTUS court ID)
2. For each result, call `google_scholar_case_law` with `case_id` for full metadata
3. Present case name, court, date decided, docket, cited cases

## Presenting Results

### Paper Result Format

```
🎓 [Title]
   [Author1, Author2, Author3] — [Venue], [Year]
   📊 Cited by [N] · 📄 [V] versions
   "[Snippet excerpt...]"
   🔗 [primary link]
   📄 Free PDF: [resources link if available]
```

### Citation Export Format

```
📚 [Paper Title]

APA:
[citations[].snippet for APA]

BibTeX: [links[].link for BibTeX]
EndNote: [links[].link for EndNote]
```

### Author Profile Format

```
🎓 [Name] — [Affiliation]
   Interests: [interests, comma-separated]
   ✉️ Verified at [email domain]

📊 [Total] citations · h-index [N] · i10-index [N]
   Since [year]: [recent citations]

📚 Most-cited papers:
   1. [Title] · [Year] · [N] citations
   2. ...
```

## Tips

- **Stable IDs to remember:** `result_id` (→ cite export), `cites_id` (→ citing papers), `cluster_id` (→ all versions), `author_id` (→ author profile), `case_id` (→ case law detail). Capture them from `inline_links` and `publication_info.authors[]` on every search.
- **`scisbd` only covers the past year.** For "latest research" on longer ranges, use `as_ylo` and post-sort by year.
- **`num` caps at 20** on this engine (unlike most SerpApi engines where 100 works). Paginate with `start` for larger sets.
- **Dedupe by `result_id`.** The same paper shows up across `cites=` and topic searches; track seen IDs.
- **PDFs hide in clusters.** If the primary result has no PDF in `resources`, the cluster (all versions) almost always exposes a preprint copy on arXiv, SSRN, or a university repo.
- **`as_rr=1` is the lit-review shortcut.** Review papers consolidate hundreds of references — a single strong review can replace dozens of individual paper reads.
- **`as_vis=1` cleans noise.** Excluding bare citations (no full text) is useful when building a reading list you actually want to read.
- **Author IDs are stable.** Once captured, an `author_id` can be reused indefinitely to track new publications.
- **Case law court codes** follow Google Scholar's `as_sdt=4,<court_id>...` convention — `33` is SCOTUS. For other courts, browse Google Scholar's case law page to capture IDs before automating.
- **Citation counts are point-in-time.** Don't cache them long — re-fetch when freshness matters.
- **Pair with `google_scholar_cite` early.** If a literature review is the goal, export citations as you go rather than batching at the end — keeps the `result_id` linkage clean.
- **Localization:** `hl` changes the interface language but not the corpus. The underlying papers are returned regardless of `hl`.
