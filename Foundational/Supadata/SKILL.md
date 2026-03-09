---
name: Supadata
description: >
  Supadata API for pulling transcripts, metadata, and structured data from videos on YouTube, TikTok, Instagram, X/Twitter, and Facebook. Also scrapes and crawls websites to markdown. Use when asked to "get a transcript", "pull captions", "transcribe a video", "get video info", "get video metadata", "extract data from a video", "scrape a webpage", "crawl a website", "map a site", "search YouTube", or when needing channel info, playlist info, batch transcripts, or batch video metadata. Supports file URLs (MP4, MP3, WAV, etc.) for transcription.
metadata:
  {
    "openclaw":
      {
        "emoji": "📝",
        "requires": { "env": ["SUPADATA_API_KEY"] },
        "primaryEnv": "SUPADATA_API_KEY",
      },
  }
---

# Supadata API

Base URL: `https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1`
Auth header: `x-api-key: ${SUPADATA_API_KEY}`

All requests require the `x-api-key` header. Always URL-encode the `url` parameter.

## Response Codes

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 202 | Async job started — poll with jobId |
| 206 | Transcript unavailable (1 credit still charged) |
| 400 | Invalid parameters |
| 401 | Missing/invalid API key |
| 402 | Payment required |
| 429 | Rate limited |
| 5xx | Server error |

Error format: `{"error": "code", "message": "...", "details": "...", "documentationUrl": "..."}`

---

## Account

### GET /me

Returns org ID, plan name, max credits, used credits.

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/me" -H "x-api-key: ${SUPADATA_API_KEY}"
```

---

## Transcripts (Multi-Platform)

### GET /transcript

Get transcript from YouTube, TikTok, Instagram, X/Twitter, Facebook, or file URL.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| url | string | Yes | Video/file URL (URL-encode it) |
| lang | string | No | ISO 639-1 language preference |
| text | boolean | No | `true` = plain text, `false` = timestamped chunks (default) |
| chunkSize | number | No | Max chars per chunk (when text=false) |
| mode | string | No | `native` (existing only), `generate` (AI), `auto` (default: native with AI fallback) |

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/transcript?url=https%3A%2F%2Fyoutu.be%2FdQw4w9WgXcQ&text=true&lang=en" \
  -H "x-api-key: ${SUPADATA_API_KEY}"
```

**Response (text=true):** `{"content": "Full text...", "lang": "en", "availableLangs": ["en", "es"]}`

**Response (text=false):** `{"content": [{"text": "segment", "offset": 0, "duration": 5000, "lang": "en"}], ...}`

Returns **202 with `{"jobId": "..."}` for large videos** (20+ min with AI generation). Poll with GET /transcript/{jobId}.

**Cost:** 1 credit (native), 2 credits/min (generated). Use `mode=native` to save credits.

### GET /transcript/{jobId}

Poll async transcript. Response same as above plus `"status": "queued|active|completed|failed"`. Poll every 1s. Expires after 1 hour.

---

## Metadata (Multi-Platform)

### GET /metadata

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| url | string | Yes | Post/video URL (URL-encode it) |

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/metadata?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DdQw4w9WgXcQ" \
  -H "x-api-key: ${SUPADATA_API_KEY}"
```

Returns: platform, type, id, title, description, author (username, displayName, verified), stats (views, likes, comments), media (type, duration, thumbnailUrl), tags, createdAt. **Cost:** 1 credit.

---

## AI Extraction

### POST /extract

Extract structured data from what is **seen and heard** in a video using AI. Always async.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| url | string | Yes | Video/file URL |
| prompt | string | Conditional | What to extract (required if no schema) |
| schema | object | Conditional | JSON Schema for structured output (required if no prompt) |

Both prompt and schema can be provided together.

```bash
curl -X POST "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/extract" \
  -H "x-api-key: ${SUPADATA_API_KEY}" -H "Content-Type: application/json" \
  -d '{"url": "https://youtube.com/watch?v=abc", "prompt": "List all products mentioned with prices"}'
```

**Response:** `{"jobId": "uuid"}` (always 202). File limits: max 200MB, max 55 min.

### GET /extract/{jobId}

Poll extraction job. Response: `{"status": "completed", "data": {...}, "schema": {...}}`. Poll every 1s. Expires after 1 hour.

---

## Web

### GET /web/scrape

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| url | string | Yes | Web page URL |
| noLinks | boolean | No | Exclude markdown links |
| lang | string | No | ISO 639-1 preference (default: en) |

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/web/scrape?url=https%3A%2F%2Fsupadata.ai" \
  -H "x-api-key: ${SUPADATA_API_KEY}"
```

Returns: url, content (markdown), name, description, countCharacters, urls (found links). **Cost:** 1 credit.

### GET /web/map

Returns all URLs found on a website: `{"urls": [...]}`. **Cost:** 1 credit.

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/web/map?url=https%3A%2F%2Fsupadata.ai" -H "x-api-key: ${SUPADATA_API_KEY}"
```

### POST /web/crawl

Async crawl of entire website. Crawler follows only child links — use top-level URL for full site.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| url | string | Yes | Website URL |
| limit | number | No | Max pages (default: 100) |

```bash
curl -X POST "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/web/crawl" \
  -H "x-api-key: ${SUPADATA_API_KEY}" -H "Content-Type: application/json" \
  -d '{"url": "https://supadata.ai", "limit": 50}'
```

**Response:** `{"jobId": "uuid"}`. **Cost:** 1 credit + 1/page crawled.

### GET /web/crawl/{jobId}

Returns: `{"status": "scraping|completed|failed|cancelled", "pages": [{"url": "...", "content": "# Markdown", "name": "..."}], "next": "...cursor URL or null..."}`. Follow `next` for pagination.

---

## YouTube — Transcripts

### GET /youtube/transcript

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| url or videoId | string | One required | YouTube video URL or ID |
| lang | string | No | ISO 639-1 preference |
| text | boolean | No | Plain text mode (default: false) |
| chunkSize | number | No | Max chars per chunk |

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/transcript?videoId=dQw4w9WgXcQ&lang=en&text=true" \
  -H "x-api-key: ${SUPADATA_API_KEY}"
```

Same response format as GET /transcript. **Cost:** 1 credit.

### GET /youtube/transcript/translate

Translate a YouTube transcript. Same params as above plus `lang` is **required** (target language).

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/transcript/translate?videoId=dQw4w9WgXcQ&lang=es&text=true" \
  -H "x-api-key: ${SUPADATA_API_KEY}"
```

**Warning:** Can take 20+ seconds. **Cost:** 30 credits/min — expensive, use sparingly.

### POST /youtube/transcript/batch

Batch transcripts for multiple videos. Provide ONE of: `videoIds` (array), `playlistId`, or `channelId`.

| Param | Type | Description |
|-------|------|-------------|
| videoIds | array | Video IDs or URLs |
| playlistId | string | Playlist URL or ID |
| channelId | string | Channel URL, handle, or ID |
| limit | number | Max videos (default: 10, max: 5000) |
| lang | string | Language preference |
| text | boolean | Plain text mode |

```bash
curl -X POST "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/transcript/batch" \
  -H "x-api-key: ${SUPADATA_API_KEY}" -H "Content-Type: application/json" \
  -d '{"videoIds": ["dQw4w9WgXcQ", "xvFZjo5PgG0"], "lang": "en", "text": true}'
```

**Response:** `{"jobId": "uuid"}`. Poll with GET /youtube/batch/{jobId}. **Cost:** 1 credit + 1/video. Paid plans only.

---

## YouTube — Video Metadata

### GET /youtube/video

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/video?id=dQw4w9WgXcQ" -H "x-api-key: ${SUPADATA_API_KEY}"
```

Returns title, description, duration, views, likes, channel, publish date, tags. **Cost:** 1 credit.

### POST /youtube/video/batch

Same input structure as transcript/batch (videoIds, playlistId, or channelId + limit).

```bash
curl -X POST "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/video/batch" \
  -H "x-api-key: ${SUPADATA_API_KEY}" -H "Content-Type: application/json" \
  -d '{"videoIds": ["dQw4w9WgXcQ", "xvFZjo5PgG0"]}'
```

**Response:** `{"jobId": "uuid"}`. Poll with GET /youtube/batch/{jobId}. **Cost:** 1 credit + 1/video. Paid plans only.

### GET /youtube/batch/{jobId}

Returns batch results for transcript or video metadata jobs:

```json
{
  "status": "queued|active|completed|failed",
  "results": [
    {"videoId": "dQw4w9WgXcQ", "transcript": {"content": "...", "lang": "en"}},
    {"videoId": "xvFZjo5PgG0", "errorCode": "transcript-unavailable"}
  ],
  "stats": {"total": 2, "succeeded": 1, "failed": 1}
}
```

---

## YouTube — Channels & Playlists

### GET /youtube/channel

Accepts: channel URL, @handle, or channel ID. Returns: id, name, description, subscriberCount, videoCount, thumbnail, banner. **Cost:** 1 credit.

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/channel?id=@RickAstley" -H "x-api-key: ${SUPADATA_API_KEY}"
```

### GET /youtube/channel/videos

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Channel URL, handle, or ID |
| limit | number | No | Max results (default: 30, max: 5000) |
| type | string | No | `all`, `video`, `short`, `live` (default: all) |

Returns: `{"videoIds": [...], "shortIds": [...], "liveIds": [...]}`. Latest-first. **Cost:** 1 credit.

### GET /youtube/playlist

Returns: id, title, description, videoCount, viewCount, lastUpdated, channel. **Cost:** 1 credit.

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/playlist?id=PLlaN88a7y2_plecYoJxvRFTLHVbIVAOoc" \
  -H "x-api-key: ${SUPADATA_API_KEY}"
```

### GET /youtube/playlist/videos

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Playlist URL or ID |
| limit | number | No | Max results (default: 100, max: 5000) |

Returns: `{"videoIds": [...], "shortIds": [...], "liveIds": [...]}`. **Cost:** 1 credit.

---

## YouTube — Search

### GET /youtube/search

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| query | string | Yes | Search query |
| type | string | No | `all`, `video`, `channel`, `playlist`, `movie` (default: all) |
| uploadDate | string | No | `all`, `hour`, `today`, `week`, `month`, `year` |
| duration | string | No | `all`, `short` (<4min), `medium` (4-20min), `long` (20min+) |
| sortBy | string | No | `relevance`, `rating`, `date`, `views` |
| features | array | No | `hd`, `subtitles`, `creative-commons`, `3d`, `live`, `4k`, `360`, `location`, `hdr`, `vr180` |
| limit | number | No | 1-5000 (auto-paginates) |
| nextPageToken | string | No | Pagination token |

```bash
curl "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/youtube/search?query=machine%20learning&type=video&limit=20&sortBy=views" \
  -H "x-api-key: ${SUPADATA_API_KEY}"
```

Returns: `{"query": "...", "results": [{"type": "video", "id": "...", "title": "...", "duration": 213, "viewCount": 1234567, "channel": {...}}], "nextPageToken": "..."}`. **Cost:** 1 credit/page (~20 results).

---

## Async Job Polling

Endpoints that return `{"jobId": "..."}`: /transcript (large videos), /extract, /web/crawl, /youtube/transcript/batch, /youtube/video/batch.

```bash
JOB_ID=$(curl -s -X POST "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/extract" \
  -H "x-api-key: ${SUPADATA_API_KEY}" -H "Content-Type: application/json" \
  -d '{"url": "https://youtube.com/watch?v=abc", "prompt": "summarize"}' | jq -r '.jobId')

while true; do
  RESULT=$(curl -s "https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1/extract/${JOB_ID}" -H "x-api-key: ${SUPADATA_API_KEY}")
  STATUS=$(echo $RESULT | jq -r '.status')
  [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ] && { echo "$RESULT"; break; }
  sleep 1
done
```

All job results expire after 1 hour.

---

## Supported URL Formats

- **YouTube:** `youtube.com/watch?v=ID`, `youtu.be/ID`, `/shorts/ID`, `/embed/ID`, `/live/ID`, bare ID, `@handle`, `/channel/UCID`, `/playlist?list=PLID`
- **TikTok:** `tiktok.com/@user/video/ID`, `vm.tiktok.com/CODE`
- **Instagram:** `/reel/CODE`, `/p/CODE`, `/tv/CODE`
- **X/Twitter:** `x.com/user/status/ID`, `twitter.com/user/status/ID`
- **Facebook:** `/reel/ID`, `/groups/ID/permalink/ID`, `/share/p/ID`
- **Files:** Any public URL to MP4, WEBM, MP3, FLAC, MPEG, M4A, OGG, WAV (max 1GB transcripts, max 200MB/55min extract)

Only publicly accessible content works. Private/login-required videos will fail.

---

## Troubleshooting

**401 — Auth failed:** Verify `SUPADATA_API_KEY` is set and valid.

**206 — Transcript unavailable:** No captions exist. Try `mode=generate` for AI transcription (costs 2 credits/min).

**429 — Rate limited:** Back off and retry.

**402 — Payment required:** Check `/me` for credit usage. Batch endpoints require paid plans.

**Translation timeout:** `/youtube/transcript/translate` can take 20+ seconds. Set timeout to 60s+. Consider if 30 credits/min is worth it.
