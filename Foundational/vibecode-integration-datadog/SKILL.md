---
name: vibecode-integration-datadog
display_name: Datadog
provider_skill: true
integration_dependencies:
  - datadog
description: >
  Datadog API for monitoring infrastructure, querying logs, managing monitors, and APM traces.
  Consult this skill:
  1. When the user asks to check metrics, dashboards, or infrastructure status
  2. When the user needs to query or search logs
  3. When the user wants to manage monitors, alerts, or incidents
  4. When the user asks about APM traces, error rates, or performance
metadata: {"openclaw": {"emoji": "🐕", "requires": {"env": ["DATADOG_API_KEY", "DATADOG_APP_KEY"]}}}
metadata: {"openclaw": {"emoji": "🐕", "requires": {"env": ["DATADOG_API_KEY"]}}}
---

# Datadog Integration

REST API for metrics, logs, monitors, dashboards, APM, and infrastructure.

**Auth**: API key + Application key via headers (NOT Bearer auth).
**Base URL**: `https://api.${DATADOG_SITE:-datadoghq.com}`

```bash
DD_BASE="https://api.${DATADOG_SITE:-datadoghq.com}"

# All requests use these headers
curl -s "$DD_BASE/<endpoint>" \
  -H "DD-API-KEY: $DATADOG_API_KEY" \
  -H "DD-APPLICATION-KEY: ${DATADOG_APP_KEY:-}" \
  -H "Content-Type: application/json"
```

**Note**: Some read endpoints only need `DD-API-KEY`. Write/admin endpoints also need `DD-APPLICATION-KEY`.

## Monitors (alerts)

```bash
# List all monitors
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/monitor"

# Get monitor by ID
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/monitor/{monitor_id}"

# Search monitors by name/tag
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/monitor/search?query=tag:service:web-app"

# Create monitor
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  -H "Content-Type: application/json" "$DD_BASE/api/v1/monitor" \
  -d '{"name":"High Error Rate","type":"metric alert","query":"avg(last_5m):sum:trace.http.request.errors{service:web-app}.as_rate() > 0.05","message":"Error rate above 5% on web-app. @slack-alerts","tags":["service:web-app","env:production"]}'

# Mute monitor
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/monitor/{monitor_id}/mute"

# Unmute monitor
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/monitor/{monitor_id}/unmute"
```

## Logs

```bash
# Search logs (last 15 minutes)
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  -H "Content-Type: application/json" "$DD_BASE/api/v2/logs/events/search" \
  -d '{"filter":{"query":"service:web-app status:error","from":"now-15m","to":"now"},"sort":"timestamp","page":{"limit":20}}'

# Search with specific terms
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  -H "Content-Type: application/json" "$DD_BASE/api/v2/logs/events/search" \
  -d '{"filter":{"query":"@http.status_code:500 service:api","from":"now-1h","to":"now"},"page":{"limit":50}}'

# Aggregate logs (count by service)
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  -H "Content-Type: application/json" "$DD_BASE/api/v2/logs/analytics/aggregate" \
  -d '{"filter":{"query":"status:error","from":"now-1h","to":"now"},"compute":[{"aggregation":"count"}],"group_by":[{"facet":"service","limit":10}]}'
```

### Log query syntax

| Filter | Example |
|---|---|
| Service | `service:web-app` |
| Status | `status:error`, `status:warn`, `status:info` |
| HTTP status | `@http.status_code:500`, `@http.status_code:>399` |
| Host | `host:ip-10-0-1-42` |
| Tag | `env:production`, `team:backend` |
| Free text | `"connection refused"` |
| Exclude | `-service:health-check` |
| Combine | `service:api status:error env:production` |

## Metrics

```bash
# Query metric timeseries
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/query?from=$(date -d '1 hour ago' +%s 2>/dev/null || date -v-1H +%s)&to=$(date +%s)&query=avg:system.cpu.user{service:web-app}+by+{host}"

# Search metric names
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/search?q=metrics:system.cpu"

# Submit custom metric
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "Content-Type: application/json" \
  "$DD_BASE/api/v2/series" \
  -d '{"series":[{"metric":"custom.deployment.count","type":0,"points":[{"timestamp":'$(date +%s)',"value":1}],"tags":["service:web-app","env:production"]}]}'
```

## Events

```bash
# List events
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/events?start=$(date -d '24 hours ago' +%s 2>/dev/null || date -v-24H +%s)&end=$(date +%s)"

# Post event
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "Content-Type: application/json" \
  "$DD_BASE/api/v1/events" \
  -d '{"title":"Deployment completed","text":"Deployed v1.2.3 to production","tags":["service:web-app","env:production"],"alert_type":"info"}'
```

## Dashboards

```bash
# List dashboards
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/dashboard"

# Get dashboard
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/dashboard/{dashboard_id}"
```

## APM (traces)

```bash
# Search traces
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  -H "Content-Type: application/json" "$DD_BASE/api/v2/spans/events/search" \
  -d '{"filter":{"query":"service:web-app @http.status_code:500","from":"now-1h","to":"now"},"page":{"limit":20}}'

# List services
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/service_dependencies"
```

## Hosts & infrastructure

```bash
# List hosts
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/hosts?count=20"

# Search hosts
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v1/hosts?filter=service:web-app"

# Mute a host
curl -s -X POST -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  -H "Content-Type: application/json" "$DD_BASE/api/v1/host/{hostname}/mute" \
  -d '{"message":"Maintenance window","end":'$(($(date +%s) + 3600))'}'
```

## Incidents

```bash
# List incidents
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v2/incidents"

# Get incident
curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
  "$DD_BASE/api/v2/incidents/{incident_id}"
```

## Tips

- **Auth is NOT Bearer** — use `DD-API-KEY` and `DD-APPLICATION-KEY` headers.
- **`DATADOG_SITE`** determines the region: `datadoghq.com` (US1), `us3.datadoghq.com` (US3), `us5.datadoghq.com` (US5), `datadoghq.eu` (EU), `ap1.datadoghq.com` (AP1).
- **Time params**: Use Unix timestamps (seconds) for v1 endpoints, ISO 8601 or relative (`now-1h`) for v2 endpoints.
- **Metric queries**: `avg:metric.name{tag:value} by {group}` — aggregation functions: `avg`, `sum`, `min`, `max`, `count`.
- **Pagination**: v2 endpoints use cursor-based pagination via `page[cursor]`.
- **Rate limit**: Varies by endpoint. Check `X-RateLimit-Remaining` header.
- **Official skills**: Datadog publishes first-party skills at [datadog-labs/agent-skills](https://skills.sh/datadog-labs/agent-skills) covering logs, APM, monitors, and docs.

---

*Based on [datadog-labs/agent-skills](https://skills.sh/datadog-labs/agent-skills) (dd-logs, dd-apm, dd-monitors, dd-pup, dd-docs), [vm0-ai/vm0-skills](https://skills.sh/vm0-ai/vm0-skills), and [Datadog API Reference](https://docs.datadoghq.com/api/).*
