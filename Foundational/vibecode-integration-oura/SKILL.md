---
name: vibecode-integration-oura
display_name: Oura
provider_skill: true
integration_dependencies:
  - oura
description: >
  Oura API v2 for reading a connected user's Oura Ring health data: profile,
  sleep, readiness, activity, heart rate, workouts, stress, resilience, SpO2,
  ring battery, and ring configuration. Consult this skill when the user asks
  about Oura, Oura Ring metrics, sleep/readiness/activity scores, or personal
  wearable health data from Oura.
metadata: {"openclaw": {"emoji": "💍", "requires": {"env": ["OURA_ACCESS_TOKEN"]}}}
---

# Oura Integration

Oura API v2 for user-authorized Oura Ring health and wellness data.

**Auth**: Bearer token via `OURA_ACCESS_TOKEN` (OAuth via Nango).
**Base URL**: `https://api.ouraring.com`
**OpenAPI schema**: `https://cloud.ouraring.com/v2/static/json/openapi-1.29.json`

Use the OpenAPI schema when you need exact response fields, endpoint coverage,
or enum values. Most collection endpoints accept `start_date`, `end_date`,
`next_token`, and optional `fields`. High-frequency endpoints use
`start_datetime` / `end_datetime`.

```bash
OURA="https://api.ouraring.com/v2"

curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" "$OURA/<endpoint>"
```

## Common Reads

```bash
# Current user's profile
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/personal_info"

# Daily sleep scores for a date range
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_sleep?start_date=2026-05-01&end_date=2026-05-07"

# Sleep sessions with detailed timing and contributors
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/sleep?start_date=2026-05-01&end_date=2026-05-07"

# Daily readiness scores
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_readiness?start_date=2026-05-01&end_date=2026-05-07"

# Daily activity summaries
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_activity?start_date=2026-05-01&end_date=2026-05-07"

# Heart rate samples use datetimes, not dates
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/heartrate?start_datetime=2026-05-01T00:00:00Z&end_datetime=2026-05-02T00:00:00Z"

# Latest ring battery level
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/ring_battery_level?latest=true"

# Workouts
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/workout?start_date=2026-05-01&end_date=2026-05-31"
```

## Other Useful Endpoints

```bash
# SpO2, stress, resilience, cardiovascular age, VO2 max
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_spo2?start_date=2026-05-01&end_date=2026-05-07"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_stress?start_date=2026-05-01&end_date=2026-05-07"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_resilience?start_date=2026-05-01&end_date=2026-05-07"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_cardiovascular_age?start_date=2026-05-01&end_date=2026-05-07"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/vO2_max?start_date=2026-05-01&end_date=2026-05-07"

# Tags, sessions, sleep time, rest mode periods, ring configuration
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/tag?start_date=2026-05-01&end_date=2026-05-31"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/session?start_date=2026-05-01&end_date=2026-05-31"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/sleep_time?start_date=2026-05-01&end_date=2026-05-31"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/rest_mode_period?start_date=2026-05-01&end_date=2026-05-31"
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/ring_configuration?start_date=2026-05-01&end_date=2026-05-31"
```

## Pagination

Collection responses can include a `next_token`. Continue until it is absent.

```bash
curl -s -H "Authorization: Bearer $OURA_ACCESS_TOKEN" \
  "$OURA/usercollection/daily_sleep?start_date=2026-05-01&end_date=2026-05-31&next_token={next_token}"
```

## Tips

- Prefer user-local calendar dates for daily endpoints. Use ISO 8601 UTC
  datetimes for high-frequency endpoints like heart rate, battery level, and
  interbeat interval.
- `fields=` can reduce payload size on endpoints that support field selection.
  Check the OpenAPI schema before relying on a field filter.
- `401` means the token is expired, malformed, or revoked. Ask the user to
  reconnect Oura.
- `403` often means the user's Oura subscription does not allow API data
  access. Explain the access issue instead of retrying.
- `429` means rate limited. Back off and retry later.
- Do not infer medical conclusions. Summarize trends and recommend consulting
  a qualified professional for medical interpretation.

---

*Based on the Oura API v2 OpenAPI schema at https://cloud.ouraring.com/v2/static/json/openapi-1.29.json.*
