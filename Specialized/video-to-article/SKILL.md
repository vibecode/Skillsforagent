---
name: video-to-article
description: >
  Convert YouTube videos into well-structured written articles. Use when: (1) turning a video
  into a blog post or article, (2) repurposing video content as written content, (3) creating
  an article from a YouTube URL, (4) converting a talk, tutorial, or interview video into
  readable prose, (5) any task involving video-to-text content transformation beyond raw
  transcription. Combines yt-dlp (metadata, chapters) with supadata (transcripts) to produce
  structured articles — not summaries, actual readable articles with headings, flow, and quotes.
metadata: {"openclaw": {"emoji": "📝", "os": ["linux"]}}
---

# Video-to-Article

Transform YouTube videos into structured, readable articles. Not summaries — proper articles with headings, prose, and quotes.

## Foundational Skills Used

- **yt-dlp** — Video metadata, chapters, title, description
- **supadata** — Transcript extraction (or use serpapi-youtube transcript endpoint as fallback)

## Process

### 1. Get Video Structure

Extract the video's metadata and chapters — these become the article skeleton.

```bash
# Get metadata with chapters
yt-dlp --dump-json "VIDEO_URL" | jq '{
  title, description, duration, upload_date, uploader,
  chapters: [.chapters[]? | {title, start_time, end_time}],
  tags, view_count, like_count
}'
```

**If chapters exist:** Use them as article section headings directly.
**If no chapters:** You'll derive sections from topic shifts in the transcript (step 3).

### 2. Get Transcript

```bash
# Via supadata (preferred — cleaner output)
curl -s "https://api.supadata.ai/v1/youtube/transcript?url=VIDEO_URL" \
  -H "x-api-key: $SUPADATA_API_KEY"

# Fallback: serpapi-youtube transcript
curl -s "https://serpapi.com/search?engine=youtube_video_transcript&v=VIDEO_ID&api_key=$SERPAPI_KEY"
```

The transcript comes as timestamped segments. You need both the text and the timestamps to align with chapters.

### 3. Map Transcript to Sections

Align transcript segments to chapter timestamps:

- **With chapters:** Group transcript segments by chapter start/end times. Each chapter's text becomes a section.
- **Without chapters:** Read through the transcript and identify topic shifts. Create 4-7 sections based on natural breaks in subject matter.

### 4. Transform to Article

This is where the skill's value lives. For each section:

**Clean the transcript text:**
- Remove filler words (um, uh, like, you know, so, basically)
- Remove false starts and repeated phrases
- Remove verbal tics specific to the speaker
- Fix run-on sentences — spoken language has fewer sentence boundaries than written

**Restructure for reading:**
- Convert spoken order to logical order within each section (speakers often circle back)
- Merge fragmented points that were split by tangents
- Add transition sentences between sections
- Convert "so what I'm saying is..." patterns into direct statements

**Preserve the speaker's voice:**
- Keep distinctive phrases and metaphors as direct quotes
- Use `"[Speaker] explains: '...'"` for key insights
- Don't sanitize personality out of the text — it's what makes it not sound AI-generated

**Add article elements:**
- Title: use the video title or create a more article-appropriate one
- Introduction: 2-3 sentences setting up what the article covers and why it matters
- Section headings: from chapters, or derived from topic analysis
- Key takeaways: pull 3-5 main points as a bulleted list at the end
- Attribution: "Based on [Video Title] by [Channel Name]" with link

### 5. Output Format

```markdown
# [Article Title]

*Based on "[Video Title]" by [Channel Name] — [link]*

[Introduction paragraph — what this covers and why it matters]

## [Section 1 Heading]

[Prose paragraphs with direct quotes where impactful]

"[Notable quote from speaker]" — [Speaker Name]

[More prose...]

## [Section 2 Heading]

...

## Key Takeaways

- [Point 1]
- [Point 2]
- [Point 3]

---
*Source: [Video Title](URL) by [Channel Name] | Published: [Date] | [X] views*
```

## What Makes a Good Conversion

| Video Type | Conversion Approach |
|------------|-------------------|
| Tutorial | Step-by-step article with code blocks or numbered instructions |
| Interview | Profile piece with heavy quoting, Q&A sections |
| Talk/Lecture | Essay-style with thesis, supporting arguments, conclusion |
| Review | Structured review with verdict, pros/cons sections |
| Listicle ("Top 10...") | Keep the list format, expand each item with detail from transcript |
| Discussion/Podcast | Extract key arguments per speaker, organize by topic not chronology |

## Tips

- **Long videos (>30 min):** Focus on the most substantive 60-70% of the transcript. Intros, outros, and tangents can be cut.
- **Multiple speakers:** Attribute quotes clearly. Use the video description or intro to identify speakers.
- **Technical content:** Keep jargon but add brief parenthetical explanations where the speaker didn't.
- **The description helps:** Video descriptions often contain links, timestamps, and structured summaries the speaker prepared. Use these to inform your article structure.
- **Don't over-quote:** An article that's 80% block quotes isn't an article. Paraphrase most content, quote only the most impactful or distinctive statements.
