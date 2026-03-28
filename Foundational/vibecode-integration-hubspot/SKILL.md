---
name: vibecode-integration-hubspot
display_name: HubSpot
description: >
  HubSpot CRM API for managing contacts, companies, deals, tickets, and engagements.
  Consult this skill:
  1. When the user asks to look up, create, or update contacts, companies, or deals
  2. When the user needs to manage tickets or support pipelines
  3. When the user wants to log calls, emails, meetings, or notes
  4. When the user asks to search CRM records or check deal pipelines
  5. When the user mentions HubSpot, CRM, leads, or sales pipeline
metadata: {"openclaw": {"emoji": "🧲", "requires": {"env": ["HUBSPOT_ACCESS_TOKEN"]}}}
---

# HubSpot Integration

CRM API v3 for contacts, companies, deals, tickets, engagements, pipelines, and search.

**Auth**: Bearer token via `HUBSPOT_ACCESS_TOKEN`.
**Base URL**: `https://api.hubapi.com`

```bash
curl -s https://api.hubapi.com/<endpoint> \
  -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

**All CRM objects** follow the same CRUD pattern at `/crm/v3/objects/{objectType}`.

## Contacts

```bash
# List contacts
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/objects/contacts?limit=20&properties=firstname,lastname,email,phone,company"

# Get contact by ID
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/objects/contacts/{id}?properties=firstname,lastname,email,phone"

# Create contact
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/contacts" \
  -d '{"properties":{"firstname":"Alice","lastname":"Smith","email":"alice@example.com","company":"Acme Inc"}}'

# Update contact
curl -s -X PATCH -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/contacts/{id}" \
  -d '{"properties":{"phone":"+1234567890","lifecyclestage":"customer"}}'

# Delete contact
curl -s -X DELETE -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/objects/contacts/{id}"
```

## Companies

```bash
# List companies
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/objects/companies?limit=20&properties=name,domain,industry,numberofemployees"

# Create company
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/companies" \
  -d '{"properties":{"name":"Acme Inc","domain":"acme.com","industry":"Technology","numberofemployees":"50"}}'
```

## Deals

```bash
# List deals
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/objects/deals?limit=20&properties=dealname,amount,dealstage,pipeline,closedate"

# Create deal
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/deals" \
  -d '{"properties":{"dealname":"Enterprise License","amount":"50000","dealstage":"appointmentscheduled","pipeline":"default","closedate":"2026-06-30"}}'

# Update deal stage
curl -s -X PATCH -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/deals/{id}" \
  -d '{"properties":{"dealstage":"closedwon"}}'

# Get deal pipelines (to find valid stage IDs)
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/pipelines/deals"
```

## Tickets

```bash
# List tickets
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/objects/tickets?limit=20&properties=subject,content,hs_pipeline_stage,hs_ticket_priority"

# Create ticket
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/tickets" \
  -d '{"properties":{"subject":"Login issue","content":"User cannot login with SSO","hs_pipeline":"0","hs_pipeline_stage":"1","hs_ticket_priority":"HIGH"}}'

# Get ticket pipelines
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/pipelines/tickets"
```

## Engagements (calls, emails, meetings, notes)

```bash
# Log a call
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/calls" \
  -d '{"properties":{"hs_call_title":"Discovery call","hs_call_body":"Discussed pricing and timeline","hs_call_duration":"1800000","hs_call_direction":"OUTBOUND","hs_timestamp":"2026-03-25T10:00:00Z"}}'

# Log an email
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/emails" \
  -d '{"properties":{"hs_email_subject":"Follow up","hs_email_text":"Thanks for the call...","hs_email_direction":"EMAIL","hs_timestamp":"2026-03-25T11:00:00Z"}}'

# Log a meeting
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/meetings" \
  -d '{"properties":{"hs_meeting_title":"Product demo","hs_meeting_body":"Demo of new features","hs_meeting_start_time":"2026-03-26T14:00:00Z","hs_meeting_end_time":"2026-03-26T15:00:00Z"}}'

# Create a note
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/notes" \
  -d '{"properties":{"hs_note_body":"Spoke with Alice, interested in enterprise plan","hs_timestamp":"2026-03-25T12:00:00Z"}}'
```

## Associations (link records together)

```bash
# Associate contact with company (type 1)
curl -s -X PUT -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v4/objects/contacts/{contactId}/associations/companies/{companyId}" \
  -H "Content-Type: application/json" \
  -d '[{"associationCategory":"HUBSPOT_DEFINED","associationTypeId":1}]'

# Associate deal with contact (type 3)
curl -s -X PUT -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v4/objects/deals/{dealId}/associations/contacts/{contactId}" \
  -H "Content-Type: application/json" \
  -d '[{"associationCategory":"HUBSPOT_DEFINED","associationTypeId":3}]'

# Associate note with contact
curl -s -X PUT -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v4/objects/notes/{noteId}/associations/contacts/{contactId}" \
  -H "Content-Type: application/json" \
  -d '[{"associationCategory":"HUBSPOT_DEFINED","associationTypeId":202}]'
```

Common association type IDs: `1` (contact→company), `3` (deal→contact), `5` (deal→company), `202` (note→contact).

## Search

```bash
# Search contacts by email
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/contacts/search" \
  -d '{"filterGroups":[{"filters":[{"propertyName":"email","operator":"EQ","value":"alice@example.com"}]}],"properties":["firstname","lastname","email"]}'

# Search deals by stage
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/deals/search" \
  -d '{"filterGroups":[{"filters":[{"propertyName":"dealstage","operator":"EQ","value":"closedwon"}]}],"properties":["dealname","amount","closedate"],"sorts":[{"propertyName":"closedate","direction":"DESCENDING"}],"limit":20}'

# Search companies by domain
curl -s -X POST -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.hubapi.com/crm/v3/objects/companies/search" \
  -d '{"filterGroups":[{"filters":[{"propertyName":"domain","operator":"CONTAINS_TOKEN","value":"acme"}]}],"properties":["name","domain","industry"]}'
```

### Search operators

`EQ`, `NEQ`, `LT`, `LTE`, `GT`, `GTE`, `CONTAINS_TOKEN`, `NOT_CONTAINS_TOKEN`, `HAS_PROPERTY`, `NOT_HAS_PROPERTY`

## Owners

```bash
# List owners (sales reps / team members)
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/crm/v3/owners?limit=100"
```

## Account info

```bash
curl -s -H "Authorization: Bearer $HUBSPOT_ACCESS_TOKEN" \
  "https://api.hubapi.com/account-info/v3/details"
```

## Tips

- **Always specify `properties`** param on GET requests — only requested properties are returned.
- **Search before creating** to avoid duplicates (especially contacts by email, companies by domain).
- **Associations use v4** (`/crm/v4/`) while everything else uses v3.
- **Pipeline stages**: Get pipelines first to find valid `dealstage`/`hs_pipeline_stage` IDs — they're internal names, not display labels.
- **Pagination**: Cursor-based via `paging.next.after` in response. Pass as `after` query param.
- **Rate limit**: 100 requests per 10 seconds for OAuth apps. Back off on 429.
- **Batch operations**: POST to `/crm/v3/objects/{type}/batch/create`, `/batch/update`, `/batch/read` for bulk ops (max 100 records per call).
- **Property names are internal** (e.g., `firstname` not `First Name`) — get available properties via `GET /crm/v3/properties/{objectType}`.

---

*Extracted from [vm0-ai/vm0-skills/hubspot](https://skills.sh/vm0-ai/vm0-skills/hubspot), [composiohq/hubspot-automation](https://skills.sh/composiohq/awesome-claude-skills/hubspot-automation), and [HubSpot API Reference](https://developers.hubspot.com/docs/api/overview).*
