---
name: vibecode-integration-airtable
description: >
  Airtable API for managing bases, tables, records, and views.
  Consult this skill:
  1. When the user asks to query, create, or update Airtable records
  2. When the user needs to list bases, tables, or view schemas
  3. When the user wants to filter, sort, or search Airtable data
  4. When the user mentions Airtable, bases, tables, or spreadsheet-like databases
metadata: {"openclaw": {"emoji": "📊", "requires": {"env": ["AIRTABLE_ACCESS_TOKEN"]}}}
---

# Airtable Integration

REST API for bases, tables, records, and views.

**Auth**: Bearer token via `AIRTABLE_ACCESS_TOKEN` (OAuth via Nango).
**Base URL**: `https://api.airtable.com/v0`

```bash
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" "https://api.airtable.com/v0/<endpoint>"
```

## Bases

```bash
# List all bases
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/meta/bases"

# Get base schema (tables, fields)
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/meta/bases/{baseId}/tables"
```

## Records

```bash
# List records from a table
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}?maxRecords=20"

# List with specific fields
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}?fields%5B%5D=Name&fields%5B%5D=Status&fields%5B%5D=Email"

# Filter records (formula)
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}?filterByFormula=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"{Status} = 'Active'\"))")"

# Sort records
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}?sort%5B0%5D%5Bfield%5D=Created&sort%5B0%5D%5Bdirection%5D=desc&maxRecords=20"

# Use a view
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}?view=Grid+view"

# Get single record
curl -s -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}/{recordId}"

# Create record(s)
curl -s -X POST -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}" \
  -d '{"records":[{"fields":{"Name":"Alice Smith","Email":"alice@example.com","Status":"Active"}}]}'

# Create multiple records (max 10 per request)
curl -s -X POST -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}" \
  -d '{"records":[{"fields":{"Name":"Alice"}},{"fields":{"Name":"Bob"}},{"fields":{"Name":"Charlie"}}]}'

# Update record(s) (PATCH = partial update)
curl -s -X PATCH -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}" \
  -d '{"records":[{"id":"recABC123","fields":{"Status":"Completed"}}]}'

# Replace record (PUT = full replace, clears unset fields)
curl -s -X PUT -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}" \
  -d '{"records":[{"id":"recABC123","fields":{"Name":"Alice Smith","Status":"Done"}}]}'

# Delete record(s)
curl -s -X DELETE -H "Authorization: Bearer $AIRTABLE_ACCESS_TOKEN" \
  "https://api.airtable.com/v0/{baseId}/{tableIdOrName}?records%5B%5D=recABC123&records%5B%5D=recDEF456"
```

## Formula filter examples

| Formula | Meaning |
|---|---|
| `{Status} = 'Active'` | Exact match |
| `{Status} != 'Done'` | Not equal |
| `{Amount} > 1000` | Numeric comparison |
| `FIND('alice', LOWER({Email}))` | Contains (case-insensitive) |
| `IS_AFTER({Due Date}, TODAY())` | Date after today |
| `IS_BEFORE({Due Date}, DATEADD(TODAY(), 7, 'days'))` | Due within 7 days |
| `AND({Status}='Active', {Priority}='High')` | Multiple conditions |
| `OR({Status}='Active', {Status}='Pending')` | Either condition |
| `{Assignee} = BLANK()` | Empty field |
| `NOT({Completed})` | Checkbox is false |

## Tips

- **Always get the base schema first** (`/meta/bases/{baseId}/tables`) to see table names, field names, and field types.
- **Table reference**: Use table name (URL-encoded) or table ID (`tblXXX`). IDs are more reliable.
- **Record IDs** start with `rec` (e.g., `recABC123`).
- **Base IDs** start with `app` (e.g., `appXYZ789`).
- **Max 10 records per create/update/delete** request. Loop for larger batches.
- **Pagination**: Responses with more data include `offset` — pass as query param for next page.
- **Rate limit**: 5 requests per second per base. Back off on 429.
- **PATCH vs PUT**: PATCH updates only specified fields. PUT replaces entire record (unset fields become empty).
- **`filterByFormula`** must be URL-encoded — use `python3 -c "import urllib.parse; ..."` for complex formulas.
- **Field names are case-sensitive** and may contain spaces — always match exactly.

---

*Based on [claude-office-skills/airtable-automation](https://skills.sh/claude-office-skills/skills/airtable-automation), [composiohq/airtable-automation](https://skills.sh/composiohq/awesome-claude-skills/airtable-automation), and [Airtable Web API Reference](https://airtable.com/developers/web/api).*
