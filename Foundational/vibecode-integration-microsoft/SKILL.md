---
name: vibecode-integration-microsoft
display_name: Microsoft 365
provider_skill: true
integration_dependencies:
  - microsoft
description: >
  Microsoft 365 integration via Microsoft Graph API. Consult this skill:
  1. When the user asks to read, send, or manage Outlook emails
  2. When the user asks to schedule or manage calendar events
  3. When the user wants to send or read Microsoft Teams messages
  4. When the user needs to manage OneDrive or SharePoint files
  5. When the user asks to work with Excel workbooks, OneNote, Planner, or Power BI
  6. When the user mentions Outlook, Teams, OneDrive, SharePoint, or any Microsoft 365 service
metadata: {"openclaw": {"emoji": "📎", "requires": {"env": ["OPENCLAW_CONNECTION_MICROSOFT_CREDENTIALS_BASE64"]}}}
---

# Microsoft 365 Integration

All Microsoft 365 services through one unified API: `https://graph.microsoft.com/v1.0/`.

## Environment variables

| Var | Purpose |
|---|---|
| `OPENCLAW_CONNECTION_MICROSOFT_CREDENTIALS_BASE64` | Base64 JSON with client_id, client_secret, token_url, refresh_token, scopes |
| `OPENCLAW_CONNECTION_MICROSOFT_ACCOUNT` | Email of the connected Microsoft account |

## Setup (run once per session)

Access tokens expire in ~1 hour. Create a refresh helper and get a token:

```bash
# Decode credentials
echo "$OPENCLAW_CONNECTION_MICROSOFT_CREDENTIALS_BASE64" | base64 -d > /tmp/ms-creds.json

# Create token refresh script
cat > /tmp/ms-refresh.sh << 'SCRIPT'
#!/bin/bash
C=/tmp/ms-creds.json
curl -s -X POST "$(jq -r .token_url $C)" \
  -d "client_id=$(jq -r .client_id $C)" \
  -d "client_secret=$(jq -r .client_secret $C)" \
  -d "refresh_token=$(jq -r .refresh_token $C)" \
  -d "grant_type=refresh_token" \
  -d "scope=$(jq -r '.scopes | join(" ")' $C)" \
  | jq -r .access_token
SCRIPT
chmod +x /tmp/ms-refresh.sh

# Get token
export MS_TOKEN=$(/tmp/ms-refresh.sh)

# Verify
curl -s -H "Authorization: Bearer $MS_TOKEN" https://graph.microsoft.com/v1.0/me | jq '{name:.displayName,email:.mail}'
```

If you get a 401 on any call, re-run: `export MS_TOKEN=$(/tmp/ms-refresh.sh)`

**All curl commands below assume `$MS_TOKEN` is set.**

## Outlook Mail

```bash
# List recent messages
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/messages?\$top=10&\$orderby=receivedDateTime+desc&\$select=subject,from,receivedDateTime,isRead"

# Read a message
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/messages/{id}"

# Search messages
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/messages?\$search=\"subject:quarterly report\""

# Send email
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/sendMail" \
  -d '{"message":{"subject":"Hello","body":{"contentType":"Text","content":"Message body"},"toRecipients":[{"emailAddress":{"address":"alice@example.com"}}]}}'

# Reply to a message
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/messages/{id}/reply" \
  -d '{"comment":"Thanks for the update!"}'

# List mail folders
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/mailFolders"

# List unread messages
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/messages?\$filter=isRead+eq+false&\$top=20"
```

## Outlook Calendar

```bash
# List upcoming events
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/calendarView?\$orderby=start/dateTime&startDateTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)&endDateTime=$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+7d +%Y-%m-%dT%H:%M:%SZ)"

# Create event
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/events" \
  -d '{"subject":"Team standup","start":{"dateTime":"2026-03-25T10:00:00","timeZone":"America/New_York"},"end":{"dateTime":"2026-03-25T10:30:00","timeZone":"America/New_York"},"attendees":[{"emailAddress":{"address":"alice@example.com"},"type":"required"}]}'

# Delete event
curl -s -X DELETE -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/events/{id}"

# Find meeting times
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/findMeetingTimes" \
  -d '{"attendees":[{"emailAddress":{"address":"alice@example.com"}}],"timeConstraint":{"timeslots":[{"start":{"dateTime":"2026-03-25T09:00:00","timeZone":"America/New_York"},"end":{"dateTime":"2026-03-25T17:00:00","timeZone":"America/New_York"}}]},"meetingDuration":"PT30M"}'
```

## Microsoft Teams

```bash
# List joined teams
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/joinedTeams"

# List channels in a team
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/teams/{team-id}/channels"

# List channel messages
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/teams/{team-id}/channels/{channel-id}/messages?\$top=20"

# Send channel message
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/teams/{team-id}/channels/{channel-id}/messages" \
  -d '{"body":{"content":"Hello team!"}}'

# List chats
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/chats?\$top=20"

# Send chat message
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/chats/{chat-id}/messages" \
  -d '{"body":{"content":"Hey!"}}'

# Create online meeting
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/onlineMeetings" \
  -d '{"subject":"Quick sync","startDateTime":"2026-03-25T14:00:00Z","endDateTime":"2026-03-25T14:30:00Z"}'
```

## OneDrive

```bash
# List root files
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/drive/root/children?\$select=name,size,lastModifiedDateTime,folder"

# List folder contents
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/drive/root:/{folder-path}:/children"

# Search files
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/drive/root/search(q='report')"

# Download file
curl -s -L -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/drive/items/{id}/content" -o output.pdf

# Upload small file (<4MB)
curl -s -X PUT -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/octet-stream" \
  "https://graph.microsoft.com/v1.0/me/drive/root:/{path/filename}:/content" \
  --data-binary @localfile.pdf

# Create folder
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/drive/root/children" \
  -d '{"name":"New Folder","folder":{}}'

# Create sharing link
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/drive/items/{id}/createLink" \
  -d '{"type":"view","scope":"organization"}'
```

## SharePoint

```bash
# Search sites
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/sites?search=marketing"

# Get site by hostname/path
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/sites/{hostname}:/{site-path}"

# List site document libraries
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/sites/{site-id}/drives"

# List files in document library
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/sites/{site-id}/drive/root/children"

# List SharePoint lists
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/sites/{site-id}/lists"

# List items in a list
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/sites/{site-id}/lists/{list-id}/items?\$expand=fields"

# Create list item
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/sites/{site-id}/lists/{list-id}/items" \
  -d '{"fields":{"Title":"New item","Status":"Active"}}'
```

## Microsoft Excel (Online)

Excel workbooks are accessed via their OneDrive/SharePoint file ID:

```bash
# List worksheets
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/drive/items/{file-id}/workbook/worksheets"

# Read a range
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/drive/items/{file-id}/workbook/worksheets/{sheet-name}/range(address='A1:D10')"

# Update a range
curl -s -X PATCH -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/drive/items/{file-id}/workbook/worksheets/{sheet-name}/range(address='A1:B2')" \
  -d '{"values":[["Name","Age"],["Alice","30"]]}'

# Add rows to a table
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/drive/items/{file-id}/workbook/tables/{table-id}/rows" \
  -d '{"values":[["New","Row","Data"]]}'

# Get used range (auto-detect data bounds)
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/drive/items/{file-id}/workbook/worksheets/{sheet-name}/usedRange"
```

## OneNote

```bash
# List notebooks
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/onenote/notebooks"

# List sections in notebook
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/onenote/notebooks/{notebook-id}/sections"

# List pages in section
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/onenote/sections/{section-id}/pages"

# Get page content (HTML)
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/onenote/pages/{page-id}/content"

# Create page (HTML body)
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: text/html" \
  "https://graph.microsoft.com/v1.0/me/onenote/sections/{section-id}/pages" \
  -d '<!DOCTYPE html><html><head><title>My Note</title></head><body><p>Note content</p></body></html>'

# Create notebook
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/me/onenote/notebooks" \
  -d '{"displayName":"Work Notes"}'
```

## Microsoft Planner

```bash
# List my tasks
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/planner/tasks"

# List plans for a group
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/groups/{group-id}/planner/plans"

# List tasks in a plan
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/planner/plans/{plan-id}/tasks"

# List buckets in a plan
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/planner/plans/{plan-id}/buckets"

# Create task
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/planner/tasks" \
  -d '{"planId":"{plan-id}","bucketId":"{bucket-id}","title":"New task"}'

# Update task (requires If-Match header with etag)
curl -s -X PATCH -H "Authorization: Bearer $MS_TOKEN" -H "Content-Type: application/json" \
  -H "If-Match: {etag}" \
  "https://graph.microsoft.com/v1.0/planner/tasks/{task-id}" \
  -d '{"percentComplete":100}'
```

## Power BI

Power BI uses its own API at `api.powerbi.com`, not the Graph API:

```bash
# List workspaces
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://api.powerbi.com/v1.0/myorg/groups"

# List reports in workspace
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://api.powerbi.com/v1.0/myorg/groups/{workspace-id}/reports"

# List dashboards
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://api.powerbi.com/v1.0/myorg/groups/{workspace-id}/dashboards"

# List datasets
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://api.powerbi.com/v1.0/myorg/groups/{workspace-id}/datasets"

# Trigger dataset refresh
curl -s -X POST -H "Authorization: Bearer $MS_TOKEN" \
  "https://api.powerbi.com/v1.0/myorg/groups/{workspace-id}/datasets/{dataset-id}/refreshes"
```

Note: Power BI requires additional scopes (`Dataset.Read.All`, `Report.Read.All`, `Dashboard.Read.All`) which may not be in the default grant.

## Entra ID (Users & Directory)

```bash
# Get current user
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me?\$select=displayName,mail,jobTitle,department"

# List users
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/users?\$top=25&\$select=displayName,mail,jobTitle"

# Search users
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/users?\$filter=startsWith(displayName,'Alice')"

# Get user's manager
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/manager"

# Get direct reports
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/me/directReports"

# List groups
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/groups?\$top=25&\$select=displayName,description,groupTypes"

# List group members
curl -s -H "Authorization: Bearer $MS_TOKEN" \
  "https://graph.microsoft.com/v1.0/groups/{group-id}/members?\$select=displayName,mail"
```

## Tips

- **Token expires in ~1 hour** — re-run `export MS_TOKEN=$(/tmp/ms-refresh.sh)` on 401 errors.
- **OData query params**: `$top` (page size), `$select` (fields), `$filter` (conditions), `$orderby` (sort), `$search` (text search), `$expand` (include related). Escape `$` in bash: `\$top`.
- **Pagination**: Responses include `@odata.nextLink` — follow it for next page.
- **Planner updates need `If-Match`** — GET the task first, extract `@odata.etag`, pass as `If-Match` header on PATCH.
- **Excel uses file IDs** — find the workbook via OneDrive (`/me/drive/root/search(q='budget.xlsx')`) then use its `id` for Excel operations.
- **The user may not say "Microsoft"** — "check my email" could mean Outlook, "share the file" could mean OneDrive, "post in the channel" means Teams.

---

*Based on [Microsoft Graph REST API v1.0](https://learn.microsoft.com/en-us/graph/api/overview), [Microsoft Graph Auth docs](https://learn.microsoft.com/en-us/graph/auth-v2-user), and [claude-office-skills](https://skills.sh/claude-office-skills/skills) (workflow patterns).*
