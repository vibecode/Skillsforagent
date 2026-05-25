---
name: vibecode-integration-peopledatalabs
display_name: People Data Labs
provider_skill: true
integration_dependencies:
  - peopledatalabs
description: >
  People Data Labs (PDL) API for enriching and searching people and company
  data — sales prospecting, CRM enrichment, contact lookup, and firmographic
  research. Consult this skill:
  1. When the user asks to enrich a person by email, LinkedIn URL, or name
  2. When the user wants to search for people matching specific criteria
  3. When the user needs to enrich or search companies by domain, name, or attributes
  4. When the user asks for autocomplete suggestions on job titles, locations, or skills
  5. When the user mentions People Data Labs, PDL, person enrichment, or B2B data
metadata: {"openclaw": {"emoji": "🧠", "requires": {"env": ["PEOPLEDATALABS_API_KEY"]}}}
---

# People Data Labs Integration

REST API for person + company enrichment, search, and supporting lookups (autocomplete, IP, cleaner, job postings).

**Auth**: `X-Api-Key` header (preferred) — `?api_key=` query param also works.
**Base URL**: `https://api.peopledatalabs.com`
**Credits**: Every match against billable data consumes credits per the user's plan. Search endpoints charge per matched record returned, not per query. Enrich endpoints charge only on successful matches (`status: 200`).

```bash
# All examples use the header form
curl -s "https://api.peopledatalabs.com/v5/<endpoint>" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY"
```

## Person Enrichment

Lookup one person by any combination of identifiers. Returns the full PDL person record.

```bash
# By LinkedIn profile
curl -s -G "https://api.peopledatalabs.com/v5/person/enrich" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "profile=linkedin.com/in/seanthorne"

# By work email
curl -s -G "https://api.peopledatalabs.com/v5/person/enrich" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "email=alice@acme.com"

# By name + company (lower confidence — use only as fallback)
curl -s -G "https://api.peopledatalabs.com/v5/person/enrich" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "first_name=Alice" \
  --data-urlencode "last_name=Smith" \
  --data-urlencode "company=acme"

# Set minimum match confidence (default returns any match)
curl -s -G "https://api.peopledatalabs.com/v5/person/enrich" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "email=alice@acme.com" \
  --data-urlencode "min_likelihood=6"
```

`status: 200` = match found; `status: 404` = no match (no credit charged).

## Person Search

Find multiple people matching criteria. Body accepts Elasticsearch DSL **or** SQL — pick one.

```bash
# Elasticsearch DSL
curl -s -X POST "https://api.peopledatalabs.com/v5/person/search" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 10,
    "query": {
      "bool": {
        "must": [
          {"term": {"location_country": "united states"}},
          {"term": {"job_title_role": "engineering"}},
          {"term": {"job_title_levels": "vp"}}
        ]
      }
    }
  }'

# SQL form (same query, easier to read)
curl -s -X POST "https://api.peopledatalabs.com/v5/person/search" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 10,
    "sql": "SELECT * FROM person WHERE location_country='\''united states'\'' AND job_title_role='\''engineering'\'' AND job_title_levels='\''vp'\''"
  }'

# Pagination: use scroll_token from previous response
curl -s -X POST "https://api.peopledatalabs.com/v5/person/search" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"size": 10, "scroll_token": "<token-from-prev-response>", "sql": "SELECT * FROM person WHERE location_country='\''united states'\'' AND job_title_role='\''engineering'\''"}'
```

Returns: `{ status, data: [...], scroll_token, total }`. Each record in `data` consumes one credit.

## Person Identify

Match a partial record against PDL's index — returns candidate matches ranked by confidence. Useful when you have ambiguous identifiers (e.g., common name + company) and want to disambiguate before pulling a full record. **Costs 1 credit per call** (same tier as Person Enrichment) — don't run it as a free pre-check.

```bash
curl -s -G "https://api.peopledatalabs.com/v5/person/identify" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "first_name=Alice" \
  --data-urlencode "last_name=Smith" \
  --data-urlencode "company=acme"
```

Returns a list of match candidates with confidence scores — pick the best `id` and pass it to `/person/enrich?pdl_id=...` for the full record.

## Company Enrichment

```bash
# By domain (most reliable)
curl -s -G "https://api.peopledatalabs.com/v5/company/enrich" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "website=acme.com"

# By name (lower confidence — use only when domain unknown)
curl -s -G "https://api.peopledatalabs.com/v5/company/enrich" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "name=Acme Corp"
```

## Company Search

```bash
# Find SaaS companies in a size + location bracket
curl -s -X POST "https://api.peopledatalabs.com/v5/company/search" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 20,
    "sql": "SELECT * FROM company WHERE industry='\''computer software'\'' AND size='\''51-200'\'' AND location.country='\''united states'\''"
  }'
```

## Autocomplete

Resolve user-typed strings to canonical PDL values for use in search queries (job titles, companies, locations, skills, etc).

```bash
# Job titles starting with "soft"
curl -s -G "https://api.peopledatalabs.com/v5/autocomplete" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "field=title" \
  --data-urlencode "text=soft" \
  --data-urlencode "size=10"

# Locations
curl -s -G "https://api.peopledatalabs.com/v5/autocomplete" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "field=location" \
  --data-urlencode "text=san fran"
```

Supported `field` values: `title`, `company`, `location`, `school`, `industry`, `role`, `sub_role`, `skill`, `country`.

## Bulk Person Enrichment

Enrich up to 100 people per request — cheaper than 100 individual calls.

```bash
curl -s -X POST "https://api.peopledatalabs.com/v5/person/bulk" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "requests": [
      {"params": {"profile": "linkedin.com/in/seanthorne"}},
      {"params": {"email": "alice@acme.com"}},
      {"params": {"first_name": "Bob", "last_name": "Jones", "company": "acme"}}
    ]
  }'
```

Returns an array in the same order as `requests`, each with its own `status`.

## IP Enrichment

```bash
# Look up company / location from an IP address
curl -s -G "https://api.peopledatalabs.com/v5/ip" \
  -H "X-Api-Key: $PEOPLEDATALABS_API_KEY" \
  --data-urlencode "ip=72.212.42.169"
```

## Tips & gotchas

- **`X-Api-Key` header is the cleaner auth** — avoid `?api_key=` query param so the key doesn't end up in webserver logs.
- **No-match returns `status: 404`** and no credit is consumed — safe to retry with different identifiers.
- **`min_likelihood` (0–10)** raises the match confidence threshold for enrichment. Default returns any match; production lookups should set 6+ to avoid false positives.
- **Search endpoints use HTTP POST with a JSON body**, even though they're "GET-like" operations. The body uses either `query` (Elasticsearch DSL) or `sql` — never both.
- **Credits are per matched record, not per query** on search. A `size: 100` query that returns 100 results = 100 credits.
- **Use Person Identify only when disambiguating multiple candidate matches** (e.g., common name + company) — it costs 1 credit per call just like enrichment, so don't reflexively call it as a pre-check.
- **Run `autocomplete` before search** when the user passes free-form strings ("VP Eng at SF startups") — search filters need canonical PDL values (`job_title_role: "engineering"`, `job_title_levels: "vp"`).
- **Rate limits depend on plan** — 429 responses include a `Retry-After` header; back off and retry.
