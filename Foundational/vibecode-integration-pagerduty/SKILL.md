---
name: vibecode-integration-pagerduty
description: >
  PagerDuty API for managing incidents, on-call schedules, services, and escalation policies.
  Consult this skill:
  1. When the user asks who is on-call or about on-call schedules
  2. When the user needs to view, acknowledge, or resolve incidents
  3. When the user wants to check services, escalation policies, or create incidents
  4. When the user mentions PagerDuty, incidents, on-call, or alerts
metadata: {"openclaw": {"emoji": "🚨", "requires": {"env": ["PAGERDUTY_TOKEN"]}}}
---

# PagerDuty Integration

REST API v2 for incidents, on-call, services, schedules, and escalation policies.

**Auth**: Bearer token via `PAGERDUTY_TOKEN` (OAuth tokens issued by Nango):

```bash
curl -s https://api.pagerduty.com/<endpoint> \
  -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  -H "Content-Type: application/json"
```

## On-call

```bash
# Who is on-call right now?
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/oncalls?earliest=true" | jq '.oncalls[] | {user: .user.summary, schedule: .schedule.summary, escalation_policy: .escalation_policy.summary}'

# On-call for a specific schedule
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/oncalls?schedule_ids[]={schedule_id}&earliest=true"

# On-call for a time range
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/oncalls?since=$(date -u +%Y-%m-%dT%H:%M:%SZ)&until=$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+7d +%Y-%m-%dT%H:%M:%SZ)"
```

## Incidents

```bash
# List active incidents (triggered + acknowledged)
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/incidents?statuses[]=triggered&statuses[]=acknowledged&sort_by=created_at:desc&limit=20"

# Get incident details
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/incidents/{incident_id}"

# Acknowledge incident
curl -s -X PUT -H "Authorization: Bearer $PAGERDUTY_TOKEN" -H "Content-Type: application/json" \
  "https://api.pagerduty.com/incidents/{incident_id}" \
  -d '{"incident":{"type":"incident_reference","status":"acknowledged"}}'

# Resolve incident
curl -s -X PUT -H "Authorization: Bearer $PAGERDUTY_TOKEN" -H "Content-Type: application/json" \
  "https://api.pagerduty.com/incidents/{incident_id}" \
  -d '{"incident":{"type":"incident_reference","status":"resolved","resolution":"Fixed the database connection pool issue"}}'

# Create incident
curl -s -X POST -H "Authorization: Bearer $PAGERDUTY_TOKEN" -H "Content-Type: application/json" \
  "https://api.pagerduty.com/incidents" \
  -d '{"incident":{"type":"incident","title":"Database connection timeout","service":{"id":"SERVICE_ID","type":"service_reference"},"urgency":"high","body":{"type":"incident_body","details":"Connection pool exhausted at 10:30 UTC"}}}'

# Add note to incident
curl -s -X POST -H "Authorization: Bearer $PAGERDUTY_TOKEN" -H "Content-Type: application/json" \
  "https://api.pagerduty.com/incidents/{incident_id}/notes" \
  -d '{"note":{"content":"Restarted the service, monitoring recovery."}}'

# List incident log entries (timeline)
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/incidents/{incident_id}/log_entries?limit=20"
```

## Services

```bash
# List services
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/services?limit=25" | jq '.services[] | {id, name, status, escalation_policy: .escalation_policy.summary}'

# Get service details
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/services/{service_id}"
```

## Schedules

```bash
# List schedules
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/schedules?limit=25" | jq '.schedules[] | {id, name, summary}'

# Get schedule with rendered on-call slots
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/schedules/{schedule_id}?since=$(date -u +%Y-%m-%dT%H:%M:%SZ)&until=$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+7d +%Y-%m-%dT%H:%M:%SZ)"
```

## Escalation policies

```bash
# List escalation policies
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/escalation_policies?limit=25" | jq '.escalation_policies[] | {id, name, num_loops}'
```

## Users

```bash
# List users
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/users?limit=25" | jq '.users[] | {id, name, email, role}'

# Get current user
curl -s -H "Authorization: Bearer $PAGERDUTY_TOKEN" \
  "https://api.pagerduty.com/users/me"
```

## Tips

- **Auth header format**: `Bearer <token>` for OAuth tokens (Nango). Legacy API keys use `Token token=<key>` but that format does not apply here.
- **Incident status flow**: `triggered` → `acknowledged` → `resolved` (forward-only).
- **IDs are alphanumeric**: e.g., `P1234AB`. Always use `type` field in references (`service_reference`, `incident_reference`, etc.).
- **Pagination**: Offset-based with `offset`, `limit`, `more` boolean, `total` count.
- **Date format**: ISO 8601 for `since`/`until` params.
- **`earliest=true`** on `/oncalls` returns only the current on-call person (not the full rotation).

---

*Based on [composiohq/pagerduty-automation](https://skills.sh/composiohq/awesome-claude-skills/pagerduty-automation), [PagerDuty REST API v2 Reference](https://developer.pagerduty.com/api-reference/), and [PagerDuty API Guides](https://developer.pagerduty.com/docs/).*
