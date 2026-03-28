---
name: vibecode-integration-intercom
description: >
  Intercom API for managing conversations, contacts, articles, and support workflows.
  Consult this skill:
  1. When the user asks to view, reply to, or manage Intercom conversations
  2. When the user needs to search or update contacts or companies
  3. When the user wants to manage help center articles or tags
  4. When the user asks about support metrics, team assignments, or ticket operations
  5. When you need to send admin-initiated messages or track events
metadata: {"openclaw": {"emoji": "💬", "requires": {"env": ["INTERCOM_ACCESS_TOKEN"]}}}
---

# Intercom Integration

REST API v2.15 for conversations, contacts, articles, companies, tags, and support workflows.

**Auth**: Bearer token via `INTERCOM_ACCESS_TOKEN` env var.

```bash
# All requests use these headers
curl -s https://api.intercom.com/<endpoint> \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15"
```

**Regional endpoints**: US `api.intercom.com` | EU `api.eu.intercom.io` | AU `api.au.intercom.io`. Default to US unless user specifies otherwise.

## Conversations

```bash
# List conversations
curl -s "https://api.intercom.com/conversations" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"

# Get conversation with full thread
curl -s "https://api.intercom.com/conversations/{id}?display_as=plaintext" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"

# Search conversations (open, assigned to team)
curl -s -X POST "https://api.intercom.com/conversations/search" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"query":{"operator":"AND","value":[
    {"field":"state","operator":"=","value":"open"},
    {"field":"team_assignee_id","operator":"=","value":"TEAM_ID"}
  ]}}'

# Reply to conversation (as admin)
curl -s -X POST "https://api.intercom.com/conversations/{id}/reply" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"message_type":"comment","type":"admin","admin_id":"ADMIN_ID","body":"Reply text"}'

# Add internal note
curl -s -X POST "https://api.intercom.com/conversations/{id}/reply" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"message_type":"note","type":"admin","admin_id":"ADMIN_ID","body":"Internal note"}'

# Assign conversation
curl -s -X POST "https://api.intercom.com/conversations/{id}/parts" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"message_type":"assignment","type":"admin","admin_id":"ADMIN_ID","assignee_id":"TARGET_ADMIN_OR_TEAM_ID"}'

# Close conversation
curl -s -X POST "https://api.intercom.com/conversations/{id}/parts" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"message_type":"close","type":"admin","admin_id":"ADMIN_ID"}'
```

## Contacts

```bash
# Search contacts by email
curl -s -X POST "https://api.intercom.com/contacts/search" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"query":{"field":"email","operator":"=","value":"user@example.com"}}'

# Create contact
curl -s -X POST "https://api.intercom.com/contacts" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"role":"user","email":"user@example.com","name":"Jane Doe"}'

# Update contact (PATCH not PUT)
curl -s -X PATCH "https://api.intercom.com/contacts/{id}" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"name":"Updated Name","custom_attributes":{"plan":"enterprise"}}'

# List contacts
curl -s "https://api.intercom.com/contacts" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"
```

## Articles (Help Center)

```bash
# List articles
curl -s "https://api.intercom.com/articles" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"

# Search articles
curl -s "https://api.intercom.com/articles/search?phrase=billing+FAQ" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"

# Create article
curl -s -X POST "https://api.intercom.com/articles" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"title":"Getting Started","body":"<p>Welcome...</p>","author_id":"ADMIN_ID","state":"published"}'
```

## Admins & Teams

```bash
# List admins (needed for admin_id in replies/assignments)
curl -s "https://api.intercom.com/admins" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"

# List teams
curl -s "https://api.intercom.com/teams" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"
```

## Tags, Notes & Events

```bash
# List tags
curl -s "https://api.intercom.com/tags" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Intercom-Version: 2.15"

# Tag a contact
curl -s -X POST "https://api.intercom.com/contacts/{contact_id}/tags" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"id":"TAG_ID"}'

# Create note on contact
curl -s -X POST "https://api.intercom.com/contacts/{contact_id}/notes" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"admin_id":"ADMIN_ID","body":"Note text"}'

# Track event
curl -s -X POST "https://api.intercom.com/events" \
  -H "Authorization: Bearer $INTERCOM_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Intercom-Version: 2.15" \
  -d '{"event_name":"completed-onboarding","email":"user@example.com","created_at":1711382400}'
```

## Search Operators

For `/contacts/search`, `/conversations/search`, `/companies/search`:

| Operator | Meaning |
|---|---|
| `=`, `!=` | Equals / not equals |
| `<`, `>`, `<=`, `>=` | Numeric/date comparison |
| `IN`, `NIN` | In / not in array |
| `~`, `!~` | Contains / not contains (strings) |

Combine with `{"operator": "AND"}` or `{"operator": "OR"}` at the top level.

## Tips

- **Always list admins first** — you need `admin_id` for replies, notes, assignments, and article creation.
- **Use PATCH not PUT** for contact/company updates.
- **Pagination**: Responses include `pages.next` cursor. Pass `starting_after` param for next page.
- **Rate limit**: 10,000 calls/min per app. Check `X-RateLimit-Remaining` header.
- **`display_as=plaintext`** on conversation GET to avoid HTML in responses.
- **Custom attributes**: Must be defined in Intercom UI before setting via API.
- **Conversation states**: `open`, `closed`, `snoozed`.

---

*Extracted from [vm0-ai/vm0-skills/intercom](https://skills.sh/vm0-ai/vm0-skills/intercom), [claude-office-skills/intercom-automation](https://skills.sh/claude-office-skills/skills/intercom-automation), and [Intercom API Reference v2.15](https://developers.intercom.com/docs/references/rest-api/api.intercom.io/).*
