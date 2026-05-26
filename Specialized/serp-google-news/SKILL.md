---
name: serp-google-news
display_name: Google News
description: >
  Specialized skill for Google News workflows via SerpApi — keyword search, topic monitoring,
  full-story coverage, publication feeds, regional targeting, and cross-source analysis.
  Use when: (1) searching news articles by keyword or query, (2) monitoring a topic
  (World, Business, Technology, Sports, etc.) via topic_token, (3) drilling into a story
  for full coverage across multiple outlets via story_token, (4) pulling articles from a
  specific publisher via publication_token, (5) navigating sub-sections of a topic via
  section_token, (6) tracking breaking news with date-sorted results, (7) comparing
  coverage and framing of the same story across sources, (8) regional or multilingual news
  monitoring via gl/hl, (9) building news briefings or daily digests, (10) tracking a
  story's evolution over time, (11) any task involving Google News search, headlines, or
  source comparison. This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📰"}}
---

# Google News Workflows

News search, topic monitoring, story coverage, and cross-source comparison via SerpApi's Google News engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engine: `google_news`)

## Core Concepts

### Navigation Model

Google News is **token-driven**, not page-numbered. Every response surfaces tokens you can feed back into a follow-up request to navigate deeper. There are four token types:

| Token | Purpose | Found In |
|-------|---------|----------|
| `topic_token` | A topic feed (World, Business, Tech, etc.) | `news_results[].topic_token`, `menu_links[]`, `related_topics[]` |
| `section_token` | A sub-section of a topic or publication | `sub_menu_links[]` |
| `story_token` | Full coverage of a single story across outlets | `news_results[].story_token`, `news_results[].stories[].story_token` |
| `publication_token` | Articles from one publisher only | `related_publications[]`, URL after `/publications/` |

**Important:** `q`, `topic_token`, `publication_token`, `section_token`, and `story_token` are **mutually exclusive**. Use one at a time. `kgmid` cannot be combined with any of them.

### Request Parameters

| Parameter | Purpose | Notes |
|-----------|---------|-------|
| `q` | Keyword query | Supports `site:` and `when:` operators (e.g., `bitcoin when:7d`) |
| `gl` | Country code | `us`, `uk`, `fr`, `de`, `in`, `jp`, `br`, ... Defaults to `us` |
| `hl` | Language code | `en`, `es`, `fr`, `de`, `ja`, `zh`, `ar`, ... |
| `topic_token` | Topic feed | See Topics below |
| `section_token` | Sub-section | Combine with `topic_token` or `publication_token` |
| `story_token` | Full story coverage | Returns multi-outlet reporting on one event |
| `publication_token` | Single publisher feed | Pair with `section_token` for that publisher's sub-section |
| `so` | Sort | `0` = relevance (default), `1` = date (newest first) |
| `no_cache` | Bypass cache | `true` for fresh results (otherwise 1-hour cache) |

### Response Structure

A query returns these top-level fields:

- **`title`** — Page title (set on topic/publication views)
- **`top_stories_link`** — Link object for the top-stories section
- **`news_results[]`** — Primary article array
- **`menu_links[]`** — Topic navigation (U.S., World, Business, Tech, ...) with `topic_token`
- **`sub_menu_links[]`** — Section navigation within the current view
- **`related_topics[]`** — Suggested topics with `topic_token`
- **`related_publications[]`** — Suggested publishers with `publication_token`

Each item in `news_results[]` may contain:

```
position             — Rank in the feed (1, 2, 3, ...)
title                — Headline
link                 — Article URL
snippet              — Article excerpt
date                 — Human-readable date
iso_date             — ISO 8601 timestamp
source.name          — Publisher name (e.g., "Reuters")
source.icon          — Publisher favicon URL
source.authors[]     — Author names (when present)
thumbnail            — Full-resolution image
thumbnail_small      — Low-res thumbnail
video                — Boolean — true if the article is a video
type                 — Classification ("Opinion", "Local coverage", ...)
topic_token          — Topic deeplink token
story_token          — Story coverage deeplink token
publication_token    — Publisher deeplink token
serpapi_link         — Pre-built SerpApi follow-up URL
highlight{}          — Featured/primary version of a grouped story
stories[]            — Alternative coverage on the same story
                       (each has source, title, link, snippet, story_token)
```

### Topics

Common topic categories accessible via `topic_token`:

| Topic | Typical Use |
|-------|-------------|
| U.S. | Domestic news (when `gl=us`) |
| World | International coverage |
| Business | Markets, companies, economy |
| Technology | Tech industry, products, AI |
| Entertainment | Film, TV, music, celebrity |
| Sports | Athletics, leagues, events |
| Science | Research, space, climate |
| Health | Medicine, wellness, pandemics |

**Topic tokens are opaque, long base64-like strings.** Do not hardcode them — discover them dynamically by first calling the API with no advanced parameter, then reading `menu_links[]` or `related_topics[]` from the response.

### Story vs. Article

A single news event may have many articles across outlets. Google News groups them:

- A `news_results[]` entry with a `story_token` represents the **event**.
- Its `stories[]` array (and the `highlight` object) lists alternative reportings.
- Following the `story_token` returns the **full coverage** view: dozens of outlets, sometimes organized into sections (Top news, By the numbers, FAQs, Posts on X, etc.).

Use `story_token` whenever the user wants to **read about an event from multiple angles**, not just one source.

## Workflows

### 1. Keyword Search

The bread-and-butter use case: search news for a query.

Use the **serpapi** skill's wrapper script with the `google_news` engine.

**Key parameters:**
- `q` — The search query
- `gl`, `hl` — Country and language
- `so` — `1` for newest first, `0` (default) for relevance

**Query operators:**
- `site:reuters.com` — Restrict to one domain
- `when:7d` — Last 7 days (also `1h`, `1d`, `1w`, `1m`, `1y`)
- Quotes for exact phrase: `"large language model"`
- `OR`, `-` for boolean logic

**Presentation pattern:** Top 5-10 headlines with source, time, and a one-line snippet. See "Presenting Results" below.

### 2. Topic Monitoring

Pull the current feed for a topic (e.g., Technology, Business).

**Two-step discovery:**
1. First call: no advanced parameter (or a generic `q`). Read `menu_links[]` or `related_topics[]` to find the `topic_token` for the desired topic.
2. Second call: pass that `topic_token`. The response is the curated feed for that topic.

**Why two steps?** Topic tokens are opaque and may rotate. Always discover them from a live response rather than caching.

**Use `so=1`** to sort by date — useful for "what's happening right now in [topic]?"

### 3. Full Story Coverage

When a user wants the complete picture of a single event, use `story_token`.

**Workflow:**
1. Find the event — either from a keyword search (`q`) or topic feed.
2. Locate a `news_results[]` item with a `story_token` (or pull one from its `stories[]`).
3. Make a second request with `story_token` set. Drop `q` and other advanced params.
4. The response returns the multi-outlet view. Use `so=1` to sort coverage chronologically.

**What to surface:** The `highlight` article first (Google's chosen primary), then 5-10 alternative outlets covering the same event. Note any divergence in framing or facts.

### 4. Publication Feed

Pull articles from a specific publisher.

**Workflow:**
1. Search or browse a topic. In `related_publications[]` or on individual articles, look for `publication_token`.
2. Call with `publication_token` set. The response is that publisher's feed.
3. Optionally combine with `section_token` from `sub_menu_links[]` to drill into one of their sections (e.g., BBC → Business).

**When to use:**
- "What is the New York Times reporting today?"
- "Pull the latest from Bloomberg."
- Building a single-source briefing.

### 5. Sub-Section Navigation

Topics have sub-sections (Business → Economy, Markets, Personal Finance). Publications have sections too (For You, Business, World).

**Workflow:**
1. Fetch the parent view (topic or publication).
2. Read `sub_menu_links[]` — each entry has a `section_token`.
3. Call with that `section_token` to enter the sub-section. Pair with the parent `topic_token` or `publication_token` if required.

### 6. Breaking News Monitoring

Real-time tracking of a developing event.

**Strategy:**
- Use `q` with a tight keyword and `so=1` (sort by date).
- Add `when:1h` or `when:1d` to the query for very recent items.
- Set `no_cache=true` to force fresh results.
- Re-poll on an interval — check `iso_date` on the top item to detect new headlines.

When the event consolidates into a single story, switch to `story_token` for full coverage.

### 7. Cross-Source Coverage Analysis

Compare how outlets frame the same event.

**Strategy:**
1. Find the event via `q` or a topic feed.
2. Pull its `story_token`.
3. From the full-coverage response, extract every article's `title`, `source.name`, `snippet`, and `iso_date`.
4. Group by source. Look for divergent framing:
   - Headline tone (neutral vs. charged language)
   - Which facts each outlet emphasizes
   - Whose voices are quoted
   - Local vs. national vs. international perspective

**Presentation pattern:**
```
📰 Story: [Event title]
🕒 First reported: [earliest iso_date]
📡 Coverage: [N] outlets

| Source     | Time       | Headline framing                |
|------------|-----------|---------------------------------|
| Reuters    | 2h ago    | [neutral headline]              |
| Fox News   | 1h ago    | [charged headline]              |
| BBC        | 3h ago    | [contextual headline]           |
| Al Jazeera | 4h ago    | [regional-perspective headline] |

🎯 Divergence:
  - [Source A] emphasizes [X]
  - [Source B] emphasizes [Y]
  - Only [Source C] mentions [Z]
```

### 8. Regional & Multilingual Monitoring

Same story, different regions or languages.

**Strategy:**
- Run the same `q` (or topic) multiple times, varying `gl` and `hl`:
  - `gl=us, hl=en` — US English
  - `gl=uk, hl=en` — UK English
  - `gl=fr, hl=fr` — France, French
  - `gl=in, hl=en` — India, English
  - `gl=jp, hl=ja` — Japan, Japanese
- Compare which outlets surface, which stories rank, and what framing each region uses.

**Use cases:**
- International PR monitoring for a brand.
- Geopolitical coverage analysis.
- Tracking diaspora-relevant stories.

### 9. Story-Over-Time Tracking

How a story evolves across days or weeks.

**Strategy:**
1. Establish the keyword(s) for the story.
2. Run `q` searches with `when:1d`, `when:1w`, `when:1m` to scope different windows.
3. For each window, sort by date (`so=1`) and capture the top articles with their `iso_date` and source.
4. Plot a timeline: when did each outlet first cover it? When did coverage peak?
5. If a single canonical story emerges, capture its `story_token` and revisit it on subsequent runs to detect new entries.

**What to look for:**
- **Coverage volume curve** — spike days vs. cooling.
- **Source migration** — story starts in one outlet, spreads to wires, then mainstream.
- **Narrative shifts** — when framing changes, what new fact triggered it.

### 10. Daily News Briefing

Build a personalized digest.

**Recipe:**
1. Define topics of interest (e.g., Technology, Business, World).
2. Discover their `topic_token`s once.
3. For each topic, fetch the feed with `so=1`.
4. Take the top 3-5 stories per topic.
5. For any breaking story (high freshness, multiple outlets), follow its `story_token` and add a "Full Coverage" note.
6. Output a structured briefing (see Presenting Results).

## Filter & Param Quick Reference

| Goal | Parameter | Value |
|------|-----------|-------|
| Sort by newest | `so` | `1` |
| Sort by relevance | `so` | `0` |
| Last hour | `q` | `keyword when:1h` |
| Last 7 days | `q` | `keyword when:7d` |
| One domain | `q` | `keyword site:nytimes.com` |
| Exact phrase | `q` | `"large language model"` |
| Boolean OR | `q` | `apple OR google` |
| Exclude word | `q` | `apple -fruit` |
| Topic feed | `topic_token` | (from `menu_links[]`) |
| Sub-section | `section_token` | (from `sub_menu_links[]`) |
| Full story | `story_token` | (from `news_results[].story_token`) |
| Publisher feed | `publication_token` | (from `related_publications[]`) |
| Region | `gl` | `us`, `uk`, `fr`, `de`, ... |
| Language | `hl` | `en`, `es`, `fr`, `ja`, ... |
| Fresh results | `no_cache` | `true` |

## Presenting Results

### Headline List Format

For each article, present:

```
📰 [Headline]
   [Source] · [Relative time] · [type if Opinion/Local]
   [Snippet — one or two lines]
   [URL]
```

### News Briefing Format

```
🗞️ News Briefing — [Date]

🌍 World
  1. [Headline] — [Source], [time ago]
     [One-line snippet]
  2. ...

💼 Business
  1. ...

💻 Technology
  1. ...

🔥 Developing Stories (full coverage available)
  • [Story title] — [N] outlets covering ([story_token noted])
```

### Full-Coverage Summary

```
📡 Full Coverage: [Story title]

Primary: [Highlight source] — [Highlight headline]
[Highlight snippet]

Also reporting:
  • [Source 1] ([time]) — [Headline]
  • [Source 2] ([time]) — [Headline]
  • [Source 3] ([time]) — [Headline]
  ...

🎯 Themes across coverage: [synthesized observation]
```

## Common Patterns

### "What's the latest on [topic]?"
1. Keyword search with `q=[topic]` and `so=1`.
2. Present top 5-10 headlines with source and time.
3. If a single story dominates, follow its `story_token` for fuller context.

### "Give me today's tech news"
1. Discover the Technology `topic_token` from a base call's `menu_links[]`.
2. Fetch with that `topic_token` and `so=1`.
3. Present top 5-8 headlines grouped by sub-theme if obvious.

### "How are different outlets covering [event]?"
1. Search for the event with `q`.
2. Find the `story_token` on the most relevant result.
3. Fetch with `story_token` (drop `q`).
4. Present cross-source comparison table — highlight framing divergence.

### "What is [publisher] reporting today?"
1. Find the `publication_token` (from `related_publications[]` in a topic feed, or via a `q` that returns articles from that source).
2. Fetch with `publication_token`.
3. Optionally drill into one of their `sub_menu_links[]` sections.

### "Track [story] for me over the next week"
1. Establish a stable keyword set.
2. On each poll: `q=keywords when:1d so=1 no_cache=true`.
3. Dedupe by URL or `story_token` across polls; flag newly appearing outlets.
4. When a `story_token` emerges, switch to story-coverage tracking.

### "What's the news in [country] right now?"
1. Set `gl` to the country and `hl` to its primary language.
2. Fetch with no advanced parameter to get that country's top stories.
3. Read `menu_links[]` for the local topic structure (it varies by region).

## Tips

- **Tokens are ephemeral.** Don't store `topic_token`, `story_token`, etc. for long. They may rotate. Always discover them from a fresh response.
- **`q` is mutually exclusive** with `topic_token`, `publication_token`, `section_token`, and `story_token`. Combining them produces unexpected results — pick one.
- **`kgmid` is fully isolated** — it cannot combine with any other advanced parameter.
- **Default sort is relevance.** For breaking news, always set `so=1`.
- **Use `when:` in the query** for fast time filtering — the API has no dedicated date-range parameter.
- **`no_cache=true` is not free.** Use sparingly. The 1-hour cache is free and fast.
- **`stories[]` inside a result** is the lighter-weight version of full coverage — preview it first to decide whether a full `story_token` call is worth it.
- **`highlight` is Google's editorial pick** for a grouped story — it's usually the strongest single article to lead with.
- **Watch `type: "Opinion"`** — distinguish editorials from straight reporting when summarizing.
- **`video: true`** items don't carry an article body — link out instead of attempting to summarize.
- **Localization matters for framing.** Running the same query across `gl=us`, `gl=uk`, `gl=in` often surfaces meaningfully different headlines, even in English.
- **`source.authors[]`** is not always populated — fall back to `source.name` for attribution.
- **`iso_date`** is the reliable timestamp — prefer it over the human-readable `date` for sorting and comparison.
- **Full coverage responses** can group articles into sections like "By the numbers", "FAQs", "Posts on X". Surface these as separate buckets when present — they're valuable structure.
