---
name: Amplitude
description: >
  Amplitude analytics via MCP (Model Context Protocol). Query product data, create/edit
  charts and dashboards, manage cohorts and experiments, search session replays, and analyze
  feedback. Use when: (1) querying analytics data (events, funnels, retention, segmentation),
  (2) creating or editing charts, (3) building dashboards, (4) managing cohorts or experiments,
  (5) searching Amplitude content, (6) any task involving Amplitude analytics.
  Requires amplitude-cli (`amp` command) and AMPLITUDE_ACCESS_TOKEN (OAuth via Nango).
metadata: {"openclaw": {"emoji": "📊", "requires": {"env": ["AMPLITUDE_ACCESS_TOKEN"], "bin": ["amp"]}, "primaryEnv": "AMPLITUDE_ACCESS_TOKEN"}}
---

# Amplitude

Full Amplitude analytics via the `amp` CLI (amplitude-cli package). Auth is handled automatically — `AMPLITUDE_ACCESS_TOKEN` is injected via Nango OAuth.

## CLI: `amp`

```bash
amp auth status         # verify connection
amp charts search "DAU" # search charts
amp --help              # full command list
```

## Commands

### Auth
```bash
amp auth status                          # show auth status (API keys + OAuth)
amp auth login [--region us|eu]          # OAuth login (interactive, for humans)
amp auth logout                          # revoke tokens
amp auth setup                           # save API key + secret to ~/.amplituderc
amp auth tools                           # list available MCP tools
```

### Charts (requires OAuth)
```bash
amp charts search <query>                # search charts
amp charts get <chartId>                 # get chart definition
amp charts query <chartId>               # query chart data
amp charts create --definition '<json>'  # create chart
amp charts discover <query>              # discover events and properties
amp charts event-props <event-type>      # get properties for an event type
```

### Dashboards (requires OAuth)
```bash
amp dashboards search <query>            # search dashboards
amp dashboards get <dashboardId>         # get dashboard with all charts
amp dashboards create '<json>'           # create dashboard
```

### Analytics Queries
```bash
amp query segment <event> [options]      # event segmentation
amp query funnel <event1> <event2> ...   # funnel analysis
amp query retention <start> <return>     # retention analysis
amp query export [options]               # raw event export
```

### Users
```bash
amp users search <query>                 # search users
amp users activity <userId>              # user activity stream
```

### Cohorts
```bash
amp cohorts list                         # list all cohorts
amp cohorts get <cohortId>               # get cohort definition
```

### Experiments (requires OAuth)
```bash
amp experiments get <experimentId>       # get experiment details
amp experiments query <experimentId>     # query experiment results with stats
```

## Available MCP Tools

The CLI wraps these MCP server tools (accessible via `amp auth tools`):

### Discovery & Navigation
| Tool | Description |
|------|-------------|
| `get_context` | Current user, org, and accessible projects |
| `get_project_context` | Project settings (timezone, currency, session def) |
| `search` | Search charts, dashboards, notebooks, experiments, events, properties, cohorts |
| `get_from_url` | Get full object from any Amplitude URL |

### Charts
| Tool | Description |
|------|-------------|
| `get_charts` | Full chart definitions by ID |
| `query_chart` | Query a single chart, get data |
| `query_charts` | Query up to 3 charts concurrently |
| `create_chart` | Create chart from query definition |
| `save_chart_edits` | Save edits → permanent charts |

### Dashboards & Notebooks
| Tool | Description |
|------|-------------|
| `get_dashboard` | Dashboard with all charts |
| `create_dashboard` | Create dashboard with charts, rich text, layouts |
| `edit_dashboard` | Edit dashboard layout/metadata |
| `create_notebook` | Create interactive notebook |
| `edit_notebook` | Edit notebook layout/metadata |

### Analytics
| Tool | Description |
|------|-------------|
| `query_dataset` | **Primary query tool.** Event segmentation, funnels, retention, sessions |
| `get_event_properties` | Properties for a specific event type |

### Cohorts & Experiments
| Tool | Description |
|------|-------------|
| `get_cohorts` | Cohort definitions by ID |
| `create_cohort` | Create cohort from user properties/behaviors |
| `get_experiments` | Experiment details (state, variants, decisions) |
| `query_experiment` | Experiment analysis with statistical significance |
| `create_experiment` | Create A/B tests |
| `get_deployments` | List deployments (API keys for flags/experiments) |

### Users & Sessions
| Tool | Description |
|------|-------------|
| `get_users` | User data for a project |
| `get_session_replays` | Search session replays (last 30 days) |

### Feedback
| Tool | Description |
|------|-------------|
| `get_feedback_insights` | Processed themes (feature requests, bugs, complaints, praise) |
| `get_feedback_comments` | Raw feedback with search/pagination |
| `get_feedback_mentions` | Comments for a specific insight |
| `get_feedback_sources` | Connected feedback integrations |

## Key Patterns

### Chart → Dashboard Workflow
1. `amp query segment ...` or use MCP `query_dataset` → returns `editId` (temporary)
2. `amp charts create` / MCP `save_chart_edits` → permanent `chartId`
3. `amp dashboards create` → uses permanent `chartId`

**⚠️ Dashboards require SAVED chart IDs. Never use `editId` directly.**

### Amplitude Meta Events (for queries)
- `_active` — Any active event (DAU, MAU)
- `_all` — Any tracked event
- `_new` — New user events
- `_any_revenue_event` — Revenue events

### Property Types
- **Amplitude core:** `source: "AMPLITUDE"` — `platform`, `country`, `device_type`, `os`
- **Custom:** `source: "CUSTOMER"` — prefixed `gp:` (e.g., `gp:email`, `gp:plan`)

## Environment

| Var | Required | Description |
|-----|----------|-------------|
| `AMPLITUDE_ACCESS_TOKEN` | Yes | OAuth token (auto-injected via Nango) |
| `AMPLITUDE_API_KEY` | No | API key for read-only REST queries |
| `AMPLITUDE_SECRET_KEY` | No | Secret key for read-only REST queries |
| `AMPLITUDE_REGION` | No | `us` (default) or `eu` |
