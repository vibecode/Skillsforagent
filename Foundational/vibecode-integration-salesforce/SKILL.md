---
name: vibecode-integration-salesforce
display_name: Salesforce
description: >
  Salesforce REST API for managing CRM objects, SOQL queries, and data operations.
  Consult this skill:
  1. When the user asks to query, create, or update Salesforce records
  2. When the user needs to run SOQL queries or search with SOSL
  3. When the user wants to manage contacts, accounts, leads, or opportunities
  4. When the user mentions Salesforce, CRM objects, or SOQL
metadata: {"openclaw": {"emoji": "☁️", "requires": {"env": ["SALESFORCE_ACCESS_TOKEN"]}}}
---

# Salesforce Integration

REST API for CRM objects, SOQL queries, SOSL search, and data operations.

**Auth**: Bearer token via `SALESFORCE_ACCESS_TOKEN`.
**Base URL**: `$SALESFORCE_INSTANCE_URL/services/data/v60.0`

```bash
SF_BASE="$SALESFORCE_INSTANCE_URL/services/data/v60.0"

curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" "$SF_BASE/<endpoint>"
```

## SOQL queries

```bash
# Query contacts
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/query?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 20\"))")"

# Query accounts by industry
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/query?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"SELECT Id, Name, Industry, AnnualRevenue FROM Account WHERE Industry = 'Technology' ORDER BY AnnualRevenue DESC LIMIT 20\"))")"

# Query open opportunities
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/query?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"SELECT Id, Name, Amount, StageName, CloseDate, Account.Name FROM Opportunity WHERE IsClosed = false ORDER BY CloseDate ASC\"))")"

# Query with date filter
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/query?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"SELECT Id, Subject, Status FROM Case WHERE CreatedDate = THIS_WEEK\"))")"
```

## Object CRUD

```bash
# Get record by ID
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/sobjects/Contact/{id}"

# Create record
curl -s -X POST -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SF_BASE/sobjects/Contact/" \
  -d '{"FirstName":"Alice","LastName":"Smith","Email":"alice@example.com","Title":"VP Engineering"}'

# Update record
curl -s -X PATCH -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SF_BASE/sobjects/Contact/{id}" \
  -d '{"Phone":"+1234567890","Title":"CTO"}'

# Delete record
curl -s -X DELETE -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/sobjects/Contact/{id}"

# Upsert by external ID
curl -s -X PATCH -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SF_BASE/sobjects/Contact/External_Id__c/ext-123" \
  -d '{"FirstName":"Alice","LastName":"Smith","Email":"alice@example.com"}'
```

## SOSL search

```bash
# Full-text search across objects
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/search?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"FIND {Acme} IN ALL FIELDS RETURNING Account(Id,Name), Contact(Id,FirstName,LastName,Email)\"))")"
```

## Describe (schema discovery)

```bash
# List all available objects
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/sobjects/" | jq '.sobjects[] | select(.queryable==true) | .name' | head -30

# Describe object fields
curl -s -H "Authorization: Bearer $SALESFORCE_ACCESS_TOKEN" \
  "$SF_BASE/sobjects/Contact/describe" | jq '.fields[] | {name, type, label}' | head -50
```

## Common objects

| Object | ID prefix | Description |
|---|---|---|
| Account | `001` | Companies/organizations |
| Contact | `003` | People associated with accounts |
| Lead | `00Q` | Unqualified prospects |
| Opportunity | `006` | Deals/sales in pipeline |
| Case | `500` | Support tickets |
| Task | `00T` | Activities/to-dos |
| Event | `00U` | Calendar events |

## Tips

- **URL-encode SOQL** — use `python3 -c "import urllib.parse; print(urllib.parse.quote(...))"` for queries with spaces and special chars.
- **`SALESFORCE_INSTANCE_URL`** is required — it's the base (e.g., `https://myorg.my.salesforce.com`). Never hardcode it.
- **Monitor `Sforce-Limit-Info` header** — shows remaining API calls (e.g., `api-usage=50/15000`).
- **401 INVALID_SESSION_ID** means the token expired — tell the user to reconnect.
- **SOQL date literals**: `TODAY`, `THIS_WEEK`, `THIS_MONTH`, `LAST_N_DAYS:30`, `NEXT_N_DAYS:7`.
- **Pagination**: Large SOQL results return `nextRecordsUrl` — follow it for the next page.
- **Describe before querying** unfamiliar objects to discover field names.

---

*Extracted from [vm0-ai/vm0-skills/salesforce](https://skills.sh/vm0-ai/vm0-skills/salesforce), [jeffallan/salesforce-developer](https://skills.sh/jeffallan/claude-skills/salesforce-developer), and [Salesforce REST API Reference](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/).*
