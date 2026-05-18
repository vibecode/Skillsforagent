---
name: vibecode-integration-typefully
display_name: Typefully
provider_skill: true
integration_dependencies:
  - typefully
description: >
  Typefully API for scheduling and publishing posts to Twitter/X and LinkedIn.
  Consult this skill:
  1. When the user asks to draft, schedule, or publish social media posts
  2. When the user wants to manage their Twitter/X or LinkedIn content queue
  3. When the user mentions Typefully, tweets, threads, or social posting
metadata: {"openclaw": {"emoji": "✍️", "requires": {"env": ["TYPEFULLY_API_KEY"]}}}
---

# Typefully Integration

API for drafting, scheduling, and publishing posts to Twitter/X and LinkedIn.

**Auth**: API key via `TYPEFULLY_API_KEY` using `Authorization: Bearer ...` header.
**Base URL**: `https://api.typefully.com/v2`

```bash
curl -s https://api.typefully.com/v2/<endpoint> \
  -H "Authorization: Bearer $TYPEFULLY_API_KEY" \
  -H "Content-Type: application/json"
```

All draft endpoints need a `social_set_id`. Capture once per session:

```bash
SOCIAL_SET_ID=$(curl -s -H "Authorization: Bearer $TYPEFULLY_API_KEY" \
  "https://api.typefully.com/v2/social-sets" | jq -r '.results[0].id')
```

## Create draft

```bash
# Create a simple tweet/post
curl -s -X POST -H "Authorization: Bearer $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v2/social-sets/$SOCIAL_SET_ID/drafts" \
  -d '{"platforms":{"x":{"enabled":true,"posts":[{"text":"Just shipped a new feature! 🚀"}]}}}'

# Create a thread (one posts entry per tweet)
curl -s -X POST -H "Authorization: Bearer $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v2/social-sets/$SOCIAL_SET_ID/drafts" \
  -d '{"platforms":{"x":{"enabled":true,"posts":[
        {"text":"Thread about AI agents 🧵"},
        {"text":"1/ First, what are AI agents?"},
        {"text":"2/ They can use tools autonomously"},
        {"text":"3/ The future is agentic"}
      ]}}}'

# Schedule a post
curl -s -X POST -H "Authorization: Bearer $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v2/social-sets/$SOCIAL_SET_ID/drafts" \
  -d '{"platforms":{"x":{"enabled":true,"posts":[{"text":"Scheduled post"}]}},"publish_at":"2026-03-26T14:00:00Z"}'

# Schedule for next free slot
curl -s -X POST -H "Authorization: Bearer $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v2/social-sets/$SOCIAL_SET_ID/drafts" \
  -d '{"platforms":{"x":{"enabled":true,"posts":[{"text":"Next available slot"}]}},"publish_at":"next-free-slot"}'

# Publish to LinkedIn too
curl -s -X POST -H "Authorization: Bearer $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v2/social-sets/$SOCIAL_SET_ID/drafts" \
  -d '{"platforms":{
        "x":{"enabled":true,"posts":[{"text":"Cross-posted to LinkedIn"}]},
        "linkedin":{"enabled":true,"posts":[{"text":"Cross-posted to LinkedIn"}]}
      }}'
```

## List scheduled drafts

```bash
curl -s -H "Authorization: Bearer $TYPEFULLY_API_KEY" \
  "https://api.typefully.com/v2/social-sets/$SOCIAL_SET_ID/drafts?status=scheduled"
```

## Tips

- **Thread**: pass multiple `posts` entries in the array — one per tweet. No more `\n\n\n\n` separator.
- **`publish_at`** replaces v1's `schedule-date` / `auto-schedule`. Use `"now"`, `"next-free-slot"`, an ISO 8601 datetime, or omit to save as a draft.
- **Cross-platform**: add the platform key (`linkedin`, `mastodon`, `threads`, `bluesky`) to the `platforms` object with `enabled: true` + its own `posts`. The v1 `share-on-linkedin` flag is gone.
- **Auth is `Authorization: Bearer`**, not `X-API-KEY`. Generate a v2 key under Typefully → Settings → API.
- **Notifications endpoint is v1-only**; v2 has no equivalent (use webhooks).

---

*Based on [Typefully v1 → v2 migration guide](https://support.typefully.com/en/articles/13133296-typefully-api-v1-v2-migration-guide) and [Typefully API docs](https://typefully.com/docs/api).*
