---
name: thread-to-post
description: >
  Convert threads, discussions, and pasted text into polished blog posts or LinkedIn articles.
  Use when: (1) turning a Twitter/X thread into a blog post, (2) converting a Reddit post or
  comment chain into an article, (3) repurposing a Hacker News discussion as written content,
  (4) transforming any online thread or discussion into a polished article, (5) creating a
  LinkedIn post or article from a thread or pasted text, (6) repurposing pasted thread text
  or conversation into a structured blog post or LinkedIn article, (7) "turn this into an article",
  "make this a LinkedIn post", "repurpose as a blog post", or any thread-to-article /
  discussion-to-post / text-to-article transformation. Works with URLs and raw pasted text.
  Builds on: exa (content extraction).
metadata: {"openclaw": {"emoji": "🧵", "os": ["linux"], "requires": {"env": ["EXA_API_KEY"]}}}
---

# Thread-to-Post

Transform viral threads and online discussions into polished, structured articles. Supports two output formats: long-form blog posts and punchy LinkedIn articles.

## Foundational Skills Used

- **exa** — Content extraction from URLs (threads, posts, discussions). Read it for API details.
- **environment** — Cloud proxy for LLM access (OpenAI/Anthropic). Read it for proxy URLs and auth.

## Input Types

| Input | How to Handle |
|-------|--------------|
| URL (Hacker News) | Extract with **exa** — usually works reliably |
| URL (Twitter/X thread) | Extract with **exa** — often fails, use fallback chain |
| URL (Reddit post) | Extract with **exa** — often fails, use fallback chain |
| URL (any discussion) | Extract with **exa** `contents` endpoint |
| Raw pasted text | Use directly — skip extraction (most reliable path) |

## Workflow

### Step 1: Get the Content

**If raw text provided:** Use it directly. Skip to Step 2.

**If URL provided:** Use the **exa** skill to extract the thread content. Follow this fallback chain — each step tries a more creative approach:

1. **Try `contents` endpoint** — Request `text` content type for the readable body.
2. **If `contents` fails → try `search`** — Search for the thread by title/topic with `category` filter (e.g., `"tweet"`, `"reddit post"`). Extract content from the top result.
3. **If `search` fails → try `answer`** — Use Exa's `answer` endpoint with a query about the thread topic. This returns a synthesized summary with citations you can then extract via `contents`.
4. **If all fail → ask the user to paste the text directly.**

#### ⚠️ Known Extraction Limitations

**Reddit and X/Twitter URLs frequently fail Exa extraction** due to aggressive anti-bot measures on both platforms:

- **X/Twitter:** `contents` often returns empty results or 403/404 errors. Exa's crawler is blocked by X's robots.txt.
- **Reddit:** `contents` typically hits `CRAWL_LIVECRAWL_TIMEOUT`. Trying `old.reddit.com` or `.json` suffix does not help.
- **Hacker News:** Generally works well with `contents`.

For Reddit and X/Twitter, expect to hit Step 2-4 of the fallback chain. The `search` and `answer` endpoints work better since they use Exa's pre-indexed content rather than live crawling. When all extraction fails, asking the user to paste the thread text is the best path forward.

### Step 2: Analyze the Content

Before writing, identify:

- **Core thesis** — What's the one main point? Threads are often winding; find the spine.
- **Key arguments/points** — Number them. Most threads have 3-7 distinct points.
- **Best quotes** — Memorable phrasing worth preserving verbatim.
- **Supporting evidence** — Data, examples, anecdotes the author used.
- **Thread structure** — Is it a narrative? A list? An argument? A how-to?

### Step 3: Choose Output Format

| User Asks For | Format |
|---------------|--------|
| "blog post" / "article" / default | **Blog Post** — full article with sections, depth, ~800-2000 words |
| "LinkedIn post" / "LinkedIn article" | **LinkedIn Article** — hook-driven, shorter paragraphs, ~300-800 words |

If the user doesn't specify, default to **blog post**.

### Step 4: Transform to Article

Use the cloud proxy (see **environment** skill) to call an LLM for the restructuring. Send the extracted content with a structured prompt.

**LLM prompt should instruct:**

#### For Blog Posts:
- Open with a hook that captures the thread's core insight
- Organize into logical sections with clear headings (not just "Point 1, Point 2")
- Expand compressed thread-speak into full prose paragraphs
- Preserve the author's best lines as direct quotes with attribution
- Add transitions between sections — threads jump between points; articles flow
- Close with a synthesis or takeaway, not just the last tweet restated
- Include a "TL;DR" or key takeaways section at the end if the post exceeds 1000 words

#### For LinkedIn Articles:
- Start with a bold hook line (pattern interrupt — question, surprising stat, contrarian take)
- Short paragraphs (1-3 sentences each) — LinkedIn readers scan
- Use line breaks liberally — white space is your friend on LinkedIn
- Include a personal/professional angle: "Here's why this matters for [industry/role]"
- End with a call to engagement: question, prompt for comments, or "share if you agree"
- Keep emoji usage minimal but strategic (1-2 per post, not every line)
- No markdown headers — LinkedIn doesn't render them. Use **bold** or ALL CAPS for emphasis

### Step 5: Attribution & Formatting

Always include attribution to the original author and source:

**Blog post format:**
```markdown
# [Article Title]

*Originally shared by [@author](source_url) on [Platform]*

[Article body...]

---
*Source: [Original thread](url) by [Author] on [Platform]*
```

**LinkedIn format:**
```
[Hook line]

[Body...]

—

Originally by @[Author] on [Platform]
[URL]

#relevanthashtag #anothertag
```

Add 3-5 relevant hashtags for LinkedIn posts. No hashtags for blog posts.

### Step 6: Deliver

Present the finished article to the user as markdown. If they want it saved:
- Blog posts → `~/Documents/posts/[slug].md`
- LinkedIn articles → `~/Documents/linkedin/[slug].md`

Create the directories if they don't exist.

## Quality Checklist

Before delivering, verify:

- [ ] **Core thesis is clear** — a reader who skips to the end still gets the point
- [ ] **Original voice preserved** — key phrases quoted, author's personality intact
- [ ] **No thread artifacts** — removed "1/", "🧵", "Thread:", "(cont.)", tweet-style fragments
- [ ] **Logical flow** — sections follow a narrative arc, not just tweet order
- [ ] **Attribution present** — source and author credited
- [ ] **Format matches request** — blog post structure vs. LinkedIn structure
- [ ] **No padding** — every paragraph earns its place. Cut fluff.

## Tips

- **Thread order ≠ article order.** Threads often front-load the hook, meander through examples, then circle back. Reorganize for reading flow.
- **Expand, don't just restate.** "This is huge" in a thread becomes a sentence explaining *why* it's significant in an article.
- **Cut the meta-commentary.** Remove "I've been thinking about this..." and "Let me explain..." — just explain.
- **Multiple authors (discussions).** For Reddit/HN threads with multiple contributors, synthesize the best points from various commenters. Attribute specific insights to specific users.
- **Controversial threads.** Present the strongest arguments from each side. Don't flatten nuance into one perspective unless the user asks for a specific angle.
- **Short threads (< 5 tweets/points).** LinkedIn format works better. Don't pad a 3-tweet thread into a 1500-word blog post.
