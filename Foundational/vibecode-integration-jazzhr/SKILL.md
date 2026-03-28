---
name: vibecode-integration-jazzhr
description: >
  JazzHR API for managing job postings, applicants, and hiring workflows.
  Consult this skill:
  1. When the user asks to view or manage job postings
  2. When the user needs to check applicant status or hiring pipeline
  3. When the user wants to manage candidates or interviews
  4. When the user mentions JazzHR, recruiting, hiring, or applicants
metadata: {"openclaw": {"emoji": "🎯", "requires": {"env": ["JAZZHR_API_KEY"]}}}
---

# JazzHR Integration

REST API for jobs, applicants, activities, and hiring workflows.

**Auth**: API key via query parameter.
**Base URL**: `https://api.resumatorapi.com/v1`

```bash
JHR="https://api.resumatorapi.com/v1"

# JazzHR uses apikey query parameter
curl -s "$JHR/<endpoint>?apikey=$JAZZHR_API_KEY"
```

## Jobs

```bash
# List all jobs
curl -s "$JHR/jobs?apikey=$JAZZHR_API_KEY"

# Get job details
curl -s "$JHR/jobs/{jobId}?apikey=$JAZZHR_API_KEY"

# List open jobs
curl -s "$JHR/jobs/status/open?apikey=$JAZZHR_API_KEY"
```

## Applicants

```bash
# List all applicants
curl -s "$JHR/applicants?apikey=$JAZZHR_API_KEY"

# Get applicant details
curl -s "$JHR/applicants/{applicantId}?apikey=$JAZZHR_API_KEY"

# List applicants for a specific job
curl -s "$JHR/applicants/job_id/{jobId}?apikey=$JAZZHR_API_KEY"

# Create applicant
curl -s -X POST "$JHR/applicants?apikey=$JAZZHR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Alice","last_name":"Smith","email":"alice@example.com","job_id":"{jobId}"}'
```

## Activities & notes

```bash
# List activities for an applicant
curl -s "$JHR/activities/applicant_id/{applicantId}?apikey=$JAZZHR_API_KEY"

# Add note to applicant
curl -s -X POST "$JHR/notes?apikey=$JAZZHR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"applicant_id":"{applicantId}","user_id":"{userId}","contents":"Great phone screen, moving to next round"}'
```

## Categories & users

```bash
# List hiring workflow categories (stages)
curl -s "$JHR/categories?apikey=$JAZZHR_API_KEY"

# List users (hiring team)
curl -s "$JHR/users?apikey=$JAZZHR_API_KEY"
```

## Tips

- **API key via query param** — not header. `?apikey=$JAZZHR_API_KEY`.
- **Pagination**: Results may be paginated — check response for page info.
- **Rate limit**: 60 requests per minute.
- **Applicant statuses** map to categories/workflow stages configured in JazzHR.

---

*Based on [JazzHR API Reference](https://apidoc.jazzhrapis.com) and [JazzHR API Overview](https://help.jazzhr.com/s/article/API-Overview).*
