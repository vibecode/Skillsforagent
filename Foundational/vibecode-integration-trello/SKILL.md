---
name: vibecode-integration-trello
display_name: Trello
description: >
  Trello REST API for managing boards, lists, cards, and checklists.
  Consult this skill:
  1. When the user asks to view or manage Trello boards
  2. When the user needs to create, move, or update cards
  3. When the user wants to manage lists, labels, or checklists
  4. When the user mentions Trello, boards, cards, or kanban
metadata: {"openclaw": {"emoji": "📌", "requires": {"env": ["TRELLO_ACCESS_TOKEN"]}}}
---

# Trello Integration

REST API for boards, lists, cards, checklists, labels, and members.

**Auth**: Token via query parameter `token` (NOT Bearer).
**Base URL**: `https://api.trello.com/1`
metadata: {"openclaw": {"emoji": "📌", "requires": {"env": ["TRELLO_ACCESS_TOKEN", "TRELLO_API_KEY"]}}}
```bash
# Trello uses token query parameter
curl -s "https://api.trello.com/1/<endpoint>?token=$TRELLO_ACCESS_TOKEN"
```

## Boards

```bash
# List my boards
curl -s "https://api.trello.com/1/members/me/boards?token=$TRELLO_ACCESS_TOKEN&fields=name,url,dateLastActivity"

# Get board
curl -s "https://api.trello.com/1/boards/{boardId}?token=$TRELLO_ACCESS_TOKEN"

# Get board with lists and cards
curl -s "https://api.trello.com/1/boards/{boardId}?token=$TRELLO_ACCESS_TOKEN&lists=open&cards=open&card_fields=name,idList,labels,due,dateLastActivity"
```

## Lists

```bash
# List lists on a board
curl -s "https://api.trello.com/1/boards/{boardId}/lists?token=$TRELLO_ACCESS_TOKEN&filter=open"

# Create list
curl -s -X POST "https://api.trello.com/1/lists?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"New List","idBoard":"{boardId}"}'

# Archive list
curl -s -X PUT "https://api.trello.com/1/lists/{listId}/closed?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" -d '{"value":true}'
```

## Cards

```bash
# List cards on a board
curl -s "https://api.trello.com/1/boards/{boardId}/cards?token=$TRELLO_ACCESS_TOKEN&fields=name,idList,labels,due,desc"

# List cards in a list
curl -s "https://api.trello.com/1/lists/{listId}/cards?token=$TRELLO_ACCESS_TOKEN"

# Get card
curl -s "https://api.trello.com/1/cards/{cardId}?token=$TRELLO_ACCESS_TOKEN"

# Create card
curl -s -X POST "https://api.trello.com/1/cards?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"New task","idList":"{listId}","desc":"Card description","due":"2026-04-01T12:00:00.000Z","idLabels":"{labelId}"}'

# Update card
curl -s -X PUT "https://api.trello.com/1/cards/{cardId}?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated name","idList":"{newListId}"}'

# Move card to another list
curl -s -X PUT "https://api.trello.com/1/cards/{cardId}?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"idList":"{targetListId}"}'

# Add comment to card
curl -s -X POST "https://api.trello.com/1/cards/{cardId}/actions/comments?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"This is done, moving to review"}'

# Archive card
curl -s -X PUT "https://api.trello.com/1/cards/{cardId}?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" -d '{"closed":true}'

# Delete card
curl -s -X DELETE "https://api.trello.com/1/cards/{cardId}?token=$TRELLO_ACCESS_TOKEN"
```

## Checklists

```bash
# Get card checklists
curl -s "https://api.trello.com/1/cards/{cardId}/checklists?token=$TRELLO_ACCESS_TOKEN"

# Create checklist on card
curl -s -X POST "https://api.trello.com/1/checklists?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"idCard":"{cardId}","name":"Subtasks"}'

# Add checklist item
curl -s -X POST "https://api.trello.com/1/checklists/{checklistId}/checkItems?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Review PR"}'

# Complete checklist item
curl -s -X PUT "https://api.trello.com/1/cards/{cardId}/checkItem/{checkItemId}?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" -d '{"state":"complete"}'
```

## Labels

```bash
# List board labels
curl -s "https://api.trello.com/1/boards/{boardId}/labels?token=$TRELLO_ACCESS_TOKEN"

# Add label to card
curl -s -X POST "https://api.trello.com/1/cards/{cardId}/idLabels?token=$TRELLO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" -d '{"value":"{labelId}"}'
```

## Members

```bash
# Get current member
curl -s "https://api.trello.com/1/members/me?token=$TRELLO_ACCESS_TOKEN"

# List board members
curl -s "https://api.trello.com/1/boards/{boardId}/members?token=$TRELLO_ACCESS_TOKEN"
```

## Tips

- **Auth via query param** — `?token=$TRELLO_ACCESS_TOKEN` (not Bearer header).
- **Moving cards** between lists is just updating `idList` on the card.
- **Board IDs** are in the URL: `trello.com/b/BOARD_ID/board-name`.
- **Card IDs** can be short IDs (shown in URL) or full IDs (from API).
- **Pagination**: Use `limit` param (max 1000) and `before`/`since` for date-based.
- **Rate limit**: 100 requests per 10 seconds per token. Back off on 429.

---

*Based on [steipete/clawdis/trello](https://clawhub.ai/steipete/trello), [Trello REST API Reference](https://developer.atlassian.com/cloud/trello/rest/), and [Nango Trello integration](https://nango.dev/docs/integrations/all/trello-scim).*
