---
name: vibecode-integration-kustomer
display_name: Kustomer
description: >
  Kustomer API for managing customers, conversations, and support workflows.
  Consult this skill:
  1. When the user asks to look up or manage customer records
  2. When the user needs to view or respond to support conversations
  3. When the user wants to manage tags, teams, or routing
  4. When the user mentions Kustomer or customer support
metadata: {"openclaw": {"emoji": "🎧", "requires": {"env": ["KUSTOMER_API_KEY"]}}}
---

# Kustomer Integration

REST API for customers, conversations, messages, and support workflows.

**Auth**: Bearer token via `KUSTOMER_API_KEY`.
**Base URL**: `https://${KUSTOMER_SUBDOMAIN}.api.kustomerapp.com/v1`

```bash
KUSTOMER_BASE="https://${KUSTOMER_SUBDOMAIN}.api.kustomerapp.com/v1"

curl -s -H "Authorization: Bearer $KUSTOMER_API_KEY" "$KUSTOMER_BASE/<endpoint>"
```

## Customers

```bash
# List customers
curl -s -H "Authorization: Bearer $KUSTOMER_API_KEY" \
  "$KUSTOMER_BASE/customers?pageSize=20"

# Get customer by ID
curl -s -H "Authorization: Bearer $KUSTOMER_API_KEY" \
  "$KUSTOMER_BASE/customers/{id}"

# Search customers by email
curl -s -H "Authorization: Bearer $KUSTOMER_API_KEY" \
  "$KUSTOMER_BASE/customers/search" -X POST -H "Content-Type: application/json" \
  -d '{"and":[{"emails":{"eq":"alice@example.com"}}]}'

# Create customer
curl -s -X POST -H "Authorization: Bearer $KUSTOMER_API_KEY" -H "Content-Type: application/json" \
  "$KUSTOMER_BASE/customers" \
  -d '{"name":"Alice Smith","emails":[{"email":"alice@example.com"}],"phones":[{"phone":"+1234567890"}]}'

# Update customer
curl -s -X PATCH -H "Authorization: Bearer $KUSTOMER_API_KEY" -H "Content-Type: application/json" \
  "$KUSTOMER_BASE/customers/{id}" \
  -d '{"custom":{"planStr":"enterprise"}}'
```

## Conversations

```bash
# List conversations for a customer
curl -s -H "Authorization: Bearer $KUSTOMER_API_KEY" \
  "$KUSTOMER_BASE/customers/{customerId}/conversations"

# Get conversation
curl -s -H "Authorization: Bearer $KUSTOMER_API_KEY" \
  "$KUSTOMER_BASE/conversations/{id}"

# Get conversation messages
curl -s -H "Authorization: Bearer $KUSTOMER_API_KEY" \
  "$KUSTOMER_BASE/conversations/{id}/messages"

# Create conversation
curl -s -X POST -H "Authorization: Bearer $KUSTOMER_API_KEY" -H "Content-Type: application/json" \
  "$KUSTOMER_BASE/conversations" \
  -d '{"customer":"{customerId}","channel":"email","direction":"out","preview":"Hello, how can I help?"}'

# Send message in conversation
curl -s -X POST -H "Authorization: Bearer $KUSTOMER_API_KEY" -H "Content-Type: application/json" \
  "$KUSTOMER_BASE/conversations/{id}/messages" \
  -d '{"direction":"out","channel":"email","body":"Thank you for contacting us."}'
```

## Tags & notes

```bash
# Add tag to customer
curl -s -X POST -H "Authorization: Bearer $KUSTOMER_API_KEY" -H "Content-Type: application/json" \
  "$KUSTOMER_BASE/customers/{id}/tags" \
  -d '{"name":"vip"}'

# Add note to customer
curl -s -X POST -H "Authorization: Bearer $KUSTOMER_API_KEY" -H "Content-Type: application/json" \
  "$KUSTOMER_BASE/customers/{id}/notes" \
  -d '{"body":"Escalated to engineering team"}'
```

## Tips

- **`KUSTOMER_SUBDOMAIN`** is required for the base URL (e.g., `mycompany` → `mycompany.api.kustomerapp.com`).
- **Pagination**: Use `pageSize` and `page` query params, or `after` cursor.
- **Custom attributes**: Access via `custom.fieldName` in customer objects.
- **Conversation directions**: `in` (from customer), `out` (to customer).

---

*Based on [Kustomer API Reference](https://developer.kustomer.com) and [Kustomer API Introduction](https://help.kustomer.com/api-introduction-BkwVN42zM).*
