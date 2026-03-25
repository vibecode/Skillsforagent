---
name: vibecode-integration-sentry
description: >
  Sentry API for tracking errors, monitoring performance, and debugging issues.
  Consult this skill:
  1. When the user asks about errors, exceptions, or crashes in their application
  2. When the user needs to view, resolve, or triage Sentry issues
  3. When the user wants to check releases, deployments, or performance metrics
  4. When the user mentions Sentry, error tracking, or monitoring
metadata: {"openclaw": {"emoji": "🐛", "requires": {"env": ["SENTRY_AUTH_TOKEN"]}}}
---

# Sentry Integration

REST API for issues, events, projects, releases, and performance monitoring.

**Auth**: Bearer token via `SENTRY_AUTH_TOKEN`.
**Base URL**: `https://${SENTRY_HOSTNAME:-sentry.io}/api/0` (defaults to sentry.io if no custom hostname).

```bash
# Base URL helper
SENTRY_BASE="https://${SENTRY_HOSTNAME:-sentry.io}/api/0"

curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" "$SENTRY_BASE/<endpoint>"
```

## Discovery (run first)

```bash
# List organizations (get org slug — needed for all other calls)
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" "$SENTRY_BASE/organizations/"

# List projects
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" "$SENTRY_BASE/projects/"

# Project details
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" "$SENTRY_BASE/projects/{org}/{project}/"
```

## Issues

```bash
# List unresolved issues (most recent)
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/issues/?query=is:unresolved&sort=date&limit=25"

# List issues for a specific project
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/projects/{org}/{project}/issues/?query=is:unresolved&sort=date&limit=25"

# Search issues by error type
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/issues/?query=is:unresolved+error.type:TypeError&sort=freq"

# Search by level
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/issues/?query=level:error&sort=new"

# Get issue details
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/issues/{issue_id}/"

# Get latest event for an issue (full stack trace)
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/issues/{issue_id}/events/latest/"

# List all events for an issue
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/issues/{issue_id}/events/"

# Resolve an issue
curl -s -X PUT -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" -H "Content-Type: application/json" \
  "$SENTRY_BASE/organizations/{org}/issues/{issue_id}/" \
  -d '{"status":"resolved"}'

# Ignore an issue
curl -s -X PUT -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" -H "Content-Type: application/json" \
  "$SENTRY_BASE/organizations/{org}/issues/{issue_id}/" \
  -d '{"status":"ignored","statusDetails":{"ignoreCount":100}}'

# Assign issue to a user
curl -s -X PUT -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" -H "Content-Type: application/json" \
  "$SENTRY_BASE/organizations/{org}/issues/{issue_id}/" \
  -d '{"assignedTo":"user:USER_ID"}'
```

### Query syntax

| Filter | Example |
|---|---|
| Status | `is:unresolved`, `is:resolved`, `is:ignored` |
| Level | `level:error`, `level:warning`, `level:fatal` |
| Error type | `error.type:TypeError`, `error.type:ValueError` |
| Assigned | `assigned:me`, `assigned:user@example.com`, `!has:assignee` |
| Release | `release:1.2.3`, `!has:release` |
| Platform | `platform:python`, `platform:javascript` |
| First seen | `firstSeen:>2026-03-20` |
| Times seen | `times_seen:>100` |

Sort options: `date` (most recent), `new` (first seen), `freq` (most frequent), `priority`

## Releases

```bash
# List releases
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/releases/?limit=10"

# Get release details
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/organizations/{org}/releases/{version}/"
```

## Project events

```bash
# List recent events for a project
curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "$SENTRY_BASE/projects/{org}/{project}/events/?limit=20"
```

## Tips

- **Discover org slug first** — `GET /organizations/` returns the slug needed for all other calls.
- **Issue statuses**: `unresolved`, `resolved`, `resolvedInNextRelease`, `ignored`.
- **Pagination**: Cursor-based — check `Link` response header for `rel="next"` cursor.
- **Self-hosted**: If `SENTRY_HOSTNAME` is set, use it as base instead of `sentry.io`.
- **Rate limits**: Implement exponential backoff on 429 responses.
- **Event data includes stack traces** — use the latest event endpoint to debug issues.

---

*Extracted from [vm0-ai/vm0-skills/sentry](https://skills.sh/vm0-ai/vm0-skills/sentry), [composiohq/sentry-automation](https://skills.sh/composiohq/awesome-claude-skills/sentry-automation), and [Sentry API Reference](https://docs.sentry.io/api/).*
