---
name: scrapecreators
display_name: ScrapeCreators
description: >
  Foundational skill for the ScrapeCreators API: scraping public social-platform
  data — profiles, posts, reels, shorts, comments, followers, creators, and
  platform ad libraries — across TikTok, Instagram, YouTube, Facebook,
  X/Twitter, Reddit, LinkedIn, Threads, Bluesky, Pinterest, Twitch, Spotify,
  and more. Use when: (1) scraping a specific public social profile, post,
  video, or comment thread, (2) researching creators or audiences on a social
  platform, (3) pulling raw Facebook Ad Library, Google ads, or LinkedIn ad
  data by URL/company, (4) any task involving api.scrapecreators.com or
  ScrapeCreators. Not for general web search (use exa), Google SERP or
  Maps/Shopping/Trends (use SerpApi), video transcription of arbitrary files
  (use SupaData), or curated Meta ad-creative intelligence (use foreplay).
metadata: {"openclaw": {"requires": {"env": ["SCRAPECREATORS_API_KEY"]}, "primaryEnv": "SCRAPECREATORS_API_KEY"}}
---

# ScrapeCreators API

ScrapeCreators provides GET endpoints for public social/profile/post/video/comment/search data across many platforms.

Wrapper script: `scripts/scrapecreators.sh`
Run: `bash scripts/scrapecreators.sh <command-or-path> [--param value ...]`

## Authentication

Use the proxy-provided key already in `SCRAPECREATORS_API_KEY`.

```
Base URL: ${SCRAPECREATORS_BASE_URL:-https://api.scrapecreators.com.proxy.chorus.com}
Header:   x-api-key: ${SCRAPECREATORS_API_KEY}
```

Live docs (canonical source for all endpoints and parameters): https://docs.scrapecreators.com — machine-readable catalog at `https://docs.scrapecreators.com/openapi.json`. If a needed endpoint is missing from this quick reference, pass the documented path directly to the wrapper.

## Quick Start

```bash
# TikTok
bash scripts/scrapecreators.sh tiktok-profile --handle "stoolpresidente"
bash scripts/scrapecreators.sh tiktok-videos --handle "stoolpresidente" --sort_by latest
bash scripts/scrapecreators.sh tiktok-video --url "https://www.tiktok.com/@user/video/123" --get_transcript true
bash scripts/scrapecreators.sh tiktok-search --query "running shoes" --sort_by relevance

# Instagram
bash scripts/scrapecreators.sh instagram-profile --handle "nike"
bash scripts/scrapecreators.sh instagram-post --url "https://www.instagram.com/reel/..."
bash scripts/scrapecreators.sh instagram-reels-search --query "meal prep"

# YouTube
bash scripts/scrapecreators.sh youtube-search --query "product launch ads" --type video
bash scripts/scrapecreators.sh youtube-video --url "https://www.youtube.com/watch?v=VIDEO_ID"
bash scripts/scrapecreators.sh youtube-transcript --url "https://www.youtube.com/watch?v=VIDEO_ID"

# Ad libraries
bash scripts/scrapecreators.sh facebook-ad-search --query "nike" --country US --status active
bash scripts/scrapecreators.sh google-company-ads --domain "nike.com" --region US
bash scripts/scrapecreators.sh linkedin-ads-search --company "Nike"

# Any documented path also works
bash scripts/scrapecreators.sh /v1/reddit/search --query "best running shoes" --sort relevance
```

## Command Map

All commands are GET requests. Pagination is endpoint-specific; common cursor fields include `cursor`, `continuationToken`, `max_cursor`, `next_max_id`, `paginationToken`, and `page`.

| Command | Path |
|---|---|
| `tiktok-profile` | `/v1/tiktok/profile` |
| `tiktok-videos` | `/v3/tiktok/profile/videos` |
| `tiktok-video` | `/v2/tiktok/video` |
| `tiktok-transcript` | `/v1/tiktok/video/transcript` |
| `tiktok-search` | `/v1/tiktok/search/keyword` |
| `instagram-profile` | `/v1/instagram/profile` |
| `instagram-post` | `/v1/instagram/post` |
| `instagram-posts` | `/v2/instagram/user/posts` |
| `instagram-reels` | `/v1/instagram/user/reels` |
| `instagram-reels-search` | `/v2/instagram/reels/search` |
| `instagram-transcript` | `/v2/instagram/media/transcript` |
| `youtube-channel` | `/v1/youtube/channel` |
| `youtube-channel-videos` | `/v1/youtube/channel-videos` |
| `youtube-search` | `/v1/youtube/search` |
| `youtube-video` | `/v1/youtube/video` |
| `youtube-transcript` | `/v1/youtube/video/transcript` |
| `youtube-comments` | `/v1/youtube/video/comments` |
| `facebook-profile` | `/v1/facebook/profile` |
| `facebook-post` | `/v1/facebook/post` |
| `facebook-comments` | `/v1/facebook/post/comments` |
| `facebook-ad-search` | `/v1/facebook/adLibrary/search/ads` |
| `facebook-ad` | `/v1/facebook/adLibrary/ad` |
| `facebook-company-ads` | `/v1/facebook/adLibrary/company/ads` |
| `google-search` | `/v1/google/search` |
| `google-company-ads` | `/v1/google/company/ads` |
| `google-ad` | `/v1/google/ad` |
| `linkedin-profile` | `/v1/linkedin/profile` |
| `linkedin-company` | `/v1/linkedin/company` |
| `linkedin-post` | `/v1/linkedin/post` |
| `linkedin-ads-search` | `/v1/linkedin/ads/search` |
| `twitter-profile` | `/v1/twitter/profile` |
| `twitter-tweets` | `/v1/twitter/user-tweets` |
| `twitter-tweet` | `/v1/twitter/tweet` |
| `reddit-search` | `/v1/reddit/search` |
| `reddit-post-comments` | `/v1/reddit/post/comments` |
| `threads-profile` | `/v1/threads/profile` |
| `threads-search` | `/v1/threads/search` |
| `bluesky-profile` | `/v1/bluesky/profile` |
| `pinterest-search` | `/v1/pinterest/search` |
| `github-user` | `/v1/github/user` |
| `github-repo` | `/v1/github/repository` |
| `spotify-search` | `/v1/spotify/search` |

For every other platform in the docs, pass the path directly:

```bash
bash scripts/scrapecreators.sh /v1/twitch/profile --handle "riotgames"
bash scripts/scrapecreators.sh /v1/rumble/search --query "ai news"
bash scripts/scrapecreators.sh /v1/linktree --url "https://linktr.ee/example"
```

For the complete catalog of all 158 endpoints with verified working example params: read [references/api-reference.md](references/api-reference.md).

## Common Parameters

- `--handle`: social username/handle.
- `--url`: canonical public URL for a post, profile, video, ad, clip, or page.
- `--query`: search text.
- `--id`, `--user_id`, `--channelId`, `--pageId`, `--companyId`: platform-specific IDs.
- `--trim true`: ask supported endpoints for smaller responses.
- `--download_media true`: ask supported video/post endpoints to include downloadable media. Costs extra credits.
- `--get_transcript true`: include transcript where supported. Costs extra credits; prefer the dedicated transcript endpoints.
- `--get_ad_details true`, `--use_ai_as_fallback true`: extra-cost add-ons; leave off unless needed.
- `--language en`: transcript language where supported.
- `--region US`, `--country US`: location filter where supported.
- Cursor/page flags: reuse the exact cursor returned by the previous response.

## Choosing Endpoints

- Use native transcript endpoints when the user asks for captions or spoken content.
- Use `trim=true` for exploratory profile/post/video calls to reduce response size.
- Use ad-library endpoints for competitive creative research.
- Prefer direct URL endpoints for exact posts/videos; prefer search endpoints when the user gives only a topic, handle, or brand.

## Errors

| Status | Meaning |
|---|---|
| 400 | Invalid or missing parameter. |
| 401 | Missing/invalid `SCRAPECREATORS_API_KEY`. |
| 402 | Out of credits or plan-limited endpoint. |
| 404 | Resource not found or public data unavailable. |
| 429 | Rate limited; retry later with backoff. |
| 500 | Upstream/provider failure; retry or narrow the request. |

Known flaky/broken endpoints (live sweep of all 158 routes, 2026-06-09; everything else returned 200):

- `/v1/soundcloud/*`: consistent 500s.
- `/v1/tiktok/hashtags/popular`: 400; TikTok removed the source page.
- `/v1/rumble/video/comments`: intermittent 503.
- `/v2/instagram/media/transcript` (`instagram-transcript`): intermittent 500; retry once.

Note: some endpoints return 200 with an empty/zero payload for an unrecognized key instead of a 401 — sanity-check a known-good request before concluding data is missing.
