---
name: vibecode-integrations
description: >
  Reference for all third-party services the user has connected through the Vibecode dashboard.
  Consult this skill:
  1. When the user asks to interact with an external service (Slack, Notion, GitHub, Google, etc.)
  2. When you need to know which API tokens are available in your environment
  3. When you need the API documentation URL or auth pattern for a connected service
  4. Before making API calls to verify the correct env var name and authentication method
metadata: {"openclaw": {"always": true}}
---

# Connected Integrations

Third-party services the user has connected through the Vibecode dashboard. Tokens are injected as environment variables — use them directly with the provider APIs. **Before using any service below, verify the env var is set** (`echo $VAR_NAME`). Only services with active connections will have their env vars available.

## Authentication patterns

Most services use Bearer token auth:

```bash
curl -H "Authorization: Bearer $TOKEN_ENV_VAR" https://api.example.com/v1/resource
```

Some use API key headers or query params — check the notes column below.

## Communication

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **Slack** | `SLACK_BOT_TOKEN` | [api.slack.com/methods](https://api.slack.com/methods) | Bearer auth. Bot token (`xoxb-` prefix). Use Web API for messages, channels, reactions, files. |
| **Telegram** | `TELEGRAM_BOT_TOKEN` | [core.telegram.org/bots/api](https://core.telegram.org/bots/api) | HTTP API: `https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/methodName`. No Bearer header needed. |
| **Zoom** | `ZOOM_ACCESS_TOKEN` | [developers.zoom.us/docs/api](https://developers.zoom.us/docs/api/) | Bearer auth. Meetings, webinars, users, recordings. |
| **Intercom** | `INTERCOM_ACCESS_TOKEN` | [developers.intercom.com](https://developers.intercom.com/docs) | Bearer auth. Contacts, conversations, tickets, articles. |

## Google Workspace

Google uses a credentials-based auth flow rather than a simple token. The `gog` CLI or `gws` CLI handles authentication automatically.

| Env Var | Purpose |
|---|---|
| `OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64` | Base64-encoded JSON with OAuth client credentials and refresh token |
| `OPENCLAW_CONNECTION_GOG_ACCOUNT` | Email address of the connected Google account |
| `GOG_KEYRING_PASSWORD` | Keyring password for the `gog` CLI |

**Setup** (run once per session if `gog` is installed):
```bash
gog auth keyring file
echo "$OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d > /tmp/gog-setup.json
jq '{"installed": .installed}' /tmp/gog-setup.json | gog auth credentials set -
jq '{email: .email, client: "default", scopes: .scopes, refresh_token: .refresh_token}' /tmp/gog-setup.json | gog auth tokens import -
rm /tmp/gog-setup.json
```

**Alternatively**, if the `gws` CLI is installed:
```bash
export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/tmp/gws-creds.json
echo "$OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d > "$GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE"
```

**Services available**: Gmail, Google Drive, Google Docs, Google Sheets, Google Calendar, Google Contacts, Google Slides, Google Keep, Google Meet.

## Microsoft 365

Microsoft uses a credentials-based auth flow with the Microsoft Graph API.

| Env Var | Purpose |
|---|---|
| `OPENCLAW_CONNECTION_MICROSOFT_CREDENTIALS_BASE64` | Base64-encoded JSON with OAuth client credentials, refresh token, and token URL |
| `OPENCLAW_CONNECTION_MICROSOFT_ACCOUNT` | Email address of the connected Microsoft account |

**Token refresh** (access tokens expire in ~1 hour):
```bash
CREDS=$(echo "$OPENCLAW_CONNECTION_MICROSOFT_CREDENTIALS_BASE64" | base64 -d)
MS_TOKEN=$(curl -s -X POST "$(echo $CREDS | jq -r .token_url)" \
  -d "client_id=$(echo $CREDS | jq -r .client_id)" \
  -d "client_secret=$(echo $CREDS | jq -r .client_secret)" \
  -d "refresh_token=$(echo $CREDS | jq -r .refresh_token)" \
  -d "grant_type=refresh_token" \
  -d "scope=$(echo $CREDS | jq -r '.scopes | join(" ")')" \
  | jq -r .access_token)
```

**Usage**: All Microsoft 365 APIs through Microsoft Graph:
```bash
curl -H "Authorization: Bearer $MS_TOKEN" https://graph.microsoft.com/v1.0/me/messages
```

**Services available**: Outlook Mail, Calendar, OneDrive, Teams, SharePoint, Planner, OneNote, To Do.

## Knowledge & Docs

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **Notion** | `NOTION_API_KEY` | [developers.notion.com](https://developers.notion.com) | Bearer auth + `Notion-Version: 2022-06-28` header. Pages, databases, blocks, comments. |
| **Confluence** | `CONFLUENCE_ACCESS_TOKEN`, `CONFLUENCE_SITE_URL` | [developer.atlassian.com/cloud/confluence](https://developer.atlassian.com/cloud/confluence/rest/v2/) | Bearer auth. Base URL: `$CONFLUENCE_SITE_URL/wiki/api/v2`. Pages, spaces, content. |
| **Airtable** | `AIRTABLE_ACCESS_TOKEN` | [airtable.com/developers](https://airtable.com/developers/web/api) | Bearer auth. Bases, tables, records, views. |
| **WordPress** | `WORDPRESS_ACCESS_TOKEN` | [developer.wordpress.org/rest-api](https://developer.wordpress.org/rest-api/) | Bearer auth. Posts, pages, media, categories, users. |
| **Webflow** | `WEBFLOW_ACCESS_TOKEN` | [developers.webflow.com](https://developers.webflow.com) | Bearer auth. Sites, collections, items, CMS content. |
| **Squarespace** | `SQUARESPACE_ACCESS_TOKEN` | [developers.squarespace.com](https://developers.squarespace.com/commerce-apis) | Bearer auth. Commerce: products, orders, inventory, profiles. |

## Engineering

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **GitHub** | `GITHUB_TOKEN` | [docs.github.com/en/rest](https://docs.github.com/en/rest) | Bearer auth. Also use `gh` CLI (pre-authenticated): `echo $GITHUB_TOKEN \| gh auth login --with-token`. Repos, PRs, issues, Actions, gists. |
| **GitLab** | `GITLAB_ACCESS_TOKEN` | [docs.gitlab.com/ee/api](https://docs.gitlab.com/ee/api/rest/) | `PRIVATE-TOKEN` header. Projects, MRs, pipelines, issues. |
| **Bitbucket** | `BITBUCKET_ACCESS_TOKEN` | [developer.atlassian.com/cloud/bitbucket](https://developer.atlassian.com/cloud/bitbucket/rest/) | Bearer auth. Repos, PRs, pipelines, workspaces. |
| **Vercel** | `VERCEL_TOKEN` | [vercel.com/docs/rest-api](https://vercel.com/docs/rest-api) | Bearer auth. Deployments, projects, domains, env vars. |
| **Sentry** | `SENTRY_AUTH_TOKEN`, `SENTRY_HOSTNAME` | [docs.sentry.io/api](https://docs.sentry.io/api/) | Bearer auth. Base URL: `https://$SENTRY_HOSTNAME/api/0/`. Issues, events, projects. |
| **Cloudflare** | `CLOUDFLARE_API_TOKEN` | [developers.cloudflare.com/api](https://developers.cloudflare.com/api/) | Bearer auth. DNS, zones, tunnels, Workers, firewall. |
| **Supabase** | `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_PROJECT_URL` | [supabase.com/docs/reference](https://supabase.com/docs/reference/javascript/introduction) | `apikey` header + Bearer auth. Base URL: `$SUPABASE_PROJECT_URL/rest/v1/`. Database, storage, auth. |
| **DigitalOcean** | `DIGITALOCEAN_ACCESS_TOKEN` | [docs.digitalocean.com/reference/api](https://docs.digitalocean.com/reference/api/) | Bearer auth. Droplets, databases, domains, K8s, Spaces. |
| **Snowflake** | `SNOWFLAKE_ACCESS_TOKEN`, `SNOWFLAKE_ACCOUNT_URL` | [docs.snowflake.com/en/developer-guide/sql-api](https://docs.snowflake.com/en/developer-guide/sql-api/about-endpoints) | Bearer auth. SQL API at `$SNOWFLAKE_ACCOUNT_URL/api/v2/statements`. |
| **Clerk** | `CLERK_SECRET_KEY` | [clerk.com/docs/reference/backend-api](https://clerk.com/docs/reference/backend-api) | Bearer auth. Users, organizations, sessions, invitations. |
| **AWS** | `AWS_ACCESS_TOKEN` | [docs.aws.amazon.com](https://docs.aws.amazon.com) | Bearer auth (Cognito token). Limited to Cognito-scoped operations. |

## Productivity & PM

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **Linear** | `LINEAR_API_KEY` | [developers.linear.app](https://developers.linear.app/docs/graphql/working-with-the-graphql-api) | Bearer auth. GraphQL API at `https://api.linear.app/graphql`. Issues, projects, teams, cycles. |
| **Jira** | `JIRA_ACCESS_TOKEN`, `JIRA_SITE_URL` | [developer.atlassian.com/cloud/jira](https://developer.atlassian.com/cloud/jira/platform/rest/v3/) | Bearer auth. Base URL: `$JIRA_SITE_URL/rest/api/3/`. Issues, projects, boards, sprints. |
| **Asana** | `ASANA_ACCESS_TOKEN` | [developers.asana.com](https://developers.asana.com/reference/rest-api-reference) | Bearer auth. Tasks, projects, portfolios, workspaces. |
| **ClickUp** | `CLICKUP_ACCESS_TOKEN` | [clickup.com/api](https://clickup.com/api/) | Bearer auth. Tasks, lists, spaces, folders, goals. |
| **Monday.com** | `MONDAY_ACCESS_TOKEN` | [developer.monday.com](https://developer.monday.com/api-reference/reference) | Bearer auth. GraphQL API at `https://api.monday.com/v2`. Boards, items, updates. |
| **Trello** | `TRELLO_ACCESS_TOKEN` | [developer.atlassian.com/cloud/trello](https://developer.atlassian.com/cloud/trello/rest/) | Query param auth: `?key=...&token=$TRELLO_ACCESS_TOKEN`. Boards, lists, cards. |
| **Todoist** | `TODOIST_ACCESS_TOKEN` | [developer.todoist.com](https://developer.todoist.com/rest/v2/) | Bearer auth. Tasks, projects, labels, comments. |
| **Basecamp** | `BASECAMP_ACCESS_TOKEN`, `BASECAMP_ACCOUNT_ID` | [github.com/basecamp/bc3-api](https://github.com/basecamp/bc3-api) | Bearer auth. Base URL: `https://3.basecampapi.com/$BASECAMP_ACCOUNT_ID/`. Projects, to-dos, messages. |
| **Calendly** | `CALENDLY_ACCESS_TOKEN`, `CALENDLY_ORGANIZATION_ID` | [developer.calendly.com](https://developer.calendly.com/api-docs) | Bearer auth. Events, event types, scheduling links, invitees. |
| **Cal.com** | `CALCOM_ACCESS_TOKEN` | [cal.com/docs/api-reference](https://cal.com/docs/api-reference/v2) | Bearer auth. Event types, bookings, availability, schedules. |
| **Productboard** | `PRODUCTBOARD_ACCESS_TOKEN` | [developer.productboard.com](https://developer.productboard.com) | Bearer auth. Features, notes, objectives, releases. |
| **Teamwork** | `TEAMWORK_ACCESS_TOKEN`, `TEAMWORK_API_ENDPOINT` | [developer.teamwork.com](https://apidocs.teamwork.com) | Bearer auth. Base URL: `$TEAMWORK_API_ENDPOINT`. Projects, tasks, time entries. |

## Data & Analytics

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **Datadog** | `DATADOG_API_KEY`, `DATADOG_SITE` | [docs.datadoghq.com/api](https://docs.datadoghq.com/api/) | `DD-API-KEY` header (not Bearer). Base URL: `https://api.$DATADOG_SITE/api/`. Metrics, monitors, dashboards, logs. |
| **PostHog** | `POSTHOG_API_KEY`, `POSTHOG_HOST` | [posthog.com/docs/api](https://posthog.com/docs/api) | Bearer auth. Base URL: `$POSTHOG_HOST/api/`. Events, persons, feature flags, insights. |
| **Amplitude** | `AMPLITUDE_ACCESS_TOKEN` | [amplitude.com/docs/apis](https://www.docs.developers.amplitude.com) | Bearer auth. Events, cohorts, user profiles, funnels, charts. |
| **Granola** | `GRANOLA_API_KEY` | *(No public API docs)* | Bearer auth. Meeting notes and transcripts. |
| **Typeform** | `TYPEFORM_ACCESS_TOKEN` | [developer.typeform.com](https://developer.typeform.com/get-started/) | Bearer auth. Forms, responses, themes, workspaces. |
| **Jotform** | `JOTFORM_API_KEY` | [api.jotform.com/docs](https://api.jotform.com/docs/) | `APIKEY` query param: `?apiKey=$JOTFORM_API_KEY`. Forms, submissions, reports. |
| **ZoomInfo** | `ZOOMINFO_ACCESS_TOKEN` | [api-docs.zoominfo.com](https://api-docs.zoominfo.com) | Bearer auth. Company data, contacts, intent signals, enrichment. |

## Finance

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **Stripe** | `STRIPE_API_KEY` | [stripe.com/docs/api](https://stripe.com/docs/api) | Bearer auth. Customers, payments, subscriptions, invoices, products. |
| **Shopify** | `SHOPIFY_ACCESS_TOKEN`, `SHOPIFY_STORE_DOMAIN` | [shopify.dev/docs/api](https://shopify.dev/docs/api/admin-rest) | `X-Shopify-Access-Token` header. Base URL: `https://$SHOPIFY_STORE_DOMAIN/admin/api/2024-01/`. Orders, products, customers. |
| **QuickBooks** | `QUICKBOOKS_ACCESS_TOKEN`, `QUICKBOOKS_REALM_ID` | [developer.intuit.com](https://developer.intuit.com/app/developer/qbo/docs/api/accounting/all-entities/account) | Bearer auth. Base URL: `https://quickbooks.api.intuit.com/v3/company/$QUICKBOOKS_REALM_ID/`. Invoices, customers, payments. |
| **PayPal** | `PAYPAL_ACCESS_TOKEN` | [developer.paypal.com](https://developer.paypal.com/docs/api/overview/) | Bearer auth. Orders, payments, subscriptions, payouts. |
| **Square** | `SQUARE_ACCESS_TOKEN` | [developer.squareup.com](https://developer.squareup.com/reference/square) | Bearer auth. Payments, catalog, inventory, customers, orders. |
| **Xero** | `XERO_ACCESS_TOKEN` | [developer.xero.com](https://developer.xero.com/documentation/api/accounting/overview) | Bearer auth. Contacts, invoices, bank transactions, reports. |
| **Chargebee** | `CHARGEBEE_API_KEY`, `CHARGEBEE_SUBDOMAIN` | [apidocs.chargebee.com](https://apidocs.chargebee.com/docs/api) | Basic auth (API key as username, empty password). Base URL: `https://$CHARGEBEE_SUBDOMAIN.chargebee.com/api/v2/`. Subscriptions, customers, invoices. |
| **Brex** | `BREX_ACCESS_TOKEN` | [developer.brex.com](https://developer.brex.com/openapi/onboarding_api/) | Bearer auth. Accounts, transactions, cards, vendors, expenses. |
| **Wise** | `WISE_API_TOKEN` | [api-docs.transferwise.com](https://api-docs.transferwise.com) | Bearer auth. Transfers, balances, recipients, exchange rates. |
| **Fortnox** | `FORTNOX_ACCESS_TOKEN` | [developer.fortnox.se](https://developer.fortnox.se/documentation/) | Bearer auth. Invoices, customers, articles, bookkeeping (Swedish market). |
| **Ramp** | `RAMP_ACCESS_TOKEN` | [docs.ramp.com](https://docs.ramp.com/reference) | Bearer auth. Transactions, cards, reimbursements, accounting. |

## Social & Media

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **YouTube** | `YOUTUBE_ACCESS_TOKEN` | [developers.google.com/youtube](https://developers.google.com/youtube/v3/docs) | Bearer auth. Videos, channels, playlists, comments, search. |
| **Spotify** | `SPOTIFY_ACCESS_TOKEN` | [developer.spotify.com](https://developer.spotify.com/documentation/web-api) | Bearer auth. Playlists, tracks, artists, playback, search. |
| **Typefully** | `TYPEFULLY_API_KEY` | [typefully.com/api](https://support.typefully.com/en/articles/8718287-typefully-api) | `X-API-KEY` header. Drafts, scheduling, Twitter/X threads. |
| **DocuSign** | `DOCUSIGN_ACCESS_TOKEN` | [developers.docusign.com](https://developers.docusign.com/docs/esign-rest-api/) | Bearer auth. Envelopes, templates, signing workflows, documents. |

## Sales & CRM

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **Salesforce** | `SALESFORCE_ACCESS_TOKEN`, `SALESFORCE_INSTANCE_URL` | [developer.salesforce.com](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/) | Bearer auth. Base URL: `$SALESFORCE_INSTANCE_URL/services/data/v59.0/`. Objects, SOQL, records. |
| **HubSpot** | `HUBSPOT_ACCESS_TOKEN` | [developers.hubspot.com](https://developers.hubspot.com/docs/api/overview) | Bearer auth. Contacts, companies, deals, tickets, CMS content. |
| **Zendesk** | `ZENDESK_ACCESS_TOKEN`, `ZENDESK_SUBDOMAIN` | [developer.zendesk.com](https://developer.zendesk.com/api-reference/) | Bearer auth. Base URL: `https://$ZENDESK_SUBDOMAIN.zendesk.com/api/v2/`. Tickets, users, organizations. |
| **Kustomer** | `KUSTOMER_API_KEY`, `KUSTOMER_SUBDOMAIN` | [developer.kustomer.com](https://developer.kustomer.com) | Bearer auth. Base URL: `https://$KUSTOMER_SUBDOMAIN.api.kustomerapp.com/v1/`. Customers, conversations, messages. |
| **PagerDuty** | `PAGERDUTY_TOKEN` | [developer.pagerduty.com](https://developer.pagerduty.com/api-reference/) | Bearer auth. Incidents, services, schedules, on-call, escalation policies. |

## Other

| Service | Env Var(s) | API Docs | Notes |
|---|---|---|---|
| **Zapier** | *(Coming soon)* | [platform.zapier.com](https://platform.zapier.com) | Not yet available. |

## Tips

- **Always verify the env var is set** before attempting API calls: `[[ -n "${VAR_NAME:-}" ]] && echo "available"`.
- **Token expiry**: Most OAuth tokens are refreshed automatically on container restart. If you get a 401, inform the user the token may have expired and suggest reconnecting the integration.
- **Rate limits**: Respect provider rate limits. When you receive a 429 response, back off and retry with exponential delay.
- **Base URLs with context vars**: Several providers include a second env var for the instance URL (e.g., `JIRA_SITE_URL`, `SALESFORCE_INSTANCE_URL`). Always use these — don't hardcode URLs.
- **Special auth patterns**: Datadog uses `DD-API-KEY` header (not Bearer). Chargebee uses Basic auth. Jotform uses query params. Shopify uses `X-Shopify-Access-Token` header. Check the Notes column.
