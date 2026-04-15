---
name: vibecode-integration-spotify
display_name: Spotify
provider_skill: true
integration_dependencies:
  - spotify
description: >
  Spotify Web API for searching and browsing the public music catalog —
  tracks, artists, albums, audio features, new releases. Uses app-level
  Client Credentials auth (no user account context).
  Consult this skill:
  1. When the user asks to search for songs, artists, or albums on Spotify
  2. When the user wants details about a track, album, or artist
  3. When the user asks about audio features (tempo, key, danceability)
  4. When the user wants new releases or what's trending in a category
  5. When the user mentions Spotify or asks for music information
metadata: {"openclaw": {"emoji": "🎵", "requires": {"env": ["SPOTIFY_ACCESS_TOKEN"]}}}
---

# Spotify Integration

Web API for catalog search, track/album/artist metadata, audio features, and
public browse content.

**Auth**: Bearer token via `SPOTIFY_ACCESS_TOKEN`. Token comes from Nango's
`spotify-oauth2-cc` integration — **app-level Client Credentials, not a user
account**.
**Base URL**: `https://api.spotify.com/v1`

## What this token CAN do — read this first

This token authenticates as an *application*, not as a user. Nango's
`spotify-oauth2-cc` integration was chosen specifically so we don't need
each user to authorize the app on Spotify's developer allowlist.

| Capability | Works? |
|---|---|
| Search tracks, artists, albums, playlists | ✓ |
| Get track / album / artist by ID | ✓ |
| Get audio features and audio analysis | ✓ |
| Browse new releases, featured playlists, categories | ✓ |
| Read a *public* playlist by ID | ✓ |
| Get artist's top tracks, related artists, albums | ✓ |
| **Anything under `/me/*`** (current playback, devices, recently played, top tracks, saved library, user playlists) | ✗ 401 |
| **Control playback** (play/pause/skip/seek/volume) | ✗ 401 |
| **Create / modify playlists** | ✗ 401 |
| **Save / unsave tracks** | ✗ 401 |
| **Follow / unfollow artists** | ✗ 401 |

**If the user asks to "play X" or "add X to my playlist" or "what am I
listening to right now"** — tell them:

> "This Spotify connection is catalog-only (app-level credentials). It can't
> control playback or access your personal account. For playback control or
> playlist management, we'd need a separate user-OAuth Spotify connection,
> which Spotify hasn't yet approved for our app."

Don't try the request and let it 401 — pre-empt with the explanation.

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

# Search public playlists (returns playlists owned by anyone, not user's own)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/search?q=workout&type=playlist&limit=5"

# Multi-type search
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/search?q=taylor+swift&type=track,artist,album&limit=5"

# Filter by year, genre, market
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/search?q=year:2024+genre:rock&type=track&market=US&limit=20"
```

## Tracks

```bash
# Get a track by ID
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/tracks/4cOdK2wGLETKBW3PvgPWqT"

# Get multiple tracks (up to 50)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/tracks?ids=4cOdK2wGLETKBW3PvgPWqT,1301WleyT98MSxVHPZCA6M"
```

## Albums

```bash
# Get an album by ID
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/albums/4aawyAB9vmqN3uQ7FjRGTy"

# Get multiple albums (up to 20)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/albums?ids=4aawyAB9vmqN3uQ7FjRGTy,1DFixLWuPkv3KT3TnV35m3"

# Get tracks in an album
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/albums/4aawyAB9vmqN3uQ7FjRGTy/tracks?limit=50"
```

## Artists

```bash
# Get an artist by ID
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/artists/4Z8W4fKeB5YxbusRsdQVPb"

# Get multiple artists (up to 50)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/artists?ids=4Z8W4fKeB5YxbusRsdQVPb,1dfeR4HaWDbWqFHLkxsg1d"

# Get an artist's top tracks (market is required)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/artists/4Z8W4fKeB5YxbusRsdQVPb/top-tracks?market=US"

# Get an artist's albums
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/artists/4Z8W4fKeB5YxbusRsdQVPb/albums?include_groups=album,single&limit=20"

# Get related artists
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/artists/4Z8W4fKeB5YxbusRsdQVPb/related-artists"
```

## Audio features & analysis

```bash
# Get audio features for one track (tempo, key, danceability, energy, valence)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/audio-features/4cOdK2wGLETKBW3PvgPWqT"

# Get audio features for multiple tracks (up to 100)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/audio-features?ids=4cOdK2wGLETKBW3PvgPWqT,1301WleyT98MSxVHPZCA6M"

# Get full audio analysis (sections, segments, beats, bars, tatums)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/audio-analysis/4cOdK2wGLETKBW3PvgPWqT"
```

## Browse / discovery

```bash
# New album releases
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/browse/new-releases?country=US&limit=20"

# Featured playlists
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/browse/featured-playlists?country=US&limit=20"

# All categories (Pop, Hip-Hop, Workout, etc.)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/browse/categories?country=US&limit=50"

# Playlists in a category
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/browse/categories/{category_id}/playlists?country=US&limit=20"
```

## Public playlists (read-only)

```bash
# Read a public playlist by ID
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M"

# Get tracks in a public playlist
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M/tracks?limit=50"
```

Private playlists (and any modifications) require user OAuth — not available
on this connection.

## Markets

```bash
# List of markets where Spotify is available (use as `market=` filter elsewhere)
curl -s -H "Authorization: Bearer $SPOTIFY_ACCESS_TOKEN" \
  "https://api.spotify.com/v1/markets"
```

## Tips

- **Spotify URIs**: Format is `spotify:track:ID`, `spotify:album:ID`,
  `spotify:artist:ID`, `spotify:playlist:ID`. The ID alone (no `spotify:`
  prefix) is what most endpoints take in the URL path.
- **`market` parameter**: Many endpoints (top-tracks, search, get-track) need
  or accept a market code (ISO 3166-1, e.g. `US`, `GB`, `DE`). Required for
  `top-tracks`. For others, omit to use the app's default market or pass
  `from_token` (not available on Client Credentials — use a literal code).
- **Token expires ~1 hour** — Nango refreshes automatically. If 401 hits
  even on `/search`, the Nango integration's Client ID/Secret may be invalid.
- **Pagination**: Offset-based with `limit` (max 50, sometimes 100) and
  `offset` params. Response includes `next` URL.
- **`/recommendations` endpoint is deprecated** for apps created after
  November 2024 — don't rely on it for new functionality.
- **401 on a `/me/*` endpoint** is not a bug — see the table at the top.
  Tell the user this connection is catalog-only.

---

*Based on [Spotify Web API Reference](https://developer.spotify.com/documentation/web-api) and [Nango spotify-oauth2-cc integration](https://nango.dev/docs/integrations/all/spotify-oauth2-cc).*
