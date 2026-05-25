---
name: vibecode-integration-slack-mcp
display_name: Slack (MCP)
provider_skill: true
integration_dependencies:
  - slack-mcp
description: >
  Slack workspace API for acting on the user's Slack on their behalf — reading
  channel history, posting messages, searching messages, managing reactions,
  and looking up users. This is the **slack-mcp connection** (agent → user's
  Slack), distinct from the `slack` channel provider (users → agent via Slack,
  currently coming soon). Consult this skill:
  1. When the user asks the agent to read, post, or search Slack messages
  2. When the user wants to react to, edit, or thread off a specific message
  3. When the user wants to look up Slack users or channels
  4. When the user mentions "Slack" in the context of doing something on Slack
     (not "receive messages via Slack" — that's a different not-yet-shipped channel)
  5. When the user asks the agent to act as them in Slack
metadata: {"openclaw": {"emoji": "💬", "requires": {"env": ["SLACK_MCP_ACCESS_TOKEN"]}}}
---

# Slack (MCP) Integration

The user's Slack OAuth token is in `SLACK_MCP_ACCESS_TOKEN`. **Call Slack's Web API directly with it** — don't try to route through Nango's MCP proxy (that requires a master Nango secret the runner doesn't have).

## What this is vs what it isn't

- **slack-mcp** (this connection) — agent acts on the user's behalf in their Slack workspace. Token type: user OAuth (`xoxp-…`). Scopes granted by the user during connect.
- **slack** (separate provider, currently coming soon) — channel where users *receive* messages from the agent and *send* messages to it. Different env var, different code path. If the user wants the agent to live in their Slack as a bot, that's the channel — not this skill.

If you're unsure which intent the user has, ask one question: *"do you want to do things in Slack, or chat with me via Slack?"* The former is this skill; the latter is the channel (and you should tell them it's coming soon).

## Auth

```bash
# All Slack Web API calls use the same Bearer pattern
curl -s "https://slack.com/api/<method>" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN"
```

Slack responses are always `{ "ok": true, ... }` or `{ "ok": false, "error": "<reason>" }`. The `ok` field is the contract — always check it before reading the rest.

## Read messages

```bash
# Channel history (most recent 100 by default)
curl -s "https://slack.com/api/conversations.history?channel=C0123ABCD&limit=50" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN"

# Thread replies (need ts of the parent message)
curl -s "https://slack.com/api/conversations.replies?channel=C0123ABCD&ts=1779565166.477149" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN"

# DM history (channel ID for a DM starts with D, get via conversations.open)
curl -s "https://slack.com/api/conversations.history?channel=D0123ABCD&limit=20" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN"
```

Scopes: `channels:history`, `groups:history` (private), `im:history` (DMs), `mpim:history` (group DMs).

## Post messages

```bash
# Post to a channel
curl -s -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel": "C0123ABCD", "text": "Hi from the agent"}'

# Reply in a thread (set thread_ts to the parent's ts)
curl -s -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel": "C0123ABCD", "thread_ts": "1779565166.477149", "text": "thread reply"}'

# Rich Block Kit message
curl -s -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel": "C0123ABCD", "blocks": [{"type":"section","text":{"type":"mrkdwn","text":"*Bold* update"}}]}'

# Edit a previously-posted message (need its ts)
curl -s -X POST "https://slack.com/api/chat.update" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel": "C0123ABCD", "ts": "1779565166.477149", "text": "edited text"}'

# Delete a message
curl -s -X POST "https://slack.com/api/chat.delete" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel": "C0123ABCD", "ts": "1779565166.477149"}'
```

Scope: `chat:write` (covers post, update, and delete of the user's own messages). Posts go from the **user**, not a bot — they show the user's name/avatar.

## Search

```bash
# Search messages across channels/DMs the user can see
curl -s -G "https://slack.com/api/search.messages" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  --data-urlencode "query=from:@ansh nango" \
  --data-urlencode "count=20"

# Search with operators (channel:, from:, before:, after:, has:link, etc.)
curl -s -G "https://slack.com/api/search.messages" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  --data-urlencode "query=in:#general after:2026-05-01"
```

Scope: `search:read` (legacy — still the only scope `search.messages` honors). The granular `search:read.public` / `.private` / `.mpim` / `.im` scopes are for Slack's newer Real-time Search API (`assistant.search.context`), **not** this method. If `search.messages` returns `missing_scope` despite having the granular ones, the user needs to reconnect with `search:read` added.

## Reactions

```bash
# Add an emoji reaction
curl -s -X POST "https://slack.com/api/reactions.add" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel": "C0123ABCD", "timestamp": "1779565166.477149", "name": "thumbsup"}'
```

Scope: `reactions:write`.

## Users & channels lookup

```bash
# List all users
curl -s "https://slack.com/api/users.list?limit=200" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN"

# Get user by email
curl -s "https://slack.com/api/users.lookupByEmail?email=ansh@example.com" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN"

# List channels (public + private the user is in)
curl -s "https://slack.com/api/conversations.list?types=public_channel,private_channel&limit=200" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN"

# Resolve channel name to ID (no direct endpoint — list + filter)
curl -s "https://slack.com/api/conversations.list?types=public_channel&limit=1000" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  | jq '.channels[] | select(.name == "general") | .id'

# Open / get a DM channel ID for a user
curl -s -X POST "https://slack.com/api/conversations.open" \
  -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"users": "U0123ABCD"}'
```

Scopes: `users:read`, `users:read.email`, `channels:read`, `groups:read`, `im:read`, `mpim:read`.

**Pagination**: Both `users.list` and `conversations.list` are cursor-paginated. Slack caps `limit` at ~200 (users) / ~1000 (conversations) per page and returns `response_metadata.next_cursor` when more pages exist. **Always loop until `next_cursor` is empty** — otherwise a workspace with 300 members will silently return only the first page, and a "user not found" result might just be on page 2.

```bash
# Paginate users.list
NEXT_CURSOR=""
while :; do
  RESP=$(curl -s "https://slack.com/api/users.list?limit=200&cursor=$NEXT_CURSOR" \
    -H "Authorization: Bearer $SLACK_MCP_ACCESS_TOKEN")
  echo "$RESP" | jq '.members[]'
  NEXT_CURSOR=$(echo "$RESP" | jq -r '.response_metadata.next_cursor // ""')
  [ -z "$NEXT_CURSOR" ] && break
done
```

## Tips & gotchas

- **Always check `ok: false`** — Slack returns 200 even on logical errors. The `error` field tells you what's wrong (`missing_scope`, `channel_not_found`, `not_in_channel`, etc.).
- **`missing_scope` error** = the connection wasn't granted that scope at OAuth time. Tell the user to disconnect + reconnect with the needed scopes added in Nango (this is a connection-config issue, not something the agent can fix at call time).
- **`not_in_channel`** when posting = the user isn't a member of that private channel. You can only post where the user has access.
- **Channel IDs (`C…`, `G…`, `D…`, `MP…`)** are stable; channel *names* can change. Always resolve to ID once, then use the ID for subsequent calls.
- **MCP discovery alternative**: If you ever need the canonical tool list as Slack frames it, the MCP server is at `https://mcp.slack.com/mcp` (POST JSON-RPC, Bearer auth with the same `SLACK_MCP_ACCESS_TOKEN`). Direct Web API calls are usually simpler and let you use the exact endpoint you need.
- **Rate limits** vary by method tier — Tier 2 (~20/min) for most search/admin, Tier 3 (~50/min) for history, Tier 4 (~100/min) for user info. 429 responses include a `Retry-After` header.
