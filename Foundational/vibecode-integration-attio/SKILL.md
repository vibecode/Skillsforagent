---
name: vibecode-integration-attio
display_name: Attio
provider_skill: true
integration_dependencies:
  - attio
description: >
  Attio CRM API for records (people, companies, deals), objects and attributes,
  lists and pipeline entries, notes, tasks, comments, and workspace members.
  Consult this skill:
  1. When the user asks to look up, search, create, or update people, companies,
     or deals in their CRM
  2. When the user wants to read or work a pipeline — list entries, deal stages,
     or moving a record to a new stage
  3. When the user asks to log a note, create a follow-up task, or comment on a
     record
  4. When the user asks what fields or objects exist in their CRM, or wants to
     enrich records with new attribute values
  5. When the user mentions Attio, their CRM, pipeline, or dealflow and has Attio
     connected
metadata: {"openclaw": {"emoji": "🧭", "requires": {"env": ["ATTIO_ACCESS_TOKEN"]}}}
---

# Attio Integration

REST API for the Attio CRM: objects and attributes, records, lists and entries,
notes, tasks, comments, and workspace members.

**Auth**: Bearer token via `ATTIO_ACCESS_TOKEN`.
**Base URL**: `https://api.attio.com` — all paths start with `/v2`.
**Rate limits**: 100 req/s reads, 25 req/s writes. A `429` carries a
`Retry-After` header holding a **date** (not seconds), usually the next clock
second; rate-limited requests are not processed, so retrying is safe. The two
`*/query` endpoints additionally have a complexity-score limit over a 10s
sliding window shared across every app on the workspace — if a query is
rejected, simplify its filters/sorts rather than retrying it unchanged.

```bash
curl -s "https://api.attio.com/v2/<endpoint>" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

## Verify auth & workspace

```bash
# Call first — confirms the token is live and names the workspace + scopes
curl -s "https://api.attio.com/v2/self" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

Returns `{"active": false}` for a dead token, otherwise `workspace_id`,
`workspace_name`, `workspace_slug`, and `scope` — a **space-separated string**,
not an array. Scopes are granular (`record_permission:read-write`,
`list_entry:read-write`, `note:read-write`, `task:read-write`,
`comment:read-write`, `object_configuration:read`, `user_management:read`, …);
check `scope` before attempting a write you may not be allowed to make.

## Objects & attributes (discover the schema first)

Attribute slugs vary per workspace, so read the schema before filtering or
writing anything non-obvious.

```bash
# All objects in the workspace
curl -s "https://api.attio.com/v2/objects" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Attributes for an object (or a list — the path is shared)
curl -s "https://api.attio.com/v2/objects/people/attributes?limit=100" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
curl -s "https://api.attio.com/v2/lists/{list}/attributes" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Select options / status values for one attribute (needed to write them)
curl -s "https://api.attio.com/v2/objects/deals/attributes/stage/statuses" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
curl -s "https://api.attio.com/v2/objects/companies/attributes/categories/options" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

Standard objects: `people` and `companies` are on by default; `deals`, `users`,
and `workspaces` must be enabled by a workspace admin (expect `404 not_found`
if they aren't). Common slugs — **people**: `name`, `email_addresses`,
`phone_numbers`, `job_title`, `company`, `description`, `linkedin`,
`primary_location`. **companies**: `name`, `domains`, `description`,
`categories`, `team`, `primary_location`. **deals**: `name`, `stage`, `owner`,
`value`, `associated_people`, `associated_company`.

Attribute types: `text, number, checkbox, currency, date, timestamp, rating,
status, select, record-reference, actor-reference, location, domain,
email-address, phone-number, interaction, personal-name`.

## Records

```bash
# Query records — filter, sorts, limit, offset are all optional
curl -s -X POST "https://api.attio.com/v2/objects/people/records/query" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filter":{"email_addresses":{"email_domain":{"$eq":"acme.com"}}},
       "sorts":[{"direction":"desc","attribute":"created_at"}],
       "limit":100,"offset":0}'

# Get / delete one record
curl -s "https://api.attio.com/v2/objects/people/records/{record_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
curl -s -X DELETE "https://api.attio.com/v2/objects/people/records/{record_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Create (errors if a unique value collides)
curl -s -X POST "https://api.attio.com/v2/objects/companies/records" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"values":{"name":"Acme","domains":["acme.com"]}}}'

# Upsert — matching_attribute is REQUIRED and must be a unique attribute
curl -s -X PUT "https://api.attio.com/v2/objects/people/records?matching_attribute=email_addresses" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"values":{
        "email_addresses":["ada@acme.com"],
        "name":[{"first_name":"Ada","last_name":"Lovelace","full_name":"Ada Lovelace"}],
        "job_title":"Analyst"}}}'

# Update. PATCH appends to multiselect values; PUT overwrites them.
curl -s -X PATCH "https://api.attio.com/v2/objects/companies/records/{record_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"values":{"description":"Series A fintech"}}}'

# Which list entries is this record on?
curl -s "https://api.attio.com/v2/objects/people/records/{record_id}/entries" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Fuzzy cross-object search (beta, eventually consistent — use query for
# read-your-writes). query + objects + request_as are all required; limit ≤ 25.
curl -s -X POST "https://api.attio.com/v2/objects/records/search" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"ada lovelace","objects":["people","companies"],
       "request_as":{"type":"workspace"},"limit":25}'
```

### Writing attribute values

Bodies are always `{"data":{"values":{…}}}`. Several types have shapes that are
easy to get wrong:

| Type | Shape |
|---|---|
| Text | `"job_title":"Analyst"` |
| Personal name | `"name":[{"first_name":"Ada","last_name":"Lovelace","full_name":"Ada Lovelace"}]` — object form needs **all three**. String form must be `"Lovelace, Ada"`; a comma-less string is read as first name only. |
| Email | `"email_addresses":["a@b.com"]` (multiselect — always an array) |
| Phone | `"phone_numbers":[{"original_phone_number":"+15558675309","country_code":"US"}]` |
| Select (multi) | `"categories":["3D Printing","Architecture"]` |
| Status (single) | `"stage":"Lead"` or `[{"status":"Lead"}]` |
| Record reference | `"associated_company":[{"target_object":"companies","target_record_id":"<uuid>"}]` — or the shorthand `"associated_company":"acme.com"` for standard objects (companies→domain, people→email, users→`user_id`) |
| Actor reference | `"owner":"alice@acme.com"` or `[{"workspace_member_email_address":"alice@acme.com"}]` — only workspace members are writable |

Select and status writes **never create new options** — an unknown title or ID
is an error, so read `/statuses` or `/options` first. Record references require
the target record to already exist; writes do not create it, so write parents
before children.

## Lists & entries (pipelines live here)

```bash
# All lists (no pagination on this endpoint)
curl -s "https://api.attio.com/v2/lists" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Query entries — same body shape as records/query
curl -s -X POST "https://api.attio.com/v2/lists/{list}/entries/query" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filter":{"stage":{"$eq":"Screening"}},"limit":100}'

# Add a record to a list. Note: entry_values, NOT values — all three required.
curl -s -X POST "https://api.attio.com/v2/lists/{list}/entries" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"parent_record_id":"<uuid>","parent_object":"people",
       "entry_values":{"stage":"Screening"}}}'

# Move an entry to a new stage (PATCH appends multiselect, PUT overwrites)
curl -s -X PATCH "https://api.attio.com/v2/lists/{list}/entries/{entry_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"entry_values":{"stage":"Offer"}}}'

# Get / delete an entry; upsert by parent record
curl -s "https://api.attio.com/v2/lists/{list}/entries/{entry_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
curl -s -X DELETE "https://api.attio.com/v2/lists/{list}/entries/{entry_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
# PUT /v2/lists/{list}/entries — 400 multiple_match_results if the parent
# record already has more than one entry on the list

# Saved views
curl -s "https://api.attio.com/v2/lists/{list}/views" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

To filter entries by something on the parent record, use a **path filter**.
`parent_record` is a pseudo-attribute present on every list entry:

```bash
curl -s -X POST "https://api.attio.com/v2/lists/{list}/entries/query" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filter":{"path":[["{list}","parent_record"],["people","email_addresses"]],
       "constraints":{"email_domain":"acme.com"}}}'
```

## Notes

```bash
# List notes (limit default 10, max 50) — scope to one record when you can
curl -s "https://api.attio.com/v2/notes?parent_object=people&parent_record_id={record_id}&limit=50" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Create. parent_object, parent_record_id, title, format, content all required.
curl -s -X POST "https://api.attio.com/v2/notes" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"parent_object":"people","parent_record_id":"<uuid>",
       "title":"Intro call","format":"markdown",
       "content":"## Recap\n\n- Budget confirmed\n- **Next**: send pricing"}}'

# Get / delete
curl -s "https://api.attio.com/v2/notes/{note_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
curl -s -X DELETE "https://api.attio.com/v2/notes/{note_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

`format` is `"plaintext"` or `"markdown"`. Markdown supports a subset only:
`#`/`##`/`###` headings, `-`/`*`/`+` and `1.` lists, `**bold**`, `*italic*`,
`~~strike~~`, `==highlight==`, `[text](url)`. Images are not supported.
**There is no update-note endpoint** — to correct a note, delete and recreate.

## Tasks

```bash
# List — filter by record, assignee, or completion
curl -s "https://api.attio.com/v2/tasks?linked_object=people&linked_record_id={record_id}&is_completed=false&sort=created_at:desc" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Create — ALL SIX fields are required, even is_completed and empty arrays
curl -s -X POST "https://api.attio.com/v2/tasks" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"content":"Send pricing to Ada","format":"plaintext",
       "deadline_at":"2026-08-01T15:00:00.000000000Z","is_completed":false,
       "linked_records":[{"target_object":"people","target_record_id":"<uuid>"}],
       "assignees":[{"workspace_member_email_address":"alice@acme.com"}]}}'

# Complete / update / delete
curl -s -X PATCH "https://api.attio.com/v2/tasks/{task_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"is_completed":true}}'
curl -s -X DELETE "https://api.attio.com/v2/tasks/{task_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

`format` accepts only `"plaintext"`; `content` is capped at 2000 chars with no
links or @-mentions. `linked_records` also accepts bare strings
(`["ada@acme.com","acme.com"]`). `sort` ∈ `created_at:asc|created_at:desc|
completed_at:asc|completed_at:desc`.

## Comments & threads

```bash
# Read comments via threads (record_id pairs with object, entry_id with list)
curl -s "https://api.attio.com/v2/threads?object=people&record_id={record_id}&limit=50" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
curl -s "https://api.attio.com/v2/threads/{thread_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"

# Start a thread on a record. Supply EXACTLY ONE of record / entry / thread_id.
curl -s -X POST "https://api.attio.com/v2/comments" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"data":{"format":"plaintext","content":"Chasing this one today.",
       "author":{"type":"workspace-member","id":"<workspace_member_id>"},
       "record":{"object":"people","record_id":"<uuid>"}}}'

# Reply: swap "record" for "thread_id":"<uuid>"
curl -s -X DELETE "https://api.attio.com/v2/comments/{comment_id}" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

Mixing `record`, `entry`, and `thread_id` in one body is a 400. There is no
list-comments and no update-comment endpoint. @-mention a teammate by putting
their email address in `content`.

## Workspace members

```bash
# No pagination — returns every member. Use to resolve an author/assignee id.
curl -s "https://api.attio.com/v2/workspace_members" \
  -H "Authorization: Bearer $ATTIO_ACCESS_TOKEN"
```

Each member has `id.workspace_member_id`, `email_address`, `first_name`,
`last_name`, and `access_level` (`admin` | `member` | `suspended`).

## Filtering

Shorthand `{"name":"Ada Lovelace"}` means `$eq` on the attribute's primary
field. The verbose form drills into sub-fields:
`{"email_addresses":{"email_domain":{"$eq":"acme.com"}}}`.

Operators: `$eq`, `$in`, `$not_empty`, `$contains`, `$starts_with`,
`$ends_with` (string ops are case-insensitive), `$lt`, `$lte`, `$gt`, `$gte`,
and the logical `$and` / `$or` / `$not`. **There is no `$ne`** — wrap the
condition in `$not`. Support varies by type: select, status, actor-reference,
and checkbox accept only `$eq`; record-reference accepts `$eq` and `$in`.

Pass `"filter_view_id":"<uuid>"` instead of `filter` to reuse a saved view's
filters — the two are mutually exclusive, and sorts/limit/offset are not
inherited from the view.

## Pagination

Records/entries queries and the tasks, notes, threads, and attributes lists use
`limit` + `offset` (in the JSON body for `POST`, as query params for `GET`).
Keep paging until a response returns fewer items than `limit`. Defaults differ:
records/entries queries and tasks default to 500; notes and threads default to
10 and cap at 50. `GET /v2/objects`, `GET /v2/lists`, and
`GET /v2/workspace_members` are **not paginated** and return everything.

## Tips

- **Call `GET /v2/self` first.** It confirms the workspace and lists the scopes
  the token holds, which is cheaper than discovering a missing scope through a
  failed write.
- **Read the schema before writing.** Attribute slugs are per-workspace and
  user-editable; select/status options must exist already.
- **PATCH vs PUT is about multiselect semantics, not partial updates.** Both
  accept partial `values`; `PATCH` appends to multiselect attributes, `PUT`
  replaces them. Use `PATCH` unless you intend to remove existing values.
- **Deals cannot be upserted by default** — they have no unique attribute until
  someone adds one, so `PUT …/records?matching_attribute=` will fail.
- **Relationship attributes are bidirectional.** Writing `person.company` also
  updates the company's `team`; don't write both sides.
- Responses are always keyed by attribute **slug**, even if you wrote using an
  attribute ID. `record_id` is only unique alongside its `object_id`.
- A successful `DELETE` returns `200` with `{}`, not `204`.
- Errors are consistent: `{"status_code","type","code","message"}`. Common
  codes: `404 not_found`, `400 value_not_found` (unknown select option or
  matching attribute), `400 multiple_match_results`, `403 billing_error` (the
  feature needs a higher Attio plan), `429 rate_limit_exceeded`.
- Enriched attributes on people/companies are read-only via the API, and some
  are hidden on lower billing plans.

Full reference: https://docs.attio.com/rest-api
