---
name: vibecode-integration-google
description: >
  Google Workspace integration via the gws CLI. Consult this skill:
  1. When the user asks to read, send, or manage Gmail messages
  2. When the user asks to create, edit, or organize Google Drive files
  3. When the user asks to manage Google Calendar events or check their schedule
  4. When the user asks to work with Google Docs, Sheets, or Slides
  5. When the user needs to search contacts, manage Keep notes, or use any Google Workspace service
metadata: {"openclaw": {"requires": {"env": ["OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64"]}}}
---

# Google Workspace Integration

You have authenticated access to the user's Google Workspace account. The `gws` CLI provides typed access to Gmail, Drive, Docs, Sheets, Slides, Calendar, Tasks, People, Chat, Keep, Meet, and Forms.

## Setup (run once per session)

Check if `gws` is installed, then authenticate:

```bash
if command -v gws &>/dev/null; then
  # Write credentials file for gws
  echo "$OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d > /tmp/gws-creds.json
  export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/tmp/gws-creds.json
  export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file
  echo "gws ready"
else
  # Fallback: install gws
  npm install -g @googleworkspace/cli
  echo "$OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d > /tmp/gws-creds.json
  export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/tmp/gws-creds.json
  export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file
  echo "gws installed and ready"
fi
```

If `gog` is installed instead, use the gog setup:

```bash
gog auth keyring file
echo "$OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d > /tmp/gog-setup.json
jq '{"installed": .installed}' /tmp/gog-setup.json | gog auth credentials set -
jq '{email: .email, client: "default", scopes: .scopes, refresh_token: .refresh_token}' /tmp/gog-setup.json | gog auth tokens import -
rm /tmp/gog-setup.json
```

## Environment variables

| Var | Purpose |
|---|---|
| `OPENCLAW_CONNECTION_GOOGLE_APPLICATION_CREDENTIALS_BASE64` | Base64-encoded JSON with OAuth client credentials, refresh token, email, scopes |
| `OPENCLAW_CONNECTION_GOG_ACCOUNT` | Email address of the connected Google account |
| `GOG_KEYRING_PASSWORD` | Keyring password for gog CLI (set automatically) |

## Gmail

```bash
# List recent messages
gws gmail users.messages.list --userId me --maxResults 10

# Read a specific message
gws gmail users.messages.get --userId me --id MESSAGE_ID --format full

# Send an email
gws gmail users.messages.send --userId me --raw BASE64_RFC2822_MESSAGE

# Search messages
gws gmail users.messages.list --userId me --q "from:alice@example.com newer_than:7d"
```

**Helper shortcuts** (if gws helper skills are installed):
```bash
gws gmail +send --to "alice@example.com" --subject "Hello" --body "Message body"
gws gmail +triage                    # Summarize unread inbox
gws gmail +read MESSAGE_ID           # Pretty-print a message
gws gmail +reply MESSAGE_ID --body "Reply text"
```

## Google Drive

```bash
# List files in root
gws drive files.list --q "'root' in parents" --fields "files(id,name,mimeType)"

# Search files
gws drive files.list --q "name contains 'report'" --fields "files(id,name,mimeType,modifiedTime)"

# Download a file
gws drive files.get --fileId FILE_ID --alt media > output.pdf

# Upload a file
gws drive files.create --uploadType multipart --metadata '{"name":"report.pdf"}' --media report.pdf

# Create a folder
gws drive files.create --metadata '{"name":"My Folder","mimeType":"application/vnd.google-apps.folder"}'
```

## Google Sheets

```bash
# Read a range
gws sheets spreadsheets.values.get --spreadsheetId SHEET_ID --range "Sheet1!A1:D10"

# Write to a range
gws sheets spreadsheets.values.update --spreadsheetId SHEET_ID --range "Sheet1!A1" \
  --valueInputOption USER_ENTERED --values '[["Name","Age"],["Alice","30"]]'

# Append rows
gws sheets spreadsheets.values.append --spreadsheetId SHEET_ID --range "Sheet1" \
  --valueInputOption USER_ENTERED --values '[["New","Row"]]'
```

## Google Calendar

```bash
# List upcoming events
gws calendar events.list --calendarId primary --timeMin "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --maxResults 10 --singleEvents true --orderBy startTime

# Create an event
gws calendar events.insert --calendarId primary --summary "Meeting" \
  --start '{"dateTime":"2026-03-25T10:00:00","timeZone":"America/New_York"}' \
  --end '{"dateTime":"2026-03-25T11:00:00","timeZone":"America/New_York"}'
```

## Google Docs

```bash
# Get document content
gws docs documents.get --documentId DOC_ID

# Batch update (insert text)
gws docs documents.batchUpdate --documentId DOC_ID \
  --requests '[{"insertText":{"location":{"index":1},"text":"Hello World"}}]'
```

## Google Tasks

```bash
# List task lists
gws tasks tasklists.list

# List tasks
gws tasks tasks.list --tasklist TASKLIST_ID

# Create a task
gws tasks tasks.insert --tasklist TASKLIST_ID --title "New task" --notes "Description"
```

## Google People (Contacts)

```bash
# List contacts
gws people people.connections.list --resourceName "people/me" \
  --personFields "names,emailAddresses,phoneNumbers"

# Search contacts
gws people people.searchContacts --query "alice" --readMask "names,emailAddresses"
```

## Tips

- **Always use `--userId me`** for Gmail operations (refers to the authenticated user).
- **File IDs are opaque strings** — get them from `files.list` before operating on files.
- **Date formats**: Use RFC 3339 for Calendar (`2026-03-25T10:00:00Z`).
- **Discover commands**: Run `gws <service> --help` to see all available methods.
- **The user may not mention "Google" explicitly** — infer it from context (e.g., "check my email" means Gmail, "what's on my calendar" means Google Calendar).
- **Remember this skill across sessions** — new sessions clear memory. If the user has used Google services before, re-setup auth at the start of each session.
