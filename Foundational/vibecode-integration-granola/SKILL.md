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

Meeting notes, transcripts, and summaries via Granola's MCP server.

## Important — Chorus uses MCP OAuth, not the REST API

The Chorus Granola connection authenticates via **MCP over OAuth**. `GRANOLA_API_KEY` holds a JWT issued by `mcp-auth.granola.ai`, **not** a dashboard-issued API key. The public REST API (`public-api.granola.ai`) will reject this token with `INVALID_API_KEY` — always use the MCP endpoint.

- **Endpoint**: `https://mcp.granola.ai/mcp`
- **Transport**: Streamable HTTP, JSON-RPC 2.0
- **Auth header**: `Authorization: Bearer $GRANOLA_API_KEY`
- **If a call returns 401 / "Session expired"**: reconnect with `masterclaw connections ensure --provider granola`

## Calling MCP

Every call is a JSON-RPC POST. Responses come back as SSE — strip `data: ` and parse with `jq`. Define a helper once and reuse it:

```bash
granola() {
  # usage: granola <tool_name> '<json_args>'
  local args="$2"
  [ -z "$args" ] && args='{}'
  curl -s -X POST https://mcp.granola.ai/mcp \
    -H "Authorization: Bearer $GRANOLA_API_KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d "$(jq -nc --arg name "$1" --argjson args "$args" \
        '{jsonrpc:"2.0",id:1,method:"tools/call",params:{name:$name,arguments:$args}}')" \
    | sed -n 's/^data: //p' | jq -r '.result.content[0].text // empty'
}
```

The `// empty` filter is important: `query_granola_meetings` streams `notifications/progress` events before the final result — without it, every progress tick prints `null`.

Then:

```bash
granola list_meetings '{"time_range":"last_30_days"}'
granola query_granola_meetings '{"query":"action items from this week"}'
granola get_meetings '{"meeting_ids":["c81d271e-99b1-4489-8ec0-fb0e2b262560"]}'
granola get_account_info
```

## Available tools

| Tool | Purpose |
|---|---|
| `query_granola_meetings` | Natural-language Q&A over notes. Returns prose with inline citation links (`[[0]](url)`) — preserve these when relaying to the user. Best for open-ended questions. Args: `query` (required), `document_ids` (optional). |
| `list_meetings` | List meetings in a time range. Args: `time_range` ∈ `this_week`, `last_week`, `last_30_days` (default). Returns titles, dates, participants, UUIDs. |
| `list_meeting_folders` | List folders with IDs, titles, descriptions, note counts. |
| `get_meetings` | Detailed notes + AI summary + attendees for up to 10 meeting UUIDs. Args: `meeting_ids` (array). Use after `list_meetings`. |
| `get_meeting_transcript` | Verbatim transcript for one meeting UUID. Args: `meeting_id`. Use when exact quotes matter — payloads are large. |
| `get_account_info` | Email + active workspace for the connected account. |

For the canonical tool schemas, call `tools/list`:

```bash
curl -s -X POST https://mcp.granola.ai/mcp \
  -H "Authorization: Bearer $GRANOLA_API_KEY" \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | sed -n 's/^data: //p' | jq
```

## Tips

- **Meeting IDs are UUIDs** under MCP (e.g. `c81d271e-99b1-4489-8ec0-fb0e2b262560`). The legacy REST API used `not_*` strings — don't confuse them.
- **Prefer `query_granola_meetings`** for natural-language questions — it synthesizes an answer with citations in one call.
- **Use `list_meetings` → `get_meetings`** when you need structured data on specific meetings.
- **Preserve citation links** (`[[0]](url)`) in `query_granola_meetings` output when relaying to the user.

---

*Reference: [Granola MCP docs](https://docs.granola.ai/help-center/sharing/integrations/mcp).*
