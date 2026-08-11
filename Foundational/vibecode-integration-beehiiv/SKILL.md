---
name: vibecode-integration-beehiiv
display_name: Beehiiv
provider_skill: true
integration_dependencies:
  - beehiiv
description: >
  beehiiv API v2 for newsletter operations: subscribers, segments, tags, custom
  fields, posts, automations, tiers, and webhooks.
  Consult this skill:
  1. When the user asks to add, look up, update, unsubscribe, or delete a
     newsletter subscriber
  2. When the user wants to segment their audience, tag subscribers, or manage
     custom fields
  3. When the user asks about post performance — opens, clicks, or aggregate
     stats across sends
  4. When the user wants to enroll someone in an automation or newsletter list
  5. When the user asks to set up webhooks for subscription or post events
  6. When the user mentions beehiiv, their newsletter, or their publication
metadata: {"openclaw": {"emoji": "🐝", "requires": {"env": ["BEEHIIV_API_KEY"]}}}
---

# Beehiiv Integration

REST API v2 for newsletter publications: subscriptions, segments, tags, custom
fields, posts, automations, tiers, and webhooks.

**Auth**: Bearer token via `Authorization` header.
**Base URL**: `https://api.beehiiv.com/v2` — nearly every path is scoped to a
publication: `/v2/publications/{publicationId}/...`
**Rate limit**: **180 requests/minute per organization** (not per key, not per
publication). Watch `RateLimit-Limit` / `RateLimit-Remaining` / `RateLimit-Reset`
on authenticated responses.

```bash
BASE="https://api.beehiiv.com/v2"
PUB="$BEEHIIV_PUBLICATION_ID"   # looks like pub_xxxxxxxx-xxxx-...; if unset, discover it below

curl -s "$BASE/publications/$PUB/<endpoint>" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY"
```

## Verify auth & discover the publication id

`BEEHIIV_PUBLICATION_ID` is normally set for you when the connection is made,
but it is **not** required for this skill to load — if it is empty, discover it
yourself rather than reporting the connection as broken:

```bash
# Lists only the publications this key can reach — the reliable way to get the id
curl -s "$BASE/publications" -H "Authorization: Bearer $BEEHIIV_API_KEY"

# Resolve the id ONLY when the choice is unambiguous
if [ -z "$BEEHIIV_PUBLICATION_ID" ]; then
  PUBS=$(curl -s "$BASE/publications" -H "Authorization: Bearer $BEEHIIV_API_KEY")
  COUNT=$(printf '%s' "$PUBS" | jq 'if .data then (.data | length) else -1 end')
  case "$COUNT" in
    1)  PUB=$(printf '%s' "$PUBS" | jq -r '.data[0].id') ;;
    0)  echo "Key is valid but reaches no publications — check the beehiiv account." ;;
    -1) # No `data` at all: an auth/plan/rate-limit error. Surface it verbatim.
        printf '%s' "$PUBS" | jq -r '.errors[]? | "\(.code): \(.message)"' ;;
    *)  # Two or more reachable publications — do NOT pick one.
        printf '%s' "$PUBS" | jq -r '.data[] | "\(.id)\t\(.name)"' ;;
  esac
fi
```

**Stop if `PUB` is still empty.** Every path below interpolates it, so continuing
would request `/publications//subscriptions` and turn a clear auth or account
error into a confusing 404 somewhere else entirely.

**Never guess which publication to use.** If the key reaches more than one, show
the user the list above and ask which they mean. Picking `.data[0]` would look
like it worked while adding subscribers to, or sending posts from, the wrong
newsletter — a silent wrong-target write is far worse than stopping to ask.

A bad key returns `401 INVALID_API_KEY`. **A publication outside the key's scope
returns `404` — the exact same response as a publication that doesn't exist.**
So a 404 may mean *wrong key scope*, not *wrong id*. Check the list above before
concluding the id is wrong.

## Error shape

```json
{
  "status": 401,
  "statusText": "unauthorized",
  "errors": [{ "message": "The api key is not valid", "code": "INVALID_API_KEY" }]
}
```

Errors are an **array** under `errors`, each with `message` and `code`.

## Pagination

`limit` is 1–100 (**default 10** — always set it explicitly). Two modes:

- **`cursor`** (recommended) — but **only `GET /subscriptions` supports it.**
  Response carries `has_more` and `next_cursor`.
- **`page`** — offset-based, **deprecated**, and anything past **page 100
  returns a 400**. It's the only option on posts, segments, publications,
  automations, and referral_program.

The envelope is flat (`data`, `limit`, `page`, `total_results`, `total_pages`),
but beehiiv's own pagination doc shows a nested `pagination` object. Extract
defensively: `.next_cursor // .pagination.next_cursor`.

⚠️ **`expand` vs `expand[]` is inconsistent in beehiiv's own spec.** Use
`expand` (unbracketed) on **publications and posts**; use `expand[]` on
**subscriptions, segments, and automations**.

## Subscriptions

```bash
# Create — only `email` is required. Returns 200 (NOT 201).
curl -s -X POST "$BASE/publications/$PUB/subscriptions" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jane@example.com",
    "reactivate_existing": false,
    "send_welcome_email": true,
    "utm_source": "chorus-agent",
    "utm_campaign": "launch-2026",
    "referring_site": "https://example.com/pricing",
    "custom_fields": [{ "name": "First Name", "value": "Jane" }],
    "automation_ids": ["aut_..."],
    "newsletter_list_ids": ["list_..."]
  }'

# List — cursor pagination, filters
curl -sG "$BASE/publications/$PUB/subscriptions" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  --data-urlencode "status=active" \
  --data-urlencode "tier=premium" \
  --data-urlencode "expand[]=custom_fields" \
  --data-urlencode "expand[]=stats" \
  --data-urlencode "limit=100"

# Get by id
curl -sG "$BASE/publications/$PUB/subscriptions/{subscriptionId}" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  --data-urlencode "expand[]=custom_fields" --data-urlencode "expand[]=tags"

# Get by email — the address MUST be URL-encoded (critical for `+` addresses)
EMAIL_ENC=$(printf '%s' "jane+news@example.com" | jq -sRr @uri)
curl -s "$BASE/publications/$PUB/subscriptions/by_email/$EMAIL_ENC" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY"

# Update by id — PUT and PATCH both work here
curl -s -X PATCH "$BASE/publications/$PUB/subscriptions/{subscriptionId}" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tier": "premium",
    "custom_fields": [
      { "name": "First Name", "value": "Janet" },
      { "name": "Obsolete Field", "delete": true }
    ]
  }'

# Unsubscribe — there is NO `status` field on update; use `unsubscribe`
curl -s -X PATCH "$BASE/publications/$PUB/subscriptions/{subscriptionId}" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "unsubscribe": true }'

# Update by email — PUT ONLY (no PATCH on this path)
curl -s -X PUT "$BASE/publications/$PUB/subscriptions/by_email/$EMAIL_ENC" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{ "unsubscribe": true }'

# Delete — irreversible, and stops premium billing. Prefer unsubscribing.
curl -s -X DELETE "$BASE/publications/$PUB/subscriptions/{subscriptionId}" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY"
```

Response `status` values: `validating`, `invalid`, `pending`, `active`,
`inactive`, `needs_attention`, `paused`. **The list filter accepts only five of
those** (`validating`, `invalid`, `pending`, `active`, `inactive`) plus `all` —
you cannot filter for `paused` or `needs_attention`.

`subscription_tier` (`free`/`premium`) is what tells you whether someone is
paying. There is **no `stripe` field** on the response — `stripe_customer_id` is
request-only.

### Bulk operations

```bash
# Bulk create
curl -s -X POST "$BASE/publications/$PUB/bulk_subscriptions" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"subscriptions":[{"email":"a@example.com"},{"email":"b@example.com"}]}'

# Bulk status change (PUT or PATCH on the collection root)
curl -s -X PATCH "$BASE/publications/$PUB/subscriptions" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"subscription_ids":["sub_1","sub_2"],"new_status":"inactive"}'

# Bulk field update (tier, custom fields, stripe id)
curl -s -X PATCH "$BASE/publications/$PUB/subscriptions/bulk_actions" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"subscriptions":[{"subscription_id":"sub_1","tier":"premium"}]}'

# Poll async bulk jobs
curl -s "$BASE/publications/$PUB/bulk_subscription_updates" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY"
```

## Tags & custom fields

```bash
# Add tags — creates them on the publication if they don't exist (max 100 per publication)
curl -s -X POST "$BASE/publications/$PUB/subscriptions/{subscriptionId}/tags" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"tags":["vip","beta-tester"]}'

# Create a custom field — both `kind` and `display` required
curl -s -X POST "$BASE/publications/$PUB/custom_fields" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"kind":"string","display":"First Name"}'

curl -s "$BASE/publications/$PUB/custom_fields" -H "Authorization: Bearer $BEEHIIV_API_KEY"
```

`kind`: `string`, `integer`, `boolean`, `date`, `datetime`, `list`, `double`.

**Add is the only tag endpoint** — there is no list-tags or remove-tag. Read
tags back with `expand[]=tags` on get-by-id/get-by-email.

**Custom fields must exist before you set values.** Values are keyed by the
field's *display name*, and unknown fields are **silently discarded**.

## Segments

```bash
# Manual segment — synchronous, comes back `completed`
curl -s -X POST "$BASE/publications/$PUB/segments" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"name":"VIPs","input":{"type":"emails","emails":["a@example.com"]}}'

# Dynamic segment — ASYNCHRONOUS, comes back `pending`
curl -s -X POST "$BASE/publications/$PUB/segments" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"name":"Beta users","input":{"type":"custom_fields","operator":"and",
       "custom_fields":[{"name":"Is Beta","operator":"equal","value":"true"}]}}'

# Members — FULL subscription objects
curl -sG "$BASE/publications/$PUB/segments/{segmentId}/members" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  --data-urlencode "expand[]=custom_fields" --data-urlencode "limit=100"

# Results — subscription IDs only; prefer this when you don't need full records
curl -sG "$BASE/publications/$PUB/segments/{segmentId}/results" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" --data-urlencode "limit=100"

# Force recalculation (PUT, no body)
curl -s -X PUT "$BASE/publications/$PUB/segments/{segmentId}/recalculate" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY"
```

Types: `dynamic`, `static`, `manual`. Statuses: `pending`, `processing`,
`completed`, `failed`. Dynamic segments recalculate **once daily around 07:00
UTC** unless you force it; `expand[]=stats` returns the last calculated numbers,
not live ones. Emails in a manual segment that aren't already subscribers are
**ignored, not created**.

## Posts

```bash
# List — note `expand` is UNBRACKETED on posts
curl -sG "$BASE/publications/$PUB/posts" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  --data-urlencode "status=confirmed" \
  --data-urlencode "audience=free" \
  --data-urlencode "platform=email" \
  --data-urlencode "expand=stats" \
  --data-urlencode "order_by=publish_date" \
  --data-urlencode "direction=desc" \
  --data-urlencode "limit=100"

# Single post with content — also unbracketed, repeat the param to expand more than one
curl -sG "$BASE/publications/$PUB/posts/{postId}" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" \
  --data-urlencode "expand=stats" --data-urlencode "expand=free_web_content"

# Aggregate stats across posts
curl -sG "$BASE/publications/$PUB/posts/aggregate_stats" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" --data-urlencode "status=confirmed"

# Send a test email
curl -s -X POST "$BASE/publications/$PUB/posts/{postId}/test_sends" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"recipient_emails":["you@example.com"]}'
```

`expand` options: `stats`, `free_web_content`, `free_email_content`,
`free_rss_content`, `premium_web_content`, `premium_email_content`, `recipients`.

**Post statuses are `draft`, `confirmed`, `archived` — there is no `sent`.**
`confirmed` covers both *scheduled in the future* and *already delivered*.

`DELETE /posts/{postId}` is not always destructive: a `confirmed` post becomes
`archived`; only `draft` posts are permanently deleted.

### Creating posts is Enterprise-gated

`POST /publications/{publicationId}/posts` exists — this is beehiiv's **Send
API** — but the spec states it is **in beta and available only to Enterprise
users**. On Launch/Scale/Max it will reject rather than publish. Don't reach for
it as the default way to "send an email."

Creation is also **asynchronous**: it returns `201` with a stable `id`
immediately, but fetching that post right away can return `202` (still
building — retry per `Retry-After`) or `404` with `POST_CREATION_FAILED` (give
up). Supply **either `blocks` or `body_content`, never both**. In HTML,
`<style>` and `<link>` tags are stripped and CSS classes do nothing — **inline
`style` attributes only**.

## Automations & journeys

```bash
curl -sG "$BASE/publications/$PUB/automations" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" --data-urlencode "expand[]=stats"

# Enroll an EXISTING subscriber into an automation journey
curl -s -X POST "$BASE/publications/$PUB/automations/{automationId}/journeys" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{"email":"jane@example.com"}'
  # or: -d '{"subscription_id":"sub_..."}'
```

Two constraints that bite:

1. **The automation must have an active "Add by API" trigger** (its
   `trigger_events` must include `api`), or enrollment won't work.
2. **This endpoint only enrolls people who are already subscribers.** To
   create-and-enroll in one step, use `POST /subscriptions` with
   `automation_ids` instead.

The same pattern applies to newsletter lists: `POST
/newsletter_lists/{id}/subscriptions` enrolls existing subscribers only; use
`newsletter_list_ids` on `POST /subscriptions` to do both at once.

## Webhooks

```bash
curl -s -X POST "$BASE/publications/$PUB/webhooks" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY" -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/hooks/beehiiv",
    "event_types": ["subscription.created","subscription.confirmed","post.sent"],
    "description": "Chorus agent sync"
  }'

curl -s "$BASE/publications/$PUB/webhooks" -H "Authorization: Bearer $BEEHIIV_API_KEY"
curl -s -X DELETE "$BASE/publications/$PUB/webhooks/{endpointId}" \
  -H "Authorization: Bearer $BEEHIIV_API_KEY"
```

Event types (19): `post.sent`, `post.updated`, `post.scheduled`,
`subscription.created`, `subscription.confirmed`, `subscription.deleted`,
`subscription.upgraded`, `subscription.downgraded`, `subscription.paused`,
`subscription.resumed`, `subscription.tier.created`,
`subscription.tier.deleted`, `subscription.tier.paused`,
`subscription.tier.resumed`, `newsletter_list_subscription.subscribed`,
`newsletter_list_subscription.unsubscribed`,
`newsletter_list_subscription.paused`, `newsletter_list_subscription.resumed`,
`survey.response_submitted`.

(beehiiv's docs index shows `subscription.tier.added` in one place — the
machine-readable enum says `subscription.tier.created`. Use that one.)

## Tips & gotchas

- **`GET /publications` first.** It both validates the key and returns the
  `pub_`-prefixed id. Don't use the newsletter slug or a dashboard URL fragment.
- **A `404` can mean the key is scoped to a different publication**, not that
  the id is wrong. Same response either way.
- **`POST` status codes are inconsistent**: `/subscriptions`, `/webhooks`, and
  `/custom_fields` return **200**; `/posts` and `/segments` return **201**.
  Don't assert on 201 generically.
- **`premium_tiers` / `premium_tier_ids` silently override `tier`.** Sending
  `tier: "free"` alongside a `premium_tier_ids` array yields a premium
  subscriber.
- **Unsubscribe with `{"unsubscribe": true}`, not a status change** — update has
  no `status` field. Deleting is irreversible and cancels premium billing.
- **URL-encode the email** in `/subscriptions/by_email/{email}`, or a `+` in the
  address decodes to a space and the lookup misses. The `?email=` *filter* is
  exact-match but case-insensitive.
- **Plan gating is real.** Launch (free) gets core read/write. **Webhooks,
  automations, segments, and custom fields effectively need Scale or above**;
  the Send API (`POST /posts`) needs Enterprise. A capability that "should work"
  but 4xxs is usually the plan, not the payload.
- **New accounts may need Stripe identity verification** before any API key
  works at all.
- **These endpoints do not exist** — don't invent them: email blasts/campaigns
  (sending = a Post or an Automation), a `/referrals` collection (only
  `/referral_program` milestones and `expand[]=referrals`), tag list/delete, and
  `DELETE`/`PATCH` on `/subscriptions/by_email/{email}`.
