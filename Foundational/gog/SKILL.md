---
name: gog
description: Google Workspace CLI for Gmail, Calendar, Drive, Docs, Sheets, Slides, Forms, Contacts, and Tasks. Use this skill whenever the user asks about email, calendar events, Google Drive files, spreadsheets, documents, or any Google Workspace operation.
metadata: {"openclaw": { "requires": {"bins": ["gog"], "env": ["OPENCLAW_CONNECTION_GOG_ACCOUNT"]}}}
---

# gog — Google Workspace CLI

Use `gog` for all Google Workspace operations. Auth is automatic when Google is connected via the dashboard — no manual setup needed.

If scopes are missing, ask the user to grant the scopes in the `Connections` tab.

Always pass `--account $OPENCLAW_CONNECTION_GOG_ACCOUNT` on every command.

## Gmail

```bash
gog gmail search '<query>' --max 10 --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail thread get <threadId> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail send --to <email> --subject "Subject" --body "Body text" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail labels list --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail labels modify <threadId> --add STARRED --remove INBOX --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail drafts list --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail drafts create --subject "Subject" --body "Body" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog gmail drafts send <draftId> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

Common search queries: `newer_than:1d`, `from:user@example.com`, `is:unread`, `has:attachment`, `subject:"keyword"`.

## Calendar

```bash
gog calendar events primary --today --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog calendar events primary --week --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog calendar events primary --days 3 --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog calendar create primary --summary "Meeting" --from <YYYY-MM-DDThh:mm:ssZ> --to <YYYY-MM-DDThh:mm:ssZ> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog calendar update primary <eventId> --summary "Updated" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog calendar respond primary <eventId> --status accepted --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog calendar freebusy --calendars "primary" --from <time> --to <time> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Drive

```bash
gog drive ls --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog drive search "<query>" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog drive upload ./file --parent <folderId> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog drive download <fileId> --out ./file --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog drive share <fileId> --to user --email user@example.com --role reader --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog drive mkdir "Folder Name" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Sheets

```bash
gog sheets get <spreadsheetId> 'Sheet1!A1:B10' --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog sheets update <spreadsheetId> 'A1' 'value' --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog sheets append <spreadsheetId> 'Sheet1!A:C' 'row|data' --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Docs

```bash
gog docs cat <docId> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog docs create "Title" --file ./content.md --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog docs export <docId> --format pdf --out ./doc.pdf --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Slides

```bash
gog slides create "Presentation Title" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog slides create-from-markdown "Deck" --content-file ./slides.md --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog slides export <presentationId> --format pdf --out ./deck.pdf --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Forms

```bash
gog forms get <formId> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog forms create --title "Survey" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog forms add-question <formId> --type RADIO --title "Question?" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Tasks

```bash
gog tasks lists --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog tasks list <tasklistId> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog tasks add <tasklistId> --title "New task" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog tasks done <tasklistId> <taskId> --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Contacts

```bash
gog contacts list --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog contacts search "Name" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
gog contacts create --given "John" --family "Doe" --email "john@example.com" --account $OPENCLAW_CONNECTION_GOG_ACCOUNT
```

## Tips

- Use `--json` for structured output: `gog --json drive ls | jq '.files[]'`
- Use `--max <n>` to limit results
- The user may not mention gog or Google explicitly — infer that anything related to email, calendar, files, docs, spreadsheets, or slides should use gog.
