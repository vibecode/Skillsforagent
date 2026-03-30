---
name: vibecode-integration-posthog
display_name: PostHog
provider_skill: true
integration_dependencies:
  - posthog
description: >
  PostHog API for product analytics, feature flags, session recordings, and experiments.
  Consult this skill:
  1. When the user asks about analytics events, user behavior, or funnels
  2. When the user needs to manage feature flags or A/B experiments
  3. When the user wants to query insights, cohorts, or user properties
  4. When the user mentions PostHog, analytics, feature flags, or session recordings
metadata: {"openclaw": {"emoji": "🦔", "requires": {"env": ["POSTHOG_API_KEY"]}}}
---

# PostHog Integration

REST API for analytics events, insights, feature flags, cohorts, persons, and experiments.

**Auth**: Bearer token via `POSTHOG_API_KEY` (personal API key, starts with `phx_`).
**Base URL**: `${POSTHOG_HOST:-https://app.posthog.com}/api`

```bash
PH_BASE="${POSTHOG_HOST:-https://app.posthog.com}/api"

curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" "$PH_BASE/<endpoint>"
```

## Projects

```bash
# List projects (get project_id — needed for most endpoints)
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/"
```

Most endpoints require the project ID in the path: `/api/projects/{project_id}/...`

## Events

```bash
# List recent events
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/events/?limit=20&orderBy=-timestamp"

# Filter events by name
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/events/?event=\$pageview&limit=20"

# Filter by person
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/events/?person_id={person_id}&limit=20"

# Get event definitions (what events are tracked)
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/event_definitions/?limit=50"
```

## Insights (queries)

```bash
# List saved insights
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/insights/?limit=20"

# Get insight by ID
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/insights/{insight_id}/"

# Run a trends query (HogQL)
curl -s -X POST -H "Authorization: Bearer $POSTHOG_API_KEY" -H "Content-Type: application/json" \
  "$PH_BASE/projects/{project_id}/query/" \
  -d '{"query":{"kind":"TrendsQuery","series":[{"event":"\$pageview","kind":"EventsNode"}],"dateRange":{"date_from":"-7d"}}}'

# Run a HogQL query (SQL-like)
curl -s -X POST -H "Authorization: Bearer $POSTHOG_API_KEY" -H "Content-Type: application/json" \
  "$PH_BASE/projects/{project_id}/query/" \
  -d '{"query":{"kind":"HogQLQuery","query":"SELECT event, count() FROM events WHERE timestamp > now() - INTERVAL 1 DAY GROUP BY event ORDER BY count() DESC LIMIT 20"}}'
```

## Persons

```bash
# List persons
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/persons/?limit=20"

# Search persons by email
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/persons/?search=alice@example.com"

# Get person by ID
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/persons/{person_id}/"

# Get person properties
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/persons/{person_id}/properties/"
```

## Feature flags

```bash
# List feature flags
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/feature_flags/?limit=50"

# Get feature flag
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/feature_flags/{id}/"

# Create feature flag
curl -s -X POST -H "Authorization: Bearer $POSTHOG_API_KEY" -H "Content-Type: application/json" \
  "$PH_BASE/projects/{project_id}/feature_flags/" \
  -d '{"key":"new-checkout-flow","name":"New Checkout Flow","active":true,"filters":{"groups":[{"properties":[],"rollout_percentage":50}]}}'

# Update feature flag (toggle on/off)
curl -s -X PATCH -H "Authorization: Bearer $POSTHOG_API_KEY" -H "Content-Type: application/json" \
  "$PH_BASE/projects/{project_id}/feature_flags/{id}/" \
  -d '{"active":false}'

# Evaluate flags for a person
curl -s -X POST -H "Authorization: Bearer $POSTHOG_API_KEY" -H "Content-Type: application/json" \
  "$PH_BASE/projects/{project_id}/feature_flags/evaluation/" \
  -d '{"distinct_id":"user-123"}'
```

## Cohorts

```bash
# List cohorts
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/cohorts/"

# Get cohort persons
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/cohorts/{id}/persons/?limit=20"
```

## Experiments

```bash
# List experiments
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/experiments/"

# Get experiment results
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/experiments/{id}/results/"
```

## Dashboards

```bash
# List dashboards
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/dashboards/"

# Get dashboard with insights
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/dashboards/{id}/"
```

## Annotations

```bash
# List annotations
curl -s -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "$PH_BASE/projects/{project_id}/annotations/"

# Create annotation (mark a deployment, incident, etc.)
curl -s -X POST -H "Authorization: Bearer $POSTHOG_API_KEY" -H "Content-Type: application/json" \
  "$PH_BASE/projects/{project_id}/annotations/" \
  -d '{"content":"Deployed v2.1.0","date_marker":"2026-03-25T12:00:00Z","scope":"project"}'
```

## Tips

- **Get project ID first** — `GET /api/projects/` returns the project(s) with their IDs.
- **`POSTHOG_HOST`** defaults to `https://app.posthog.com` (PostHog Cloud US). EU is `https://eu.posthog.com`. Self-hosted uses your own domain.
- **HogQL** is PostHog's SQL-like query language — use `/query/` endpoint for flexible analytics.
- **Event names**: Built-in events start with `$` (e.g., `$pageview`, `$autocapture`). Custom events are plain strings.
- **Pagination**: Use `limit` and `offset` params. Some endpoints return `next` URL.
- **Rate limits**: Vary by plan. Back off on 429.
- **Personal API key** (starts with `phx_`) gives access to all projects the user can access.

---

*Based on [posthog/posthog-for-claude/posthog-instrumentation](https://skills.sh/posthog/posthog-for-claude/posthog-instrumentation), [composiohq/posthog-automation](https://skills.sh/composiohq/awesome-claude-skills/posthog-automation), and [PostHog API Reference](https://posthog.com/docs/api).*
