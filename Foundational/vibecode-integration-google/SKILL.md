---
name: vibecode-integration-google
display_name: Google Workspace
provider_skill: true
integration_dependencies:
  - google
description: >
  Google Workspace integration via the gws or gog CLI. Consult this skill:
  1. When the user asks to read, send, or manage Gmail messages
  2. When the user asks to create, edit, or organize Google Drive files
  3. When the user asks to manage Google Calendar events or check their schedule
  4. When the user asks to work with Google Docs, Sheets, Slides, or Forms
  5. When the user needs to search contacts or use any Google Workspace service
  6. When the user mentions email, calendar, spreadsheet, document, or presentation without specifying a provider
metadata: {"openclaw": {"emoji": "📧", "requires": {"env": ["OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64"]}}}
---

# Google Workspace Integration

Authenticated access to the user's Google Workspace: Gmail, Drive, Docs, Sheets, Slides, Calendar, Forms, Tasks, and People.

## Environment variables

| Var | Purpose |
|---|---|
| `OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64` | Base64-encoded JSON with OAuth client credentials, refresh token, email, scopes |
| `OPENCLAW_CONNECTION_GOG_ACCOUNT` | Email address of the connected Google account |
| `GOG_KEYRING_PASSWORD` | Keyring password for gog CLI (set automatically) |

## Setup (run once per session)

The credentials JSON contains `installed.client_id`, `installed.client_secret`, `refresh_token`, `email`, and `scopes`. Transform for whichever CLI is available:

### Option A: gws CLI (preferred)

```bash
# Decode and transform credentials to authorized_user format for gws
echo "$OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d | \
  jq '{type:"authorized_user", client_id:.installed.client_id, client_secret:.installed.client_secret, refresh_token:.refresh_token}' \
  > /tmp/gws-creds.json
export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/tmp/gws-creds.json
export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file

# Install if not present
command -v gws &>/dev/null || npm install -g @googleworkspace/cli

# Verify
gws gmail users.getProfile --userId me
```

### Option B: gog CLI (fallback)

```bash
gog auth keyring file
echo "$OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d > /tmp/gog-setup.json
jq '{"installed": .installed}' /tmp/gog-setup.json | gog auth credentials set -
jq '{email: .email, client: "default", scopes: .scopes, refresh_token: .refresh_token}' /tmp/gog-setup.json | gog auth tokens import -
rm /tmp/gog-setup.json
gog auth list
```

For gog commands, append `--account $OPENCLAW_CONNECTION_GOG_ACCOUNT` when multiple accounts exist.

## Gmail

```bash
# Search messages (Gmail search syntax)
gws gmail users.messages.list --userId me --q "newer_than:1d" --maxResults 10

# Read a message (plaintext)
gws gmail users.messages.get --userId me --id MSG_ID --format full

# Search by sender
gws gmail users.messages.list --userId me --q "from:alice@example.com newer_than:7d"

# List unread
gws gmail users.messages.list --userId me --q "is:unread" --maxResults 20

# List labels
gws gmail users.labels.list --userId me
```

**Helpers** (if gws gmail helper skills are installed):
```bash
gws gmail +send --to "alice@example.com" --subject "Hello" --body "Message body"
gws gmail +triage                         # Summarize unread inbox
gws gmail +read MSG_ID                    # Pretty-print a message
gws gmail +reply MSG_ID --body "Thanks!"
gws gmail +forward MSG_ID --to "bob@example.com"
```

## Google Drive

```bash
# List files in root
gws drive files.list --q "'root' in parents" --fields "files(id,name,mimeType,modifiedTime)" --orderBy "modifiedTime desc"

# Search files by name
gws drive files.list --q "name contains 'report'" --fields "files(id,name,mimeType,modifiedTime)"

# Search by type
gws drive files.list --q "mimeType='application/vnd.google-apps.spreadsheet'" --fields "files(id,name)"

# Download a file
gws drive files.get --fileId FILE_ID --alt media > output.pdf

# Upload a file
gws drive files.create --uploadType multipart --metadata '{"name":"report.pdf"}' --media report.pdf

# Upload to specific folder
gws drive files.create --uploadType multipart --metadata '{"name":"data.csv","parents":["FOLDER_ID"]}' --media data.csv

# Create a folder
gws drive files.create --metadata '{"name":"My Folder","mimeType":"application/vnd.google-apps.folder"}'

# Delete a file
gws drive files.delete --fileId FILE_ID
```

## Google Sheets

```bash
# Get spreadsheet metadata
gws sheets spreadsheets.get --spreadsheetId SHEET_ID --fields "sheets.properties"

# Read a range
gws sheets spreadsheets.values.get --spreadsheetId SHEET_ID --range "Sheet1!A1:D10"

# Read entire sheet
gws sheets spreadsheets.values.get --spreadsheetId SHEET_ID --range "Sheet1"

# Write to a range
gws sheets spreadsheets.values.update --spreadsheetId SHEET_ID --range "Sheet1!A1" \
  --valueInputOption USER_ENTERED --values '[["Name","Age"],["Alice","30"],["Bob","25"]]'

# Append rows
gws sheets spreadsheets.values.append --spreadsheetId SHEET_ID --range "Sheet1" \
  --valueInputOption USER_ENTERED --values '[["New","Row","Data"]]'

# Create new spreadsheet
gws sheets spreadsheets.create --title "My Spreadsheet"

# Clear a range
gws sheets spreadsheets.values.clear --spreadsheetId SHEET_ID --range "Sheet1!A1:D10"
```

## Google Calendar

```bash
# List upcoming events
gws calendar events.list --calendarId primary \
  --timeMin "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --maxResults 10 --singleEvents true --orderBy startTime

# List events in date range
gws calendar events.list --calendarId primary \
  --timeMin "2026-03-25T00:00:00Z" --timeMax "2026-03-26T00:00:00Z" \
  --singleEvents true --orderBy startTime

# Create an event
gws calendar events.insert --calendarId primary \
  --summary "Team standup" \
  --start '{"dateTime":"2026-03-25T10:00:00","timeZone":"America/New_York"}' \
  --end '{"dateTime":"2026-03-25T10:30:00","timeZone":"America/New_York"}' \
  --attendees '[{"email":"alice@example.com"}]'

# Create all-day event
gws calendar events.insert --calendarId primary \
  --summary "Company offsite" \
  --start '{"date":"2026-04-01"}' --end '{"date":"2026-04-03"}'

# Delete event
gws calendar events.delete --calendarId primary --eventId EVENT_ID

# List calendars
gws calendar calendarList.list
```

## Google Docs

```bash
# Get document content
gws docs documents.get --documentId DOC_ID

# Create a document
gws docs documents.create --title "My Document"

# Insert text
gws docs documents.batchUpdate --documentId DOC_ID \
  --requests '[{"insertText":{"location":{"index":1},"text":"Hello World\n"}}]'

# Replace text
gws docs documents.batchUpdate --documentId DOC_ID \
  --requests '[{"replaceAllText":{"containsText":{"text":"old text","matchCase":true},"replaceText":"new text"}}]'
```

## Google Slides

```bash
# Get presentation
gws slides presentations.get --presentationId PRES_ID

# Create presentation
gws slides presentations.create --title "My Presentation"

# Get specific slide
gws slides presentations.pages.get --presentationId PRES_ID --pageObjectId SLIDE_ID

# Add a slide
gws slides presentations.batchUpdate --presentationId PRES_ID \
  --requests '[{"createSlide":{"slideLayoutReference":{"predefinedLayout":"TITLE_AND_BODY"}}}]'

# Insert text into a shape
gws slides presentations.batchUpdate --presentationId PRES_ID \
  --requests '[{"insertText":{"objectId":"SHAPE_ID","text":"Slide content"}}]'
```

## Google Forms

```bash
# Get form
gws forms forms.get --formId FORM_ID

# List form responses
gws forms forms.responses.list --formId FORM_ID

# Get specific response
gws forms forms.responses.get --formId FORM_ID --responseId RESPONSE_ID

# Create form
gws forms forms.create --info '{"title":"Survey","documentTitle":"My Survey"}'
```

## Google Tasks

```bash
# List task lists
gws tasks tasklists.list

# List tasks in a list
gws tasks tasks.list --tasklist TASKLIST_ID

# Create task
gws tasks tasks.insert --tasklist TASKLIST_ID --title "New task" --notes "Description"

# Complete task
gws tasks tasks.patch --tasklist TASKLIST_ID --task TASK_ID --status completed
```

## Google People (Contacts)

```bash
# List contacts
gws people people.connections.list --resourceName "people/me" \
  --personFields "names,emailAddresses,phoneNumbers" --pageSize 100

# Search contacts
gws people people.searchContacts --query "alice" --readMask "names,emailAddresses"
```

## Tips

- **Always use `--userId me`** for Gmail (refers to the authenticated user).
- **File/doc IDs are in the URL**: `docs.google.com/document/d/DOC_ID/edit` → use `DOC_ID`.
- **Date formats**: RFC 3339 for Calendar (`2026-03-25T10:00:00Z`), all-day events use date only (`2026-03-25`).
- **Discover commands**: `gws <service> --help` lists all available methods.
- **The user may not say "Google"** — "check my email" = Gmail, "what's on my schedule" = Calendar, "open my spreadsheet" = Sheets.
- **Re-run setup each session** — credentials don't persist across container restarts.
- **Gmail search syntax**: `from:`, `to:`, `subject:`, `is:unread`, `newer_than:`, `older_than:`, `has:attachment`, `label:`, `in:sent`.

---

*Based on [googleworkspace/cli](https://github.com/googleworkspace/cli) and its [skill library](https://github.com/googleworkspace/cli/tree/main/skills).*
