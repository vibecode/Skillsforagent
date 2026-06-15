---
name: vibecode-integration-robinhood-mcp
display_name: Robinhood (MCP)
provider_skill: true
integration_dependencies:
  - robinhood-mcp
description: >
  Robinhood Trading MCP server for acting on the user's Robinhood account on
  their behalf — exploring trade ideas, viewing positions and orders, and
  placing trades in the user's Robinhood Agentic account. Consult this skill:
  1. When the user asks the agent to look up their Robinhood positions, balance, or orders
  2. When the user asks the agent to research a ticker, option chain, or quote via Robinhood
  3. When the user asks the agent to place, modify, or cancel a trade
  4. When the user mentions "Robinhood" in the context of doing something on Robinhood
metadata: {"openclaw": {"emoji": "📈", "requires": {"env": ["ROBINHOOD_MCP_ACCESS_TOKEN"]}}}
---

# Robinhood (MCP) Integration

The user's Robinhood OAuth token is in `ROBINHOOD_MCP_ACCESS_TOKEN`. **Call Robinhood's MCP server directly with it** — don't try to route through Nango's MCP proxy (that requires a master Nango secret the runner doesn't have).

## Account scope — important

Robinhood's Agentic Trading model splits access into two buckets:

- **Read everything**: positions, orders, balances, and account numbers for **every** Robinhood account the user has.
- **Place trades**: **only** in the user's Robinhood Agentic account. Trades targeting any other account will be rejected by the server.

If the user asks the agent to "buy $500 of AAPL", the order is implicitly against the Agentic account. If they say "buy in my main / IRA / margin account", stop and tell them: trades have to land in the Agentic account; they can move funds there manually in the Robinhood app.

## Servers

There are two separate MCP endpoints:

| Endpoint | URL | When to use |
|---|---|---|
| Trading | `https://agent.robinhood.com/mcp/trading` | Quotes, positions, orders, placing trades |
| Banking | `https://banking-agent.robinhood.com/mcp/banking` | Banking-side actions (transfers, balance) |

Both use the same `ROBINHOOD_MCP_ACCESS_TOKEN` as a Bearer token.

## Protocol — JSON-RPC over Streamable HTTP

Robinhood's MCP servers speak the MCP **Streamable HTTP** transport (JSON-RPC 2.0 over HTTP POST), not a REST API. Every request is a POST with `Content-Type: application/json` and a JSON-RPC envelope. The lifecycle is strict: `initialize` → `notifications/initialized` → only THEN can you call `tools/list` / `tools/call`. Skip a step and the server rejects every follow-up with `-32000 Server not initialized`.

```bash
# 1. initialize — required handshake. Capture the Mcp-Session-Id RESPONSE HEADER.
INIT_HEADERS=$(mktemp)
curl -sS -D "$INIT_HEADERS" -X POST "https://agent.robinhood.com/mcp/trading" \
  -H "Authorization: Bearer $ROBINHOOD_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2025-06-18" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-06-18",
      "capabilities": {},
      "clientInfo": {"name": "chorus-agent", "version": "1.0"}
    }
  }'

# Pull the session id out of the response headers (case-insensitive).
SESSION_ID=$(grep -i "^mcp-session-id:" "$INIT_HEADERS" | tr -d '\r\n' | sed 's/.*: //')
```

If `SESSION_ID` is non-empty, it MUST go on every subsequent POST as `Mcp-Session-Id: <id>`. If the server doesn't return one, you can skip it — Robinhood currently does issue session ids, so expect a value here.

```bash
# 2. notifications/initialized — fire-and-forget. NO "id" field (it's a notification, not a request).
# The server replies 202 Accepted with empty body. Until you send this, tools/list will be rejected.
curl -sS -X POST "https://agent.robinhood.com/mcp/trading" \
  -H "Authorization: Bearer $ROBINHOOD_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2025-06-18" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -d '{"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}'
```

## Discover the tools before calling them

Robinhood ships changes to its MCP tool catalog — **never hard-code tool names**. List them first, then call by exact name. Every request from here on must carry the same `Mcp-Session-Id` and `MCP-Protocol-Version` headers:

```bash
# 3. tools/list — fetch the current catalog (uses the session opened above)
curl -sS -X POST "https://agent.robinhood.com/mcp/trading" \
  -H "Authorization: Bearer $ROBINHOOD_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2025-06-18" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}'
```

The response is `{ "result": { "tools": [ { "name": "...", "description": "...", "inputSchema": {...} }, ... ] } }`. Read each `name` + `description` + `inputSchema` to figure out which tool fits the user's intent — don't guess.

## Call a tool

```bash
# 4. tools/call — invoke by exact name from the discovery step
curl -sS -X POST "https://agent.robinhood.com/mcp/trading" \
  -H "Authorization: Bearer $ROBINHOOD_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2025-06-18" \
  -H "Mcp-Session-Id: $SESSION_ID" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "<exact-tool-name-from-tools/list>",
      "arguments": { /* arguments matching the tool's inputSchema */ }
    }
  }'
```

The same `initialize` → `notifications/initialized` → `tools/list` → `tools/call` flow works against the banking server too — just swap the URL. **Don't reuse `SESSION_ID` across the two servers**; each one issues its own session id, treat them as independent connections.

## Placing a trade — must show the preview first

Per Robinhood's published policy, every trade-placing tool surfaces a **preview** first (order details, estimated cost, fees). The user has to see the preview *before* the trade is committed. Do not auto-confirm. Concretely:

1. Call the place-trade tool with the user's intended order.
2. Read the preview from the result (it'll include price, quantity, est. total, account).
3. Show the preview to the user and ask for explicit confirmation.
4. Only then call the confirm/submit step the tool returns.

If you can't find a confirm step in the response, stop and ask — don't loop or guess. A silent re-call is the kind of action the user would not have agreed to.

## Modifying or canceling an existing order

These are destructive actions on existing state — same discover-then-call rule, but the workflow is different from placing a new order:

1. Call `tools/list` and look for tools whose description mentions "modify order", "cancel order", or "replace order".
2. Most of these tools need an **order ID** as an argument, not a ticker. Get the order ID first via a positions/orders listing tool (look for one whose description mentions "list orders").
3. **Confirm with the user before calling.** There is no "preview" pattern for cancels — the action is immediate and irreversible from the agent's side. Read back the order you're about to cancel ("cancel your pending limit buy of 10 AAPL @ $180?") and wait for explicit yes.
4. Modifying an order may surface a preview (same as placing) if the tool supports it. If it does, follow the preview-then-confirm flow from the section above. If it doesn't, treat it like a cancel — confirm by description first, then call.

If a tool with a "cancel all" semantic shows up in `tools/list`, do not call it without an explicit user instruction that uses those words ("cancel all my open orders"). A blanket cancel triggered by "cancel that order" is the kind of action the user would not have agreed to.

## Errors

JSON-RPC errors come back as `{ "jsonrpc": "2.0", "id": ..., "error": { "code": ..., "message": "..." } }`. Common codes:

- **`-32601` (Method not found)** — you called a method name that doesn't exist (e.g. `tool/call` instead of `tools/call`).
- **`-32602` (Invalid params)** — `arguments` don't match the tool's `inputSchema`. Re-read the schema and retry.
- **HTTP 401 / 403** — the Bearer token is missing, malformed, or revoked. Tell the user to reconnect the integration; don't try to refresh at call time.
- **`unauthorized_account` or similar** — the user is trying to trade in a non-Agentic account. Restate the Agentic-only constraint to the user.

## Tips & gotchas

- **MCP is a session**, not a REST API. `initialize` + `notifications/initialized` once at the start of an agent turn, hold onto `SESSION_ID`, then reuse it on every subsequent POST until the turn ends or the server returns HTTP 404 (session expired — re-`initialize`).
- **The `Accept` header matters** — Robinhood's server may return `text/event-stream` (SSE) for streaming responses; include both content types in `Accept` so you don't get a 406.
- **Be conservative with size**: if the user says "buy some $TICKER" without a dollar amount or share count, ask. Don't pick a default. A wrong default that gets confirmed is a real loss.
- **Banking server is separate** — don't try to place a trade against `banking-agent.robinhood.com/mcp/banking` (its tools are transfer/balance, not trade). Use the trading endpoint for trades, banking endpoint for movement of funds between Robinhood accounts.
