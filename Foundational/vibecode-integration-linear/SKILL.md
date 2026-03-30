---
name: vibecode-integration-linear
display_name: Linear
provider_skill: true
integration_dependencies:
  - linear
description: >
  Linear GraphQL API for managing issues, projects, teams, and workflows.
  Consult this skill:
  1. When the user asks to create, update, or search Linear issues
  2. When the user needs to check project status or list team tasks
  3. When the user wants to manage cycles, labels, or workflow states
  4. When the user mentions issues, tickets, sprints, or Linear
metadata: {"openclaw": {"emoji": "🔷", "requires": {"env": ["LINEAR_API_KEY"]}}}
---

# Linear Integration

GraphQL API for issues, projects, teams, cycles, and workflows.

**Auth**: Bearer token via `LINEAR_API_KEY`.
**Endpoint**: `https://api.linear.app/graphql` (POST only).

```bash
# All requests use this pattern
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"..."}'
```

## Current user

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ viewer { id name email } }"}'
```

## Teams

```bash
# List teams
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ teams { nodes { id name key } } }"}'

# Get team workflow states (needed for setting issue status)
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ team(id: \"TEAM_ID\") { states { nodes { id name type } } } }"}'

# Get team labels
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ team(id: \"TEAM_ID\") { labels { nodes { id name } } } }"}'
```

## Issues

```bash
# List issues assigned to me
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ viewer { assignedIssues(first: 20, orderBy: updatedAt) { nodes { id identifier title state { name } priority priorityLabel assignee { name } } } } }"}'

# Get issue by identifier (e.g. ENG-123)
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ issue(id: \"ISSUE_UUID\") { id identifier title description state { name } priority priorityLabel assignee { name } labels { nodes { name } } project { name } createdAt updatedAt } }"}'

# Search issues with filter
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ issues(filter: { team: { key: { eq: \"ENG\" } }, state: { type: { nin: [\"completed\", \"canceled\"] } } }, first: 50) { nodes { id identifier title state { name } priority assignee { name } } } }"}'

# Create issue
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { issueCreate(input: { teamId: \"TEAM_ID\", title: \"Fix login bug\", description: \"Users cannot log in with SSO\", priority: 2, labelIds: [\"LABEL_ID\"] }) { success issue { id identifier url } } }"}'

# Update issue (change state)
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { issueUpdate(id: \"ISSUE_ID\", input: { stateId: \"STATE_ID\" }) { success issue { id identifier state { name } } } }"}'

# Update issue (assign + set priority)
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { issueUpdate(id: \"ISSUE_ID\", input: { assigneeId: \"USER_ID\", priority: 1 }) { success } }"}'
```

## Comments

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { commentCreate(input: { issueId: \"ISSUE_ID\", body: \"Looks good, merging now.\" }) { success comment { id } } }"}'
```

## Projects

```bash
# List projects
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ projects(first: 20) { nodes { id name state progress { scope completed } teams { nodes { name } } } } }"}'
```

## Cycles

```bash
# List active cycles
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ cycles(filter: { isActive: { eq: true } }, first: 10) { nodes { id name number startsAt endsAt progress { scope completed } team { name } } } }"}'
```

## Priority scale

| Value | Label |
|---|---|
| 0 | No priority |
| 1 | Urgent |
| 2 | High |
| 3 | Medium |
| 4 | Low |

## State types

| Type | Meaning |
|---|---|
| `backlog` | Not started, low visibility |
| `unstarted` | Ready to start |
| `started` | In progress |
| `completed` | Done |
| `canceled` | Won't do |

## Tips

- **Always list teams first** to get `teamId` — required for creating issues.
- **Get workflow states** before updating status — state IDs vary per team.
- **Issue identifiers** (like `ENG-123`) are human-readable but the API uses UUIDs. Use the `identifier` field for display, `id` for mutations.
- **Pagination**: Use `first: N` and `after: cursor` with `pageInfo { hasNextPage endCursor }`.
- **Filter syntax**: `{ field: { operator: value } }` — operators include `eq`, `neq`, `in`, `nin`, `contains`, `startsWith`.
- **GraphQL introspection** is enabled — run `{ __schema { types { name } } }` to explore.

---

*Extracted from [vm0-ai/vm0-skills/linear](https://skills.sh/vm0-ai/vm0-skills/linear), [wrsmith108/linear-claude-skill](https://skills.sh/wrsmith108/linear-claude-skill/linear), and [Linear API Reference](https://developers.linear.app/docs/graphql/working-with-the-graphql-api).*
