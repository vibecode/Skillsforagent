---
name: vibecode-integration-jotform
description: >
  Jotform API for accessing forms, submissions, and survey responses.
  Consult this skill:
  1. When the user asks to list or view their Jotform forms
  2. When the user needs to retrieve or filter form submissions
  3. When the user wants to create forms or manage form questions
  4. When the user mentions Jotform, forms, or survey submissions
metadata: {"openclaw": {"emoji": "📋", "requires": {"env": ["JOTFORM_API_KEY"]}}}
---

# Jotform Integration

REST API for forms, submissions, questions, and reports.

**Auth**: API key via query parameter (NOT Bearer auth).
**Base URL**: `https://api.jotform.com`

```bash
# All requests pass the API key as a query parameter
curl -s "https://api.jotform.com/<endpoint>?apiKey=$JOTFORM_API_KEY"
```

## User info

```bash
# Get account info
curl -s "https://api.jotform.com/user?apiKey=$JOTFORM_API_KEY"

# Get usage stats
curl -s "https://api.jotform.com/user/usage?apiKey=$JOTFORM_API_KEY"
```

## Forms

```bash
# List all forms
curl -s "https://api.jotform.com/user/forms?apiKey=$JOTFORM_API_KEY&limit=20"

# List with filter
curl -s "https://api.jotform.com/user/forms?apiKey=$JOTFORM_API_KEY&filter=%7B%22status%22%3A%22ENABLED%22%7D"

# Get form details
curl -s "https://api.jotform.com/form/{formId}?apiKey=$JOTFORM_API_KEY"

# Get form questions (field definitions)
curl -s "https://api.jotform.com/form/{formId}/questions?apiKey=$JOTFORM_API_KEY"

# Get form properties
curl -s "https://api.jotform.com/form/{formId}/properties?apiKey=$JOTFORM_API_KEY"

# Create form
curl -s -X POST "https://api.jotform.com/user/forms?apiKey=$JOTFORM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"questions":[{"type":"control_fullname","text":"Full Name","order":"1","name":"fullName","required":"Yes"},{"type":"control_email","text":"Email","order":"2","name":"email","required":"Yes"}],"properties":{"title":"Contact Form"}}'

# Delete form
curl -s -X DELETE "https://api.jotform.com/form/{formId}?apiKey=$JOTFORM_API_KEY"
```

## Submissions

```bash
# List form submissions
curl -s "https://api.jotform.com/form/{formId}/submissions?apiKey=$JOTFORM_API_KEY&limit=20"

# List with date filter
curl -s "https://api.jotform.com/form/{formId}/submissions?apiKey=$JOTFORM_API_KEY&filter=%7B%22created_at%3Agt%22%3A%222026-03-20%22%7D"

# List with sorting
curl -s "https://api.jotform.com/form/{formId}/submissions?apiKey=$JOTFORM_API_KEY&orderby=created_at&direction=DESC&limit=20"

# Get single submission
curl -s "https://api.jotform.com/submission/{submissionId}?apiKey=$JOTFORM_API_KEY"

# Get all user submissions (across all forms)
curl -s "https://api.jotform.com/user/submissions?apiKey=$JOTFORM_API_KEY&limit=20"

# Delete submission
curl -s -X DELETE "https://api.jotform.com/submission/{submissionId}?apiKey=$JOTFORM_API_KEY"
```

## Reports

```bash
# List form reports
curl -s "https://api.jotform.com/form/{formId}/reports?apiKey=$JOTFORM_API_KEY"
```

## Folders

```bash
# List folders
curl -s "https://api.jotform.com/user/folders?apiKey=$JOTFORM_API_KEY"

# Get folder contents
curl -s "https://api.jotform.com/folder/{folderId}?apiKey=$JOTFORM_API_KEY"
```

## Filter syntax

Filters are JSON objects passed as URL-encoded `filter` query param:

| Filter | JSON | Meaning |
|---|---|---|
| Status | `{"status":"ENABLED"}` | Active forms only |
| Date after | `{"created_at:gt":"2026-03-20"}` | After date |
| Date before | `{"created_at:lt":"2026-03-25"}` | Before date |
| New submissions | `{"new":"1"}` | Unread only |
| Answer contains | `{"3":"alice"}` | Question ID 3 contains "alice" |

URL-encode the JSON: `python3 -c "import urllib.parse; print(urllib.parse.quote('{\"status\":\"ENABLED\"}'))"`

## Tips

- **Auth is query param** (`?apiKey=...`), NOT Bearer header. This is Jotform-specific.
- **Form IDs** are numeric strings (e.g., `242584670123456`).
- **Submission answers** are keyed by question ID (numeric), not field name. Get questions first to map IDs to labels.
- **Pagination**: Use `limit` (max 1000) and `offset` params.
- **Rate limit**: 1000 requests per day (free plan), higher on paid plans.
- **Filter JSON must be URL-encoded** in the query string.
- **Question types**: `control_fullname`, `control_email`, `control_phone`, `control_textbox`, `control_textarea`, `control_dropdown`, `control_radio`, `control_checkbox`, `control_datetime`, `control_fileupload`.

---

*Based on [vm0-ai/vm0-skills/jotform](https://skills.sh/vm0-ai/vm0-skills/jotform) and [Jotform API Reference](https://api.jotform.com/docs/).*
