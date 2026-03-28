---
name: vibecode-integration-ramp
display_name: Ramp
description: >
  Ramp API for managing corporate expenses, cards, transactions, and reimbursements.
  Consult this skill:
  1. When the user asks to view transactions, expenses, or spending
  2. When the user needs to manage corporate cards or spend limits
  3. When the user wants to check bills, reimbursements, or receipts
  4. When the user mentions Ramp, corporate cards, or expense management
metadata: {"openclaw": {"emoji": "💳", "requires": {"env": ["RAMP_ACCESS_TOKEN"]}}}
---

# Ramp Integration

REST API for transactions, cards, users, bills, reimbursements, and corporate spend management.

**Auth**: Bearer token via `RAMP_ACCESS_TOKEN` (OAuth via Nango).
**Base URL**: `https://api.ramp.com/developer/v1`

```bash
RAMP="https://api.ramp.com/developer/v1"

curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" "$RAMP/<endpoint>"
```

## Transactions

```bash
# List recent transactions
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/transactions?page_size=20"

# Filter by date range
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/transactions?from_date=2026-03-01T00:00:00Z&to_date=2026-03-25T23:59:59Z&page_size=50"

# Filter by user
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/transactions?user_id={userId}&page_size=20"

# Filter by card
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/transactions?card_id={cardId}&page_size=20"

# Get single transaction
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/transactions/{transactionId}"

# Set memo on transaction
curl -s -X POST -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$RAMP/memos/{transactionId}" \
  -d '{"memo":"Client dinner - Acme Corp"}'
```

## Cards

```bash
# List cards
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/cards?page_size=20"

# List active cards for a user
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/cards?user_id={userId}&is_activated=true"

# Get card details
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/cards/{cardId}"

# Create virtual card (async)
curl -s -X POST -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$RAMP/cards/deferred/virtual" \
  -d '{"display_name":"Marketing Q1","spend_limit_id":"{limitId}"}'

# Suspend card
curl -s -X POST -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/cards/{cardId}/deferred/suspension"

# Terminate card
curl -s -X POST -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/cards/{cardId}/deferred/termination"

# Check async task status
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/cards/deferred/status/{taskId}"
```

## Users

```bash
# List users
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/users?status=ACTIVE&page_size=50"

# Get user
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/users/{userId}"

# Search by email
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/users?email=alice@example.com"
```

## Reimbursements

```bash
# List reimbursements
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/reimbursements?page_size=20"

# Filter by state
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/reimbursements?state=PENDING&page_size=20"

# Get single reimbursement
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/reimbursements/{reimbursementId}"
```

## Bills

```bash
# List unpaid bills
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/bills?payment_status=UNPAID&page_size=20"

# Create bill
curl -s -X POST -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$RAMP/bills" \
  -d '{"vendor_id":"{vendorId}","amount":{"amount":50000,"currency_code":"USD"},"due_date":"2026-04-01","invoice_number":"INV-001"}'

# Upload bill attachment
curl -s -X POST -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/bills/{billId}/attachments" \
  -F "file=@invoice.pdf"
```

## Receipts

```bash
# Upload receipt for a transaction
curl -s -X POST -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/receipts" \
  -F "transaction_id={transactionId}" \
  -F "file=@receipt.pdf"

# List receipts
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" \
  "$RAMP/receipts?page_size=20"
```

## Departments, locations, business

```bash
# List departments
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" "$RAMP/departments"

# List locations
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" "$RAMP/locations"

# Get business info and balance
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" "$RAMP/business"
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" "$RAMP/business/balance"

# List statements
curl -s -H "Authorization: Bearer $RAMP_ACCESS_TOKEN" "$RAMP/statements"
```

## Tips

- **Pagination**: Cursor-based. Use `page_size` (2-100) and follow `page.next` URL until it's null.
- **Async operations**: Card creation, user creation, and limit creation return a `task_id`. Poll `GET .../deferred/status/{taskId}`.
- **Amounts**: Stored in minor units (cents for USD). `amount: 50000` = $500.00.
- **Sync status**: `NOT_SYNCED`, `SYNC_READY`, `SYNCED` — filter transactions by accounting sync state.
- **Date filters**: ISO 8601 format (`2026-03-25T00:00:00Z`).
- **File uploads**: Receipts and bill attachments use `multipart/form-data`.

---

*Based on [Ramp Developer API v1 Reference](https://docs.ramp.com/developer-api/v1) and [Nango Ramp integration](https://nango.dev/docs/integrations/all/ramp).*
