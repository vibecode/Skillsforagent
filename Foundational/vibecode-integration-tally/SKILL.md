---
name: vibecode-integration-tally
display_name: Tally
provider_skill: true
integration_dependencies:
  - tally
description: >
  Tally API for managing forms, retrieving submissions, and configuring webhooks.
  Consult this skill:
  1. When the user asks to list, create, update, or delete Tally forms
  2. When the user needs to retrieve or filter form submissions
  3. When the user wants to set up webhooks to receive form events
  4. When the user wants to manage workspaces, organization members, or invites
  5. When the user mentions Tally, Tally forms, or wants to act on form responses
metadata: {"openclaw": {"emoji": "📝", "requires": {"env": ["TALLY_API_KEY"]}}}
---

# Tally Integration

REST API for forms, submissions, webhooks, workspaces, and org membership.

**Auth**: Bearer token via `Authorization` header.
**Base URL**: `https://api.tally.so`
**Rate limit**: 100 requests/minute. For new-submission feeds, prefer webhooks over polling — webhook deliveries don't consume the rate limit.

```bash
# All requests use Bearer auth
curl -s "https://api.tally.so/<endpoint>" \
  -H "Authorization: Bearer $TALLY_API_KEY"
```

## Current user

```bash
curl -s "https://api.tally.so/users/me" \
  -H "Authorization: Bearer $TALLY_API_KEY"
```

## Forms

```bash
# List forms (paginated)
curl -s "https://api.tally.so/forms?page=1&limit=20" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Get form (returns blocks + settings)
curl -s "https://api.tally.so/forms/{formId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# List questions in a form (lighter than full form)
curl -s "https://api.tally.so/forms/{formId}/questions" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Create form (optionally based on a template)
curl -s -X POST "https://api.tally.so/forms" \
  -H "Authorization: Bearer $TALLY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"workspaceId":"{workspaceId}","name":"Customer Feedback","status":"PUBLISHED"}'

# Update form (status, blocks, settings)
curl -s -X PATCH "https://api.tally.so/forms/{formId}" \
  -H "Authorization: Bearer $TALLY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status":"DRAFT"}'

# Delete form (moves to trash)
curl -s -X DELETE "https://api.tally.so/forms/{formId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"
```

## Submissions

```bash
# List submissions for a form (paginated, newest first)
curl -s "https://api.tally.so/forms/{formId}/submissions?page=1&limit=20" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Filter by status (all | partial | completed)
curl -s "https://api.tally.so/forms/{formId}/submissions?filter=completed&limit=50" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Filter by date range (ISO 8601)
curl -s "https://api.tally.so/forms/{formId}/submissions?startDate=2026-01-01T00:00:00Z&endDate=2026-02-01T00:00:00Z" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Incremental fetch: get submissions after a known submission ID
curl -s "https://api.tally.so/forms/{formId}/submissions?afterId={lastSubmissionId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Get a single submission
curl -s "https://api.tally.so/forms/{formId}/submissions/{submissionId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Delete a submission
curl -s -X DELETE "https://api.tally.so/forms/{formId}/submissions/{submissionId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"
```

## Webhooks (preferred for live feeds)

Tally delivers webhook events when form submissions arrive — far better than polling. Set up a webhook once per form, point it at your endpoint, and stop hitting the rate limit.

```bash
# Create webhook for a form
curl -s -X POST "https://api.tally.so/webhooks" \
  -H "Authorization: Bearer $TALLY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"formId":"{formId}","url":"https://yourapp.com/tally-webhook","eventTypes":["FORM_RESPONSE"]}'

# List all webhooks
curl -s "https://api.tally.so/webhooks?page=1&limit=20" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Update webhook
curl -s -X PATCH "https://api.tally.so/webhooks/{webhookId}" \
  -H "Authorization: Bearer $TALLY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://yourapp.com/new-endpoint"}'

# Delete webhook
curl -s -X DELETE "https://api.tally.so/webhooks/{webhookId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Check webhook delivery history
curl -s "https://api.tally.so/webhooks/{webhookId}/events" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Retry a failed delivery
curl -s -X POST "https://api.tally.so/webhooks/{webhookId}/events/{eventId}/retry" \
  -H "Authorization: Bearer $TALLY_API_KEY"
```

## Workspaces

```bash
# List workspaces
curl -s "https://api.tally.so/workspaces" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Get one workspace (includes members)
curl -s "https://api.tally.so/workspaces/{workspaceId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Create workspace
curl -s -X POST "https://api.tally.so/workspaces" \
  -H "Authorization: Bearer $TALLY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Marketing"}'

# Update workspace
curl -s -X PATCH "https://api.tally.so/workspaces/{workspaceId}" \
  -H "Authorization: Bearer $TALLY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Marketing & Growth"}'

# Delete workspace (also deletes its forms)
curl -s -X DELETE "https://api.tally.so/workspaces/{workspaceId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"
```

## Organization users & invites

```bash
# List org users
curl -s "https://api.tally.so/organizations/users" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Remove user from org
curl -s -X DELETE "https://api.tally.so/organizations/users/{userId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Invite user(s) to specific workspace(s)
curl -s -X POST "https://api.tally.so/organizations/invites" \
  -H "Authorization: Bearer $TALLY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"emails":["new@example.com"],"workspaceIds":["{workspaceId}"]}'

# List pending invites
curl -s "https://api.tally.so/organizations/invites" \
  -H "Authorization: Bearer $TALLY_API_KEY"

# Cancel invite
curl -s -X DELETE "https://api.tally.so/organizations/invites/{inviteId}" \
  -H "Authorization: Bearer $TALLY_API_KEY"
```

## Tips

- **Pagination**: List endpoints use `?page=` and `?limit=` query params. Default page size is small; bump `limit` (e.g., `limit=100`) for fewer round trips.
- **Forms vs Questions**: `GET /forms/{id}` returns the full form including blocks (heavy). If you only need field metadata, use `GET /forms/{id}/questions` instead.
- **Form status values**: `BLANK` (no blocks yet), `DRAFT`, `PUBLISHED`, `BLOCKED` — set via `PATCH /forms/{id}`.
- **Webhook event types**: `FORM_RESPONSE` is the main one (fires on new submission). Always prefer webhooks over polling for live data — saves rate limit and gives you sub-second latency.
- **Don't poll `/submissions` in a loop** — at 100 req/min you'll burn the limit fast. If you must poll, cache the last-seen submission ID and fetch `?afterId=<lastSubmissionId>` (the API's cursor parameter).
