# yt-dlp Reference

Complete option reference for common yt-dlp operations.

## Format Selection

### List Available Formats

```bash
yt-dlp -F "URL"
```

### Format Strings

| Format String | Description |
|---------------|-------------|
| `bv+ba/b` | Best video + best audio merged (default) |
| `bv*[height<=1080]+ba/b[height<=1080]` | Best up to 1080p |
| `bv*[height<=720]+ba/b[height<=720]` | Best up to 720p |
| `bv*[height<=480]+ba/b[height<=480]` | Best up to 480p |
| `ba/b` | Best audio only (no video) |
| `bv/b` | Best video only (no audio) |
| `137+140` | Specific format IDs (from `-F` output) |

### Merge Output

```bash
yt-dlp -f "bv+ba" --merge-output-format mp4 "URL"    # MP4
yt-dlp -f "bv+ba" --merge-output-format mkv "URL"    # MKV
yt-dlp -f "bv+ba" --merge-output-format webm "URL"   # WebM
```

---

## Audio Extraction

```bash
yt-dlp -x --audio-format mp3 --audio-quality 0 "URL"    # Best MP3
yt-dlp -x --audio-format m4a "URL"                        # M4A (AAC)
yt-dlp -x --audio-format opus "URL"                       # Opus
yt-dlp -x --audio-format wav "URL"                        # WAV (lossless)
yt-dlp -x --audio-format flac "URL"                       # FLAC (lossless)
```

`--audio-quality`: 0 = best, 9 = worst. Default: 5.

---

## Output Templates

```bash
yt-dlp -o "TEMPLATE" "URL"
```

| Placeholder | Value |
|-------------|-------|
| `%(title)s` | Video title |
| `%(id)s` | Video ID |
| `%(uploader)s` | Channel name |
| `%(upload_date)s` | Upload date (YYYYMMDD) |
| `%(duration)s` | Duration in seconds |
| `%(view_count)s` | View count |
| `%(ext)s` | File extension |
| `%(playlist_index)s` | Index in playlist |
| `%(playlist_title)s` | Playlist name |
| `%(resolution)s` | Resolution (e.g., 1920x1080) |

**Common patterns:**

```bash
# Default (config): Title [ID].ext
-o "%(title)s [%(id)s].%(ext)s"

# Organized by channel
-o "%(uploader)s/%(title)s [%(id)s].%(ext)s"

# Playlist organized
-o "%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s"

# Date-based
-o "%(upload_date)s - %(title)s.%(ext)s"
```

---

## Playlists & Channels

```bash
# Full playlist
yt-dlp "https://www.youtube.com/playlist?list=PL..."

# Specific items (1, 2, 5, and 10-20)
yt-dlp --playlist-items 1,2,5,10-20 "URL"

# First 5 only
yt-dlp --playlist-end 5 "URL"

# Channel videos
yt-dlp "https://www.youtube.com/@ChannelName/videos"

# Reverse order (oldest first)
yt-dlp --playlist-reverse "URL"
```

---

## Subtitles

```bash
# List available subs
yt-dlp --list-subs "URL"

# Download + embed English subs
yt-dlp --write-subs --sub-langs "en.*" --embed-subs "URL"

# Auto-generated subs if no manual ones
yt-dlp --write-auto-subs --sub-langs "en" --embed-subs "URL"

# Download subs only (no video)
yt-dlp --write-subs --sub-langs "en" --skip-download "URL"
```

---

## Metadata & Thumbnails

```bash
# Embed everything (default config does this)
yt-dlp --embed-metadata --embed-thumbnail --embed-subs "URL"

# Write thumbnail to disk (separate file)
yt-dlp --write-thumbnail "URL"

# Write description to .description file
yt-dlp --write-description "URL"

# Write info JSON
yt-dlp --write-info-json "URL"
```

---

## Metadata Extraction (No Download)

Extract video info as JSON without downloading:

```bash
# Full metadata JSON
yt-dlp --dump-json "URL"

# Just title
yt-dlp --print "%(title)s" "URL"

# Title + duration + view count
yt-dlp --print "%(title)s | %(duration)s | %(view_count)s" "URL"

# Playlist titles
yt-dlp --flat-playlist --print "%(title)s" "PLAYLIST_URL"
```

---

## Date Filters

```bash
# Videos uploaded after a date
yt-dlp --dateafter 20240101 "URL"

# Videos uploaded before a date
yt-dlp --datebefore 20241231 "URL"

# Videos uploaded in a range
yt-dlp --dateafter 20240101 --datebefore 20240630 "URL"
```

---

## Speed & Network

```bash
# Limit download speed
yt-dlp --limit-rate 5M "URL"           # 5 MB/s

# Retry on failure
yt-dlp --retries 10 "URL"

# Use proxy
yt-dlp --proxy socks5://127.0.0.1:1080 "URL"

# Resume partial download
yt-dlp --continue "URL"

# Concurrent fragment downloads (faster)
yt-dlp --concurrent-fragments 4 "URL"
```

---

## SponsorBlock

```bash
# Skip sponsored segments
yt-dlp --sponsorblock-remove all "URL"

# Skip only sponsor + intro
yt-dlp --sponsorblock-remove "sponsor,intro" "URL"

# Mark segments in chapters (don't remove)
yt-dlp --sponsorblock-mark all "URL"
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Unable to download webpage" | Update: `yt-dlp -U` or `pip3 install -U yt-dlp` |
| "ffmpeg not found" | Install ffmpeg: `apt install ffmpeg` or `brew install ffmpeg` |
| "Sign in to confirm you're not a bot" | Use cookies: `--cookies-from-browser chrome` |
| "Video unavailable" | May be region-locked — try `--geo-bypass` |
| Slow downloads | Try `--concurrent-fragments 4` |
| Wrong format merged | Specify explicitly: `-f "bv*[height<=1080]+ba" --merge-output-format mp4` |
