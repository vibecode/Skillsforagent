---
name: vibecode-integration-youtube
display_name: YouTube
provider_skill: true
integration_dependencies:
  - youtube
description: >
  YouTube Data API for managing channels, videos, playlists, and analytics.
  Consult this skill:
  1. When the user asks to search for videos or get video details
  2. When the user wants to manage playlists or view channel info
  3. When the user asks about video comments, captions, or analytics
  4. When the user mentions YouTube, videos, or their channel
metadata: {"openclaw": {"emoji": "📺", "requires": {"env": ["YOUTUBE_ACCESS_TOKEN"]}}}
---

# YouTube Integration

Data API v3 for videos, channels, playlists, search, comments, and captions.

**Auth**: Bearer token via `YOUTUBE_ACCESS_TOKEN` (OAuth via Nango).
**Base URL**: `https://www.googleapis.com/youtube/v3`

## Scope & Limitations — read this before attempting writes

The token's capabilities are controlled by the OAuth scopes granted at connect
time. Two common scope setups:

| Scope | Reads | Writes |
|---|---|---|
| `youtube.readonly` | ✓ all | ✗ everything 401/403s |
| `youtube.force-ssl` | ✓ all | ✓ playlists, comments, metadata, subscriptions |
| `youtube.upload` | — | ✓ upload videos (in addition to above) |

**If you call a write endpoint (POST / PUT / DELETE) and get 401 or 403, do not
retry blindly.** That's almost certainly a missing scope — the Nango `youtube`
OAuth integration was configured with read-only scope. Tell the user:

> "Writes are blocked because the connection was made with read-only scope.
> An admin needs to add `https://www.googleapis.com/auth/youtube.force-ssl` to
> the Nango YouTube integration's OAuth Scopes field, then you'll need to
> reconnect YouTube to pick up the new grant."

Reads (search, channel info, video details, playlist contents, subscriptions,
comments) work with either scope.

```bash
YT="https://www.googleapis.com/youtube/v3"

curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" "$YT/<endpoint>"
```

## Search

```bash
# Search videos
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/search?part=snippet&q=machine+learning+tutorial&type=video&maxResults=10"

# Search channels
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/search?part=snippet&q=tech+reviews&type=channel&maxResults=5"

# Search playlists
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/search?part=snippet&q=coding+playlist&type=playlist&maxResults=5"

# Search with filters
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/search?part=snippet&q=react+tutorial&type=video&order=viewCount&publishedAfter=2026-01-01T00:00:00Z&maxResults=10"
```

## My channel

```bash
# Get authenticated user's channel
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/channels?part=snippet,statistics,contentDetails&mine=true"

# Get channel by ID
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/channels?part=snippet,statistics&id={channelId}"
```

## Videos

```bash
# Get video details
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/videos?part=snippet,statistics,contentDetails&id={videoId}"

# List my uploaded videos
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/search?part=snippet&forMine=true&type=video&order=date&maxResults=20"

# Get video statistics (views, likes, comments)
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/videos?part=statistics&id={videoId}" | jq '.items[0].statistics'

# Update video metadata
curl -s -X PUT -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$YT/videos?part=snippet" \
  -d '{"id":"{videoId}","snippet":{"title":"Updated Title","description":"New description","categoryId":"22","tags":["tag1","tag2"]}}'
```

## Playlists

```bash
# List my playlists
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/playlists?part=snippet,contentDetails&mine=true&maxResults=20"

# Get playlist items
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/playlistItems?part=snippet&playlistId={playlistId}&maxResults=50"

# Create playlist
curl -s -X POST -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$YT/playlists?part=snippet,status" \
  -d '{"snippet":{"title":"My Playlist","description":"Curated videos"},"status":{"privacyStatus":"private"}}'

# Add video to playlist
curl -s -X POST -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$YT/playlistItems?part=snippet" \
  -d '{"snippet":{"playlistId":"{playlistId}","resourceId":{"kind":"youtube#video","videoId":"{videoId}"}}}'
```

## Comments

```bash
# List comments on a video
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/commentThreads?part=snippet&videoId={videoId}&maxResults=20&order=relevance"

# Post a comment
curl -s -X POST -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$YT/commentThreads?part=snippet" \
  -d '{"snippet":{"videoId":"{videoId}","topLevelComment":{"snippet":{"textOriginal":"Great video!"}}}}'

# Reply to a comment
curl -s -X POST -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$YT/comments?part=snippet" \
  -d '{"snippet":{"parentId":"{commentId}","textOriginal":"Thanks for watching!"}}'
```

## Captions

```bash
# List captions for a video
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/captions?part=snippet&videoId={videoId}"

# Download caption track
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/captions/{captionId}?tfmt=srt" -o captions.srt
```

## Subscriptions

```bash
# List my subscriptions
curl -s -H "Authorization: Bearer $YOUTUBE_ACCESS_TOKEN" \
  "$YT/subscriptions?part=snippet&mine=true&maxResults=20"
```

## Tips

- **Video IDs are in the URL**: `youtube.com/watch?v=VIDEO_ID`.
- **`part` parameter is required** on every request — controls which data sections are returned (`snippet`, `statistics`, `contentDetails`, `status`).
- **Quota**: YouTube API has a daily quota (default 10,000 units). Searches cost 100 units, reads cost 1-3, writes cost 50+. Monitor usage.
- **Pagination**: Use `pageToken` from response's `nextPageToken`.
- **`order`** options for search: `date`, `rating`, `relevance`, `title`, `viewCount`.
- **Category IDs**: `22` = People & Blogs, `28` = Science & Technology, `10` = Music. Full list via `videoCategories` endpoint.
- **401/403 on writes only** — scope issue, not a code issue. See "Scope & Limitations" at the top.
- **401/403 on everything including reads** — token expired/revoked, reconnect YouTube.

---

*Based on [michaelgathara/youtube-watcher](https://skills.sh/michaelgathara/youtube-watcher), [YouTube Data API v3 Reference](https://developers.google.com/youtube/v3/docs), and [Nango YouTube integration](https://nango.dev/docs/api-integrations/youtube).*
