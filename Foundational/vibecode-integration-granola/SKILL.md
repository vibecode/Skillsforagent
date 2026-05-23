---
name: vibecode-integration-granola
display_name: Granola
provider_skill: true
integration_dependencies:
  - granola
description: >
  Granola API for accessing meeting notes, transcripts, and summaries.
  Consult this skill:
  1. When the user asks about recent meetings or meeting notes
  2. When the user needs a transcript or summary of a specific meeting
  3. When the user wants to search for meetings by date or keyword
  4. When the user mentions meeting notes, transcripts, or Granola
metadata: {"openclaw": {"emoji": "🎙️", "requires": {"env": ["GRANOLA_API_KEY"]}}}
---

# Granola Integration

Meeting notes, transcripts, and summaries via Granola.

The Chorus Granola connection uses **MCP over OAuth** (not the REST API). `GRANOLA_API_KEY` holds a JWT bearer token issued by `mcp-auth.granola.ai`. Use the MCP endpoint described below — the public REST API will reject this token with `INVALID_API_KEY`.

**Auth**: Bearer token via `GRANOLA_API_KEY` (JWT issued by Granola MCP OAuth).
**MCP endpoint**: `https://mcp.granola.ai/mcp`
**Transport**: Streamable HTTP (JSON-RPC 2.0).

## Quick start — call MCP via curl

Every call is a JSON-RPC 2.0 POST to `https://mcp.granola.ai/mcp`. Required headers: `Authorization: Bearer $GRANOLA_API_KEY`, `Content-Type: application/json`, `Accept: application/json, text/event-stream`.

Responses are returned as Server-Sent Events. Pipe through `sed` to strip the `data: ` prefix and `jq` to parse the JSON payload:

```bash
... | sed -n 's/^data: //p' | jq '.result.content[0].text | fromjson?'
```

### Initialize the session (optional, but standard MCP handshake)

```bash
curl -s -X POST "https://mcp.granola.ai/mcp" \
  -H "Authorization: Bearer $GRANOLA_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"chorus","version":"1.0"}}}'
```

### List available tools

```bash
curl -s -X POST "https://mcp.granola.ai/mcp" \
  -H "Authorization: Bearer $GRANOLA_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
```

## Available MCP tools

| Tool | Purpose |
|---|---|
| `query_granola_meetings` | Natural-language Q&A over meeting notes. Returns prose with inline citation links (`[[0]](url)`) — preserve them in user-facing responses. Best for open-ended questions ("what did we decide about X?", "any action items from last week?"). |
| `list_meetings` | List meetings in a time range. `time_range` ∈ `this_week`, `last_week`, `last_30_days` (default). Returns titles, dates, participants, IDs. |
| `list_meeting_folders` | List folders with IDs, titles, descriptions, note counts. |
| `get_meetings` | Retrieve detailed notes + AI summary + attendees for up to 10 meeting UUIDs. Use after `list_meetings`. |
| `get_meeting_transcript` | Full verbatim transcript for one meeting UUID. Use when exact quotes matter. |
| `get_account_info` | Returns the email + active workspace for the connected Granola account. |

### Example — list recent meetings

```bash
curl -s -X POST "https://mcp.granola.ai/mcp" \
  -H "Authorization: Bearer $GRANOLA_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_meetings","arguments":{"time_range":"last_30_days"}}}' \
  | sed -n 's/^data: //p' | jq '.result.content[0].text'
```

### Example — natural-language query

```bash
curl -s -X POST "https://mcp.granola.ai/mcp" \
  -H "Authorization: Bearer $GRANOLA_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"query_granola_meetings","arguments":{"query":"What action items came out of meetings this week?"}}}'
```

### Example — get full meeting details

```bash
curl -s -X POST "https://mcp.granola.ai/mcp" \
  -H "Authorization: Bearer $GRANOLA_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"get_meetings","arguments":{"meeting_ids":["<uuid>"]}}}'
```

## Tips

- **Meeting IDs are UUIDs** (`c81d271e-99b1-4489-8ec0-fb0e2b262560`), not `not_*` strings. The legacy REST API used `not_*`; MCP uses UUIDs.
- **Prefer `query_granola_meetings`** for natural-language questions — it returns a synthesized answer with citations.
- **Use `list_meetings` → `get_meetings`** when you need structured data on specific meetings.
- **Transcripts are large** — only call `get_meeting_transcript` when verbatim text is needed.
- **Preserve citation links** (`[[0]](url)`) when relaying `query_granola_meetings` output to the user.
- **Token is OAuth-issued and expires.** If a call returns 401, the Chorus integration needs to be reconnected via `masterclaw connections ensure --provider granola`.

## Legacy REST API (not used by Chorus)

Granola also publishes a separate REST API at `https://public-api.granola.ai/v1/notes` that takes a different bearer key issued from the Granola dashboard (not OAuth). Chorus connections do **not** populate `GRANOLA_API_KEY` with this kind of key — calls to the REST API will fail with `INVALID_API_KEY`. Only consult the REST docs if the user has manually exported a dashboard API key.

---

*Source: [Granola MCP — Docs & Help Center](https://docs.granola.ai/help-center/sharing/integrations/mcp).*
