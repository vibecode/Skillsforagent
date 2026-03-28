---
name: vibecode-integrations
display_name: Connected Integrations
description: >
  Reference for third-party services the user has connected through the Vibecode dashboard.
  Consult this skill:
  1. When the user asks to interact with an external service (Slack, Notion, GitHub, etc.)
  2. When you need to discover which integration tokens are available in your environment
  3. Before making API calls to verify the correct env var and auth method
metadata: {"openclaw": {"always": true}}
---

# Connected Integrations

The user connects third-party services through the Vibecode dashboard. When connected, OAuth tokens are injected as environment variables. You can discover what's available by inspecting your environment.

## Discovering connected services

```bash
# List all integration env vars
env | grep -iE '(TOKEN|API_KEY|ACCESS_TOKEN|SECRET_KEY|OPENCLAW_CONNECTION)' | sort
```

Only services with active connections will have env vars set.

## Default auth pattern

Most integrations use Bearer token auth:

```bash
curl -H "Authorization: Bearer $ENV_VAR_NAME" https://api.service.com/v1/resource
```

## Common integrations and their env vars

| Service | Env Var | Auth |
|---|---|---|
| Slack | `SLACK_BOT_TOKEN` | Bearer |
| GitHub | `GITHUB_TOKEN` | Bearer (or `gh` CLI) |
| Notion | `NOTION_API_KEY` | Bearer + `Notion-Version: 2022-06-28` header |
| Linear | `LINEAR_API_KEY` | Bearer (GraphQL: `https://api.linear.app/graphql`) |
| Jira | `JIRA_ACCESS_TOKEN` + `JIRA_SITE_URL` | Bearer (base: `$JIRA_SITE_URL/rest/api/3/`) |
| Stripe | `STRIPE_API_KEY` | Bearer |
| HubSpot | `HUBSPOT_ACCESS_TOKEN` | Bearer |
| Salesforce | `SALESFORCE_ACCESS_TOKEN` + `SALESFORCE_INSTANCE_URL` | Bearer |
| Shopify | `SHOPIFY_ACCESS_TOKEN` + `SHOPIFY_STORE_DOMAIN` | `X-Shopify-Access-Token` header |

Many more integrations follow the same pattern — if an `_ACCESS_TOKEN` or `_API_KEY` env var exists for a service, use it with Bearer auth against that service's public API.

## Non-standard auth (exceptions)

| Service | Env Var | Auth Pattern |
|---|---|---|
| Telegram | `TELEGRAM_BOT_TOKEN` | URL-based: `https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/methodName` |
| Datadog | `DATADOG_API_KEY` + `DATADOG_SITE` | `DD-API-KEY` header (not Bearer) |
| Chargebee | `CHARGEBEE_API_KEY` + `CHARGEBEE_SUBDOMAIN` | Basic auth (key as username, empty password) |
| Jotform | `JOTFORM_API_KEY` | Query param: `?apiKey=$JOTFORM_API_KEY` |
| Supabase | `SUPABASE_ACCESS_TOKEN` + `SUPABASE_PROJECT_URL` | `apikey` header + Bearer |
| Supabase | `SUPABASE_SERVICE_ROLE_KEY` + `SUPABASE_PROJECT_URL` | `apikey` header + Bearer |

## Complex integrations

**Google Workspace** and **Microsoft 365** use credential-based auth (not simple tokens). If these are connected, dedicated integration skills handle the setup — consult those skills instead of using these env vars directly.

| Service | Env Var | Notes |
|---|---|---|
| Google | `OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64` | Use `gws` or `gog` CLI. See `vibecode-integration-google` skill. |
| Microsoft | `OPENCLAW_CONNECTION_MICROSOFT_CREDENTIALS_BASE64` | Use Microsoft Graph API with token refresh. |

## Tips

- **Check before calling**: `[[ -n "${VAR:-}" ]] && echo "available"` — don't assume a service is connected.
- **Instance URLs**: Some services include a second env var for the base URL (e.g., `JIRA_SITE_URL`, `SALESFORCE_INSTANCE_URL`, `ZENDESK_SUBDOMAIN`). Always use these.
- **Token expiry**: Tokens refresh on container restart. If you get a 401, tell the user to reconnect the integration.
- **Rate limits**: Back off on 429 responses with exponential delay.

---

*Sources: [Nango integration docs](https://nango.dev/docs/api-integrations), individual provider API docs (linked in env var tables above). Env var names from [agents-backend provider configs](https://github.com/vibecode/vibecodeapp/tree/main/agents-backend/src/domains/connections/providers).*
