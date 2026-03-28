---
name: vibecode-integration-typefully
display_name: Typefully
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

**Auth**: API key via `TYPEFULLY_API_KEY` using `X-API-KEY` header (not Bearer).
**Base URL**: `https://api.typefully.com/v1`

```bash
curl -s https://api.typefully.com/v1/<endpoint> \
  -H "X-API-KEY: $TYPEFULLY_API_KEY" \
  -H "Content-Type: application/json"
```

## Create draft

```bash
# Create a simple tweet/post
curl -s -X POST -H "X-API-KEY: $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v1/drafts/" \
  -d '{"content":"Just shipped a new feature! 🚀","threadify":false}'

# Create a thread (use \n\n\n\n to separate tweets)
curl -s -X POST -H "X-API-KEY: $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v1/drafts/" \
  -d '{"content":"Thread about AI agents 🧵\n\n\n\n1/ First, what are AI agents?\n\n\n\n2/ They can use tools autonomously\n\n\n\n3/ The future is agentic","threadify":false}'

# Auto-threadify (let Typefully split into tweets)
curl -s -X POST -H "X-API-KEY: $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v1/drafts/" \
  -d '{"content":"Long post that Typefully will automatically split into a thread based on character limits...","threadify":true}'

# Schedule a post
curl -s -X POST -H "X-API-KEY: $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v1/drafts/" \
  -d '{"content":"Scheduled post","schedule-date":"2026-03-26T14:00:00Z"}'

# Schedule for next free slot
curl -s -X POST -H "X-API-KEY: $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v1/drafts/" \
  -d '{"content":"Next available slot","auto-schedule":true}'

# Publish to LinkedIn too
curl -s -X POST -H "X-API-KEY: $TYPEFULLY_API_KEY" -H "Content-Type: application/json" \
  "https://api.typefully.com/v1/drafts/" \
  -d '{"content":"Cross-posted to LinkedIn","share-on-linkedin":true}'
```

## List scheduled drafts

```bash
curl -s -H "X-API-KEY: $TYPEFULLY_API_KEY" \
  "https://api.typefully.com/v1/drafts/recently-scheduled"
```

## Notifications

```bash
# Get recent notifications (replies, likes, retweets)
curl -s -H "X-API-KEY: $TYPEFULLY_API_KEY" \
  "https://api.typefully.com/v1/notifications/"
```

## Tips

- **Thread separator**: Use `\n\n\n\n` (4 newlines) to manually split tweets in a thread.
- **`threadify: true`** lets Typefully auto-split long content into optimal tweet-sized chunks.
- **`auto-schedule: true`** uses your Typefully schedule queue (set up in Typefully settings).
- **`share-on-linkedin: true`** cross-posts to LinkedIn.
- **Auth is `X-API-KEY` header**, not Bearer.
- **No delete/update API** — drafts can only be managed through the Typefully web UI once created.

---

*Based on [typefully/agent-skills/typefully](https://skills.sh/typefully/agent-skills/typefully), [synapz-org/typefully-claude-skill](https://skills.sh/synapz-org/typefully-claude-skill/typefully), and [Typefully API docs](https://support.typefully.com/en/articles/8718287-typefully-api).*
