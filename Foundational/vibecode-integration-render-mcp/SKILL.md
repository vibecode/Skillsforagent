---
name: vibecode-integration-render-mcp
display_name: Render (MCP)
provider_skill: true
integration_dependencies:
  - render-mcp
description: >
  Render REST API for managing the user's Render resources on their behalf —
  listing services, triggering deploys, reading deploy status and logs, and
  managing environment variables. Consult this skill:
  1. When the user asks the agent to list, create, or modify Render services
  2. When the user asks the agent to trigger or cancel a deploy
  3. When the user asks about deploy status or wants to read deploy logs
  4. When the user asks the agent to read/add/update/remove environment variables
  5. When the user mentions "Render" in the context of doing something on Render
metadata: {"openclaw": {"emoji": "🚀", "requires": {"env": ["RENDER_MCP_ACCESS_TOKEN"]}}}
---

# Render (MCP) Integration

The user's Render API key is in `RENDER_MCP_ACCESS_TOKEN`. **Call Render's REST API directly with it** — don't try to route through Nango's MCP proxy (that requires a master Nango secret the runner doesn't have).

## Auth

```bash
# All Render API calls use the same Bearer pattern
curl -s "https://api.render.com/v1/<endpoint>" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"
```

Render API keys are broadly scoped — they grant access to all workspaces and services the user can access. There are no per-scope OAuth scopes; if the key works, the call works.

## Services

```bash
# List services (paginated, default 20, max 100)
curl -s "https://api.render.com/v1/services?limit=20" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"

# Filter by name (substring) or type
curl -s -G "https://api.render.com/v1/services" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  --data-urlencode "name=api" \
  --data-urlencode "type=web_service"

# Get a single service by ID
curl -s "https://api.render.com/v1/services/srv-abc123" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"

# Modify a service (PATCH — only send fields you want to change)
curl -s -X PATCH "https://api.render.com/v1/services/srv-abc123" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "api-v2"}'
```

Service IDs are prefixed `srv-…` and are stable. Service *names* can change — always resolve by ID once and use the ID for subsequent calls.

## Deploys

```bash
# Trigger a deploy (latest commit on configured branch)
curl -s -X POST "https://api.render.com/v1/services/srv-abc123/deploys" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"

# Trigger a deploy of a specific commit
curl -s -X POST "https://api.render.com/v1/services/srv-abc123/deploys" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"commitId": "a1b2c3d"}'

# List deploys for a service
curl -s "https://api.render.com/v1/services/srv-abc123/deploys?limit=10" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"

# Get a specific deploy (status: created, build_in_progress, update_in_progress, pre_deploy_in_progress, live, deactivated, build_failed, update_failed, pre_deploy_failed, canceled)
curl -s "https://api.render.com/v1/services/srv-abc123/deploys/dep-xyz789" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"

# Cancel an in-progress deploy
curl -s -X POST "https://api.render.com/v1/services/srv-abc123/deploys/dep-xyz789/cancel" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"
```

Deploy IDs are prefixed `dep-…`. Poll the single-deploy endpoint with the returned `id` until `status` is `live`, `build_failed`, `update_failed`, `pre_deploy_failed`, `canceled`, or `deactivated`. Without `pre_deploy_failed` in the terminal set, a deploy that fails during a pre-deploy command (DB migrations, asset sync, etc.) will look like it's still running forever — and without `deactivated`, a deploy superseded by a newer one will too.

## Logs

`GET /v1/logs` requires **both** `ownerId` (workspace ID, `own-…`) and `resource` (service/deploy/cron/db ID). Resolve `ownerId` once per agent turn via `/v1/owners` and reuse it.

```bash
# Resolve the workspace ID first (required for every logs call)
OWNER_ID=$(curl -s "https://api.render.com/v1/owners?limit=1" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  | jq -r '.[0].owner.id')

# List recent logs for a resource (both ownerId and resource are required)
curl -s -G "https://api.render.com/v1/logs" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  --data-urlencode "ownerId=$OWNER_ID" \
  --data-urlencode "resource=srv-abc123" \
  --data-urlencode "limit=100"

# Filter logs by time window
curl -s -G "https://api.render.com/v1/logs" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  --data-urlencode "ownerId=$OWNER_ID" \
  --data-urlencode "resource=srv-abc123" \
  --data-urlencode "startTime=2026-06-15T00:00:00Z" \
  --data-urlencode "endTime=2026-06-15T23:59:59Z"

# Filter by log level
curl -s -G "https://api.render.com/v1/logs" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  --data-urlencode "ownerId=$OWNER_ID" \
  --data-urlencode "resource=srv-abc123" \
  --data-urlencode "level=error"
```

If the user belongs to multiple workspaces, `/v1/owners` returns each one — match by `name` against what the user said before passing the `id`.

For *live* log streaming, Render exposes `GET /v1/logs/subscribe` (which the client upgrades to a WebSocket) with the same Bearer header and the same `ownerId`/`resource` query params — usually overkill for an agent turn; the polled GET above is simpler.

## Environment variables

```bash
# List env vars on a service (values redacted by default — secret values won't come back)
curl -s "https://api.render.com/v1/services/srv-abc123/env-vars" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"

# Add or update a single env var (safe — leaves all other vars untouched). PREFER this for one-off changes.
curl -s -X PUT "https://api.render.com/v1/services/srv-abc123/env-vars/LOG_LEVEL" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"value": "debug"}'

# Bulk set — REPLACES the entire env-var list on the service. Use only when the user truly wants a full rewrite (read existing first, merge locally, then send).
curl -s -X PUT "https://api.render.com/v1/services/srv-abc123/env-vars" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{"key": "LOG_LEVEL", "value": "debug"}, {"key": "REGION", "value": "us-east"}]'

# Delete a single env var by key
curl -s -X DELETE "https://api.render.com/v1/services/srv-abc123/env-vars/LOG_LEVEL" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_MCP_ACCESS_TOKEN"
```

Render auto-redeploys the service after an env-var change. If the user wants no redeploy, mention it — there's no flag to suppress it. Per-key `PUT /env-vars/{key}` does not work for variables linked from an environment group; those need to be updated on the group itself.

## Tips & gotchas

- **401 / 403** = the API key is missing, malformed, or the user has lost access to that resource. Tell the user to reconnect the integration so a fresh key flows through Nango — don't try to fix it at call time.
- **404 on a service ID** the user just gave you = typo or wrong workspace. Render keys can span workspaces but service IDs are workspace-scoped; confirm by re-listing services.
- **Deploy doesn't appear** right after `POST .../deploys` = there's a small lag (a few seconds) before it shows up in the list endpoint. Poll the single-deploy GET with the returned `id` instead of relisting.
- **MCP discovery alternative**: Render also hosts an MCP server at `https://mcp.render.com/mcp` (POST JSON-RPC, same `RENDER_MCP_ACCESS_TOKEN` as Bearer). Direct REST calls above are usually simpler and let you target an exact endpoint without going through tool discovery.
- **Rate limits**: Render publishes 1200 req / 5 min per user as the standard limit. 429 responses include a `Retry-After` header — back off and retry.
