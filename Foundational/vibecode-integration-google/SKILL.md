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

The pinned CLI uses space-separated resources and JSON flags for API calls. Older API-call examples with dotted resources or flags such as `--userId`, `--documentId`, and `--requests` are invalid. Schema lookup is the exception: its method identifier uses dotted notation.

1. Confirm the installed version with `gws --version` when diagnosing a failure.
2. Discover helpers and resources with `gws <service> --help`.
3. Before an unfamiliar API call, inspect its exact contract with `gws schema <service>.<resource>.<method>` (dotted notation for schema lookup only).
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

**Reply-all: `+reply-all` computes the CC list itself and gets it wrong, so you must supply
CC yourself every time.** The helper matches the CC header name case-sensitively. Real senders
on Outlook/Exchange write it as `CC:` (all caps), so the helper's own recipient computation
silently drops every one of those people — and it does this even after you've read the correct
recipients, because passing `--body` alone lets the helper decide CC. Reading the recipients is
not enough; knowing who should be on the mail does nothing unless you put them on the outgoing
`--cc`. Treat these two calls as one inseparable step — never run the second without the first:

```bash
# 1. Get the real To and Cc from the API (case-insensitive, unlike the helper)
gws gmail users messages get --params '{"userId":"me","id":"MSG_ID","format":"metadata","metadataHeaders":["From","To","Cc","Reply-To"]}'

# 2. Reply, and pass EVERY original Cc address (and any extra To) explicitly. Do not omit
#    --cc and trust the helper — that is exactly the path that drops recipients.
gws gmail +reply-all --message-id MSG_ID --body "..." \
  --cc "noah@example.com,ava@example.com"   # the addresses you read in step 1
```

`+forward` has the same blind spot — set recipients explicitly there too. Then confirm the
sent message's `To`/`Cc` with another `messages get` (not `+read`, which shares the bug and
will cheerfully show a wrong result as correct). If the `Cc` you intended isn't on the sent
copy, you dropped it — resend with `--cc`.

## Google Drive

```bash
# List recent files
gws drive files list --params '{"pageSize":10,"orderBy":"modifiedTime desc","fields":"files(id,name,mimeType,modifiedTime)"}'

# Search by name
gws drive files list --params '{"q":"name contains '\''report'\''","pageSize":10,"fields":"files(id,name,mimeType,modifiedTime)"}'

# Get file metadata
gws drive files get --params '{"fileId":"FILE_ID","fields":"id,name,mimeType,modifiedTime"}'

# Download a stored binary file. Always use --output: sending alt=media to
# stdout returns an API error instead of the file bytes.
gws drive files get --params '{"fileId":"FILE_ID","alt":"media"}' --output ./download.bin

# Export a Google-native Doc, Sheet, or Slide
gws drive files export --params '{"fileId":"FILE_ID","mimeType":"application/pdf"}' --output ./export.pdf

# Delete a file — run from a writable directory (cd ~ first). The command can
# exit non-zero from an unwritable cwd even when the delete actually succeeded,
# so re-check rather than trusting the exit code.
gws drive files delete --params '{"fileId":"FILE_ID"}'
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

# Update a range. Choose valueInputOption deliberately (see below).
gws sheets spreadsheets values update \
  --params '{"spreadsheetId":"SHEET_ID","range":"Sheet1!A1","valueInputOption":"RAW"}' \
  --json '{"values":[["Name","Age"],["Alice",30]]}'
```

Preserving values like `0074` takes care at two layers, and missing either one silently
corrupts the data:
1. **Quote every value as a JSON string.** `{"values":[["0074"]]}` keeps the leading zero;
   `{"values":[[0074]]}` is a JSON number and becomes `74` before the request even leaves —
   nothing the API does can recover it. Codes, ZIPs, and phone numbers are the usual victims.
2. **Use `valueInputOption: RAW`.** `USER_ENTERED` mimics a person typing, so it strips leading
   zeros (`0074` → `74`), runs a leading `=` as a formula, and applies locale parsing. `RAW`
   stores exactly what you send. Reach for `USER_ENTERED` only when you genuinely want a
   formula evaluated or a date parsed.

After writing IDs or codes, read the range back and confirm the leading zeros survived.

Maintained helpers:

```bash
gws sheets +read --help
# Pass rows as JSON, not the plain --values flag (which splits on commas and
# corrupts any value that contains one):
gws sheets +append --spreadsheet SHEET_ID --json-values '[["Alice","New York, NY"]]'
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

Formatting is where naive Docs edits go wrong, so pick the path by the kind of edit. The
trap to avoid: `gws docs +write` and a bare `insertText` add **plain text**, so markdown like
`# Heading` or `**bold**` lands as literal characters. Real formatting comes either from Drive
converting an HTML source, or from explicit style requests in `batchUpdate`.

**Create a formatted doc** — write the content as HTML locally, then let Drive convert it. The
conversion produces genuine headings, bold, and lists, and it is far more reliable than
hand-building style requests:
```bash
cd ~ && cat > doc.html <<'EOF'
<h1>Title</h1><h2>Section</h2><p>Body with <b>bold</b>.</p><ul><li>a</li><li>b</li></ul>
EOF
gws drive files create --upload doc.html --upload-content-type text/html \
  --json '{"name":"My Doc","mimeType":"application/vnd.google-apps.document"}'
```
(`--upload` needs a path inside the current directory, hence `cd ~` first.)

**Targeted edit** (rename a term, fix a value, swap a link) — use find/replace; it preserves
all surrounding styling and never disturbs layout:
```bash
gws docs documents batchUpdate --params '{"documentId":"DOC_ID"}' \
  --json '{"requests":[{"replaceAllText":{"containsText":{"text":"old","matchCase":true},"replaceText":"new"}}]}'
```

**Add or restructure a section** — choose by whether the doc has live comments:
- *Safe to rewrite (no collaborators mid-review):* read the current content
  (`gws docs documents get ...`), regenerate the whole doc as HTML with the change in place,
  and push it back to the **same file** so the ID and sharing survive:
  `gws drive files update --params '{"fileId":"DOC_ID"}' --upload doc.html --upload-content-type text/html`.
  This replaces all content, which orphans anchored comments — so don't use it on a doc people
  are actively commenting on.
- *Must preserve comments (surgical insert):* `insertText` at the target index, then in the
  **same batchUpdate** reset the inserted range's style. Inserted text inherits the paragraph
  and character style at the insertion index, so a paragraph placed after a heading renders
  oversized/bold until you fix it — follow the insert with `updateParagraphStyle`
  (`namedStyleType`: `NORMAL_TEXT` for body, or the right `HEADING_n` for a new header) and
  `updateTextStyle` clearing `bold`/`fontSize` over the range you inserted. Match the doc's own
  convention: check first whether its section headers are real `HEADING_n` paragraphs or just
  bold `NORMAL_TEXT`, and reproduce whichever it uses.

Verify any structural edit before reporting it done — export to PDF and look, or re-read the
structure and confirm the heading/body styles are what you intended:
```bash
gws drive files export --params '{"fileId":"DOC_ID","mimeType":"application/pdf"}' --output /tmp/check.pdf
```

## Google Slides

Editing an existing deck is straightforward with `batchUpdate`: `createSlide`, `deleteObject`,
and `insertText`/`replaceAllText` cover add, remove, and edit. Adding a slide with text is the
fiddly one: each entry in `placeholderIdMappings` pairs a `layoutPlaceholder` (the slot type on
the chosen layout) with a **new `objectId` you invent** (at least 5 chars), and `insertText`
then targets that new id — never the layout's own id. Do all of it in one `batchUpdate`:

```json
{"requests":[
  {"createSlide":{"objectId":"agenda01","slideLayoutReference":{"predefinedLayout":"TITLE_AND_BODY"},
    "placeholderIdMappings":[
      {"layoutPlaceholder":{"type":"TITLE"},"objectId":"agenda01title"},
      {"layoutPlaceholder":{"type":"BODY"},"objectId":"agenda01body"}]}},
  {"insertText":{"objectId":"agenda01title","text":"Agenda"}},
  {"insertText":{"objectId":"agenda01body","text":"First point\nSecond point"}}
]}
```

To **change wording already on a slide** (e.g. a year or a title), use `replaceAllText`, which
swaps the text in place across the deck. Do not instead add a new text box with the new
wording — that leaves the old text sitting on the slide, so the "change" reads as a duplicate.
After the edit, re-read with `presentations get` and confirm the old text is actually gone.
```bash
# Inspect (also how you verify slide count/text after an edit)
gws slides presentations get --params '{"presentationId":"PRESENTATION_ID"}'
# Create an empty presentation
gws slides presentations create --json '{"title":"My Presentation"}'
```

Building a **polished multi-slide deck from scratch** is the one workflow `gws` makes tedious —
there is no HTML-import equivalent, so you must lay out every slide via `batchUpdate`. If a
second CLI named `gog` is present (also Chorus-managed, same account), `gog slides
create-from-markdown --content-file deck.md` (one `# Heading` per slide, `---` between slides)
does this in a single step; otherwise build it with `batchUpdate` as above. Use whichever is
available — this is a convenience for greenfield decks only, not something to depend on.

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
