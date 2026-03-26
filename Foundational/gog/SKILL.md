---
name: gog
description: Google Workspace CLI for Gmail, Calendar, Drive, Docs, Sheets, Slides, Forms, Contacts, and Tasks. Use this skill whenever the user asks about email, calendar events, Google Drive files, spreadsheets, documents, or any Google Workspace operation.
metadata: {"openclaw": { "requires": {"bins": ["gog"], "env": ["OPENCLAW_CONNECTION_GOG_ACCOUNT"]}}}
---

# gog — Google Workspace CLI

Use `gog` for all Google Workspace operations. Auth is automatic when Google is connected via the dashboard — no manual setup needed.

If scopes are missing, ask the user to grant the scopes in the `Connections` tab.

Use `$OPENCLAW_CONNECTION_GOG_ACCOUNT` as the `--account` flag value.

## Gmail

```bash
gog gmail search '<query>' --max 10 --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail thread get <threadId>
gog gmail send --to <email> --subject "Subject" --body "Body text"
gog gmail labels list
gog gmail labels modify <threadId> --add STARRED --remove INBOX
gog gmail drafts list / create / send <draftId>
```

Common search queries: `newer_than:1d`, `from:user@example.com`, `is:unread`, `has:attachment`, `subject:"keyword"`.

## Calendar

```bash
gog calendar events primary --today --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog calendar events primary --week
gog calendar events primary --days 3
gog calendar create primary --summary "Meeting" --from 2025-01-15T10:00:00Z --to 2025-01-15T11:00:00Z
gog calendar update primary <eventId> --summary "Updated"
gog calendar respond primary <eventId> --status accepted
gog calendar freebusy --calendars "primary" --from <time> --to <time>
```

## Drive

```bash
gog drive ls --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog drive search "<query>"
gog drive upload ./file --parent <folderId>
gog drive download <fileId> --out ./file
gog drive share <fileId> --to user --email user@example.com --role reader
gog drive mkdir "Folder Name"
```

## Sheets

```bash
gog sheets get <spreadsheetId> 'Sheet1!A1:B10'
gog sheets update <spreadsheetId> 'A1' 'value'
gog sheets append <spreadsheetId> 'Sheet1!A:C' 'row|data'
```

## Docs

```bash
gog docs cat <docId>
gog docs create "Title" --file ./content.md
gog docs export <docId> --format pdf --out ./doc.pdf
```

## Slides

```bash
gog slides create "Presentation Title"
gog slides create-from-markdown "Deck" --content-file ./slides.md
gog slides export <presentationId> --format pdf --out ./deck.pdf
```

## Forms

```bash
gog forms get <formId>
gog forms create --title "Survey"
gog forms add-question <formId> --type RADIO --title "Question?"
```

## Tasks

```bash
gog tasks lists
gog tasks list <tasklistId>
gog tasks add <tasklistId> --title "New task"
gog tasks done <tasklistId> <taskId>
```

## Contacts

```bash
gog contacts list
gog contacts search "Name"
gog contacts create --given "John" --family "Doe" --email "john@example.com"
```

## Tips

- Use `--json` for structured output: `gog --json drive ls | jq '.files[]'`
- Use `--max <n>` to limit results
- The user may not mention gog or Google explicitly — infer that anything related to email, calendar, files, docs, spreadsheets, or slides should use gog.
