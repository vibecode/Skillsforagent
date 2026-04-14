---
name: vibecode-integration-calcom
display_name: Cal.com
provider_skill: true
integration_dependencies:
  - calcom
description: >
  Cal.com API for managing scheduling, event types, bookings, and availability.
  Consult this skill:
  1. When the user asks to manage their scheduling or calendar bookings
  2. When the user needs to check availability or event types
  3. When the user wants to create or cancel bookings
  4. When the user mentions Cal.com, scheduling links, or appointment booking
metadata: {"openclaw": {"emoji": "📅", "requires": {"env": ["CALCOM_ACCESS_TOKEN"]}}}
---

# Cal.com Integration

REST API v2 for event types, bookings, availability, and schedules.

**Auth**: Bearer token via `CALCOM_ACCESS_TOKEN` (OAuth v2 via Nango).
**Base URL**: `https://api.cal.com/v2`

```bash
curl -s -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" \
  -H "cal-api-version: 2024-06-14" \
  "https://api.cal.com/v2/<endpoint>"
```

## Event types

```bash
# List my event types
curl -s -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  "https://api.cal.com/v2/event-types"

# Get event type
curl -s -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  "https://api.cal.com/v2/event-types/{eventTypeId}"

# Create event type
curl -s -X POST -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  -H "Content-Type: application/json" "https://api.cal.com/v2/event-types" \
  -d '{"title":"30 Min Meeting","slug":"30min","lengthInMinutes":30,"locations":[{"type":"integration","integration":"google-meet"}]}'
```

## Bookings

```bash
# List my bookings
curl -s -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  "https://api.cal.com/v2/bookings?status=upcoming"

# Get booking
curl -s -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  "https://api.cal.com/v2/bookings/{bookingUid}"

# Cancel booking
curl -s -X POST -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  -H "Content-Type: application/json" "https://api.cal.com/v2/bookings/{bookingUid}/cancel" \
  -d '{"cancellationReason":"Schedule conflict"}'

# Reschedule booking
curl -s -X POST -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  -H "Content-Type: application/json" "https://api.cal.com/v2/bookings/{bookingUid}/reschedule" \
  -d '{"start":"2026-04-01T10:00:00Z","reschedulingReason":"Time change"}'
```

## Availability

```bash
# Get my schedules (availability)
curl -s -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  "https://api.cal.com/v2/schedules"

# Check available slots for an event type
curl -s -H "Authorization: Bearer $CALCOM_ACCESS_TOKEN" -H "cal-api-version: 2024-06-14" \
  "https://api.cal.com/v2/slots/available?startTime=2026-03-25T00:00:00Z&endTime=2026-03-31T23:59:59Z&eventTypeId={eventTypeId}"
```

## Tips

- **`cal-api-version` header required** — use `2024-06-14` (latest stable; `2024-08-13` causes 404s).
- **Booking statuses**: `upcoming`, `past`, `cancelled`, `recurring`.
- **Event type slugs** are used in booking URLs: `cal.com/username/slug`.
- **Rate limit**: Back off on 429.

---

*Based on [calcom/cal.com/calcom-api skill](https://skills.sh/calcom/cal.com/calcom-api) and [Cal.com API Reference](https://cal.com/docs/api-reference/v2).*
