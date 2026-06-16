---
name: youtube-downloader
display_name: YouTube Downloader
description: >
  YouTube Downloader API for downloading 3rd party YouTube videos. Use when: (1) the user asks to download, save, or fetch an MP4 from a YouTube URL or video ID (2) local yt-dlp is blocked, unavailable, or should not be used. This is for downloading media files; use YouTube Data API skills for search/metadata/channel operations and Supadata for transcripts. This is for downloading 3rd party YouTube videos only.
metadata: {"openclaw": {"emoji": "🎬", "requires": {"bins": ["curl", "jq"]}}}
---

# Clipper

Download YouTube videos through the Chorus Clipper service API and return the managed MP4 URL.
Clipper owns the provider credentials, object storage, and billing event; callers only provide
the YouTube URL.

Wrapper script: `scripts/clipper-download.sh`

```bash
bash scripts/clipper-download.sh --url "https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s"
```

## Setup

Clipper is private infrastructure. Use it from Pylon, Vibecode, Chorus private networking, or
another allowed client IP. `CHORUS_PROJECT_ID` should already be set.

```bash
export CLIPPER_BASE_URL="${CLIPPER_BASE_URL:-https://clipper.chorus.com}"
export VIBECODE_PROJECT_ID="<project-id>"
```

Send exactly one project attribution header on every request. Use `X-Chorus-Project-ID`.

## Quick Reference

### Create a Download

```bash
curl -sS -X POST "$CLIPPER_BASE_URL/v1/youtube/downloads" \
  -H "Content-Type: application/json" \
  -H "X-Vibecode-Project: $VIBECODE_PROJECT_ID" \
  -d '{"url":"https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s"}' | jq .
```

Response:

```json
{
  "download": {
    "id": "dl_...",
    "status": "pending",
    "progress": 10,
    "url": "https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s",
    "videoId": "OxFyVcO1Yow",
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

### Poll Until Ready

```bash
curl -sS "$CLIPPER_BASE_URL/v1/youtube/downloads/dl_..." \
  -H "X-Vibecode-Project: $VIBECODE_PROJECT_ID" | jq .
```

Ready response includes the hosted MP4 URL:

```json
{
  "download": {
    "id": "dl_...",
    "status": "ready",
    "progress": 100,
    "fileUrl": "https://clipper.media.chorus.com/downloads/dl_.../video.mp4",
    "expiresAt": "..."
  }
}
```

### Resolve the File Redirect

```bash
curl -I "$CLIPPER_BASE_URL/v1/youtube/downloads/dl_.../file" \
  -H "X-Vibecode-Project: $VIBECODE_PROJECT_ID"
```

When the job is ready, `/file` returns a `302` redirect to `download.fileUrl`.

## Wrapper Usage

The helper creates the job, polls it, and prints the final JSON once the file is ready.

```bash
bash scripts/clipper-download.sh \
  --url "https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s" \
  --project-id "$VIBECODE_PROJECT_ID"
```

Optional settings:

| Option | Description |
|--------|-------------|
| `--quality 720` | Request a video quality when the API supports it |
| `--base-url URL` | Override `CLIPPER_BASE_URL` |
| `--project-id ID` | Override `CLIPPER_PROJECT_ID`, `VIBECODE_PROJECT_ID`, or `CHORUS_PROJECT_ID` |
| `--project-header NAME` | Use `X-Chorus-Project-ID` or `X-Project-ID` instead of the default |
| `--poll-seconds N` | Poll interval, default `15` |
| `--timeout-seconds N` | Overall wait timeout, default `900` |
| `--create-only` | Create the job and print the initial response without polling |
| `--raw` | Print compact JSON instead of pretty JSON |

## Inputs

Accepted URL forms include `youtube.com/watch?v=...`, `youtu.be/...`, `/shorts/...`,
`/embed/...`, `/live/...`, and bare video IDs if the API accepts them. Preserve the user's
original URL in the request.

Timestamp query parameters such as `t=73s` are attribution only in v1. Clipper downloads the
full video; it does not trim the output to the timestamp.

## Billing

Creating a download bills one load after the provider accepts the job:

| Field | Value |
|-------|-------|
| Provider | `youtube_downloader` |
| Meter | `youtube_downloader.loads` |
| Quantity | `1` |
| Unit | `load` |
| Price | `$0.01` |
| Webhook cost | `total_cost_millicents: 1000` |

Polling a job and resolving `/file` do not create additional usage events.

## Response Codes

| Status | Meaning |
|--------|---------|
| `202` | Download accepted or still pending |
| `302` | `/file` redirect to the hosted MP4 URL |
| `400` | Invalid URL or request body |
| `401` | Missing project header or unauthorized client |
| `404` | Download ID was not found for the project |
| `409` | Download failed; inspect `download.error` |
| `410` | File URL expired; create a new download |
| `5xx` | Provider or Clipper error; retry with backoff |

## Troubleshooting

- **Cannot connect:** Verify `clipper.chorus.com` resolves to the public Clipper host and
  the caller is on an allowlisted IP for `/v1` requests.
- **401:** Include one project attribution header and call from an allowed client IP.
- **Pending for a long time:** Keep polling every 10-15 seconds. Large videos can take minutes.
- **Failed with provider error:** Report the `download.error` code/message. Deleted, private,
  geo-restricted, age-restricted, or login-required videos may fail.
- **Need metadata/search/transcripts:** Use YouTube Data API or Supadata instead of Clipper.

Only download content the user has the rights or permission to access.
