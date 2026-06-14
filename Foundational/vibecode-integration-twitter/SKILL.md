---
name: vibecode-integration-twitter
display_name: X (Twitter)
provider_skill: true
integration_dependencies:
  - twitter
description: >
  X (Twitter) v2 API for reading and posting tweets, searching the timeline,
  managing likes / follows / bookmarks / lists, working with Spaces, sending
  direct messages, uploading media, and moderating replies. Consult this skill:
  1. When the user wants to post, delete, retweet, or moderate replies to a tweet
  2. When the user wants to read their timeline, mentions, or a specific user's tweets
  3. When the user wants to search recent tweets by keyword, hashtag, or filter
  4. When the user wants to like, bookmark, follow, block, mute, or manage lists
  5. When the user wants to send or read direct messages on X / Twitter
  6. When the user wants to upload media, look up Spaces, or fetch Space recordings
  7. When the user mentions Twitter, X, tweets, DMs, Spaces, or the X API
metadata: {"openclaw": {"emoji": "🐦", "requires": {"env": ["TWITTER_ACCESS_TOKEN"]}}}
---

# X (Twitter) Integration

REST v2 API for the X platform. Bearer-token authenticated, called as the connected user.

**Auth**: Bearer token via `Authorization` header.
**Base URL**: `https://api.twitter.com`
**Scope-gated**: every endpoint below lists the OAuth scopes it needs. If a call returns `403 Forbidden` with `"required_enrollment"` or `"unauthorized_for_resource"`, the connection is missing a scope — broaden the scope list in Nango and have the user reconnect.
**Tier note**: Free X API tier is severely limited (≈100 tweet reads / 500 writes per month). Basic ($100/mo) and Pro tiers raise these. Rate-limit headers (`x-rate-limit-remaining`, `x-rate-limit-reset`) appear on every response — always check before retrying.

```bash
# All requests use Bearer auth
curl -s "https://api.twitter.com/2/<endpoint>" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"
```

## Current user

Identify the connected account. Useful as a first call to confirm auth is healthy and to learn the user's numeric ID for endpoints that take `{user_id}`.

```bash
# Scope: users.read
curl -s "https://api.twitter.com/2/users/me" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Request additional user fields
curl -s -G "https://api.twitter.com/2/users/me" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "user.fields=id,name,username,description,public_metrics,verified,created_at"
```

Returns `{ data: { id, name, username } }`. The numeric `id` is what most write endpoints expect — cache it.

## Tweets — read

```bash
# Scope: tweet.read

# Single tweet by ID
curl -s "https://api.twitter.com/2/tweets/{id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Multiple tweets (comma-separated, up to 100)
curl -s -G "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "ids=1234567890,1234567891"

# Request specific tweet fields + expansions
curl -s -G "https://api.twitter.com/2/tweets/{id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "tweet.fields=created_at,public_metrics,entities,referenced_tweets" \
  --data-urlencode "expansions=author_id,attachments.media_keys" \
  --data-urlencode "user.fields=username,verified" \
  --data-urlencode "media.fields=type,url,preview_image_url"

# User timeline (their recent tweets) — max 100 per page
curl -s -G "https://api.twitter.com/2/users/{user_id}/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "max_results=20"

# User mentions (tweets that mention {user_id})
curl -s -G "https://api.twitter.com/2/users/{user_id}/mentions" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "max_results=20"

# Home timeline (reverse-chronological tweets from accounts the user follows)
# Scope: tweet.read users.read
curl -s "https://api.twitter.com/2/users/{user_id}/timelines/reverse_chronological" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"
```

## Tweets — search

```bash
# Scope: tweet.read

# Recent search (last 7 days). Operators: from:, to:, @, #, lang:, has:media, -is:retweet
curl -s -G "https://api.twitter.com/2/tweets/search/recent" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "query=from:elonmusk -is:retweet" \
  --data-urlencode "max_results=20" \
  --data-urlencode "tweet.fields=created_at,public_metrics"

# Search with time window
curl -s -G "https://api.twitter.com/2/tweets/search/recent" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "query=#ai lang:en" \
  --data-urlencode "start_time=2024-01-01T00:00:00Z" \
  --data-urlencode "end_time=2024-01-07T23:59:59Z"

# Full-archive search (Pro tier only — falls back to 403 on lower tiers)
curl -s -G "https://api.twitter.com/2/tweets/search/all" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "query=#launch"
```

## Tweets — write

```bash
# Scope: tweet.write users.read

# Post a plain tweet
curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from the API"}'

# Reply to a tweet
curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Great point!","reply":{"in_reply_to_tweet_id":"1234567890"}}'

# Quote a tweet
curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Worth reading","quote_tweet_id":"1234567890"}'

# Tweet with media (attach already-uploaded media_ids — see Media section)
curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Check this","media":{"media_ids":["1234567890"]}}'

# Delete a tweet (only the authenticated user's own tweets)
curl -s -X DELETE "https://api.twitter.com/2/tweets/{id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Hide a reply (only on the authenticated user's own tweets) — Scope: tweet.moderate.write
curl -s -X PUT "https://api.twitter.com/2/tweets/{reply_tweet_id}/hidden" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"hidden":true}'

# Unhide a reply
curl -s -X PUT "https://api.twitter.com/2/tweets/{reply_tweet_id}/hidden" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"hidden":false}'
```

## Media upload

The v2 native media upload endpoint (`POST /2/media/upload`) is gated by the `media.write` scope. Simple uploads (≤5 MB images) post directly to it; chunked uploads (videos, GIFs, large images) use the dedicated `/initialize`, `/{media_id}/append`, `/{media_id}/finalize` endpoints and poll status via `GET /2/media/upload?command=STATUS&media_id=...`.

```bash
# Scope: media.write

# Simple upload — image up to 5 MB
curl -s -X POST "https://api.twitter.com/2/media/upload" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -F "media=@/path/to/image.png" \
  -F "media_category=tweet_image"

# Chunked upload: INITIALIZE (dedicated endpoint, JSON body — returns media_id)
curl -s -X POST "https://api.twitter.com/2/media/upload/initialize" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"total_bytes":12345678,"media_type":"video/mp4","media_category":"tweet_video"}'

# Chunked upload: APPEND (one call per chunk, segment_index 0..999, max 5 MB per chunk)
curl -s -X POST "https://api.twitter.com/2/media/upload/{media_id}/append" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -F "segment_index=0" \
  -F "media=@/path/to/chunk_0.bin"

# Chunked upload: FINALIZE
curl -s -X POST "https://api.twitter.com/2/media/upload/{media_id}/finalize" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Poll processing status (videos require this before they're attachable)
curl -s -G "https://api.twitter.com/2/media/upload" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "command=STATUS" \
  --data-urlencode "media_id={media_id}"
```

`media_category` values: `tweet_image`, `tweet_video`, `tweet_gif`, `dm_image`, `dm_video`, `dm_gif`, `amplify_video`, `subtitles`. Once the `STATUS` poll returns `processing_info.state = "succeeded"`, attach the `media_id` to a tweet via the `media.media_ids` field in `POST /2/tweets`.

## Retweets

```bash
# Scope: tweet.write users.read

# Retweet a tweet
curl -s -X POST "https://api.twitter.com/2/users/{user_id}/retweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tweet_id":"1234567890"}'

# Undo retweet
curl -s -X DELETE "https://api.twitter.com/2/users/{user_id}/retweets/{tweet_id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"
```

## Likes

```bash
# Like a tweet — Scope: like.write users.read
curl -s -X POST "https://api.twitter.com/2/users/{user_id}/likes" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tweet_id":"1234567890"}'

# Unlike — Scope: like.write users.read
curl -s -X DELETE "https://api.twitter.com/2/users/{user_id}/likes/{tweet_id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# List tweets a user has liked — Scope: like.read tweet.read users.read
curl -s "https://api.twitter.com/2/users/{user_id}/liked_tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"
```

## Users — lookup, follow, block, mute

```bash
# Lookup by username — Scope: users.read tweet.read
curl -s "https://api.twitter.com/2/users/by/username/{username}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Lookup by ID(s)
curl -s -G "https://api.twitter.com/2/users" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "ids=123,456,789"

# Who the user follows — Scope: follows.read users.read
curl -s "https://api.twitter.com/2/users/{user_id}/following" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Who follows the user
curl -s "https://api.twitter.com/2/users/{user_id}/followers" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Follow a user — Scope: follows.write users.read
curl -s -X POST "https://api.twitter.com/2/users/{user_id}/following" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_user_id":"9876543210"}'

# Unfollow — Scope: follows.write users.read
curl -s -X DELETE "https://api.twitter.com/2/users/{source_user_id}/following/{target_user_id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Block — Scope: block.write users.read
curl -s -X POST "https://api.twitter.com/2/users/{user_id}/blocking" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_user_id":"9876543210"}'

# Mute — Scope: mute.write users.read
curl -s -X POST "https://api.twitter.com/2/users/{user_id}/muting" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_user_id":"9876543210"}'
```

## Lists

```bash
# Scope: list.read | list.write users.read

# Get a list
curl -s "https://api.twitter.com/2/lists/{list_id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Lists owned by a user
curl -s "https://api.twitter.com/2/users/{user_id}/owned_lists" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Tweets from a list
curl -s "https://api.twitter.com/2/lists/{list_id}/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Create a list
curl -s -X POST "https://api.twitter.com/2/lists" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Engineering Leaders","description":"VPs of Eng to follow","private":false}'

# Add a member
curl -s -X POST "https://api.twitter.com/2/lists/{list_id}/members" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"9876543210"}'

# Remove a member
curl -s -X DELETE "https://api.twitter.com/2/lists/{list_id}/members/{user_id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"
```

## Bookmarks

```bash
# Scope: bookmark.read | bookmark.write users.read

# List the user's bookmarked tweets
curl -s "https://api.twitter.com/2/users/{user_id}/bookmarks" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Bookmark a tweet
curl -s -X POST "https://api.twitter.com/2/users/{user_id}/bookmarks" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tweet_id":"1234567890"}'

# Remove a bookmark
curl -s -X DELETE "https://api.twitter.com/2/users/{user_id}/bookmarks/{tweet_id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"
```

## Spaces

```bash
# Scope: space.read tweet.read users.read

# Get a Space by ID
curl -s "https://api.twitter.com/2/spaces/{space_id}" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Look up multiple Spaces
curl -s -G "https://api.twitter.com/2/spaces" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "ids=1mrGmkRYKEEKy,1OdJrXgYWvRJX"

# Spaces by creator(s) — comma-separated user IDs
curl -s -G "https://api.twitter.com/2/spaces/by/creator_ids" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "user_ids=123,456"

# Search Spaces (live + scheduled)
curl -s -G "https://api.twitter.com/2/spaces/search" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "query=AI" \
  --data-urlencode "state=live"

# Tweets shared inside a Space (host curated)
curl -s "https://api.twitter.com/2/spaces/{space_id}/tweets" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Buyers of a Space's Ticketed access (for the host only)
curl -s "https://api.twitter.com/2/spaces/{space_id}/buyers" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"
```

State values: `live`, `scheduled`, `ended`. Only `live` and `scheduled` Spaces are queryable in detail; ended Spaces are best-effort.

## Direct messages

```bash
# Scope: dm.read | dm.write users.read

# List DM events (most recent first)
curl -s "https://api.twitter.com/2/dm_events" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Get events in a specific conversation
curl -s "https://api.twitter.com/2/dm_conversations/{dm_conversation_id}/dm_events" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN"

# Send a DM to a user (starts a conversation if none exists)
curl -s -X POST "https://api.twitter.com/2/dm_conversations/with/{participant_id}/messages" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hi! Saw your tweet about X."}'

# Send a DM in an existing group conversation
curl -s -X POST "https://api.twitter.com/2/dm_conversations/{dm_conversation_id}/messages" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Replying to the group"}'

# Create a group DM conversation
curl -s -X POST "https://api.twitter.com/2/dm_conversations" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"conversation_type":"Group","participant_ids":["123","456"],"message":{"text":"Group thread started"}}'
```

DM target must follow the sender (or be a brand/business account). 403 means the recipient blocks DMs from strangers — surface that to the user; it is not a transient error.

## Tweet counts (analytics)

```bash
# Scope: tweet.read

# Count tweets matching a query in time buckets (last 7 days)
curl -s -G "https://api.twitter.com/2/tweets/counts/recent" \
  -H "Authorization: Bearer $TWITTER_ACCESS_TOKEN" \
  --data-urlencode "query=#vibecoded" \
  --data-urlencode "granularity=day"
```

## Tips

- **Cache the connected user's `id`**: nearly every write endpoint requires `{user_id}` in the path, and it's stable for the lifetime of the account.
- **Rate limits are per-endpoint, per-tier, and tight**: always parse `x-rate-limit-remaining` from the response. On `429`, honour the `x-rate-limit-reset` epoch — do not retry sooner.
- **`max_results` caps vary**: timeline endpoints cap at 100; search at 100 (Free/Basic) or 500 (Pro). Exceeding the cap returns `400 Bad Request` with a `value out of range` problem — clamp before sending.
- **Pagination**: responses include a `meta.next_token`. Pass it back as `pagination_token` to get the next page. Stop when `next_token` is absent.
- **Tweet text limits**: 280 chars for standard accounts, 4000 for X Premium. The API rejects over-length tweets with 400 — count grapheme clusters, not bytes.
- **Soft-deleted tweets**: a tweet may return `200` with `errors[]` indicating it was deleted or the author was suspended. Always check for `errors[]` even on 200.
- **Free-tier media uploads**: `POST /2/media/upload` works on Free tier with the `media.write` scope, but `/initialize` and `/finalize` are capped at ~17 requests / 24h on Free — a 403 most often means missing `media.write`, a 429 means you hit the cap.
