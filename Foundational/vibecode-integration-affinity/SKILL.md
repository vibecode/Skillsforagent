---
name: vibecode-integration-affinity
display_name: Affinity
provider_skill: true
integration_dependencies:
  - affinity
description: >
  Affinity CRM API for relationship intelligence: companies, persons,
  opportunities, lists, pipeline field data, notes, reminders, and interaction
  history (emails, meetings, calls).
  Consult this skill:
  1. When the user asks to look up, search, or filter companies, people, or
     deals in their CRM
  2. When the user wants to read or update pipeline lists, list entries, or
     field values (e.g. move a deal to a new stage)
  3. When the user asks to log or read notes, or set reminders on a company,
     person, or opportunity
  4. When the user asks about relationship history — last contact, emails,
     meetings, calls, or warm intro paths
  5. When the user mentions Affinity, dealflow, or their pipeline and has
     Affinity connected
metadata: {"openclaw": {"emoji": "🤝", "requires": {"env": ["AFFINITY_API_KEY"]}}}
---

# Affinity Integration

REST API for the Affinity CRM: companies, persons, opportunities, lists, field
data, notes, reminders, and interaction metadata.

**Auth**: Bearer token via `Authorization` header.
**Base URL**: `https://api.affinity.co` — all v2 paths start with `/v2`.
**Rate limits**: 900 requests/user/minute, plus a monthly account-level pool
(Scale/Advanced: 100k, Enterprise: unlimited). v1 and v2 calls share the same
pool. Handle 429s; check `x-ratelimit-limit-user-remaining` /
`x-ratelimit-limit-org-remaining` response headers when doing bulk work.

```bash
# All v2 requests use Bearer auth
curl -s "https://api.affinity.co/v2/<endpoint>" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
```

## Verify auth & permissions

```bash
# Returns current user, org, and what this key is allowed to do — call first
curl -s "https://api.affinity.co/v2/auth/whoami" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
```

The API respects in-product permissions: the key can only see lists, notes, and
interactions its owner can see, and some endpoints need endpoint-specific
permissions granted by the Affinity admin (a 403 names the missing permission).

## Pagination

List endpoints return a `pagination.nextUrl` property. Follow it verbatim until
it is `null` — don't construct page URLs yourself. Max 100 results per page
(`?limit=100`).

## Companies

```bash
# List companies (paginated)
curl -s "https://api.affinity.co/v2/companies?limit=100" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Get one company (basic info + non-list-specific field data)
curl -s "https://api.affinity.co/v2/companies/{companyId}" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Search companies — term matches name + primary domain (min 3 chars)
curl -s -X POST "https://api.affinity.co/v2/companies/search" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"search":{"term":"acme"},"limit":25}'

# Discover company field metadata (ids + valueType — needed for filters/updates)
curl -s "https://api.affinity.co/v2/companies/fields" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Field values on one company
curl -s "https://api.affinity.co/v2/companies/{companyId}/fields" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Update a single field value (body shape depends on the field's valueType)
curl -s -X POST "https://api.affinity.co/v2/companies/{companyId}/fields/{fieldId}" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"value":{"type":"dropdown","data":{"dropdownOptionId":123}}}'

# Batch field updates on one company
curl -s -X PATCH "https://api.affinity.co/v2/companies/{companyId}/fields" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"operations":[{"fieldId":"field-1234","value":{"type":"text","data":"Series A"}}]}'

# Where does this company appear? (lists + list entries with field data)
curl -s "https://api.affinity.co/v2/companies/{companyId}/lists" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
curl -s "https://api.affinity.co/v2/companies/{companyId}/list-entries" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Relationships (who on the team knows this company, incl. interaction score)
curl -s "https://api.affinity.co/v2/companies/{companyId}/relationships" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Notes attached to a company
curl -s "https://api.affinity.co/v2/companies/{companyId}/notes" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
```

## Persons

Same shape as companies — swap `/companies` for `/persons`:

```bash
# Search persons; term matches name/emails
curl -s -X POST "https://api.affinity.co/v2/persons/search" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"search":{"term":"jane doe"},"limit":25}'

# Also available: GET /v2/persons, /v2/persons/{id}, /v2/persons/fields,
# /v2/persons/{id}/fields (+ POST single / PATCH batch updates),
# /v2/persons/{id}/lists, /v2/persons/{id}/list-entries,
# /v2/persons/{id}/relationships, /v2/persons/{id}/notes
```

## Opportunities

```bash
# Basic info only — opportunity FIELD DATA lives on list entries (see Lists)
curl -s "https://api.affinity.co/v2/opportunities?limit=100" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
curl -s "https://api.affinity.co/v2/opportunities/{opportunityId}" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
```

## Lists & list entries (pipelines live here)

```bash
# All lists you can see
curl -s "https://api.affinity.co/v2/lists" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# A list's fields (stage, status, owner, etc.)
curl -s "https://api.affinity.co/v2/lists/{listId}/fields" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Rows on a list, with field data
curl -s "https://api.affinity.co/v2/lists/{listId}/list-entries?limit=100" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Search/filter rows (e.g. deals in a given stage)
curl -s -X POST "https://api.affinity.co/v2/lists/{listId}/list-entries/search" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"filters":{"type":"filter-group","operation":"and","items":[{"type":"filter","fieldId":"field-1234","operator":"is-any-of","value":[123]}]}}'

# Update a field on a row (e.g. move deal to a new stage)
curl -s -X POST "https://api.affinity.co/v2/lists/{listId}/list-entries/{listEntryId}/fields/{fieldId}" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"value":{"type":"dropdown","data":{"dropdownOptionId":456}}}'

# Batch: PATCH /v2/lists/{listId}/list-entries/{listEntryId}/fields

# Saved views (respect the view's filters — good for "show me my pipeline view")
curl -s "https://api.affinity.co/v2/lists/{listId}/saved-views" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
curl -s "https://api.affinity.co/v2/lists/{listId}/saved-views/{viewId}/list-entries" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Create a list
curl -s -X POST "https://api.affinity.co/v2/lists" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Q3 Prospects","type":"company","isPublic":true}'

# Manage dropdown options on a list field:
# GET/POST /v2/lists/{listId}/fields/{fieldId}/dropdown-options
# PUT/DELETE /v2/lists/{listId}/fields/{fieldId}/dropdown-options/{optionId}
```

## Notes

```bash
# All notes / one note / keyword search
curl -s "https://api.affinity.co/v2/notes" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
curl -s -X POST "https://api.affinity.co/v2/notes/search" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"term":"term sheet"}'

# Create a note attached to entities (content is HTML — allowed tags only:
# <p> <br> <strong> <em> <u> <ol> <ul> <li> <span> <a href=...>)
curl -s -X POST "https://api.affinity.co/v2/notes" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"type":"entities","content":{"html":"<p>Call went well; sending deck.</p>"},"companies":[{"id":10}],"persons":[{"id":1}]}'

# Update / delete
curl -s -X POST "https://api.affinity.co/v2/notes/{noteId}" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content":{"html":"<p>Updated summary.</p>"}}'
curl -s -X DELETE "https://api.affinity.co/v2/notes/{noteId}" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
```

## Reminders

```bash
curl -s "https://api.affinity.co/v2/reminders" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"
# type: one-time | recurring; attach exactly one of company/person/opportunity
curl -s -X POST "https://api.affinity.co/v2/reminders" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"type":"one-time","dueDate":"2026-08-01T17:00:00Z","content":"Follow up on term sheet","company":{"id":10}}'
```

## Interactions & relationship intelligence (read-only)

```bash
# Metadata on emails / meetings / calls / chat messages (paginated)
curl -s "https://api.affinity.co/v2/emails" -H "Authorization: Bearer $AFFINITY_API_KEY"
curl -s "https://api.affinity.co/v2/meetings" -H "Authorization: Bearer $AFFINITY_API_KEY"
curl -s "https://api.affinity.co/v2/calls" -H "Authorization: Bearer $AFFINITY_API_KEY"
curl -s "https://api.affinity.co/v2/chat-messages" -H "Authorization: Bearer $AFFINITY_API_KEY"

# Meeting transcripts (incl. fragments)
curl -s "https://api.affinity.co/v2/transcripts" -H "Authorization: Bearer $AFFINITY_API_KEY"

# Audit trail of field changes (e.g. stage history for velocity analysis)
curl -s "https://api.affinity.co/v2/field-value-changes?fieldId=field-1234" \
  -H "Authorization: Bearer $AFFINITY_API_KEY"

# Warm intro paths: coworkers connected to people at a target company
curl -s "https://api.affinity.co/v2/inferred-connections/coworkers" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  --data-urlencode "filter=target.currentCompany.id = 10" -G

# Keyword search over attached files
curl -s -X POST "https://api.affinity.co/v2/files/search" \
  -H "Authorization: Bearer $AFFINITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"term":"pitch deck"}'
```

## v1 fallback (creating entities & webhooks)

v2 is not yet at feature parity with v1. Notably, v2 **cannot create or delete
companies, persons, opportunities, or list entries**, and webhooks are
v1-only. The same API key works on v1 with **HTTP Basic auth** (blank
username, key as password) at the same host — note v1 calls companies
"organizations":

```bash
# Create a person (v1)
curl -s -X POST "https://api.affinity.co/persons" \
  -u ":$AFFINITY_API_KEY" -H "Content-Type: application/json" \
  -d '{"first_name":"Jane","last_name":"Doe","emails":["jane@acme.com"],"organization_ids":[10]}'

# Create a company (v1 "organization")
curl -s -X POST "https://api.affinity.co/organizations" \
  -u ":$AFFINITY_API_KEY" -H "Content-Type: application/json" \
  -d '{"name":"Acme","domain":"acme.com"}'

# Add an entity to a list (v1 list entry)
curl -s -X POST "https://api.affinity.co/lists/{list_id}/list-entries" \
  -u ":$AFFINITY_API_KEY" -H "Content-Type: application/json" \
  -d '{"entity_id":10}'
```

Full v1 reference: https://api-docs.affinity.co/

## Tips

- **Start with `GET /v2/auth/whoami`** — it tells you which endpoint permissions
  the key has before you burn requests on 403s.
- **Field IDs first**: filters, sorts, and updates all need field ids and
  `valueType` from `/v2/{companies,persons}/fields` or `/v2/lists/{id}/fields`.
  Some relationship fields (`last-email`, `last-contact`, `next-event`, …) also
  need `attributeId: "date-of-activity"` in filters/sorts.
- **Opportunity data lives on lists**: `GET /v2/opportunities` returns only
  name/ids. For stage, amount, owner, etc., read the opportunity list's entries.
- **Search limits**: term min 3 chars, max 100 results/page, max 50 items per
  filter group, max 5 sort criteria.
- **Don't poll for changes** — use `/v2/field-value-changes` for field audit
  history, or v1 webhooks for push notifications.
- **API access is plan-gated** (Scale and up; Essentials has no API access) and
  each user can hold a limited number of keys.
