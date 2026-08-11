---
name: serp-google-patents
display_name: Google Patents
description: >
  Specialized skill for Google Patents workflows via SerpApi — prior-art search, inventor and
  assignee lookup, jurisdiction filtering, patent detail retrieval (claims, classifications,
  citations, family members), and competitive IP landscape analysis. Use when: (1) searching
  for prior art on a technical topic or keyword, (2) finding patents filed by a specific
  inventor, (3) finding patents assigned to a company or competitor, (4) filtering patents by
  country or jurisdiction (US, EP, WO, CN, JP, etc.), (5) restricting results to a date range
  via filing, priority, or publication date, (6) fetching full patent details including claims,
  abstract, classifications, and figures, (7) exploring the citation graph — patents cited by
  or citing a given patent, (8) tracking patent family members and worldwide applications,
  (9) analyzing competitive IP landscapes for a technology area, (10) tracking filing trends
  over time for an assignee or CPC class, (11) finding granted patents vs pending applications,
  (12) any task involving patent search or patent metadata. This skill builds on the
  foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📜"}}
---

# Google Patents Workflows

Prior-art search, patent detail retrieval, citation graph exploration, and competitive IP landscape analysis via SerpApi's Google Patents engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_patents`, `google_patents_details`)

## Core Concepts

### Two Engines

| Engine | Purpose | Key Input |
|--------|---------|-----------|
| `google_patents` | Search for patents matching a query, filters, dates | `q` query string + filters |
| `google_patents_details` | Fetch full record for one patent (claims, citations, family) | `patent_id` |

A typical workflow runs a `google_patents` search first, then drills into specific results with `google_patents_details`.

### Patent ID Format

The `patent_id` used by the details engine has a strict shape:

```
patent/<publication_number>/<two-letter language code>
```

- Examples: `patent/US11734097B1/en`, `patent/EP3000000A1/en`, `patent/WO2019123456A1`
- The language suffix is optional but recommended for full-text content.
- Use the `patent_id` field returned by the search engine directly — do not hand-construct.
- Scholar documents use `scholar/<scholar_id>` (only when `scholar=true` is set on search).

### Query Syntax (`q`)

The `q` parameter supports boolean logic and grouping:

- **Boolean operators:** `AND`, `OR`, `NOT` (uppercase).
- **Grouping:** Wrap in parentheses — `(coffee OR tea) AND brewing`.
- **Phrases:** Quote multi-word terms — `"machine learning"`.
- **Multiple search facets:** Separate independent terms with `;` — `(coffee) OR (tea);(A47J)` combines a text query with a CPC class filter.
- **CPC classes** can appear in `q` directly (e.g., `H04L` for digital transmission).

### Date Filters (`before` / `after`)

Date filters use a typed format: `type:YYYYMMDD`. The `type` selects which date the filter applies to:

| Type | Meaning |
|------|---------|
| `priority` | Priority date (earliest claimed filing) |
| `filing` | Application filing date |
| `publication` | Publication date |

Examples:
- `after=priority:20180101` — only patents with priority on/after 2018-01-01
- `before=publication:20231231` — published on/before 2023-12-31

Combine `before` and `after` of the same type for a window.

### Filter Quick Reference

| Goal | Parameter | Value |
|------|-----------|-------|
| Granted patents only | `status` | `GRANT` |
| Applications only | `status` | `APPLICATION` |
| Utility patents only | `type` | `PATENT` |
| Design patents only | `type` | `DESIGN` |
| US patents only | `country` | `US` |
| US + EP + WO | `country` | `US,EP,WO` |
| English-language only | `language` | `ENGLISH` |
| Has known litigation | `litigation` | `YES` |
| No known litigation | `litigation` | `NO` |
| Inventor lookup | `inventor` | `"Jane Doe"` |
| Assignee lookup | `assignee` | `Google LLC` |
| Newest first | `sort` | `new` |
| Oldest first | `sort` | `old` |
| Up to 100 per page | `num` | `100` |
| Cluster by CPC | `clustered` | `true` |
| Include scholar refs | `scholar` | `true` |
| Dedup across family | `dups` | (default = family) |
| Dedup per language only | `dups` | `language` |

### Country Codes

Patent country codes are the issuing patent office:
- `US` — United States
- `EP` — European Patent Office
- `WO` — WIPO / PCT international applications
- `CN` — China
- `JP` — Japan
- `KR` — South Korea
- `DE` — Germany
- `GB` — United Kingdom
- `CA` — Canada

Comma-separate to search multiple jurisdictions (e.g., `country=US,EP,WO`).

### Search Response Structure

`google_patents` returns:

- **`search_information`** — `total_results`, `total_pages`, `page_number`
- **`organic_results[]`** — Individual patent hits with:
  - `position`, `rank`
  - `patent_id` — Use directly with the details engine
  - `patent_link`, `serpapi_link`
  - `title`, `snippet`
  - `publication_number`, `language`
  - `priority_date`, `filing_date`, `grant_date`, `publication_date`
  - `inventor` (string), `assignee` (string)
  - `country_status` — Map of country → `ACTIVE` / `NOT_ACTIVE` / `UNKNOWN`
  - `thumbnail`, `pdf`, `figures`
- **`summary`** — Aggregated counts across the result set:
  - `assignee` — Top assignees with `%` and year breakdowns
  - `inventor` — Top inventors with same shape
  - `cpc` — Top CPC classifications
- **`related_queries`** — Suggested follow-up searches
- **`pagination`** — `current`, `next`

### Details Response Structure

`google_patents_details` returns the full patent record:

- **Bibliographic:** `title`, `type`, `publication_number`, `country`, `application_number`, `family_id`, `pdf`
- **Dates:** `priority_date`, `filing_date`, `publication_date`, `prior_art_date`
- **People:** `inventors[]` (with `name`, `link`, `serpapi_link`), `assignees[]`
- **Content:** `abstract`, `description_link`, `claims[]`, `images[]`
- **Classifications:** `classifications[]` with `code`, `description`, `leaf`, `is_cpc`
- **Family / relationships:**
  - `parent_applications[]`
  - `child_applications[]`
  - `priority_applications[]`
  - `applications_claiming_priority[]`
  - `worldwide_applications` — Grouped by year; entries include `filing_date`, `country_code`, `application_number`, `legal_status`
- **Citations:**
  - `patent_citations.original[]` — Direct citations
  - `patent_citations.family_to_family[]` — Family-level citations
  - `non_patent_citations[]` — Journal articles, standards, etc.
  - `cited_by.original[]`, `cited_by.family_to_family[]` — Patents that cite this one
- **Events:** `events[]` (date, title, type, document_id), `legal_events[]` (USPTO codes)
- **Discovery:** `similar_documents[]`, `prior_art_keywords[]`, `external_links[]`, `concepts[]`

## Workflows

### 1. Prior-Art Search by Keyword

Search for patents related to a technical topic.

Use the **serpapi** wrapper with the `google_patents` engine.

**Strategy:**
1. Construct `q` with the user's topic, using boolean operators for variants — `(neural network OR "deep learning") AND ("on-device" OR edge)`.
2. Add date filters to bound recency — `after=publication:20200101`.
3. Optionally restrict to granted patents only — `status=GRANT`.
4. Sort by `new` for state-of-the-art or by relevance (default) for best matches.

**Present:** Top 5-10 results in the standard patent card format (see Presenting Results). Include the `summary.cpc` block as a quick read on the relevant CPC classes — useful for tightening the next query.

### 2. Inventor Lookup

Find all patents filed by a specific person.

**Parameters:**
- `inventor` — Full name. Wrap any name containing a comma in parentheses: `inventor=(Doe, Jane)`.
- Optional: `assignee` to scope to inventor work at a specific company.
- Optional: `sort=new` to see the most recent filings.

**Present:** Chronological list; group by `assignee` to show where the inventor has worked over time.

### 3. Assignee / Company Lookup

Find all patents owned by a company.

**Parameters:**
- `assignee` — Company name as it appears on filings. Try variants if results look thin (e.g., `Google LLC`, `Google Inc.`, `Alphabet Inc.`).
- Optional: `country=US` to scope to a jurisdiction.
- Optional: date window via `after=filing:YYYYMMDD` for filings since a point in time.

**Strategy:** Run multiple searches with `sort=new` and paginate to build a complete portfolio view. Use the `summary.cpc` block to see what technology areas the assignee is filing in.

### 4. Jurisdiction Filtering

Restrict search to one or more patent offices.

**Pattern:** `country=US,EP,WO` searches US patents, EPO patents, and PCT international applications. Useful when:
- The user only cares about enforceable rights in specific markets.
- You're comparing US-only filings vs international filings for an assignee.
- You want to filter out CN-heavy noise when searching certain technologies.

### 5. Date Range Analysis

Bound results to a specific time window.

**Common patterns:**
- "Patents since 2020": `after=priority:20200101`
- "Patents filed in 2022": `after=filing:20220101&before=filing:20221231`
- "Recently published": `after=publication:20240101`

**Choose the date type carefully:**
- `priority` — When the invention was first claimed (earliest in the chain)
- `filing` — When the application was submitted to this office
- `publication` — When it became publicly visible (~18 months after filing)

For "what's the state of the art in technology X", use `priority` — that's when the inventive activity happened.

### 6. Patent Detail Lookup

Fetch the full record for a single patent.

Use the **serpapi** wrapper with the `google_patents_details` engine and the `patent_id` from a previous search.

**When to drill into details:**
- User asks about claims or scope
- Need citation graph (prior art or who cites this)
- Need full classifications for technology mapping
- Need family / worldwide application data for FTO analysis
- Need full abstract or figures

**Present:** Abstract first, then the independent claims (claims with no parent reference — typically claim 1, plus any other independents), then a one-line summary of citations (`N patent citations, M cited by`), then classifications.

### 7. Citation Graph Exploration

Explore backward and forward citations to map the prior-art landscape.

**Backward citations (what this patent cites):**
1. Fetch details for the seed patent
2. Walk `patent_citations.original[]` — these are direct prior art
3. For each interesting citation, recurse to its details to go deeper

**Forward citations (what cites this patent):**
1. Fetch details for the seed patent
2. Walk `cited_by.original[]` — these are later patents building on this one
3. Sort by date to see the technology evolution

**Family-level citations:** `patent_citations.family_to_family[]` and `cited_by.family_to_family[]` aggregate across the patent family — use these for a broader view that includes equivalents filed in other countries.

**Depth control:** Citation graphs explode quickly. Cap depth at 2 and limit breadth (top 5-10 per node by relevance or recency).

### 8. Patent Family / Worldwide Applications

Map the international footprint of an invention.

**From details:**
- `family_id` — The shared identifier across all family members
- `worldwide_applications` — Grouped by year; lists every jurisdiction with `country_code`, `application_number`, `filing_date`, `legal_status`

**Use cases:**
- Freedom-to-operate: where is this patent enforceable?
- Pruning analysis: which family members are abandoned vs active?
- Competitive intelligence: where does this assignee prioritize protection?

**Present:** A jurisdiction × status table summarizing the family.

### 9. Competitive IP Landscape

Profile a company or technology area's patent activity.

**Strategy:**
1. Search by `assignee` (or by topic via `q`).
2. Set `num=100` and paginate to get a full result set.
3. Read the `summary.cpc` block — these are the dominant technology areas.
4. Read `summary.inventor` — these are the key contributors.
5. Use date windows (`after`, `before`) to see how filings have shifted over time.
6. Drill into the top patents (by recency or by `cited_by` count from details) to identify the company's crown jewels.

**Present:**
```
📜 [Company] — IP Landscape

Total patents (filtered): [N]
Top CPC classes:
  - H04L (Digital transmission) — 34%
  - G06F (Electric digital data processing) — 22%
  - ...
Top inventors:
  - [Name] — [N] patents
Filing trend: [↗️/→/↘️] over the last 5 years
Key recent grants:
  [List]
```

### 10. Technology Trend Tracking

Track filing volume over time for a topic or CPC class.

**Strategy:**
1. Run the same `q` search with a series of `after`/`before` windows (e.g., one per year).
2. Record `search_information.total_results` from each.
3. Plot the trend.

**Tip:** Use `priority` as the date type for trend analysis — it captures actual invention timing, unaffected by publication lag.

### 11. Granted vs Pending Filings

Distinguish active grants from pending applications.

- `status=GRANT` — Only granted patents. These are enforceable.
- `status=APPLICATION` — Only applications. These show where the assignee is *currently* investing.

**For competitive intel:** Look at recent `APPLICATION` results — they reveal where the company is heading, often before public product announcements.

### 12. Classification-Based Search

Use CPC codes for precise technical scoping.

CPC codes can be passed directly in `q`:
- `H04L` — Transmission of digital information
- `G06N 3/08` — Learning methods for neural networks
- `A61K 31/00` — Medicinal preparations of organic chemistry

Combine with text: `q=("federated learning");G06N 3/08`.

**Tip:** Get CPC codes from the `summary.cpc` block of an exploratory search, then re-run with the dominant codes for a more precise result set.

## Presenting Results

### Patent Card Format

For each result in a search:

```
📜 [Title]
   ID: [patent_id]  •  [publication_number]
   Assignee: [assignee]  •  Inventor: [inventor]
   Filed: [filing_date]  •  Published: [publication_date]  •  [GRANT/APPLICATION]
   Status: [country_status summary, e.g. US: ACTIVE]
   [snippet — 1-2 line excerpt]
   [Optional: PDF link]
```

### Search Summary

When presenting a result list, lead with:

```
📊 [N] patents matched • [date range]
   Top assignees: [name (%)], [name (%)], [name (%)]
   Top CPC: [code (%)], [code (%)]
```

### Patent Detail Format

When presenting a single patent's full record:

```
📜 [Title]
   [publication_number] • [country] • [type]
   Filed [filing_date] • Priority [priority_date] • Published [publication_date]
   Inventors: [names]
   Assignees: [names]

📄 Abstract:
   [abstract]

⚖️ Independent Claims:
   1. [claim 1 text]
   [other independent claims]

🔗 Citations:
   Cites: [N original, M family-to-family]
   Cited by: [N original, M family-to-family]

🏷️ Classifications:
   [code] — [description]
   ...

🌍 Family: [N worldwide applications across [list of countries]]
```

## Common Patterns

### "Is there prior art for [invention]?"
1. Construct a `q` covering the key concepts with synonyms
2. Bound by `before=priority:[invention's priority date]`
3. Sort by relevance (default), scan titles and snippets
4. Drill into the top 3-5 via details for full claims and abstracts
5. Report whether close prior art exists

### "What patents does [company] hold for [technology]?"
1. Search with `assignee=[company]` and topic terms in `q`
2. Use `status=GRANT` if only enforceable rights matter
3. Read `summary.cpc` to confirm technology coverage
4. Present a portfolio summary with the top 10 by recency

### "Who's working on [technology]?"
1. Topic search via `q` with relevant terms or CPC codes
2. Read `summary.assignee` and `summary.inventor`
3. Present the top players ranked by filing volume
4. Optionally narrow by `country` for regional analysis

### "What's the citation graph for [patent]?"
1. Fetch details for the seed `patent_id`
2. Report direct citations (`patent_citations.original`) and forward citations (`cited_by.original`) with counts and top examples
3. Offer to expand into specific cited patents

### "How has filing activity in [field] changed over time?"
1. Decide on a topic query and a date type (usually `priority`)
2. Run the same query with annual `after`/`before` windows
3. Build a year-by-year table of `total_results`
4. Identify the inflection points

### "What's a patent family look like for [patent]?"
1. Fetch details for the patent
2. Group `worldwide_applications` by `country_code` and `legal_status`
3. Present a family map showing where protection is active

## Tips

- **Always use the returned `patent_id` verbatim** when chaining to the details engine. Don't reconstruct it.
- **Boolean operators are case-sensitive** — use uppercase `AND`, `OR`, `NOT`.
- **Use `;` to combine query facets** — keyword text + a CPC code as a separate facet often beats one giant `AND` chain.
- **Family deduplication is on by default.** A search for "cellular antennas" won't return the US, EP, and CN family members of the same invention — just one canonical entry. Set `dups=language` if you need per-language entries.
- **`priority_date` is the most stable date** for chronology — it doesn't change as the patent moves through prosecution.
- **`status=GRANT` filters out pending applications**, which matters for enforceability questions but hides early-signal research filings.
- **`country_status` in search results** shows the legal status per jurisdiction (`ACTIVE`, `NOT_ACTIVE`, `UNKNOWN`). Check it before relying on a patent as still in force.
- **Classifications are hierarchical.** A code like `G06N 3/08` is a leaf under `G06N 3/00` under `G06N`. Searching the broader code captures more.
- **`num=100` is the max per page** — use it to minimize pagination cost on large portfolio sweeps.
- **`clustered=true`** groups results by classification — useful when exploring a new technology area to understand its structure.
- **`scholar=true`** mixes Google Scholar results into the response — useful for academic prior art alongside patents.
- **Details responses are large.** When citing claims in user-facing output, lead with the independent claims; only include dependent claims if specifically requested.
- **Citation chains explode fast.** Always cap depth and breadth when traversing the graph.
- **`litigation=YES`** surfaces patents with known disputes — relevant for risk assessment.
- **Inventor and assignee names are messy.** Try common variants (e.g., `IBM` vs `International Business Machines`) if the first search looks incomplete.
