---
name: vibecode-integration-google
display_name: Google Workspace
provider_skill: true
integration_dependencies:
  - google
description: >
  Google Workspace integration via the Chorus-managed gws CLI. Consult this skill
  for Gmail, Drive, Calendar, Docs, Sheets, Slides, Forms, Tasks, and People.
metadata: {"openclaw": {"emoji": "📧", "requires": {"bins": ["gws"]}}}
---

# Google Workspace Integration

Use the preinstalled `gws` CLI for authenticated access to the user's Google Workspace.

## Chorus manages authentication

Chorus installs and pins `gws`, supplies its credential file, and refreshes OAuth tokens.

- Do **not** run `gws auth setup`, `gws auth login`, or install/upgrade `gws`.
- Do **not** rebuild credential files, inspect `CHORUS_CONNECTION_*` variables, or ask the user for Google secrets.
- Do **not** claim that a service is disconnected based only on a failed command. First validate the command with `gws schema` and retry with the current syntax.
- If a correctly formed command reports missing authorization or scopes, run `masterclaw connections ensure --provider google` and give the returned connection action to the user.

## Required workflow

The pinned CLI uses space-separated resources and JSON flags. Older examples with dotted resources or flags such as `--userId`, `--documentId`, and `--requests` are invalid.

1. Confirm the installed version with `gws --version` when diagnosing a failure.
2. Discover helpers and resources with `gws <service> --help`.
3. Before an unfamiliar API call, inspect its exact contract with `gws schema <service>.<resource>.<method>`.
4. Pass URL/query parameters in one JSON object with `--params`.
5. Pass request bodies in one JSON object with `--json`.
6. When parsing JSON output, keep stderr separate: use `gws ... | jq ...`, never `gws ... 2>&1 | jq ...`. Status messages such as the keyring backend are written to stderr and are not JSON.
7. Read-only calls may run immediately. Confirm with the user before sending email, creating or editing data, sharing files, or deleting anything. Prefer `--dry-run` when a mutating command supports it.
8. Never reveal email bodies, contact details, file contents, calendar details, credentials, or tokens unless the user asked for that specific data.

General form:

```bash
gws <service> <resource> [sub-resource] <method> --params '{"parameter":"value"}' --json '{"body":"value"}'
```

## Gmail

```bash
# Search messages
gws gmail users messages list --params '{"userId":"me","q":"newer_than:1d","maxResults":10}'

# Read a message
gws gmail users messages get --params '{"userId":"me","id":"MSG_ID","format":"full"}'

# List labels
gws gmail users labels list --params '{"userId":"me"}'
```

Gmail helpers are available for common workflows. Inspect each helper before use:

```bash
gws gmail +send --help
gws gmail +triage --help
gws gmail +read --help
gws gmail +reply --help
gws gmail +forward --help
```

Gmail search supports operators such as `from:`, `to:`, `subject:`, `is:unread`, `newer_than:`, `has:attachment`, `label:`, and `in:sent`.

## Google Drive

```bash
# List recent files
gws drive files list --params '{"pageSize":10,"orderBy":"modifiedTime desc","fields":"files(id,name,mimeType,modifiedTime)"}'

# Search by name
gws drive files list --params '{"q":"name contains '\''report'\''","pageSize":10,"fields":"files(id,name,mimeType,modifiedTime)"}'

# Get file metadata
gws drive files get --params '{"fileId":"FILE_ID","fields":"id,name,mimeType,modifiedTime"}'
```

For uploads, inspect the maintained helper instead of constructing multipart requests manually:

```bash
gws drive +upload --help
```

## Google Sheets

```bash
# Get spreadsheet metadata
gws sheets spreadsheets get --params '{"spreadsheetId":"SHEET_ID","fields":"sheets.properties"}'

# Read a range
gws sheets spreadsheets values get --params '{"spreadsheetId":"SHEET_ID","range":"Sheet1!A1:D10"}'

# Update a range after user confirmation
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"SHEET_ID","range":"Sheet1!A1","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["Name","Age"],["Alice",30]]}'
```

Maintained helpers:

```bash
gws sheets +read --help
gws sheets +append --help
```

## Google Calendar

```bash
# List calendars
gws calendar calendarList list

# List upcoming events
gws calendar events list --params '{"calendarId":"primary","timeMin":"TIME_MIN_RFC3339","maxResults":10,"singleEvents":true,"orderBy":"startTime"}'

# Create an event after user confirmation
gws calendar events insert \
  --params '{"calendarId":"primary"}' \
  --json '{"summary":"Team standup","start":{"dateTime":"START_RFC3339"},"end":{"dateTime":"END_RFC3339"}}'
```

For agenda and event creation workflows, inspect the maintained helpers:

```bash
gws calendar +agenda --help
gws calendar +insert --help
```

Calendar timestamps use RFC 3339. All-day events use `date` instead of `dateTime`.

## Google Docs

```bash
# Get a document
gws docs documents get --params '{"documentId":"DOC_ID"}'

# Create a document after user confirmation
gws docs documents create --json '{"title":"My Document"}'

# Insert text after user confirmation
gws docs documents batchUpdate \
  --params '{"documentId":"DOC_ID"}' \
  --json '{"requests":[{"insertText":{"location":{"index":1},"text":"Hello World\n"}}]}'
```

For common writing workflows, inspect `gws docs +write --help`.

## Google Slides

```bash
# Get a presentation
gws slides presentations get --params '{"presentationId":"PRESENTATION_ID"}'

# Create a presentation after user confirmation
gws slides presentations create --json '{"title":"My Presentation"}'

# Add a slide after user confirmation
gws slides presentations batchUpdate \
  --params '{"presentationId":"PRESENTATION_ID"}' \
  --json '{"requests":[{"createSlide":{"slideLayoutReference":{"predefinedLayout":"TITLE_AND_BODY"}}}]}'
```

## Google Forms

```bash
# Get a form
gws forms forms get --params '{"formId":"FORM_ID"}'

# List responses
gws forms forms responses list --params '{"formId":"FORM_ID"}'

# Create a form after user confirmation
gws forms forms create --json '{"info":{"title":"Survey","documentTitle":"My Survey"}}'
```

## Google Tasks

```bash
# List task lists
gws tasks tasklists list

# List tasks
gws tasks tasks list --params '{"tasklist":"TASKLIST_ID"}'

# Create a task after user confirmation
gws tasks tasks insert --params '{"tasklist":"TASKLIST_ID"}' --json '{"title":"New task","notes":"Description"}'

# Complete a task after user confirmation
gws tasks tasks patch \
  --params '{"tasklist":"TASKLIST_ID","task":"TASK_ID"}' \
  --json '{"status":"completed"}'
```

## Google People (Contacts)

```bash
# List contacts
gws people people connections list \
  --params '{"resourceName":"people/me","personFields":"names,emailAddresses,phoneNumbers","pageSize":100}'

# Search contacts
gws people people searchContacts \
  --params '{"query":"alice","readMask":"names,emailAddresses"}'
```

## Troubleshooting

- A usage or unknown-argument error usually means the command came from an older CLI example. Run `gws schema ...` and rebuild it using `--params` and `--json`.
- A `403` can mean the connected account lacks that specific OAuth scope or the Google Workspace administrator has blocked the API. Do not assume all Google access is disconnected.
- A `404` usually means an incorrect resource ID or a resource the connected account cannot access.
- A `429` or `5xx` is generally transient. Retry with bounded exponential backoff; do not reconnect Google as the first response.
- Document, spreadsheet, presentation, form, file, event, task, and message IDs come from their resource URLs or prior list/search results.

---

Based on the pinned [`googleworkspace/cli` v0.22.5](https://github.com/googleworkspace/cli/tree/v0.22.5) and its [generated skill library](https://github.com/googleworkspace/cli/tree/v0.22.5/skills).
