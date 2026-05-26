---
name: serp-instagram-profile
display_name: Instagram Profile
description: >
  Specialized skill for Instagram profile workflows via SerpApi — profile lookup, follower and
  engagement metrics, feed extraction, post analysis, and influencer/brand monitoring.
  Use when: (1) looking up an Instagram profile by username or handle, (2) summarizing follower,
  following, and post counts for an account, (3) extracting recent posts with media URLs,
  captions, and engagement, (4) analyzing engagement rate, hashtags, or mentions across recent
  posts, (5) validating audience size and verification status for sponsorship or influencer
  deals, (6) comparing two or more creators or brands side by side, (7) monitoring a brand or
  competitor profile over time, (8) collecting media (photos, video thumbnails, carousel
  children) from a public feed, (9) paginating through a large feed for bulk post analysis,
  (10) extracting bio links, business contact info, and category for a business account,
  (11) any task involving public Instagram profile data. This skill builds on the foundational
  serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "📸"}}
---

# Instagram Profile Workflows

Public Instagram profile lookup, feed extraction, and engagement analysis via SerpApi's Instagram Profile engine. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engine: `instagram_profile`)

## Core Concepts

### Profile ID

The engine takes a `profile_id` parameter. This is the **handle/username** from the profile URL — not the numeric user ID.

| Instagram URL | `profile_id` |
|---|---|
| `instagram.com/natgeo` | `natgeo` |
| `instagram.com/nike/` | `nike` |
| `instagram.com/leomessi` | `leomessi` |

Strip the leading `@` if the user gives a handle that way. Profile IDs are case-insensitive on Instagram but pass them lowercased to be safe.

### Public vs Private Accounts

The engine only returns **public profile data**. For private accounts:
- Basic profile metadata (`username`, `full_name`, `profile_pic_url`, `followers`, `is_private: true`) is typically available.
- The post feed is **not accessible** — `is_private: true` means no posts will be returned.

Always check `is_private` before promising feed analysis.

### Response Structure

A profile query returns several sections:

**Profile metadata** (top-level fields about the account):

| Field | Description |
|---|---|
| `username` | Handle (without `@`) |
| `full_name` | Display name |
| `id` | Numeric Instagram user ID |
| `biography` | Bio text |
| `external_url` | Primary website link in bio |
| `bio_links[]` | All clickable bio links (URL + type) |
| `followers` | Follower count (integer) |
| `following` | Following count (integer) |
| `posts_count` | Total number of public posts |
| `is_verified` | Blue checkmark (legacy verification) |
| `is_verified_by_meta` | Meta Verified subscription |
| `is_business_account` | True for business profiles |
| `is_professional_account` | True for creator or business accounts |
| `is_private` | True if account is private (feed unavailable) |
| `profile_pic_url` | Standard-res profile photo |
| `profile_pic_url_hd` | HD profile photo |
| `category_enum`, `category_name` | Account category (e.g., "Public Figure") |
| `business_category_name` | Business-specific category |
| `business_email`, `business_phone_number` | Contact info when surfaced |
| `hide_like_and_view_counts` | If true, like counts hidden on posts |
| `has_reels`, `has_guides`, `has_channel`, `has_threads_profile` | Feature flags |

**Posts/feed array** — recent public posts. Each post contains:

| Field | Description |
|---|---|
| `id`, `shortcode` | Post identifiers (shortcode appears in `instagram.com/p/<shortcode>/`) |
| `product_type` | `feed`, `clips` (reels), `igtv`, etc. |
| `is_video`, `has_audio`, `video_duration` | Video attributes |
| `display_url` | Primary image/media URL |
| `serpapi_display_url` | SerpApi-proxied mirror (more reliable for fetching) |
| `display_resources[]` | Multiple resolution variants |
| `thumbnail_src`, `thumbnail_tall_src` | Thumbnail variants |
| `dimensions` | `{ height, width }` in pixels |
| `media_captions[]` | Caption strings (typically one entry) |
| `accessibility_caption` | Alt text |
| `comments_count` | Total comments |
| `liked_by_count` | Like count |
| `comments_disabled` | Comment restriction flag |
| `like_and_view_counts_disabled` | Visibility toggle |
| `location` | `{ name, id, slug }` when post is geo-tagged |
| `media_tagged_users[]` | Users tagged with `{ x, y }` coordinates |
| `sidecar_to_children[]` | Carousel album items (see below) |
| `owner` | Creator info |
| `media_preview` | Base64-encoded thumbnail preview |

**Carousel children** (`sidecar_to_children[]`) — for album/multi-image posts, each child includes its own `id`, `shortcode`, `display_url`, `is_video`, `accessibility_caption`, and `media_tagged_users`.

**Pagination**:
- `serpapi_pagination.next_page_token` — pass to a subsequent search to fetch older posts
- `serpapi_pagination.next` — pre-built URL for the next page

### What's NOT Available

The engine surfaces only public profile and feed data. The following are **not returned**:
- Direct messages (DMs)
- Stories or Story Highlights content (the docs do not surface a dedicated highlights array — do not promise highlight data)
- Posts from private accounts
- Real-time / push notifications
- Reach, impressions, saves, or other private analytics (even for business accounts)
- Follower lists or following lists (only the counts)
- Per-post viewer breakdowns or audience demographics

If the user asks for any of the above, state the limit explicitly and offer the closest public-data alternative.

### Pagination

Posts are returned a page at a time (typically ~12 per page, following Instagram's default feed batch size).

To paginate:
1. First call returns the most recent posts plus `serpapi_pagination.next_page_token`.
2. Pass that token via `next_page_token` on the next call to fetch the next batch of older posts.
3. Repeat until `next_page_token` is no longer present or you hit your desired post count.

**Each page costs one SerpApi credit** — sample strategically for accounts with thousands of posts.

## Workflows

### 1. Basic Profile Lookup

Look up a single profile by handle.

Use the **serpapi** skill's wrapper script with the `instagram_profile` engine.

**Required:** `profile_id` (the handle without `@`)
**Optional:** `no_cache` (force fresh fetch), `next_page_token` (for pagination)

**Presentation pattern:**
1. Show the profile summary card (see below).
2. List 3-5 recent posts with caption snippet, type (photo/reel/carousel), likes, comments.
3. Note verification, account type, and `is_private` flag if relevant.

**Profile summary card:**

```
📸 @[username] — [full_name] [✓ if verified]
   [category_name] [• Business if business account]

   [follower_count] followers • [following] following • [posts_count] posts

   [biography]
   🔗 [external_url]

   Recent posts: [N reels, N photos, N carousels] in latest page
   Avg likes: [X] | Avg comments: [Y]
```

### 2. Follower & Engagement Metrics Summary

Quick metrics snapshot for sponsorship or audit purposes.

**Strategy:**
1. Fetch the profile (page 1).
2. Pull `followers`, `following`, `posts_count`, `is_verified`, `is_business_account`.
3. From the returned posts, compute engagement metrics on the most recent ~12 posts:
   - Average likes per post
   - Average comments per post
   - Engagement rate ≈ `(avg_likes + avg_comments) / followers`
4. Note posts where `like_and_view_counts_disabled` is true (excludes them from likes-based math).

**Engagement rate benchmarks** (rough industry guidance for context, not from the API):
- < 1%: Low
- 1-3%: Average
- 3-6%: Good
- > 6%: Excellent

### 3. Recent Posts Extraction

Pull the most recent posts with full content and media.

**Strategy:**
1. Fetch profile (page 1).
2. For each post in the feed array:
   - Caption text (`media_captions[0]`)
   - Media URL (`display_url` or `serpapi_display_url` for reliability)
   - Post URL: `https://instagram.com/p/<shortcode>/`
   - Type: `is_video ? 'Video/Reel' : (sidecar_to_children?.length ? 'Carousel' : 'Photo')`
   - Engagement: `liked_by_count`, `comments_count`
3. Extract hashtags and mentions from the caption:
   - Hashtags: regex `#\w+`
   - Mentions: regex `@\w+`

### 4. Hashtag & Mention Analysis

Identify recurring hashtags and tagged accounts across the feed.

**Strategy:**
1. Fetch one or more pages of posts.
2. Parse `media_captions[0]` for `#tags` and `@mentions`.
3. Also include `media_tagged_users[]` from each post and any carousel children.
4. Tally frequencies and surface the top N.

**Use cases:**
- Identify a creator's brand partners (frequently mentioned accounts)
- Understand a brand's hashtag strategy
- Find recurring campaign tags

### 5. Competitive Influencer Analysis

Compare two or more creators side by side.

**Strategy:**
1. Fetch each profile (page 1 is typically enough for a summary).
2. Compare followers, posts_count, engagement rate, verification, and recent post mix.
3. Read 3-5 recent posts from each for qualitative differences (content style, frequency).

**Presentation pattern:**

```
📸 Influencer Comparison

| Metric          | @creatorA | @creatorB | @creatorC |
|-----------------|-----------|-----------|-----------|
| Followers       | 1.2M      | 480K      | 2.1M      |
| Posts           | 1,840     | 624       | 3,205     |
| Verified        | ✓         | —         | ✓         |
| Avg likes       | 45.2K     | 28.1K     | 62.3K     |
| Avg comments    | 612       | 384       | 905       |
| Engagement rate | 3.8%      | 5.9%      | 3.0%      |
| Category        | Athlete   | Foodie    | Musician  |

🏆 Largest audience: @creatorC
🏆 Best engagement rate: @creatorB
🏆 Most active: @creatorC (highest post count)
```

### 6. Brand Profile Monitoring

Track a brand's posting cadence and engagement over time.

**Strategy:**
1. Fetch page 1 to capture the most recent posts.
2. Use post timestamps (when present in the response) or post order to estimate cadence (posts per week).
3. Track average engagement over the last ~12 posts.
4. Re-run periodically and diff: follower delta, engagement trend, post mix change.

**What to look for:**
- Follower growth or decline between snapshots
- Shift toward Reels (`product_type: clips`) vs static feed posts
- Engagement rate trending up or down
- New product categories or partnerships surfacing in captions

### 7. Audience-Size Validation for Sponsorships

Validate a creator's claims before a sponsorship deal.

**Checks:**
1. **Authenticity signals:**
   - `is_verified` or `is_verified_by_meta` — small positive signal
   - `is_business_account` / `is_professional_account` — typical for paid partnerships
   - `business_email` present — easier to reach for outreach
2. **Audience scale:** `followers`
3. **Engagement quality:** Compute engagement rate from recent posts. Suspiciously low engagement (< 0.5%) on a large account can indicate inflated followers.
4. **Content fit:** Read recent captions and `category_name` — does the creator's content match the brand?
5. **Cadence:** How many posts on page 1 — frequent posters tend to retain engaged audiences.

Flag for the user when:
- `is_private: true` — feed analysis is impossible
- Engagement rate is far below the benchmark for the account's follower tier
- `hide_like_and_view_counts: true` — likes are hidden, so engagement rate uses comments only

### 8. Paginating Large Feeds

For bulk analysis, paginate older posts.

**Strategy:**
1. First call: `profile_id=<handle>`. Capture `serpapi_pagination.next_page_token`.
2. Subsequent calls: `profile_id=<handle>`, `next_page_token=<token from previous response>`.
3. Stop when `next_page_token` is absent or you have enough posts.

**Sampling guidance** (each page ≈ one credit, ~12 posts):

| Goal | Pages |
|---|---|
| Quick snapshot | 1 |
| Engagement rate on recent activity | 1-2 |
| Hashtag/mention analysis | 3-5 |
| Brand audit / quarterly review | 8-15 |
| Full historical extract for a large account | Sample evenly across pages — don't fetch all |

### 9. Media Collection

Extract media URLs from a profile for visual review.

**Strategy:**
1. Paginate as needed.
2. For each post, collect:
   - `serpapi_display_url` (preferred — proxied for reliability) or `display_url`
   - For carousels, iterate `sidecar_to_children[]` and collect each child's `display_url`
   - For videos/reels, use `thumbnail_src` as a still preview (the engine surfaces a video URL is not guaranteed — note this limit)
3. Group by `product_type` if filtering for reels vs photos.

**Note:** Direct video stream URLs are not consistently exposed. Use `thumbnail_src` for previews and the post URL (`instagram.com/p/<shortcode>/`) for the playable content.

### 10. Bio Link & Contact Extraction

Pull all bio links and business contact info.

**Strategy:**
1. Fetch the profile.
2. Collect `external_url` and iterate `bio_links[]` for additional URLs.
3. For business accounts, surface `business_email` and `business_phone_number`.

**Use case:** Build a contact sheet for outreach to creators or brands.

## Common Patterns

### "Look up @username on Instagram"
1. Fetch profile with `profile_id=username`.
2. Present the profile summary card.
3. Highlight 3 most recent posts with engagement.

### "How big is @creator's audience and what's their engagement?"
1. Fetch profile (page 1).
2. Report follower count, post count, verification status.
3. Compute and present average likes, average comments, and engagement rate from recent posts.

### "Compare @brandA vs @brandB on Instagram"
1. Fetch both profiles.
2. Side-by-side comparison table (followers, posts, engagement, verified, category).
3. Recommend based on user's goal (reach, engagement, content fit).

### "What's @brand been posting recently?"
1. Fetch profile (page 1).
2. Summarize the last ~12 posts: post types (photo/reel/carousel), themes (from captions), top hashtags, tagged accounts.

### "Get all of @creator's posts from the last few months"
1. Paginate using `next_page_token` until you've covered the desired range.
2. Note: timestamps may be approximate via post ordering; surface what's directly available.
3. Watch credit usage — sample if the account is very active.

### "Is @influencer worth sponsoring?"
1. Fetch profile + recent posts.
2. Validate: followers, verification, business account, engagement rate, content category.
3. Read 3-5 recent captions for brand-safety and tone fit.
4. Flag risk signals (low engagement on a big account, off-category content, private profile).

## Tips

- **`profile_id` is the handle, not the numeric ID.** It comes straight from the URL (`instagram.com/<profile_id>`). Strip any leading `@`.
- **Check `is_private` first.** Private accounts return profile metadata but no feed — don't promise post analysis until you've confirmed the account is public.
- **Use `serpapi_display_url` over `display_url`.** SerpApi proxies media URLs for reliability; raw Instagram CDN URLs can expire or 403.
- **Engagement rate math:** `(avg_likes + avg_comments) / followers × 100`. If `hide_like_and_view_counts` is true, the likes count may not be reliable — compute on comments only and flag the caveat.
- **Reels vs feed posts:** `product_type: 'clips'` indicates Reels; `feed` is a standard photo or carousel. Carousels have a non-empty `sidecar_to_children[]`.
- **Carousels:** Always check `sidecar_to_children[]` — a single post can have up to 10 child images/videos with their own tagged users.
- **Hashtags and mentions live in `media_captions[0]`.** Parse with regex `#\w+` and `@\w+`. Tagged users with on-image positions live in `media_tagged_users[]`.
- **No story or highlights data.** Don't promise either — the engine doesn't surface them. State this limit explicitly if the user asks.
- **No follower or following lists.** Only the counts are available. Don't promise follower demographics.
- **No native video stream URLs.** Use `thumbnail_src` previews and link to the post via shortcode for playback.
- **Cache window is 1 hour.** Set `no_cache=true` to force a fresh fetch when monitoring fast-moving accounts.
- **Each page is one credit.** Plan pagination — sample evenly for large accounts instead of fetching the entire feed.
- **Verified vs Meta Verified:** `is_verified` is the legacy blue check; `is_verified_by_meta` indicates the paid Meta Verified subscription. Surface both when relevant — they signal different things.
