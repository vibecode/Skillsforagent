---
name: trend-spotter
description: >
  Specialized skill for spotting emerging trends by cross-referencing YouTube trending videos with
  web coverage via Exa. Use when: (1) identifying emerging trends or viral topics before they peak,
  (2) comparing YouTube popularity signals against web coverage depth, (3) finding topics that are
  hot on YouTube but under-covered on the web (emerging signals), (4) finding topics that are hot
  on both YouTube and web (peaking/saturated), (5) monitoring trend momentum across platforms,
  (6) scouting content gaps where YouTube interest outpaces written coverage, (7) any task involving
  cross-platform trend detection or signal comparison. Requires both serpapi-youtube and exa
  foundational skills. The unique value is cross-platform signal comparison: YouTube heat vs web
  depth reveals where a trend sits in its lifecycle.
dependencies:
  - serpapi
  - exa
metadata: {"openclaw": {"emoji": "📈", "requires": {"env": ["SERPAPI_API_KEY", "EXA_API_KEY"]}, "primaryEnv": "SERPAPI_API_KEY"}}
---

# Trend Spotter

Cross-reference YouTube trending signals with web coverage to classify where trends sit in their lifecycle. YouTube hot + web thin = emerging. Both hot = peaking. Web thick + YouTube cooling = declining.

## Dependencies

This skill builds on two foundational skills:
- **serpapi-youtube** — YouTube search, video details, and metadata via SerpApi
- **exa** — Semantic web search and content extraction

Load those skills if you need parameter details. This skill focuses on the **workflow logic**.

## Core Concept: Signal Comparison

Every topic generates signals on different platforms at different speeds:

| YouTube Signal | Web Signal | Classification | Opportunity |
|---------------|------------|----------------|-------------|
| 🔥 High views, many recent uploads | 📉 Few/no articles | **Emerging** | First-mover content, articles, analysis |
| 🔥 High views, many uploads | 📈 Many articles, deep coverage | **Peaking** | Differentiation needed, niche angles only |
| 📉 Views declining | 📈 Extensive coverage | **Declining** | Avoid unless doing retrospective |
| 📉 Low activity | 📉 Low coverage | **Niche/dormant** | Only if evergreen potential |

The key insight: YouTube creators move faster than writers. A topic with YouTube heat but thin web coverage is an **emerging trend** — there's a content gap you can fill.

## Workflow

### Step 1: Discover Trending Topics on YouTube

Use the **serpapi-youtube** skill to search YouTube for a topic area. Filter to recent uploads (this week) using the `sp=EgIIAw%3D%3D` parameter. The foundational skill has full API details — load it when you need endpoint specifics.

**What to extract from each result:**
- `title` — the topic/angle
- `views` (or `extracted_views`) — raw popularity
- `published_date` — recency
- `channel.name` and `channel.subscribers` — creator size (big creator ≠ trend; small creators going viral = signal)

**Strategies for finding trending content:**
- Search broad category terms filtered to "This week" (`sp=EgIIAw%3D%3D`)
- Search multiple related queries to triangulate
- Look for pattern: multiple creators covering the same topic = trend signal
- High view-to-age ratio (many views on a video only 1-2 days old) = strong signal
- Small channels getting unusual views = organic trend (vs. big channel hype)

### Step 2: Extract Topic Signals

From the YouTube results, identify candidate topics. A topic is a candidate if:
- Multiple independent creators uploaded about it recently (≥3 videos in past 7 days)
- At least one video has high engagement relative to the channel size
- The topic is specific enough to search for (not just "AI" but "AI agents for coding")

For each candidate topic, note:
- **YouTube heat score** (informal): How many recent videos? Total views across them? Growth velocity?
- **Topic query** — A clear search phrase to check web coverage

### Step 3: Check Web Coverage via Exa

Use the **exa** skill to search the web for written coverage of each candidate topic. The foundational skill has full API details — load it when you need endpoint specifics.

Search with these parameters:
- **Type:** `auto`
- **Category:** `news` (also try general for blog coverage)
- **Results:** 10
- **Date filter:** Start from ~2 weeks ago to match the YouTube window
- **Content extraction:** Use highlights with the topic query, max 500 characters per highlight

**What to assess:**
- **Result count** — How many relevant articles exist?
- **Source quality** — Major outlets vs. obscure blogs?
- **Publish dates** — Are articles mostly very recent (following YouTube), or older (YouTube is late)?
- **Depth** — Surface mentions vs. deep analysis?

**Coverage classification:**
- **Thin** (0-2 relevant articles in past 2 weeks): Web hasn't caught up
- **Moderate** (3-7 articles): Starting to get coverage, still opportunity
- **Thick** (8+ articles, major outlets): Well-covered, harder to stand out

### Step 4: Classify and Rank

For each candidate topic, combine the signals:

```
Topic: [name]
YouTube Heat: [High/Medium/Low] — [X videos this week, Y total views, Z avg view velocity]
Web Coverage: [Thin/Moderate/Thick] — [N articles found, quality summary]
Classification: [Emerging / Peaking / Declining / Niche]
Opportunity Score: [1-5] — higher = better content opportunity
Recommended Angle: [what kind of content would fill the gap]
```

**Scoring heuristic:**
- Emerging + Thin web = **5** (best opportunity)
- Emerging + Moderate web = **4**
- Peaking + Moderate web = **3** (need unique angle)
- Peaking + Thick web = **2** (saturated)
- Declining or Niche = **1**

## Output Format

Present results as a ranked table:

```
## Trend Report: [Category] — [Date]

### 🔥 Emerging (Act Now)
| Topic | YT Heat | Web Coverage | Score | Angle |
|-------|---------|-------------|-------|-------|
| ...   | ...     | ...         | 5     | ...   |

### 📊 Peaking (Differentiate)
| Topic | YT Heat | Web Coverage | Score | Angle |
|-------|---------|-------------|-------|-------|
| ...   | ...     | ...         | 3     | ...   |

### 📉 Declining (Skip)
| Topic | YT Heat | Web Coverage | Score | Angle |
|-------|---------|-------------|-------|-------|
| ...   | ...     | ...         | 1     | ...   |
```

## Tips

- **Run multiple searches.** A single YouTube query won't capture a full trend landscape. Search 3-5 related queries per category.
- **Check both `news` and general categories** in Exa. A topic might have blog coverage but no news coverage (or vice versa).
- **Time-box Exa searches** to match the YouTube window. If you're looking at YouTube videos from the past week, search Exa for the past 2 weeks (web lags slightly).
- **Channel diversity matters.** Five videos from one creator ≠ trend. Five videos from five different creators = trend.
- **Use Exa highlights** (`maxCharacters: 500`) to quickly assess article relevance without reading full content.
- **For niche topics**, use Exa's `includeText` parameter to require specific terms and reduce false positives.
- **Iterate the topic query.** If Exa returns irrelevant results, refine the query — the web may use different terminology than YouTube titles.

## Variations

### Niche monitoring
Pick a narrow category (e.g., "3D printing"), run weekly. Track which topics move between classifications over time.

### Competitor gap analysis
Search YouTube for a competitor's topic area. Find emerging topics they haven't covered on their blog yet.

### Content calendar
Run trend-spotter across 3-5 categories weekly. Use the emerging topics to plan content for the next week while they're still underserved on the web.
