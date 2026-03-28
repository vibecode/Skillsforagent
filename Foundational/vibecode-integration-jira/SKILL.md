---
name: vibecode-integration-jira
description: >
  Jira REST API for managing issues, projects, boards, sprints, and workflows.
  Consult this skill:
  1. When the user asks to create, update, or search Jira issues
  2. When the user needs to check sprint status, board, or backlog
  3. When the user wants to manage projects, transitions, or comments
  4. When the user mentions Jira, tickets, sprints, or project tracking
metadata: {"openclaw": {"emoji": "📋", "requires": {"env": ["JIRA_ACCESS_TOKEN"]}}}
---

# Jira Integration

REST API v3 for issues, projects, boards, sprints, and workflows.

**Auth**: Bearer token via `JIRA_ACCESS_TOKEN` (API token via Nango Basic auth).
**Base URL**: `${JIRA_SITE_URL}/rest/api/3`

```bash
JIRA="${JIRA_SITE_URL}/rest/api/3"

curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" -H "Accept: application/json" "$JIRA/<endpoint>"
```

## Search (JQL)

```bash
# Search issues with JQL
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/search?jql=$(python3 -c "import urllib.parse; print(urllib.parse.quote('project = PROJ AND status != Done ORDER BY created DESC'))")&maxResults=20"

# My open issues
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/search?jql=$(python3 -c "import urllib.parse; print(urllib.parse.quote('assignee = currentUser() AND status != Done ORDER BY priority DESC'))")&maxResults=20"

# Issues in current sprint
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/search?jql=$(python3 -c "import urllib.parse; print(urllib.parse.quote('sprint in openSprints() AND project = PROJ'))")&maxResults=50"

# Recently updated
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/search?jql=$(python3 -c "import urllib.parse; print(urllib.parse.quote('project = PROJ AND updated >= -7d ORDER BY updated DESC'))")&maxResults=20"

# Bugs only
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/search?jql=$(python3 -c "import urllib.parse; print(urllib.parse.quote('project = PROJ AND issuetype = Bug AND status != Done'))")&maxResults=20"
```

## Issues

```bash
# Get issue
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/issue/PROJ-123"

# Get issue with specific fields
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/issue/PROJ-123?fields=summary,status,assignee,priority,description"

# Create issue
curl -s -X POST -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$JIRA/issue" \
  -d '{"fields":{"project":{"key":"PROJ"},"summary":"Fix login timeout","description":{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"Users experience timeouts on login"}]}]},"issuetype":{"name":"Bug"},"priority":{"name":"High"},"assignee":{"accountId":"ACCOUNT_ID"}}}'

# Update issue
curl -s -X PUT -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$JIRA/issue/PROJ-123" \
  -d '{"fields":{"summary":"Updated title","priority":{"name":"Critical"}}}'

# Transition issue (change status)
# First get available transitions:
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" "$JIRA/issue/PROJ-123/transitions"
# Then transition:
curl -s -X POST -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$JIRA/issue/PROJ-123/transitions" \
  -d '{"transition":{"id":"31"}}'

# Assign issue
curl -s -X PUT -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$JIRA/issue/PROJ-123/assignee" \
  -d '{"accountId":"ACCOUNT_ID"}'

# Add comment
curl -s -X POST -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$JIRA/issue/PROJ-123/comment" \
  -d '{"body":{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"Fixed in PR #45"}]}]}}'

# Delete issue
curl -s -X DELETE -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/issue/PROJ-123"
```

## Projects

```bash
# List projects
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/project?maxResults=50"

# Get project
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/project/PROJ"

# List issue types for project
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/project/PROJ/statuses"
```

## Boards & Sprints (Agile API)

```bash
AGILE="${JIRA_SITE_URL}/rest/agile/1.0"

# List boards
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" "$AGILE/board?maxResults=20"

# Get board
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" "$AGILE/board/{boardId}"

# List sprints for a board
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" "$AGILE/board/{boardId}/sprint?state=active"

# Get sprint issues
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" "$AGILE/sprint/{sprintId}/issue?maxResults=50"

# Get backlog
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" "$AGILE/board/{boardId}/backlog?maxResults=50"
```

## Users

```bash
# Search users
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/user/search?query=alice&maxResults=10"

# Get current user
curl -s -H "Authorization: Bearer $JIRA_ACCESS_TOKEN" \
  "$JIRA/myself"
```

## Common JQL operators

| Operator | Example |
|---|---|
| Equals | `status = "In Progress"` |
| Not equals | `status != Done` |
| Contains text | `summary ~ "login"` |
| In list | `status in ("To Do", "In Progress")` |
| Not in | `status not in (Done, Closed)` |
| Is empty | `assignee is EMPTY` |
| Current user | `assignee = currentUser()` |
| Date relative | `created >= -7d`, `updated >= startOfWeek()` |
| Sprint | `sprint in openSprints()`, `sprint = "Sprint 5"` |
| Order | `ORDER BY priority DESC, created ASC` |

## Tips

- **`JIRA_SITE_URL`** is the full Atlassian URL (e.g., `https://mycompany.atlassian.net`).
- **JQL must be URL-encoded** — use `python3 -c "import urllib.parse; ..."` for queries.
- **Description uses Atlassian Document Format (ADF)** — not plain text. Wrap in `{"type":"doc","version":1,"content":[...]}`.
- **Transitions** (status changes) require getting available transition IDs first, then POSTing the ID.
- **Agile API** is at `/rest/agile/1.0/`, not `/rest/api/3/`.
- **Account IDs** (not usernames) are used for assignee — get from user search.
- **Pagination**: `startAt` + `maxResults` params. Default max is 50.
- **Rate limit**: Varies by Atlassian plan. Back off on 429.

---

*Based on [skillcreatorai/jira-issues](https://skills.sh/skillcreatorai/ai-agent-skills/jira-issues), [davila7/jira](https://skills.sh/davila7/claude-code-templates/jira), and [Jira Cloud REST API v3 Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v3/).*
