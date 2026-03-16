---
name: SupaData
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

Wrapper script: `scripts/supadata.sh`
Run: `bash scripts/supadata.sh <command> [options]`

Auth: Set `SUPADATA_API_KEY` env var. The script handles auth headers automatically.

## Quick Reference

### Account

```bash
bash scripts/supadata.sh me
```

### Transcripts (Multi-Platform)

Get transcript from YouTube, TikTok, Instagram, X/Twitter, Facebook, or any file URL:

```bash
# Plain text transcript
bash scripts/supadata.sh transcript --url "https://youtu.be/dQw4w9WgXcQ" --text true --lang en

# Timestamped chunks (default)
bash scripts/supadata.sh transcript --url "https://youtu.be/dQw4w9WgXcQ" --lang en

# With AI generation for videos without captions
bash scripts/supadata.sh transcript --url "https://example.com/video.mp4" --mode generate
```

**Response (text=true):** `{"content": "Full text...", "lang": "en", "availableLangs": ["en", "es"]}`
**Response (text=false):** `{"content": [{"text": "segment", "offset": 0, "duration": 5000, "lang": "en"}], ...}`

Large videos (20+ min with AI) return `{"jobId": "..."}`. Poll:

```bash
bash scripts/supadata.sh transcript-job --jobId <id>
```

**Cost:** 1 credit (native), 2 credits/min (generated). Use `--mode native` to save credits.

| Param | Description |
|-------|-------------|
| --url | Video/file URL (required) |
| --lang | ISO 639-1 language preference |
| --text | `true` = plain text, `false` = timestamped chunks (default) |
| --chunkSize | Max chars per chunk (when text=false) |
| --mode | `native`, `generate`, or `auto` (default) |

### Metadata (Multi-Platform)

Get video/post metadata from any supported platform:

```bash
bash scripts/supadata.sh metadata --url "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

Returns: platform, type, id, title, description, author, stats (views/likes/comments), media info, tags, createdAt. **Cost:** 1 credit.

### AI Extraction

Extract structured data from what is **seen and heard** in a video. Always async.

```bash
# With prompt
bash scripts/supadata.sh extract --url "https://youtube.com/watch?v=abc" --prompt "List all products mentioned with prices"

# With JSON schema
bash scripts/supadata.sh extract --url "https://youtube.com/watch?v=abc" --schema '{"type":"object","properties":{"products":{"type":"array"}}}'

# Poll result
bash scripts/supadata.sh extract-job --jobId <id>
```

File limits: max 200MB, max 55 min. **Cost:** varies by video length.

### Web Scraping

```bash
# Scrape page to markdown
bash scripts/supadata.sh web-scrape --url "https://example.com"
# Returns: url, content (markdown), name, description, countCharacters, urls

# Map all URLs on a site
bash scripts/supadata.sh web-map --url "https://example.com"

# Crawl entire site (async)
bash scripts/supadata.sh web-crawl --url "https://example.com" --limit 50

# Poll crawl job
bash scripts/supadata.sh web-crawl-job --jobId <id>
```

Crawl costs: 1 credit + 1/page. Follows only child links — use top-level URL for full site.

---

## YouTube-Specific Commands

YouTube endpoints accept video IDs directly (no URL encoding needed).

### Transcripts

```bash
# Get transcript by video ID
bash scripts/supadata.sh yt-transcript --videoId dQw4w9WgXcQ --lang en --text true

# Translate transcript (expensive: 30 credits/min)
bash scripts/supadata.sh yt-transcript-translate --videoId dQw4w9WgXcQ --lang es --text true

# Batch transcripts (async, paid plans only)
bash scripts/supadata.sh yt-transcript-batch --videoIds '["dQw4w9WgXcQ","xvFZjo5PgG0"]' --lang en --text true

# Batch by playlist or channel
bash scripts/supadata.sh yt-transcript-batch --playlistId PLlaN88a7y2_plecYoJxvRFTLHVbIVAOoc --limit 50
bash scripts/supadata.sh yt-transcript-batch --channelId "@RickAstley" --limit 10
```

### Video Metadata

```bash
# Single video
bash scripts/supadata.sh yt-video --id dQw4w9WgXcQ

# Batch metadata (async, paid plans only)
bash scripts/supadata.sh yt-video-batch --videoIds '["dQw4w9WgXcQ","xvFZjo5PgG0"]'

# Poll batch job (works for both transcript and video batches)
bash scripts/supadata.sh yt-batch-job --jobId <id>
```

### Channels & Playlists

```bash
# Channel info (accepts @handle, URL, or channel ID)
bash scripts/supadata.sh yt-channel --id "@RickAstley"

# List channel videos
bash scripts/supadata.sh yt-channel-videos --id "@RickAstley" --limit 50 --type video
# type: all (default), video, short, live

# Playlist info
bash scripts/supadata.sh yt-playlist --id PLlaN88a7y2_plecYoJxvRFTLHVbIVAOoc

# List playlist videos
bash scripts/supadata.sh yt-playlist-videos --id PLlaN88a7y2_plecYoJxvRFTLHVbIVAOoc --limit 100
```

### YouTube Search

```bash
bash scripts/supadata.sh yt-search --query "machine learning" --type video --limit 20 --sortBy views
```

| Param | Description |
|-------|-------------|
| --query | Search query (required) |
| --type | `all`, `video`, `channel`, `playlist`, `movie` |
| --uploadDate | `all`, `hour`, `today`, `week`, `month`, `year` |
| --duration | `all`, `short` (<4min), `medium` (4-20min), `long` (20min+) |
| --sortBy | `relevance`, `rating`, `date`, `views` |
| --limit | 1-5000 (auto-paginates) |

**Cost:** 1 credit/page (~20 results).

---

## Async Jobs

Several endpoints return `{"jobId": "..."}` for async processing:
- `transcript` (large videos with AI generation)
- `extract` (always async)
- `web-crawl` (always async)
- `yt-transcript-batch` (always async)
- `yt-video-batch` (always async)

Use the corresponding `-job` command to poll. The script polls automatically until completed/failed. Jobs expire after 1 hour.

## Supported Platforms & URL Formats

- **YouTube:** `youtube.com/watch?v=ID`, `youtu.be/ID`, `/shorts/ID`, `/embed/ID`, `/live/ID`, bare video ID, `@handle`, `/channel/UCID`, `/playlist?list=PLID`
- **TikTok:** `tiktok.com/@user/video/ID`, `vm.tiktok.com/CODE`
- **Instagram:** `/reel/CODE`, `/p/CODE`, `/tv/CODE`
- **X/Twitter:** `x.com/user/status/ID`, `twitter.com/user/status/ID`
- **Facebook:** `/reel/ID`, `/groups/ID/permalink/ID`, `/share/p/ID`
- **Files:** Any public URL to MP4, WEBM, MP3, FLAC, MPEG, M4A, OGG, WAV (max 1GB transcripts, max 200MB/55min extract)

Only publicly accessible content works. Private/login-required videos will fail.

## Response Codes

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 202 | Async job started — poll with jobId |
| 206 | Transcript unavailable (1 credit still charged) |
| 400 | Invalid parameters |
| 401 | Missing/invalid API key |
| 402 | Payment required (batch endpoints need paid plans) |
| 429 | Rate limited — back off and retry |

## Troubleshooting

- **401:** Verify `SUPADATA_API_KEY` is set and valid.
- **206:** No captions exist. Try `--mode generate` for AI transcription (2 credits/min).
- **402:** Check credits with `supadata.sh me`. Batch endpoints require paid plans.
- **Translation slow:** `yt-transcript-translate` can take 20+ seconds. Costs 30 credits/min — use sparingly.

## References

For raw curl examples and full parameter tables: [references/api-reference.md](references/api-reference.md)
