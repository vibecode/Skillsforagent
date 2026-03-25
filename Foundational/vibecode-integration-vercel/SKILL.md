---
name: vibecode-integration-vercel
description: >
  Vercel integration for deployments, projects, domains, and logs.
  Consult this skill:
  1. When the user asks to deploy, check deployment status, or view build logs
  2. When the user needs to manage Vercel projects, domains, or environment variables
  3. When the user wants to check runtime logs or debug a deployment
  4. When the user mentions Vercel, deployments, or hosting
metadata: {"openclaw": {"emoji": "▲", "requires": {"env": ["VERCEL_TOKEN"]}}}
---

# Vercel Integration

Deploy and manage web services via the Vercel REST API and CLI.

**Auth**: Bearer token via `VERCEL_TOKEN`.

## Setup

```bash
# Option A: Use Vercel CLI (preferred — richer output, interactive)
echo "$VERCEL_TOKEN" | vercel login --token 2>/dev/null || \
  npm install -g vercel && vercel login --token "$VERCEL_TOKEN"

# Option B: Direct API calls with curl
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" https://api.vercel.com/v9/projects
```

## Projects

```bash
# List projects
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects?limit=20" | jq '.projects[] | {name, framework, updatedAt}'

# Get project details
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects/{projectId}"

# Or via CLI
vercel project ls
vercel inspect {deployment-url}
```

## Deployments

```bash
# List recent deployments
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v6/deployments?projectId={projectId}&limit=10" | jq '.deployments[] | {uid, url, state, created}'

# Get deployment details
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v13/deployments/{deploymentId}"

# Get build logs
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v2/deployments/{deploymentId}/events"

# Deploy via CLI (from project directory)
vercel --token "$VERCEL_TOKEN" --yes
vercel --token "$VERCEL_TOKEN" --prod --yes
```

## Domains

```bash
# List domains
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v5/domains?limit=20"

# Check domain availability
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v4/domains/status?name=example.com"

# Add domain to project
curl -s -X POST -H "Authorization: Bearer $VERCEL_TOKEN" -H "Content-Type: application/json" \
  "https://api.vercel.com/v10/projects/{projectId}/domains" \
  -d '{"name":"example.com"}'

# Via CLI
vercel domains ls
vercel domains add example.com
```

## Environment variables

```bash
# List env vars for a project
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects/{projectId}/env"

# Create env var
curl -s -X POST -H "Authorization: Bearer $VERCEL_TOKEN" -H "Content-Type: application/json" \
  "https://api.vercel.com/v10/projects/{projectId}/env" \
  -d '{"key":"DATABASE_URL","value":"postgres://...","type":"encrypted","target":["production","preview"]}'

# Via CLI
vercel env ls
vercel env add DATABASE_URL production
vercel env pull .env.local
```

## DNS records

```bash
# List DNS records
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v4/domains/{domain}/records"

# Create DNS record
curl -s -X POST -H "Authorization: Bearer $VERCEL_TOKEN" -H "Content-Type: application/json" \
  "https://api.vercel.com/v2/domains/{domain}/records" \
  -d '{"name":"app","type":"CNAME","value":"cname.vercel-dns.com"}'
```

## Runtime logs

```bash
# Query runtime logs (via CLI — easier filtering)
vercel logs {deployment-url} --token "$VERCEL_TOKEN"

# Via API (more filtering options)
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v1/deployments/{deploymentId}/logs?follow=0&limit=100"
```

## Tips

- **CLI vs API**: Prefer the `vercel` CLI for interactive operations (deploy, logs, env). Use the API for programmatic queries.
- **Always pass `--token "$VERCEL_TOKEN"`** to CLI commands for auth (no interactive login needed).
- **Team scope**: Add `?teamId={teamId}` to API calls if the user works with teams.
- **Deployment states**: `BUILDING`, `ERROR`, `INITIALIZING`, `QUEUED`, `READY`, `CANCELED`.
- **Env var targets**: `production`, `preview`, `development` — specify which environments receive the var.

---

*Based on [Vercel REST API docs](https://vercel.com/docs/rest-api), [Vercel MCP server](https://vercel.com/docs/agent-resources/vercel-mcp), and [Vercel CLI reference](https://vercel.com/docs/cli).*
