---
name: yt-competitor-analysis
description: >
  Specialized skill for YouTube competitor analysis and content gap research. Use when:
  (1) analyzing competitors in a YouTube niche, (2) finding top-performing channels and videos
  for a topic, (3) identifying content gaps and opportunities in a market, (4) extracting
  competitor video strategies (topics, posting frequency, engagement), (5) researching what
  content is working in a space, (6) building a competitive landscape report for YouTube
  marketing. This skill builds on: serpapi, supadata, exa.
metadata: {"openclaw": {"emoji": "📊"}}
---

# YouTube Competitor Analysis

Analyze YouTube competitors in any niche — find who's creating content, what's performing, and where the gaps are. Combines YouTube search data, transcript extraction, and web research.

## Foundational Skills Used

This skill builds on three foundational skills. Load them for API details and wrapper scripts:

- **serpapi** — YouTube search, video details, channel data, transcripts (via `scripts/serpapi.sh`)
- **supadata** — Video transcripts and metadata extraction (via `scripts/supadata.sh`)
- **exa** — Web research for company/creator background info (via `scripts/exa.sh`)

## Workflow

### Step 1: Discover Competitors

Search YouTube for the niche to find active channels and top-performing videos.

Use the **serpapi** skill's `youtube` engine to search:

```bash
bash scripts/serpapi.sh youtube --search_query "NICHE_KEYWORDS"
```

This returns video results (title, channel, views, date, link) and channel results (title, handle, subscribers).

Run multiple searches with variations of the niche keywords to build a complete picture. Extract unique channel names from the video results.

### Step 2: Analyze Top Videos Per Competitor

For each competitor channel, search for their content and get video details.

Use the **serpapi** skill to search a channel's content and get video metrics:

```bash
# Search for a specific channel's content
bash scripts/serpapi.sh youtube --search_query "CHANNEL_NAME NICHE"

# Get detailed metrics on their top videos
bash scripts/serpapi.sh youtube_video --v "VIDEO_ID"
```

The video details include: title, views, likes, published date, description, and chapters.

Collect for each competitor:
- **Top videos** (by views)
- **Recent videos** (last 30-90 days)
- **Publishing frequency** (dates between videos)
- **Average engagement** (views, likes)
- **Content themes** (from titles and descriptions)

### Step 3: Extract Content Strategy (Transcripts)

Pull transcripts from top-performing videos to understand what topics and angles work.

Use the **supadata** skill to get transcripts:

```bash
bash scripts/supadata.sh yt-transcript --url "https://youtube.com/watch?v=VIDEO_ID"
```

If `SUPADATA_API_KEY` is not available, use the **serpapi** skill's transcript engine as fallback:

```bash
bash scripts/serpapi.sh youtube_video_transcript --v "VIDEO_ID"
```

From transcripts, identify:
- **Key topics** covered
- **Talking points** that recur across top videos
- **Content format** (tutorial, review, listicle, interview, etc.)
- **Call-to-actions** used

### Step 4: Research Competitor Background (Optional)

Use the **exa** skill to find company/creator info beyond YouTube:

```bash
bash scripts/exa.sh search --query "CHANNEL_NAME company" --category company --numResults 5
```

This adds: company size, funding, product offerings, social presence, target audience.

### Step 5: Identify Gaps & Opportunities

Compare findings across competitors to find:

1. **Underserved topics** — keywords with search volume but few quality videos
2. **Format gaps** — if everyone does tutorials, maybe reviews or comparisons are missing
3. **Engagement outliers** — videos that overperform relative to channel size (indicates untapped demand)
4. **Recency gaps** — topics where the top videos are old and due for an update
5. **Audience questions** — from comments on competitor videos (use the serpapi skill's `youtube_video` engine with comment pagination)

## Output Format

Structure the analysis as:

```markdown
# YouTube Competitor Analysis: [NICHE]

## Landscape Summary
- Total competitors found: X
- Combined subscriber base: X
- Content velocity: X videos/month average

## Top Competitors

### 1. [Channel Name] (@handle)
- Subscribers: X
- Top video: "Title" (X views)
- Publishing frequency: X videos/month
- Content themes: [list]
- Strengths: [what they do well]
- Weaknesses: [gaps in their content]

### 2. [Channel Name] ...

## Content Themes Ranking
| Theme | # Videos | Avg Views | Top Performer |
|-------|----------|-----------|---------------|

## Gaps & Opportunities
1. [Opportunity description + evidence]
2. ...

## Recommended Content Strategy
- Topics to target
- Formats to use
- Posting frequency suggestion
- Differentiation angle
```

## Tips

- **Cast a wide net first.** Search 5-10 keyword variations before narrowing to competitors.
- **Views ≠ quality.** A video with 50K views on a 5K subscriber channel is more interesting than 500K views on a 5M subscriber channel. Look at view-to-subscriber ratios.
- **Check recent performance.** A channel's last 10 videos matter more than their all-time hits. Algorithms and audiences change.
- **Comments reveal demand.** Questions in comments on competitor videos are free content ideas. Use the serpapi skill's `youtube_video` engine to paginate through comments.
- **Don't over-research.** 3-5 competitors is usually enough to spot patterns. More than that and you're stalling.
