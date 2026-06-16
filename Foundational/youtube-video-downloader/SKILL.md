---
name: youtube-video-downloader
display_name: YouTube Video Downloader
description: >
  YouTube Video Downloader API for downloading 3rd party YouTube videos. Use when:
  (1) the user asks to download, save, or fetch an MP4 from a YouTube URL or
  video ID (2) local yt-dlp is blocked, unavailable, or should not be used.
  This is for downloading media files; use YouTube Data API skills for
  search/metadata/channel operations and Supadata for transcripts. This is for
  downloading 3rd party YouTube videos only.
metadata: {"openclaw": {"emoji": "▶️", "requires": {"bins": ["curl", "jq"]}}}
---

# YouTube Video Downloader

Download a YouTube video through the Chorus downloader service and return the hosted MP4 URL.

Use the helper script when possible:

```bash
bash scripts/youtube-video-download.sh --url "https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s"
```

## Setup

The downloader is auth-gated. In Chorus environments, the required project env var is
already injected. Do not ask the user to set it manually.

Use `CLIPPER_BASE_URL`, defaulting to `https://clipper.chorus.com`, and the injected
`VIBECODE_PROJECT_ID`.

Every request needs:

```text
X-Chorus-Project-ID: $VIBECODE_PROJECT_ID
```

Outside Chorus, pass `--project-id` to the helper or set `VIBECODE_PROJECT_ID` yourself.

## API

Create the download:

```bash
curl -sS -X POST "$CLIPPER_BASE_URL/v1/youtube/downloads" \
  -H "Content-Type: application/json" \
  -H "X-Chorus-Project-ID: $VIBECODE_PROJECT_ID" \
  -d '{"url":"https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s"}' | jq .
```

Poll the returned `download.id` until `download.status` is `ready`:

```bash
curl -sS "$CLIPPER_BASE_URL/v1/youtube/downloads/dl_..." \
  -H "X-Chorus-Project-ID: $VIBECODE_PROJECT_ID" | jq .
```

Return `download.fileUrl` to the user. It is the hosted MP4 URL.

## Notes

- Timestamps in YouTube URLs are preserved for attribution, but the service downloads the full video.
- A successful accepted download costs `$0.01`; polling does not add more billing.
- If the API returns `401`, the caller is missing `X-Chorus-Project-ID` or is not on an allowed IP.
- If the user needs search, metadata, channel operations, or transcripts, use a YouTube Data API or transcript skill instead.
