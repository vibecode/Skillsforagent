---
name: yt-dlp
description: >
  Download videos, audio, and playlists from YouTube and thousands of other sites using yt-dlp.
  Use when: (1) downloading a video from a URL, (2) extracting audio/MP3 from a video,
  (3) downloading playlists or channel content, (4) getting specific video quality or resolution,
  (5) extracting video metadata without downloading (title, duration, views), (6) downloading
  subtitles, (7) any task involving yt-dlp or media downloading from the web. Requires yt-dlp
  CLI and ffmpeg for format merging/conversion.
metadata: {"openclaw": {"emoji": "📥", "os": ["linux"], "requires": {"bins": ["ffmpeg"]}, "install": [{"kind": "uv", "formula": "yt-dlp", "bins": ["yt-dlp"]}]}}
---

# yt-dlp

Download videos, audio, and playlists from YouTube and 1000+ sites via CLI.

## Setup

```bash
bash scripts/setup.sh
```

Installs yt-dlp via pip, verifies ffmpeg, creates config with sensible defaults (embed metadata, thumbnails, subs, merge to MP4). Or manually: `pip3 install -U yt-dlp`

**Requirements:** `ffmpeg` (pre-installed), Python 3 (pre-installed).

## Quick Reference

### Download a Video

```bash
yt-dlp "https://www.youtube.com/watch?v=VIDEO_ID"
```

Default config: best quality, merged to MP4, metadata + thumbnail + subs embedded.

### Specific Quality

```bash
yt-dlp -f "bv*[height<=1080]+ba/b[height<=1080]" "URL"    # 1080p max
yt-dlp -f "bv*[height<=720]+ba/b[height<=720]" "URL"      # 720p max
```

### Extract Audio

```bash
yt-dlp -x --audio-format mp3 --audio-quality 0 "URL"      # Best MP3
yt-dlp -x --audio-format m4a "URL"                          # M4A (AAC)
yt-dlp -x --audio-format wav "URL"                          # WAV
```

### Download Playlist

```bash
yt-dlp "https://www.youtube.com/playlist?list=PL..."        # Full playlist
yt-dlp --playlist-items 1-10 "URL"                           # First 10 only
```

### Channel Videos

```bash
yt-dlp "https://www.youtube.com/@ChannelName/videos"
```

### Extract Metadata (No Download)

```bash
yt-dlp --dump-json "URL"                                     # Full JSON metadata
yt-dlp --print "%(title)s" "URL"                             # Just title
yt-dlp --print "%(title)s | %(duration)s" "URL"              # Title + duration
yt-dlp --flat-playlist --print "%(title)s" "PLAYLIST_URL"    # Playlist titles
yt-dlp -F "URL"                                              # List available formats
```

### Subtitles

```bash
yt-dlp --list-subs "URL"                                     # List available subs
yt-dlp --write-subs --sub-langs "en.*" --embed-subs "URL"    # Download + embed English
yt-dlp --write-auto-subs --sub-langs "en" --skip-download "URL"  # Subs only
```

## Output Location

Default: current directory. Control with `-o`:

```bash
yt-dlp -o "~/Downloads/%(title)s [%(id)s].%(ext)s" "URL"
yt-dlp -o "~/Music/%(uploader)s/%(title)s.%(ext)s" "URL"
```

## Useful Flags

| Flag | Purpose |
|------|---------|
| `-f FORMAT` | Format selection string |
| `-x` | Extract audio only |
| `--audio-format FMT` | Audio format (mp3, m4a, wav, opus, flac) |
| `-o TEMPLATE` | Output filename template |
| `--embed-metadata` | Embed metadata in file |
| `--embed-thumbnail` | Embed thumbnail |
| `--embed-subs` | Embed subtitles |
| `--sponsorblock-remove all` | Remove sponsored segments |
| `--concurrent-fragments N` | Parallel downloads (faster) |
| `--dump-json` | Print metadata as JSON |
| `--print TEMPLATE` | Print specific fields |
| `-F` | List available formats |
| `--flat-playlist` | List playlist items without downloading |
| `--playlist-items RANGE` | Download specific playlist items |
| `--dateafter YYYYMMDD` | Only videos after date |
| `--limit-rate RATE` | Limit download speed (e.g., `5M`) |
| `--geo-bypass` | Bypass geo-restrictions |

## Supported Sites

YouTube, Vimeo, Twitch, SoundCloud, TikTok, Twitter/X, Instagram, Facebook, Dailymotion, Reddit, and [1000+ others](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md). Any URL worth trying — yt-dlp probably supports it.

## Detailed Reference

Full format strings, output templates, playlist options, SponsorBlock, speed controls, troubleshooting: read [references/guide.md](references/guide.md).
