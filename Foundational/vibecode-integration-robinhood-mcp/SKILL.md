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

## Protocol — JSON-RPC over HTTP

Robinhood's MCP servers speak the MCP protocol (JSON-RPC 2.0 over HTTP POST), not a REST API. Every request is a POST with `Content-Type: application/json` and a JSON-RPC envelope.

```bash
# 1. initialize — required handshake before any other call
curl -s -X POST "https://agent.robinhood.com/mcp/trading" \
  -H "Authorization: Bearer $ROBINHOOD_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
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
```

## Discover the tools before calling them

Robinhood ships and ships changes to its MCP tool catalog — **never hard-code tool names**. List them first, then call by exact name:

```bash
# 2. tools/list — fetch the current catalog
curl -s -X POST "https://agent.robinhood.com/mcp/trading" \
  -H "Authorization: Bearer $ROBINHOOD_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}'
```

The response is `{ "result": { "tools": [ { "name": "...", "description": "...", "inputSchema": {...} }, ... ] } }`. Read each `name` + `description` + `inputSchema` to figure out which tool fits the user's intent — don't guess.

## Call a tool

```bash
# 3. tools/call — invoke by exact name from the discovery step
curl -s -X POST "https://agent.robinhood.com/mcp/trading" \
  -H "Authorization: Bearer $ROBINHOOD_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
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

The same `tools/list` → `tools/call` flow works against the banking server too — just swap the URL.

## Placing a trade — must show the preview first

Per Robinhood's published policy, every trade-placing tool surfaces a **preview** first (order details, estimated cost, fees). The user has to see the preview *before* the trade is committed. Do not auto-confirm. Concretely:

1. Call the place-trade tool with the user's intended order.
2. Read the preview from the result (it'll include price, quantity, est. total, account).
3. Show the preview to the user and ask for explicit confirmation.
4. Only then call the confirm/submit step the tool returns.

If you can't find a confirm step in the response, stop and ask — don't loop or guess. A silent re-call is the kind of action the user would not have agreed to.

## Errors

JSON-RPC errors come back as `{ "jsonrpc": "2.0", "id": ..., "error": { "code": ..., "message": "..." } }`. Common codes:

- **`-32601` (Method not found)** — you called a method name that doesn't exist (e.g. `tool/call` instead of `tools/call`).
- **`-32602` (Invalid params)** — `arguments` don't match the tool's `inputSchema`. Re-read the schema and retry.
- **HTTP 401 / 403** — the Bearer token is missing, malformed, or revoked. Tell the user to reconnect the integration; don't try to refresh at call time.
- **`unauthorized_account` or similar** — the user is trying to trade in a non-Agentic account. Restate the Agentic-only constraint to the user.

## Tips & gotchas

- **MCP is a session**, not a REST API. You'll usually want to `initialize` once at the start of an agent turn, then reuse the connection for subsequent `tools/call` requests.
- **The `Accept` header matters** — Robinhood's server may return `text/event-stream` (SSE) for streaming responses; include both content types in `Accept` so you don't get a 406.
- **Be conservative with size**: if the user says "buy some $TICKER" without a dollar amount or share count, ask. Don't pick a default. A wrong default that gets confirmed is a real loss.
- **Banking server is separate** — don't try to place a trade against `banking-agent.robinhood.com/mcp/banking` (its tools are transfer/balance, not trade). Use the trading endpoint for trades, banking endpoint for movement of funds between Robinhood accounts.
