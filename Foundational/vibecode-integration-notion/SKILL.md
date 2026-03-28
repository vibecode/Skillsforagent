---
name: vibecode-integration-notion
display_name: Notion
description: >
  Notion API for managing pages, databases, blocks, and workspace content.
  Consult this skill:
  1. When the user asks to read, create, or update Notion pages
  2. When the user needs to query, filter, or add entries to Notion databases
  3. When the user asks to search their Notion workspace
  4. When the user wants to append or edit content blocks on a page
  5. When the user mentions notes, docs, wikis, or knowledge base and has Notion connected
metadata: {"openclaw": {"emoji": "📝", "requires": {"env": ["NOTION_API_KEY"]}}}
---

# Notion Integration

REST API for pages, databases, blocks, search, users, and comments.

**Auth**: Bearer token via `NOTION_API_KEY`. Tokens never expire — no refresh needed.

```bash
# All requests use these headers
curl -s https://api.notion.com/v1/<endpoint> \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json"
```

**Important**: Pages and databases must be shared with the integration in Notion before they're accessible via the API.

## Search

```bash
# Search all pages and databases
curl -s -X POST https://api.notion.com/v1/search \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"query":"meeting notes","page_size":10}'

# Search only databases
curl -s -X POST https://api.notion.com/v1/search \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"query":"tasks","filter":{"property":"object","value":"database"}}'

# Search only pages
curl -s -X POST https://api.notion.com/v1/search \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"filter":{"property":"object","value":"page"},"page_size":20}'
```

## Pages

```bash
# Get page properties
curl -s https://api.notion.com/v1/pages/{page_id} \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"

# Get page content (blocks)
curl -s https://api.notion.com/v1/blocks/{page_id}/children?page_size=100 \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"

# Create page in a database
curl -s -X POST https://api.notion.com/v1/pages \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent":{"database_id":"DB_ID"},
    "properties":{
      "Name":{"title":[{"text":{"content":"New page title"}}]},
      "Status":{"select":{"name":"In Progress"}},
      "Tags":{"multi_select":[{"name":"urgent"}]}
    }
  }'

# Create page under another page
curl -s -X POST https://api.notion.com/v1/pages \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent":{"page_id":"PARENT_PAGE_ID"},
    "properties":{"title":{"title":[{"text":{"content":"Child page"}}]}},
    "children":[
      {"object":"block","type":"paragraph","paragraph":{"rich_text":[{"text":{"content":"Page content here."}}]}},
      {"object":"block","type":"heading_2","heading_2":{"rich_text":[{"text":{"content":"Section"}}]}}
    ]
  }'

# Update page properties
curl -s -X PATCH https://api.notion.com/v1/pages/{page_id} \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"properties":{"Status":{"select":{"name":"Done"}}}}'

# Archive page
curl -s -X PATCH https://api.notion.com/v1/pages/{page_id} \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"archived":true}'
```

## Databases

```bash
# Get database schema (see property names and types)
curl -s https://api.notion.com/v1/databases/{db_id} \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"

# Query database (all entries)
curl -s -X POST https://api.notion.com/v1/databases/{db_id}/query \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"page_size":50}'

# Query with filter
curl -s -X POST https://api.notion.com/v1/databases/{db_id}/query \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "filter":{"property":"Status","select":{"equals":"In Progress"}},
    "sorts":[{"property":"Created","direction":"descending"}],
    "page_size":20
  }'

# Compound filter (AND/OR)
curl -s -X POST https://api.notion.com/v1/databases/{db_id}/query \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "filter":{"and":[
      {"property":"Status","select":{"does_not_equal":"Done"}},
      {"property":"Priority","select":{"equals":"High"}}
    ]}
  }'

# Create a database
curl -s -X POST https://api.notion.com/v1/databases \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent":{"page_id":"PARENT_PAGE_ID"},
    "title":[{"text":{"content":"Task Tracker"}}],
    "properties":{
      "Name":{"title":{}},
      "Status":{"select":{"options":[{"name":"Not Started"},{"name":"In Progress"},{"name":"Done"}]}},
      "Priority":{"select":{"options":[{"name":"High"},{"name":"Medium"},{"name":"Low"}]}},
      "Due Date":{"date":{}}
    }
  }'
```

### Filter operators by property type

| Type | Operators |
|---|---|
| **title/rich_text** | `equals`, `does_not_equal`, `contains`, `does_not_contain`, `starts_with`, `ends_with`, `is_empty`, `is_not_empty` |
| **number** | `equals`, `does_not_equal`, `greater_than`, `less_than`, `greater_than_or_equal_to`, `less_than_or_equal_to` |
| **select** | `equals`, `does_not_equal`, `is_empty`, `is_not_empty` |
| **multi_select** | `contains`, `does_not_contain`, `is_empty`, `is_not_empty` |
| **date** | `equals`, `before`, `after`, `on_or_before`, `on_or_after`, `past_week`, `past_month`, `past_year`, `next_week`, `next_month`, `next_year` |
| **checkbox** | `equals` (`true`/`false`) |
| **relation** | `contains`, `does_not_contain`, `is_empty`, `is_not_empty` |

## Blocks (page content)

```bash
# Get child blocks of a page or block
curl -s https://api.notion.com/v1/blocks/{block_id}/children?page_size=100 \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"

# Append blocks to a page
curl -s -X PATCH https://api.notion.com/v1/blocks/{page_id}/children \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"children":[
    {"object":"block","type":"paragraph","paragraph":{"rich_text":[{"text":{"content":"New paragraph"}}]}},
    {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[{"text":{"content":"List item"}}]}},
    {"object":"block","type":"to_do","to_do":{"rich_text":[{"text":{"content":"Task item"}}],"checked":false}},
    {"object":"block","type":"code","code":{"rich_text":[{"text":{"content":"console.log(\"hello\")"}}],"language":"javascript"}}
  ]}'

# Delete a block
curl -s -X DELETE https://api.notion.com/v1/blocks/{block_id} \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"
```

### Common block types

`paragraph`, `heading_1`, `heading_2`, `heading_3`, `bulleted_list_item`, `numbered_list_item`, `to_do`, `toggle`, `code`, `quote`, `callout`, `divider`, `table`, `bookmark`, `image`, `embed`

## Comments

```bash
# List comments on a page
curl -s "https://api.notion.com/v1/comments?block_id={page_id}" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"

# Add comment to a page
curl -s -X POST https://api.notion.com/v1/comments \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{"parent":{"page_id":"PAGE_ID"},"rich_text":[{"text":{"content":"Comment text"}}]}'
```

## Users

```bash
# List workspace users
curl -s https://api.notion.com/v1/users \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"

# Get bot user (self)
curl -s https://api.notion.com/v1/users/me \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"
```

## Property value formats (for creating/updating pages)

| Type | Format |
|---|---|
| **title** | `{"title":[{"text":{"content":"text"}}]}` |
| **rich_text** | `{"rich_text":[{"text":{"content":"text"}}]}` |
| **number** | `{"number":42}` |
| **select** | `{"select":{"name":"Option"}}` |
| **multi_select** | `{"multi_select":[{"name":"Tag1"},{"name":"Tag2"}]}` |
| **date** | `{"date":{"start":"2026-03-25","end":"2026-03-26"}}` |
| **checkbox** | `{"checkbox":true}` |
| **url** | `{"url":"https://example.com"}` |
| **email** | `{"email":"user@example.com"}` |
| **phone_number** | `{"phone_number":"+1234567890"}` |
| **relation** | `{"relation":[{"id":"page_id"}]}` |
| **people** | `{"people":[{"id":"user_id"}]}` |

## Tips

- **Always get the database schema first** (`GET /databases/{id}`) to see property names and types before querying or creating pages.
- **Page IDs are in the URL**: `notion.so/Page-Title-abc123def456` → ID is `abc123def456` (add hyphens: `abc123de-f456-...`).
- **Pagination**: Responses with `has_more: true` include `next_cursor` — pass as `start_cursor` in next request.
- **Rate limit**: 3 requests/second average. Back off on 429 responses.
- **Notion-Version header is required** on every request.
- **Pages must be shared** with the integration in Notion before they appear in search or API calls.
- **Rich text** is always an array of text objects: `[{"text":{"content":"text"}}]`.

---

*Extracted from [vm0-ai/vm0-skills/notion](https://skills.sh/vm0-ai/vm0-skills/notion), [steipete/clawdis/notion](https://skills.sh/steipete/clawdis/notion), and [Notion API Reference](https://developers.notion.com/reference).*
