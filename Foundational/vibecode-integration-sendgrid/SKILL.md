---
name: vibecode-integration-sendgrid
display_name: SendGrid
provider_skill: true
integration_dependencies:
  - sendgrid
description: >
  SendGrid API for sending transactional and marketing email, managing
  templates, contacts, lists, suppressions, and stats. Consult this skill:
  1. When the user asks to send an email (transactional, broadcast, or test)
  2. When the user wants to create, list, update, or use dynamic email templates
  3. When the user needs to manage marketing contacts, lists, or segments
  4. When the user asks about bounces, blocks, spam reports, or unsubscribes (suppressions)
  5. When the user wants email delivery stats or to inspect recent sends
  6. When the user mentions SendGrid, Twilio SendGrid, or wants to act on email infra
metadata: {"openclaw": {"emoji": "✉️", "requires": {"env": ["SENDGRID_API_KEY"]}}}
---

# SendGrid Integration

REST v3 API for transactional + marketing email, templates, contacts, suppressions, and stats.

**Auth**: Bearer token via `Authorization` header.
**Base URL**: `https://api.sendgrid.com`
**Rate limits**: Vary by endpoint and account tier. Mail Send is generous (~100s/sec on paid). Marketing endpoints rate-limit harder — batch when possible.

```bash
# All requests use Bearer auth
curl -s "https://api.sendgrid.com/v3/<endpoint>" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"
```

## Send mail (the main one)

```bash
# Simple transactional send (single recipient)
curl -s -X POST "https://api.sendgrid.com/v3/mail/send" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [{"to": [{"email": "alice@example.com"}]}],
    "from": {"email": "noreply@yourdomain.com", "name": "Your App"},
    "subject": "Hello from SendGrid",
    "content": [{"type": "text/plain", "value": "Body text"}]
  }'

# HTML email
curl -s -X POST "https://api.sendgrid.com/v3/mail/send" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [{"to": [{"email": "alice@example.com"}]}],
    "from": {"email": "noreply@yourdomain.com"},
    "subject": "Welcome",
    "content": [{"type": "text/html", "value": "<h1>Welcome</h1><p>Thanks for signing up.</p>"}]
  }'

# Multiple recipients with personalization (each gets a separate email)
curl -s -X POST "https://api.sendgrid.com/v3/mail/send" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [
      {"to": [{"email": "alice@example.com"}], "subject": "Hi Alice"},
      {"to": [{"email": "bob@example.com"}], "subject": "Hi Bob"}
    ],
    "from": {"email": "noreply@yourdomain.com"},
    "content": [{"type": "text/plain", "value": "Generic body"}]
  }'

# Using a dynamic template (no inline content needed)
curl -s -X POST "https://api.sendgrid.com/v3/mail/send" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [{
      "to": [{"email": "alice@example.com"}],
      "dynamic_template_data": {"firstName": "Alice", "orderTotal": "$42.00"}
    }],
    "from": {"email": "orders@yourdomain.com"},
    "template_id": "d-abc123..."
  }'
```

**202 Accepted** = queued for delivery (success). Failures return 4xx with an `errors` array.

## Templates (transactional)

```bash
# List dynamic templates
curl -s "https://api.sendgrid.com/v3/templates?generations=dynamic&page_size=20" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Get one template (includes all versions)
curl -s "https://api.sendgrid.com/v3/templates/{templateId}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Create a dynamic template (then add a version with HTML)
curl -s -X POST "https://api.sendgrid.com/v3/templates" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Order Confirmation", "generation": "dynamic"}'

# Add a version (the actual HTML/subject of the template)
curl -s -X POST "https://api.sendgrid.com/v3/templates/{templateId}/versions" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "active": 1,
    "name": "v1",
    "subject": "Order #{{orderId}} confirmed",
    "html_content": "<p>Hi {{firstName}}, your order is on the way.</p>",
    "plain_content": "Hi {{firstName}}, your order is on the way."
  }'

# Delete template
curl -s -X DELETE "https://api.sendgrid.com/v3/templates/{templateId}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"
```

## Marketing contacts & lists

Marketing endpoints (under `/v3/marketing/`) are async — most return a `job_id` rather than the operation result.

```bash
# Upsert contacts (returns job_id)
curl -s -X PUT "https://api.sendgrid.com/v3/marketing/contacts" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "list_ids": ["{listId}"],
    "contacts": [
      {"email": "alice@example.com", "first_name": "Alice", "last_name": "Smith"}
    ]
  }'

# Check job status
curl -s "https://api.sendgrid.com/v3/marketing/contacts/imports/{jobId}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Search contacts by email/criteria (SQL-like)
curl -s -X POST "https://api.sendgrid.com/v3/marketing/contacts/search" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "email LIKE '"'"'%@example.com'"'"' AND CONTAINS(list_ids, '"'"'{listId}'"'"')"}'

# Get contact by ID
curl -s "https://api.sendgrid.com/v3/marketing/contacts/{contactId}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Delete contacts (DELETE with query param)
curl -s -X DELETE "https://api.sendgrid.com/v3/marketing/contacts?ids={contactId1},{contactId2}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# List all lists
curl -s "https://api.sendgrid.com/v3/marketing/lists?page_size=100" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Create list
curl -s -X POST "https://api.sendgrid.com/v3/marketing/lists" \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Beta Users"}'

# Remove a contact from a list
curl -s -X DELETE "https://api.sendgrid.com/v3/marketing/lists/{listId}/contacts?contact_ids={contactId}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"
```

## Suppressions (bounces, blocks, spam reports, unsubscribes)

Check before sending — emailing a suppressed address still counts against your reputation.

```bash
# List bounces (delivery failures)
curl -s "https://api.sendgrid.com/v3/suppression/bounces" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# List blocks (IP/domain refusals)
curl -s "https://api.sendgrid.com/v3/suppression/blocks" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# List spam reports
curl -s "https://api.sendgrid.com/v3/suppression/spam_reports" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# List invalid emails
curl -s "https://api.sendgrid.com/v3/suppression/invalid_emails" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Global unsubscribe check (returns the address if suppressed)
curl -s "https://api.sendgrid.com/v3/asm/suppressions/global/{email}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Remove a bounce (re-enable sending)
curl -s -X DELETE "https://api.sendgrid.com/v3/suppression/bounces/{email}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"
```

## Stats

```bash
# Aggregate stats over a date range
curl -s "https://api.sendgrid.com/v3/stats?start_date=2026-05-01&end_date=2026-05-25&aggregated_by=day" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"

# Category-level stats (e.g. for a specific tag)
curl -s "https://api.sendgrid.com/v3/categories/stats?start_date=2026-05-01&end_date=2026-05-25&categories={tag}" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"
```

## Tips & gotchas

- **`from` address must be verified** in Sender Authentication. Sending from an unverified domain/sender returns `403 Forbidden` with a clear error.
- **Mail Send returns 202** on success — there's no body, just a `X-Message-Id` response header. To track delivery, set up Event Webhooks (configured in the SendGrid dashboard).
- **Templates use Handlebars-style `{{var}}`** for substitution. Pass values via `dynamic_template_data` in personalizations.
- **Marketing API is async** — most write operations return `{ "job_id": "..." }`. Poll the relevant `imports/{jobId}` or `exports/{jobId}` endpoint to confirm completion.
- **Pagination** on most list endpoints uses `?page_size=N&page_token=<cursor>`. Default page size is small; set to 100 for fewer round trips.
- **API keys are scoped** — if a call returns `401`/`403`, the key may not have the needed permission (e.g., Mail Send vs Marketing). Use a Full Access key for general agent work or check the key's scopes in SendGrid settings.
- **Don't loop on `/messages`** — that's the Email Activity endpoint and it's a paid feature with tight rate limits. Use Event Webhooks for delivery tracking instead.
