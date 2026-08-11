---
name: serp-google-jobs
display_name: Google Jobs
description: >
  Specialized skill for Google Jobs workflows via SerpApi — job search, remote filtering,
  posted-date filtering, employment-type filtering, salary filtering, employer targeting,
  apply-link extraction, and labor-market analysis. Use when: (1) searching for jobs by
  title, role, or keyword in a specific location, (2) filtering for remote / work-from-home
  positions, (3) filtering by date posted (last 24 hours, 3 days, week, month), (4) filtering
  by employment type (full-time, part-time, contract, internship), (5) filtering by salary
  range, (6) targeting jobs at specific employers or companies, (7) paginating through large
  result sets via next_page_token, (8) extracting apply links and application channels,
  (9) analyzing job market trends and demand for a role or skill, (10) comparing hiring
  activity across cities or companies, (11) building a job-feed for a candidate, (12) any
  task involving Google Jobs listings. This skill builds on the foundational serpapi skill
  for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "💼"}}
---

# Google Jobs Workflows

Job search, filtering, apply-link extraction, and market analysis via SerpApi's Google Jobs engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engine: `google_jobs`)

## Core Concepts

### Query Anatomy

A Google Jobs search needs two ingredients: **what** (the role) and **where** (the location).

- **`q`** — Free-text query: job title, keywords, skills (e.g., `"Java Developer"`, `"barista new york"`, `"product manager fintech"`). You can embed location here, but the `location` parameter is more reliable.
- **`location`** — City-level origin point for the search (e.g., `"Austin, Texas"`, `"London, United Kingdom"`). Cannot be combined with `uule`.
- **`lrad`** — Search radius in kilometers around the location. Soft limit — Google may still return jobs outside the radius.
- **`gl`** — Country code (e.g., `us`, `uk`, `de`). Match to the target market.
- **`hl`** — Language code (e.g., `en`, `es`, `fr`).

### Filters: `uds` vs `chips` vs `ltype`

Google has shifted filter mechanics over time. SerpApi exposes three approaches:

| Mechanism | Status | When to Use |
|-----------|--------|-------------|
| `uds` | **Preferred** | Modern Google filter system. Values come from the `filters[]` array in a previous response. Supports chaining (combine multiple filters from the same category). |
| `chips` | Deprecated by Google | Older filter param. Still works in some cases; fall back if `uds` isn't available. |
| `ltype=1` | Deprecated by Google | Quick toggle for remote-only. Try the `Remote` filter via `uds` first; use `ltype=1` as a backup. |

**Pattern:** First call returns a `filters[]` array. Each option includes a `uds` value you pass to the next call to refine results.

### Response Structure

A search returns:

- **`jobs_results[]`** — Up to 10 jobs per page. Each job has:
  - `title` — Position title
  - `company_name` — Employer
  - `location` — Job location (or `"Anywhere"` for remote)
  - `via` — Source job board (e.g., `"via LinkedIn"`, `"via Indeed"`, `"via ZipRecruiter"`)
  - `description` — Full job description
  - `extensions[]` — Badge strings (e.g., `"25 days ago"`, `"Full-time"`, `"Health insurance"`)
  - `detected_extensions` — Parsed metadata object (see below)
  - `job_highlights[]` — Structured sections: `{ title: "Qualifications" | "Responsibilities" | "Benefits", items: [...] }`
  - `apply_options[]` — Application channels: `{ title, link }` pairs (e.g., Indeed, LinkedIn, company site)
  - `share_link` — Google Jobs detail page URL
  - `thumbnail` — Company logo (when available)
  - `job_id` — Base64-encoded identifier
- **`filters[]`** — Available refinement categories with `uds` values
- **`serpapi_pagination.next_page_token`** — Token for the next page (when more results exist)

### `detected_extensions` Object

Parsed structured data from each listing. Common fields:

| Field | Type | Example |
|-------|------|---------|
| `posted_at` | string | `"25 days ago"`, `"3 days ago"` |
| `schedule_type` | string | `"Full-time"`, `"Part-time"`, `"Contractor"`, `"Internship"` |
| `work_from_home` | boolean | `true` for remote |
| `salary` | string | `"$80K–$120K a year"` (when listed) |
| `health_insurance` | boolean | Benefit flags |
| `dental_coverage` | boolean | |
| `paid_time_off` | boolean | |
| `qualifications` | string | Education / required experience summary |

Always prefer `detected_extensions` over parsing the raw `extensions[]` strings.

### Pagination

Google Jobs uses **token-based pagination**, not offset:

1. First call returns up to 10 jobs and a `serpapi_pagination.next_page_token`
2. Pass that token as `next_page_token` in the next call
3. Continue until no `next_page_token` is returned

The deprecated `start` parameter does not work — always use the token.

## Workflows

### 1. Basic Job Search by Title + Location

Use the **serpapi** skill's wrapper script with the `google_jobs` engine.

**Required:**
- `q` — Job title or keywords
- `location` — City / region

**Recommended:**
- `gl` and `hl` — Match the target market for localized listings

**Presentation pattern:** Show the top 5-10 jobs with title, company, location, posted date, employment type, and a direct apply link.

### 2. Remote-Only Filtering

Two ways to filter for remote jobs:

**Preferred — via `uds`:**
1. Run an initial search
2. Inspect `filters[]` for a category named `"Remote"` or `"Work from home"`
3. Grab the `uds` value of the remote option
4. Re-run the search with `uds` set to that value

**Fallback — via `ltype`:**
- Set `ltype=1` to force remote-only results (deprecated but often still works)

**Detection in results:** Even without filtering, `detected_extensions.work_from_home === true` flags remote roles, and `location` often shows `"Anywhere"`.

### 3. Posted-Date Filtering

Filter by recency to surface fresh listings.

**Approach:**
1. Run an initial search
2. Find the `"Date posted"` category in `filters[]`
3. Select the desired option (`"Past 24 hours"`, `"Past 3 days"`, `"Past week"`, `"Past month"`)
4. Re-run with the option's `uds` value

**Quick reference of typical date filters:**

| Filter Option | Typical Use |
|---------------|-------------|
| Past 24 hours | Real-time job alerts |
| Past 3 days | Daily candidate digest |
| Past week | Weekly opportunity scan |
| Past month | Broader market sweep |

**Tip:** For tracking newly-posted roles over time, store the `job_id` of seen jobs and diff against new searches.

### 4. Employment-Type Filtering

Filter for full-time, part-time, contract, or internship roles.

**Approach:** Use the `"Job type"` filter from `filters[]` and pass its `uds` value.

**Or filter client-side** using `detected_extensions.schedule_type` from a broader search:

```
schedule_type values: "Full-time", "Part-time", "Contractor", "Internship"
```

**When to filter client-side vs server-side:**
- Server-side (`uds`) — Single employment type; more efficient
- Client-side — Need to count or compare multiple types in one pass

### 5. Salary Filtering

Filter for jobs above a salary threshold.

**Approach:** Look for `"Salary"` in `filters[]` — options typically include thresholds like `"$60,000+"`, `"$80,000+"`, `"$100,000+"`. Pass the chosen option's `uds`.

**Note:** Not all listings publish salary. `detected_extensions.salary` will be missing on those — they may still appear in salary-filtered results based on Google's estimates.

**For salary analysis:** Pull jobs without a salary filter, then bucket by parsed `detected_extensions.salary` strings client-side.

### 6. Employer / Company Filtering

Target jobs at specific employers.

**Two approaches:**

**A — Filter via `uds`:** The `"Company"` (or `"Employer"`) filter in `filters[]` lists top employers in the result set. Pick one and pass its `uds`.

**B — Embed in query:** Add the company name to `q` (e.g., `q="software engineer Google"`). Less precise but works when the employer isn't in the filter list.

**Pattern:** For a focused company watch, do (A) once to learn the employer's filter `uds`, then reuse it for ongoing searches.

### 7. Pagination Through Large Result Sets

Collect all jobs (or a large sample) for a query.

**Loop:**
1. First call with `q`, `location`, filters
2. Read `jobs_results[]` and `serpapi_pagination.next_page_token`
3. While `next_page_token` exists: call again with `next_page_token` set, append results
4. Stop when no token or when you hit your sample target

**When to paginate fully vs sample:**

| Goal | Strategy |
|------|----------|
| Top matches for a candidate | First 1-3 pages (10-30 jobs) |
| Daily candidate digest | First 2 pages |
| Market analysis | 5-20 pages (50-200 jobs) for stats |
| Comprehensive scrape | Paginate to completion — token loop |

**Cost note:** Each page is one SerpApi credit. Cap deep pagination at the analysis goal.

### 8. Extracting Apply Links

Each job's `apply_options[]` array lists application channels:

```
apply_options: [
  { title: "LinkedIn", link: "https://www.linkedin.com/jobs/view/..." },
  { title: "Indeed",   link: "https://www.indeed.com/viewjob?..." },
  { title: "Company site", link: "https://careers.example.com/..." }
]
```

**Best practice:**
- Prefer the company site link when present (no third-party account required)
- Otherwise prefer LinkedIn, then Indeed
- Always include the `share_link` as a Google Jobs fallback

### 9. Job Market Trend Analysis

Measure demand for a role, skill, or location.

**Strategy:**
1. Run a baseline search (`q="role"`, `location="city"`) — paginate 3-10 pages
2. Aggregate counts by:
   - Employer (`company_name`)
   - Recency (`detected_extensions.posted_at`)
   - Salary band (`detected_extensions.salary`)
   - Schedule type (`detected_extensions.schedule_type`)
   - Remote vs onsite (`detected_extensions.work_from_home`)
3. Repeat for comparable roles or cities and compare totals

**What to report:**
- Total open roles found (mind pagination depth)
- Top hiring employers
- Distribution of salaries (when published)
- % remote vs onsite
- Freshness — how many posted in the last week

### 10. Comparing Demand Across Skills, Titles, or Cities

Run parallel searches and compare result counts and characteristics.

**Example — "Rust vs Go developer demand":**
1. Search `q="rust developer"`, `location="San Francisco, CA"` — collect N pages
2. Search `q="go developer"`, `location="San Francisco, CA"` — collect N pages
3. Compare:
   - Total listings (same pagination depth)
   - Salary distributions
   - Top employers
   - Remote availability %

**Example — "Where is data science hiring most?":**
- Run the same `q="data scientist"` across 5+ cities, equal pagination depth
- Rank cities by total listings, % remote, salary medians

## Filter Quick Reference

| Goal | Mechanism | Notes |
|------|-----------|-------|
| Remote only | `uds` (`Remote` filter) or `ltype=1` | `ltype` is a fallback |
| Posted last 24h | `uds` (`Date posted` → `Past 24 hours`) | |
| Posted last 3 days | `uds` (`Date posted` → `Past 3 days`) | |
| Posted last week | `uds` (`Date posted` → `Past week`) | |
| Posted last month | `uds` (`Date posted` → `Past month`) | |
| Full-time only | `uds` (`Job type` → `Full-time`) | |
| Part-time only | `uds` (`Job type` → `Part-time`) | |
| Contract roles | `uds` (`Job type` → `Contractor`) | |
| Internships | `uds` (`Job type` → `Internship`) | |
| Salary ≥ $X | `uds` (`Salary` filter) | Options vary by market |
| Specific employer | `uds` (`Company` filter) or in `q` | |
| Radius around city | `lrad=<km>` | Soft limit |
| Different country | `gl` + `location` | Match both |

## Presenting Results

### Single Job Format

```
💼 [Title] — [Company]
   📍 [Location] [• Remote if work_from_home]
   💰 [Salary if present]
   ⏱️  [posted_at] • [schedule_type]
   🔗 Source: [via] · Apply: [best apply_options link]
```

### Job List Format

```
💼 [N] [role] jobs in [location]

1. [Title] — [Company]
   📍 [Location] • ⏱️ [posted_at] • [schedule_type]
   💰 [salary or "Salary not listed"]
   → [apply link]

2. [Title] — [Company]
   ...
```

### Market Snapshot Format

```
📊 [Role] hiring in [Location]

Total listings (top N pages): [count]
Posted in last 7 days:        [count] ([%])
Remote-friendly:              [count] ([%])

Top employers:
  1. [Company A] — [N] roles
  2. [Company B] — [N] roles
  3. [Company C] — [N] roles

Salary distribution (where listed):
  $60-80K:   ▇▇ [N]
  $80-100K:  ▇▇▇▇ [N]
  $100-150K: ▇▇▇▇▇▇ [N]
  $150K+:    ▇▇▇ [N]

Schedule mix:
  Full-time: [%] · Part-time: [%] · Contract: [%] · Intern: [%]
```

## Common Patterns

### "Find me [role] jobs in [city]"
1. Search with `q="role"`, `location="city"`, `gl`/`hl` for the market
2. Present top 5-10 from page 1
3. Offer to filter by date posted, remote, or employment type

### "Remote [role] jobs posted this week"
1. Initial search to discover filters
2. Apply `uds` for `Remote` + `Date posted: Past week`
3. Present results with apply links

### "Who is hiring [role] in [city]?"
1. Paginate 3-5 pages
2. Aggregate by `company_name`
3. Rank employers by listing count, show top 10

### "Compare [skill A] vs [skill B] demand"
1. Two parallel searches, equal pagination depth, same location
2. Compare listing counts, salaries, top employers
3. Present a side-by-side market snapshot

### "Build a daily job digest for [candidate]"
1. Search with candidate's role + location
2. Apply `Date posted: Past 24 hours` filter
3. Optionally filter by salary or remote based on preferences
4. Present each job with apply link; cache `job_id`s to avoid re-showing tomorrow

### "Where should I move for [role] work?"
1. Run the same `q` across 5-10 candidate cities
2. Compare: listing volume, remote %, salary medians, top employers
3. Recommend cities by the user's priorities

## Tips

- **Filters are dynamic.** The `filters[]` array depends on the query and location. Always inspect it on the first call rather than hard-coding `uds` values.
- **`uds` beats `chips`.** Google deprecated `chips`. Prefer `uds` from the response `filters[]` for any refinement.
- **Token-based pagination only.** Don't try `start` or `offset` — only `next_page_token` works.
- **10 jobs per page.** Plan pagination accordingly. Five pages = up to 50 jobs.
- **`detected_extensions` is structured gold.** Parse it instead of regexing `extensions[]` strings.
- **Salary is often missing.** Many listings omit salary. Report counts of listings with and without salary in market analyses.
- **`via` reveals the source.** Useful for routing applicants to their preferred job board, or for excluding spammy aggregators.
- **`apply_options` order matters.** Surface company-direct links first; they have higher trust and no third-party account barrier.
- **Localize for international markets.** Set both `gl` (country) and `hl` (language) — `gl=de, hl=de` for German listings, etc.
- **`location` over query embedding.** Pass city via `location` rather than stuffing it in `q` — more reliable matching.
- **Watch for `"Anywhere"` in location.** This is Google's signal for remote — combine with `work_from_home` for confirmation.
- **Cache `job_id`s** when running recurring searches (digests, alerts) to dedupe across runs.
- **Page-1 results are highest relevance.** For candidate-facing summaries, depth past page 3 rapidly drops in quality.
