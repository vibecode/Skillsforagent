---
name: vibecode-integration-spotify
description: >
  Spotify Web API for managing playlists, searching music, and controlling playback.
  Consult this skill:
  1. When the user asks to search for songs, artists, or albums
  2. When the user wants to manage playlists or view their library
  3. When the user asks to control playback or check what's playing
  4. When the user mentions Spotify, music, or playlists
metadata: {"openclaw": {"emoji": "🎵", "requires": {"env": ["SPOTIFY_ACCESS_TOKEN"]}}}
---

# Spotify Integration

Web API for search, playlists, library, playback control, and user profile.

**Auth**: Bearer token via `SPOTIFY_ACCESS_TOKEN`.
**Base URL**: `https://api.spotify.com/v1`

```bash
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" "https://api.spotify.com/v1/<endpoint>"
```

## Search

```bash
# Search tracks
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/search?q=bohemian+rhapsody&type=track&limit=5"

# Search artists
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/search?q=radiohead&type=artist&limit=5"

# Search albums
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/search?q=dark+side+of+the+moon&type=album&limit=5"

# Multi-type search
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/search?q=taylor+swift&type=track,artist,album&limit=5"
```

## Player / playback

```bash
# Get currently playing
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player/currently-playing"

# Get playback state
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player"

# Get available devices
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player/devices"

# Start/resume playback
curl -s -X PUT -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.spotify.com/v1/me/player/play" \
  -d '{"uris":["spotify:track:4cOdK2wGLETKBW3PvgPWqT"]}'

# Pause
curl -s -X PUT -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player/pause"

# Skip to next/previous
curl -s -X POST -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player/next"
curl -s -X POST -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player/previous"

# Get recently played
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player/recently-played?limit=20"

# Add to queue
curl -s -X POST -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/player/queue?uri=spotify:track:4cOdK2wGLETKBW3PvgPWqT"
```

## Playlists

```bash
# List user's playlists
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/playlists?limit=20"

# Get playlist tracks
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/playlists/{id}/tracks?limit=50"

# Create playlist
curl -s -X POST -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.spotify.com/v1/me/playlists" \
  -d '{"name":"My Playlist","description":"Created by agent","public":false}'

# Add tracks to playlist
curl -s -X POST -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.spotify.com/v1/playlists/{id}/tracks" \
  -d '{"uris":["spotify:track:4cOdK2wGLETKBW3PvgPWqT","spotify:track:1301WleyT98MSxVHPZCA6M"]}'

# Remove tracks from playlist
curl -s -X DELETE -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.spotify.com/v1/playlists/{id}/tracks" \
  -d '{"tracks":[{"uri":"spotify:track:4cOdK2wGLETKBW3PvgPWqT"}]}'
```

## Library

```bash
# Get user's saved tracks
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/tracks?limit=20"

# Get user's top tracks
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/top/tracks?time_range=medium_term&limit=20"

# Get user's top artists
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/top/artists?time_range=medium_term&limit=20"

# Save tracks to library
curl -s -X PUT -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me/tracks?ids=4cOdK2wGLETKBW3PvgPWqT"
```

## User profile

```bash
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/me"
```

## Tips

- **Spotify URIs**: Format is `spotify:track:ID`, `spotify:album:ID`, `spotify:artist:ID`, `spotify:playlist:ID`.
- **Playback requires active device** — check `/me/player/devices` first. Transfer playback with `PUT /me/player` + `device_ids`.
- **Token expires ~1 hour** — Nango handles refresh. If 401, tell user to reconnect.
- **`time_range`** for top tracks/artists: `short_term` (~4 weeks), `medium_term` (~6 months), `long_term` (all time).
- **Pagination**: Offset-based with `limit` and `offset` params.

---

*Based on [steipete/spotify-player](https://skills.sh/steipete/clawdis/spotify-player), [fabioc-aloha/spotify-api](https://skills.sh/fabioc-aloha/spotify-skill/spotify-api), and [Spotify Web API Reference](https://developer.spotify.com/documentation/web-api).*
