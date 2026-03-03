---
name: seo-auditor
description: >
  Specialized skill for producing actionable SEO audit reports by crawling a website and
  cross-referencing with competitor research. Use when: (1) auditing a website's SEO health,
  (2) finding missing or broken meta tags, thin content, or structural issues on a site,
  (3) identifying keyword gaps vs competitors, (4) checking for broken internal/external links,
  (5) analyzing a site's page structure and content quality for search optimization,
  (6) producing a prioritized list of SEO fixes, (7) comparing on-page SEO against competitor
  sites, (8) any task involving SEO analysis, site audit, or search optimization review.
  Builds on: firecrawl-setup (site crawling/scraping), exa (competitor and backlink research).
dependencies:
  - firecrawl-setup
  - exa
metadata: {"openclaw": {"emoji": "🔍", "requires": {"env": ["FIRECRAWL_API_KEY", "EXA_API_KEY"]}, "primaryEnv": "FIRECRAWL_API_KEY"}}
---

# SEO Auditor

Crawl a website, analyze on-page SEO issues, research competitors, and produce an actionable audit report with prioritized fixes.

## Foundational Skills Used

This skill builds on two foundational skills. Load them if you need API/CLI details:

- **firecrawl-setup** — Site crawling, page scraping, and content extraction via the Firecrawl CLI
- **exa** — Semantic web search for competitor research, backlink discovery, and content gap analysis

## Workflow Overview

```
Target URL → Map site → Crawl pages → Analyze on-page SEO → Research competitors → Synthesize report
```

The audit has two halves: **on-site analysis** (what's wrong with this site) and **competitive analysis** (what competitors do better). Both feed into a prioritized fix list.

---

### Step 1: Map the Site Structure

Use the **firecrawl-setup** skill to map all discoverable URLs on the target site.

- Map the root URL to get a full list of pages
- Optionally filter with a search term to focus on a specific section (e.g., "blog" or "products")
- Note the total page count — very large sites (500+ pages) should be sampled rather than fully crawled

**What to capture:** Full list of URLs, how deep the site goes (URL path depth), whether there's a logical hierarchy.

### Step 2: Crawl Key Pages

Use the **firecrawl-setup** skill to scrape the most important pages. Prioritize:

1. **Homepage** — always
2. **Top-level navigation pages** — main sections (about, products, blog, contact)
3. **Blog/content pages** — sample 5-10 of the most recent
4. **Key landing pages** — any pages the user specifically cares about

For each page, extract the content as markdown. The markdown output from Firecrawl includes the page structure (headings, links, images) which is exactly what you need for SEO analysis.

**What to extract per page:**
- Page title (from the `<title>` tag or metadata)
- Meta description
- H1, H2, H3 heading structure
- Internal and external links
- Image alt text presence
- Word count / content length
- URL structure (clean vs. messy)

### Step 3: Analyze On-Page SEO

For each crawled page, evaluate these SEO factors:

#### Title Tags
- Present? Unique across pages? (duplicate titles are a major issue)
- Length: 50-60 characters is optimal
- Contains primary keyword?
- Compelling for click-through?

#### Meta Descriptions
- Present? Unique across pages?
- Length: 150-160 characters optimal
- Contains call-to-action or value proposition?
- Missing descriptions = missed opportunity for every page

#### Heading Structure
- Exactly one H1 per page?
- H1 matches the page topic and includes target keyword?
- Logical heading hierarchy (H1 → H2 → H3, no skipping levels)?
- Are headings descriptive or generic ("Read More", "Welcome")?

#### Content Quality
- **Thin content:** Pages with < 300 words (excluding navigation/footer). Flag these.
- **Duplicate/near-duplicate content:** Similar content across multiple pages
- **Keyword presence:** Does the content naturally include relevant search terms?
- **Readability:** Wall-of-text pages with no headings, lists, or formatting

#### Internal Linking
- Orphan pages (pages not linked from elsewhere on the site)
- Pages with very few internal links pointing to them
- Broken internal links (404s found during crawl)
- Anchor text quality (descriptive vs "click here")

#### URL Structure
- Clean, readable URLs vs. parameter-heavy or cryptic ones
- Consistent URL pattern across the site
- Excessive URL depth (more than 3-4 levels)

#### Images
- Missing alt text (accessibility + SEO issue)
- Generic alt text ("image1.jpg", "photo", "untitled")
- Very large images that might impact page speed

### Step 4: Check for Broken Links

During the crawl in Step 2, note any pages that returned errors. Additionally:

- Look for links in the crawled content that point to pages not found in the site map
- External links that may be broken (note: you can verify external links by attempting to scrape them with the firecrawl-setup skill — a failed scrape suggests a broken link)
- Redirect chains (URLs that redirect multiple times before reaching the final page)

### Step 5: Competitor Research

Use the **exa** skill to research the competitive landscape:

#### Find Competitors
- Search for the target site's primary keywords to see who ranks
- Use Exa's semantic search to find sites similar to the target (the `findSimilar` endpoint is ideal here)
- Identify 3-5 direct competitors from the results

#### Analyze Competitor Content
- For each competitor, search for their content in the same topic areas as the target site
- Compare: Do competitors cover topics the target site doesn't? (content gaps)
- Compare: Do competitors have deeper/longer content on shared topics?
- Check if competitors have content hubs or topic clusters the target site lacks

#### Keyword Gap Analysis
- Search Exa for the target site's core topics — who else appears?
- Identify topics where competitors have coverage but the target site has nothing
- Look for keywords/topics that are trending (recent publish dates) that the target site hasn't addressed

#### Backlink Signals
- Use Exa to search for mentions of the target site and competitor sites
- Compare: Who gets more mentions/citations?
- Look for link-worthy content types competitors publish that the target doesn't (studies, tools, infographics)

### Step 6: Synthesize the Report

Combine all findings into a structured report. **Prioritize fixes by impact and effort:**

**Priority Matrix:**
| Impact | Effort | Priority |
|--------|--------|----------|
| High | Low | 🔴 Critical — fix immediately |
| High | High | 🟠 Important — plan and execute |
| Low | Low | 🟡 Quick win — batch these |
| Low | High | ⚪ Backlog — do if time permits |

---

## Output Format

```markdown
# SEO Audit Report: [Site Name]
**URL:** [target URL]
**Date:** [audit date]
**Pages Analyzed:** [count]

## Executive Summary
[2-3 sentence overview: overall SEO health, biggest issues, top opportunities]

**Overall Score: [X/100]**
- Technical SEO: [X/10]
- Content Quality: [X/10]
- On-Page Optimization: [X/10]
- Internal Linking: [X/10]
- Competitive Position: [X/10]

## 🔴 Critical Issues (High Impact, Fix Now)

### 1. [Issue Title]
**Affected pages:** [count or list]
**Problem:** [what's wrong]
**Impact:** [why it matters for SEO]
**Fix:** [specific action to take]

### 2. ...

## 🟠 Important Issues (High Impact, Requires Effort)

### 1. [Issue Title]
...

## 🟡 Quick Wins (Low Effort Improvements)

### 1. [Issue Title]
...

## ⚪ Backlog (Lower Priority)

### 1. [Issue Title]
...

## Page-by-Page Analysis

| Page | Title | Meta Desc | H1 | Content | Links | Issues |
|------|-------|-----------|----|---------|-------|--------|
| /    | ✅ 55 chars | ❌ Missing | ✅ | ✅ 1200 words | 12 internal | Meta desc |
| /about | ✅ 42 chars | ✅ 148 chars | ❌ 2 H1s | ⚠️ 280 words | 3 internal | Thin, dual H1 |
| /blog/... | ... | ... | ... | ... | ... | ... |

## Competitor Comparison

| Factor | [Target] | [Competitor 1] | [Competitor 2] |
|--------|----------|----------------|----------------|
| Content depth | ... | ... | ... |
| Topic coverage | ... | ... | ... |
| Content freshness | ... | ... | ... |
| Mentions/citations | ... | ... | ... |

## Content Gap Opportunities

1. **[Topic]** — [Competitor] covers this, target site doesn't. Search volume signal: [evidence]
2. ...

## Keyword Opportunities

1. **[Keyword/topic]** — [why it's an opportunity, who ranks, what to create]
2. ...

## Technical Notes
- Total pages discovered: [X]
- Pages with errors: [X]
- Broken links found: [X]
- Average content length: [X words]
```

## Scoring Guide

Score each category 1-10 based on what you find:

| Category | 8-10 | 5-7 | 1-4 |
|----------|------|-----|-----|
| Technical SEO | No broken links, clean URLs, fast-loading indicators | Few broken links, mostly clean URLs | Many broken links, messy URLs, errors |
| Content Quality | All pages 500+ words, well-structured, unique | Most pages adequate, some thin | Many thin/duplicate pages, poor structure |
| On-Page Optimization | All pages have unique titles, meta descs, proper H1s | Most pages optimized, some gaps | Widespread missing/duplicate metadata |
| Internal Linking | Strong cross-linking, no orphans, descriptive anchors | Adequate linking, few orphans | Poor linking, many orphans, generic anchors |
| Competitive Position | Strong coverage, few gaps, unique content angles | Decent coverage, some gaps | Major content gaps, competitors far ahead |

**Overall score** = average of category scores × 10

## Tips

- **Start with the map.** The site map tells you a lot before you scrape a single page — URL structure, depth, section organization.
- **Sample large sites.** For sites with 100+ pages, crawl the homepage, top-level pages, and a random sample of 10-15 content pages. Don't try to crawl everything.
- **Duplicate titles are the #1 easy find.** Most sites have them, and they're easy to fix. Always check.
- **Meta descriptions matter more than people think.** They're the sales copy in search results. Missing = Google writes one for you (usually badly).
- **Don't overcount competitor backlinks.** Exa gives you mention signals, not exact backlink counts. Use it for directional comparison, not precise metrics.
- **Content length isn't everything.** A 300-word page that perfectly answers a query beats a 2000-word page that rambles. Flag thin content but consider intent.
- **Group fixes by page.** The report prioritizes by issue type, but when the user goes to fix things, they'll work page by page. The page-by-page table helps with that.
- **Be specific in fix recommendations.** "Improve meta descriptions" is useless. "Add a meta description to /about that includes 'digital marketing agency in Austin' and a call-to-action" is actionable.

## Variations

### Quick Audit (5-10 pages)
Skip the competitor research. Map the site, scrape the top 5-10 pages, analyze on-page factors only. Good for a fast health check.

### Competitive Focus
Light on-site audit (homepage + 3-4 pages), heavy competitor research. Good when the user knows their site is okay but wants to find opportunities.

### Content Audit Only
Focus on content pages (blog, resources). Assess content quality, topic coverage, freshness, and gaps vs competitors. Skip technical SEO factors.
