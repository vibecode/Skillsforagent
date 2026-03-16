---
name: serpapi-youtube
description: >
  Specialized skill for YouTube search, video analysis, transcript extraction, comment mining,
  and content research workflows via SerpApi. Use when: (1) searching YouTube for videos,
  channels, playlists, or Shorts, (2) getting detailed video metadata (views, likes, chapters,
  description), (3) extracting and analyzing YouTube video transcripts, (4) reading and
  analyzing YouTube comments, (5) finding related videos or building content maps,
  (6) researching YouTube content for a topic or niche, (7) filtering YouTube search results
  by upload date, duration, type, or resolution, (8) paginating through YouTube search results
  or video comments, (9) building content briefs from YouTube research, (10) any YouTube
  data task using SerpApi. This skill builds on the foundational serpapi skill for all API details.
metadata: {"openclaw": {"emoji": "▶️", "requires": {"env": ["SERPAPI_KEY"]}, "primaryEnv": "SERPAPI_KEY"}}
---

# YouTube Search & Analysis Workflows

YouTube search, video analysis, transcript extraction, comment mining, and content research via SerpApi's YouTube engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `youtube`, `youtube_video`, `youtube_video_transcript`)

## Core Concepts

### Three YouTube Engines

| Engine | Purpose | Key Input |
|--------|---------|-----------|
| `youtube` | Search videos, channels, playlists, Shorts | `search_query` |
| `youtube_video` | Video details, comments, related videos | `v` (video ID) |
| `youtube_video_transcript` | Video captions/transcript with timestamps | `v` (video ID) |

### Search Result Types

A YouTube search returns mixed result types:
- **`video_results[]`** — Videos with title, link, channel, views, published_date, description_snippet, length, thumbnail
- **`channel_results[]`** — Channels with title, handle, subscribers, link, verified status, description_snippet, thumbnail
- **`playlist_results[]`** — Playlists with title, link, video_count, videos preview
- **`shorts_results[]`** — YouTube Shorts with title, link, thumbnail, views
- **`movie_results[]`** — Movies/paid content when relevant
- **`ads_results[]`** — Promoted video results

### Search Filters via `sp` Parameter

YouTube filtering uses the `sp` parameter with encoded tokens. Common filters:

**Sort order:**
- Sort by upload date: `CAI%3D`

**Upload date:**
- Today: `EgIIAg%3D%3D`
- This week: `EgIIAw%3D%3D`
- This month: `EgIIBA%3D%3D`
- This year: `EgIIBQ%3D%3D`

**Duration:**
- Under 4 minutes: `EgIYAQ%3D%3D`
- 4–20 minutes: `EgIYAw%3D%3D`
- Over 20 minutes: `EgIYAg%3D%3D`

**Result type:**
- Videos only: `EgIQAQ%3D%3D`
- Channels only: `EgIQAg%3D%3D`
- Playlists only: `EgIQAw%3D%3D`

**Quality:**
- 4K: `EgJwAQ%3D%3D`
- HD: `EgIhAQ%3D%3D`

**Features:**
- Live: `EgJAAQ%3D%3D`
- Subtitles/CC: `EgIoAQ%3D%3D`
- Creative Commons: `EgIwAQ%3D%3D`
- 360°: `EgJ4AQ%3D%3D`
- VR180: `EgPQAQE%3D`

**Custom filters:** Apply any filter combination on YouTube's website, then copy the `sp` value from the URL. This is the most reliable way to combine multiple filters.

### Video Detail Response

The `youtube_video` engine returns rich data for a single video:
- **Metadata** — title, channel (name, link, subscribers, thumbnail), views, extracted_views, likes, extracted_likes, published_date
- **Description** — Full description with content (text) and extracted links
- **Chapters** — `chapters[]` with title, start_time, thumbnails (if the video has chapters)
- **Key Moments** — `key_moments[]` similar to chapters but auto-generated
- **Comments** — `comments[]` with author, text, likes, published_date, replies_count, and reply data
- **Comment sorting** — `comments_sorting_token` with tokens for "Top comments" vs "Newest first"
- **Related videos** — `related_videos[]` with title, link, channel, views, published_date, length
- **Pagination tokens** — `comments_next_page_token`, `related_videos_next_page_token` for more data

### Transcript Response

The `youtube_video_transcript` engine returns:
- **`transcript[]`** — Array of segments with `snippet` (text), `start_ms`, `end_ms`, `start_time_text`
- **`chapters[]`** — Chapter markers with `chapter` (title), `start_ms`, `end_ms`
- **`available_transcripts[]`** — List of available transcript languages (with `language`, `language_code`, `title`, `type`)

Transcript options:
- `language_code` — e.g., `en`, `es`, `ja` (default: `en`)
- `title` — Select a specific transcript by name (e.g., "Twitch Chat - Simple")
- `type` — `asr` for auto-generated transcripts

### Pagination

- **YouTube search** — Token-based. Use `serpapi_pagination.next_page_token` as the `sp` parameter for the next page
- **Video comments** — Token-based. Use `comments_next_page_token` as `next_page_token`
- **Related videos** — Token-based. Use `related_videos_next_page_token` as `next_page_token`
- **Comment replies** — Token-based. Use `replies_next_page_token` as `next_page_token`

### Localization

- `gl` — Country code (e.g., `us`, `uk`, `jp`) — affects which videos appear and trending content
- `hl` — Language code (e.g., `en`, `es`, `ja`) — affects UI text and result language

## Workflows

### 1. Topic Research

Find what content exists on YouTube for a given topic. Useful for content planning, SEO research, or general exploration.

**Step 1: Broad search.**
Use the **serpapi** skill with the `youtube` engine. Search for the topic with `search_query`. Note total result types returned (videos, channels, Shorts).

**Step 2: Filter by recency.**
Re-search with the upload date filter to see what's been published recently:
- This week (`sp=EgIIAw%3D%3D`) for trending content
- This month (`sp=EgIIBA%3D%3D`) for broader recent coverage

**Step 3: Identify top performers.**
From the video results, note which videos have high view counts relative to their age. A video published a week ago with 500K views is more significant than one published 3 years ago with 2M views.

**Step 4: Deep-dive top videos.**
Use the `youtube_video` engine on 3–5 top-performing videos to get:
- Full description (often contains keywords, links, topics)
- Chapters (reveals content structure)
- Related videos (expands the topic map)

**Presentation:**

```
📺 YouTube Research: [Topic]

🔍 Search Overview:
- Videos found: [count]
- Channels found: [count]
- Shorts found: [count]

🏆 Top Videos:
1. "[Title]" by [Channel] — [Views] views ([Date])
   Duration: [Length] | Chapters: [Yes/No]
2. ...

📈 Recent Trend (past week):
- [count] new videos published
- Fastest growing: "[Title]" ([Views] in [Days] days)

📺 Key Channels:
- [Channel] (@handle) — [Subscribers] subscribers, [verified status]
- ...
```

### 2. Video Deep Dive

Get comprehensive information about a specific video — metadata, content structure, audience reaction.

**Step 1: Get video details.**
Use the `youtube_video` engine with the video ID.

**Step 2: Extract transcript.**
Use the `youtube_video_transcript` engine with the same video ID. Check `available_transcripts` first for language options. Use `language_code` matching the video's primary language.

**Step 3: Analyze comments.**
From the video details, review the initial comments. If deeper analysis is needed, paginate through more comments using `comments_next_page_token`. Switch to newest-first using `comments_sorting_token` to see recent sentiment.

**Step 4: Check related videos.**
Review `related_videos` to understand what YouTube associates with this content.

**Presentation:**

```
📺 Video Analysis: "[Title]"

📊 Metrics:
- Views: [X] | Likes: [X]
- Published: [Date]
- Channel: [Name] ([Subscribers] subscribers)

📝 Content Structure:
[List chapters if available, or summarize transcript sections]

💬 Audience Reaction ([comment count] comments):
- Sentiment: [Positive/Mixed/Negative]
- Common themes: [list recurring topics from comments]
- Top comment: "[text]" — [likes] likes

🔗 Related Content:
- [Related video 1]
- [Related video 2]
```

### 3. Transcript Extraction & Analysis

Extract and work with video transcripts for summarization, content repurposing, or quote extraction.

**Step 1: Check available transcripts.**
Use the `youtube_video_transcript` engine. The response includes `available_transcripts[]` showing all languages and types (manual vs auto-generated). Manual transcripts are more accurate; auto-generated (`asr` type) are available on most videos.

**Step 2: Extract the transcript.**
Request with the desired `language_code`. If a specific named transcript is needed, use the `title` parameter.

**Step 3: Process the transcript.**
The transcript returns as timestamped segments. For different use cases:

- **Full text summary** — Concatenate all `snippet` values. If chapters exist, summarize per chapter.
- **Quote extraction** — Search snippets for keywords, note `start_time_text` for timestamp references.
- **Content outline** — Use `chapters[]` as section headers, summarize transcript segments within each chapter's time range.
- **Key moments** — Find segments where topic changes or key points are made.

**Presentation for summaries:**

```
📝 Transcript Summary: "[Video Title]"

⏱️ Duration: [X] minutes | Language: [X] | Type: [Manual/Auto-generated]

📑 Chapters:
1. [Chapter Title] (0:00) — [Summary]
2. [Chapter Title] (3:45) — [Summary]
...

🔑 Key Quotes:
- "[Quote]" — [Timestamp]
- "[Quote]" — [Timestamp]

📋 Full Summary:
[Paragraph summary of the entire video]
```

### 4. Comment Mining

Extract insights from video comments — audience questions, sentiment, feature requests, feedback patterns.

**Step 1: Get initial comments.**
Use the `youtube_video` engine. The response includes the first page of comments and sorting options.

**Step 2: Choose sort order.**
- **Top comments** (default) — most liked/relevant comments, best for sentiment analysis
- **Newest first** — use `comments_sorting_token` to switch; best for recent reactions or tracking response to events

**Step 3: Paginate for volume.**
Use `comments_next_page_token` as `next_page_token` to get more comments. Each page returns ~20 comments. For thorough analysis, collect 3–5 pages (60–100 comments).

**Step 4: Analyze patterns.**
Look for:
- **Questions** — Comments with `?` or asking for help → content gap indicators
- **Feature requests** — "Wish you'd cover..." or "Can you make a video about..."
- **Complaints** — Negative sentiment → pain points
- **Praise** — Specific compliments → what resonates
- **Timestamps** — Comments referencing specific moments (e.g., "5:32 was hilarious") → highlights

**Step 5: Check replies.**
High-engagement comments often have reply threads. Use `replies_next_page_token` to expand them. Creator replies are especially valuable (marked by channel author badges).

**Presentation:**

```
💬 Comment Analysis: "[Video Title]"

📊 Overview:
- Total comments (estimated): [X]
- Analyzed: [X] comments across [X] pages
- Sort: [Top / Newest]

😊 Sentiment Breakdown:
- Positive: ~[X]%
- Neutral: ~[X]%
- Negative: ~[X]%

❓ Top Questions Asked:
1. "[Question]" — [likes] likes
2. "[Question]" — [likes] likes

💡 Common Themes:
- [Theme 1] — mentioned [X] times
- [Theme 2] — mentioned [X] times

🔥 Most Engaged Comments:
- "[Comment excerpt]" — [likes] likes, [replies] replies
```

### 5. Channel Research

Research a YouTube channel's content strategy, top videos, and audience.

**Step 1: Find the channel.**
Search with the `youtube` engine using the channel name. Look for `channel_results[]` to find the exact channel with subscriber count and verification status.

**Step 2: Get their content.**
Search for videos from the channel: use `search_query` with the channel name or include `site:youtube.com/@handle` patterns. Filter by recency to see recent uploads.

**Step 3: Analyze top videos.**
Use the `youtube_video` engine on 5–10 of their videos (mix of top-performing and recent) to extract:
- View counts and engagement (likes)
- Content structure (chapters)
- Description links and calls-to-action
- Related videos (what YouTube associates with their content)

**Step 4: Review audience via comments.**
Check comments on 2–3 videos to understand audience demographics, sentiment, and what they request.

**Presentation:**

```
📺 Channel Analysis: [Channel Name] (@handle)

📊 Channel Overview:
- Subscribers: [X]
- Verified: [Yes/No]
- Description: [excerpt]

🎬 Content Overview (from [X] analyzed videos):
- Average views: [X]
- Average likes: [X]
- Publishing frequency: ~[X] videos/month
- Typical video length: [X] minutes

🏆 Top Videos:
1. "[Title]" — [Views] views ([Date])
2. "[Title]" — [Views] views ([Date])

📈 Recent Performance (last month):
- Videos published: [X]
- Total views: [X]
- Best performer: "[Title]"

💡 Content Themes:
- [Theme 1] — [X] videos
- [Theme 2] — [X] videos

👥 Audience Insights (from comments):
- [Key insight]
- [Common request or question]
```

### 6. Content Brief from YouTube Research

Build a content brief for a new video or article based on what's already on YouTube.

**Step 1: Research the topic.**
Follow Workflow 1 (Topic Research) to find existing content.

**Step 2: Extract transcripts from top videos.**
Use Workflow 3 (Transcript Extraction) on the 3–5 best-performing videos. Focus on chapter structures and key points.

**Step 3: Mine comments for gaps.**
Use Workflow 4 (Comment Mining) on top videos. Look for unanswered questions — these are content opportunities.

**Step 4: Map related content.**
From the `related_videos` of top performers, identify adjacent topics that could be covered.

**Step 5: Synthesize the brief.**

```
📋 Content Brief: [Topic]

🎯 Opportunity:
- [Why this topic is worth covering]
- Search volume signal: [X] videos in the past [timeframe]

📺 Existing Top Content:
1. "[Title]" by [Channel] — [Views] views
   Key points: [summary]
   Gap: [what it doesn't cover]
2. ...

❓ Audience Questions (from comments):
1. [Question not answered in existing videos]
2. ...

📝 Recommended Structure:
1. [Section] — Cover [topic], which top videos miss
2. [Section] — Address [common question]
3. [Section] — Include [unique angle]

🔑 Must-Include Points:
- [Point from transcript analysis]
- [Point from comment mining]

🎯 Differentiation:
- [How to stand out from existing content]
```

### 7. Multi-Video Comparison

Compare multiple videos on the same topic — useful for benchmarking, review analysis, or finding the best resource.

**Step 1: Find competing videos.**
Search the topic with the `youtube` engine. Identify 3–5 videos covering the same subject.

**Step 2: Get details for each.**
Use the `youtube_video` engine on each video to collect metadata.

**Step 3: Extract transcripts for each.**
Use the `youtube_video_transcript` engine to get content for comparison.

**Step 4: Compare across dimensions.**

```
📊 Video Comparison: [Topic]

| Metric | Video A | Video B | Video C |
|--------|---------|---------|---------|
| Title | [title] | [title] | [title] |
| Channel | [name] | [name] | [name] |
| Views | [X] | [X] | [X] |
| Likes | [X] | [X] | [X] |
| Duration | [X] min | [X] min | [X] min |
| Chapters | [Y/N] | [Y/N] | [Y/N] |
| Published | [date] | [date] | [date] |

📝 Content Coverage:
- Video A covers: [topics]
- Video B covers: [topics]
- Video C covers: [topics]
- Unique to A: [topics]
- Unique to B: [topics]
- Common to all: [topics]

🏆 Best For:
- Quick overview: [Video X] (shortest, most concise)
- Deep learning: [Video Y] (most comprehensive)
- Most engaging: [Video Z] (highest like ratio)
```

## Common Patterns

### "Find YouTube videos about [topic]"
1. Search with `youtube` engine, `search_query=[topic]`
2. Present top 5–8 video results with views, date, channel
3. Offer to dive deeper into any specific video

### "What does [video] cover?"
1. Get video details with `youtube_video`
2. Get transcript with `youtube_video_transcript`
3. Summarize using chapters (if available) or transcript sections

### "Get me the transcript of this video"
1. Use `youtube_video_transcript` with the video ID
2. Check `available_transcripts` for language options
3. Return formatted transcript with timestamps

### "What are people saying about [video]?"
1. Get video details (includes first page of comments)
2. Paginate if needed for more comments
3. Summarize sentiment and recurring themes

### "Find recent videos about [topic]"
1. Search with `youtube` engine
2. Filter with `sp=EgIIAw%3D%3D` (this week) or `sp=EgIIBA%3D%3D` (this month)
3. Sort by upload date with `sp=CAI%3D` for chronological order

### "What videos are similar to [this one]?"
1. Get video details with `youtube_video`
2. Present `related_videos[]` from the response
3. Offer to analyze any of the related videos

### "Research [channel name] on YouTube"
1. Search with `youtube` engine for the channel name
2. Identify the channel from `channel_results[]`
3. Follow Channel Research workflow (Workflow 5)

### "Build me a content brief about [topic]"
1. Follow Content Brief workflow (Workflow 6)
2. Combine topic research, transcript analysis, and comment mining

## Tips

- **Video ID extraction** — The video ID is the `v` parameter from any YouTube URL: `youtube.com/watch?v=VIDEO_ID`. Also works from short URLs: `youtu.be/VIDEO_ID`.
- **sp filter stacking** — To combine filters, apply them on YouTube's UI and copy the resulting `sp` value from the URL. Manually combining encoded tokens is unreliable.
- **Views vs age** — Always contextualize view counts with publish date. Calculate views-per-day for fair comparison across videos of different ages.
- **Transcript availability** — Most videos have auto-generated (ASR) transcripts. Manual transcripts are higher quality but less common. Check `available_transcripts` first.
- **Comment sampling** — Top comments (default sort) are biased toward early, popular responses. For recent sentiment, switch to newest-first sorting.
- **Localization matters** — Set `gl` and `hl` to match your target audience. YouTube serves different trending content and search results per region.
- **Shorts vs videos** — Shorts appear in `shorts_results[]`, separate from `video_results[]`. They have different engagement dynamics (higher views, lower engagement depth).
- **Pagination costs** — Each page of results costs one SerpApi search credit. Be strategic — 2–3 pages of comments is usually enough for analysis.
- **Channel content** — YouTube search doesn't have a direct "list all videos by channel" API. Search with the channel name + topic keywords, or use multiple searches to build a picture.
- **Chapters as structure** — Videos with chapters are easier to analyze. Use chapter titles as section headers when summarizing transcripts.
