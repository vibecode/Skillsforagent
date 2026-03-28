---
name: vibecode-integration-zoominfo
display_name: ZoomInfo
description: >
  ZoomInfo API for company and contact intelligence, enrichment, and sales prospecting.
  Consult this skill:
  1. When the user asks to look up company or contact information
  2. When the user needs to enrich CRM data with firmographic or technographic details
  3. When the user wants to find leads matching specific criteria
  4. When the user mentions ZoomInfo, prospecting, or lead enrichment
metadata: {"openclaw": {"emoji": "🔎", "requires": {"env": ["ZOOMINFO_ACCESS_TOKEN"]}}}
---

# ZoomInfo Integration

Company and contact intelligence API for sales prospecting, enrichment, and intent data.

**Auth**: Bearer token via `ZOOMINFO_ACCESS_TOKEN`.
**Base URL**: `https://api.zoominfo.com`

```bash
curl -s https://api.zoominfo.com/<endpoint> \
  -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

## Company search

```bash
# Search companies by name
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/search/company" \
  -d '{"companyName":"Acme","maxResults":10,"outputFields":["id","name","website","revenue","employeeCount","industry","city","state","country"]}'

# Search by domain
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/search/company" \
  -d '{"companyWebsite":"acme.com","outputFields":["id","name","website","revenue","employeeCount","industry"]}'

# Filter by industry and size
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/search/company" \
  -d '{"industry":["Software","Technology"],"employeeCountMin":50,"employeeCountMax":500,"maxResults":20,"outputFields":["id","name","website","revenue","employeeCount","industry"]}'
```

## Contact search

```bash
# Search contacts by company
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/search/contact" \
  -d '{"companyId":"COMPANY_ID","maxResults":20,"outputFields":["id","firstName","lastName","email","phone","jobTitle","companyName"]}'

# Search by job title and location
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/search/contact" \
  -d '{"jobTitle":["VP Engineering","CTO","Director of Engineering"],"country":"US","maxResults":20,"outputFields":["id","firstName","lastName","email","jobTitle","companyName"]}'

# Search by name
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/search/contact" \
  -d '{"firstName":"Alice","lastName":"Smith","outputFields":["id","firstName","lastName","email","phone","jobTitle","companyName"]}'
```

## Enrich

```bash
# Enrich company by domain
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/enrich/company" \
  -d '{"matchCompanyInput":[{"companyWebsite":"acme.com"}],"outputFields":["id","name","website","revenue","employeeCount","industry","techStack","fundingInfo"]}'

# Enrich contact by email
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/enrich/contact" \
  -d '{"matchPersonInput":[{"emailAddress":"alice@acme.com"}],"outputFields":["id","firstName","lastName","email","phone","jobTitle","companyName","linkedinUrl"]}'
```

## Intent data

```bash
# Get intent signals for a company
curl -s -X POST -H "Authorization: Bearer $ZOOMINFO_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://api.zoominfo.com/intent/company" \
  -d '{"companyId":["COMPANY_ID"],"topicIds":["TOPIC_ID"]}'
```

## Tips

- **All search/enrich endpoints are POST** — pass filters in the request body.
- **`outputFields`** controls which fields are returned — always specify to reduce response size.
- **`maxResults`** defaults vary — always set explicitly.
- **Rate limits**: Vary by plan. Back off on 429.
- **Company IDs** are needed for contact searches — search company first, then contacts.
- **Credit consumption**: Each API call may consume ZoomInfo credits depending on plan.

---

*Based on [composiohq/zoominfo-automation](https://skills.sh/composiohq/awesome-claude-skills/zoominfo-automation) and [ZoomInfo API Reference](https://api-docs.zoominfo.com).*
