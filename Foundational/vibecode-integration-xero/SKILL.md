---
name: vibecode-integration-xero
display_name: Xero
provider_skill: true
integration_dependencies:
  - xero
description: >
  Xero Accounting API for managing invoices, contacts, bank transactions, and reports.
  Consult this skill:
  1. When the user asks to manage invoices, bills, or payments
  2. When the user needs to look up or manage contacts/customers
  3. When the user wants to check bank transactions or account balances
  4. When the user mentions Xero, accounting, or bookkeeping
metadata: {"openclaw": {"emoji": "📗", "requires": {"env": ["XERO_ACCESS_TOKEN"]}}}
---

# Xero Integration

Accounting API for invoices, contacts, bank transactions, accounts, and reports.

**Auth**: Bearer token via `XERO_ACCESS_TOKEN` (OAuth2 Client Credentials via Nango).
**Base URL**: `https://api.xero.com/api.xro/2.0`
**Tenant header required**: `Xero-Tenant-Id` (get from `/connections` endpoint).

```bash
# First: get tenant ID
XERO_TENANT=$(curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" \
  "https://api.xero.com/connections" | jq -r '.[0].tenantId')

# All subsequent requests
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" \
  -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/<endpoint>"
```

## Invoices

```bash
# List invoices
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Invoices?page=1"

# Get invoice
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Invoices/{invoiceId}"

# Filter invoices (unpaid)
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Invoices?where=Status==%22AUTHORISED%22&order=DueDate"

# Create invoice
curl -s -X POST -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  -H "Content-Type: application/json" "https://api.xero.com/api.xro/2.0/Invoices" \
  -d '{"Invoices":[{"Type":"ACCREC","Contact":{"ContactID":"{contactId}"},"LineItems":[{"Description":"Consulting","Quantity":10,"UnitAmount":150,"AccountCode":"200"}],"Date":"2026-03-25","DueDate":"2026-04-25"}]}'
```

## Contacts

```bash
# List contacts
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Contacts?page=1"

# Search by name
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Contacts?where=Name.Contains(%22Acme%22)"

# Create contact
curl -s -X POST -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  -H "Content-Type: application/json" "https://api.xero.com/api.xro/2.0/Contacts" \
  -d '{"Contacts":[{"Name":"Acme Inc","EmailAddress":"billing@acme.com"}]}'
```

## Bank transactions & accounts

```bash
# List bank transactions
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/BankTransactions?page=1"

# List accounts
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Accounts"
```

## Reports

```bash
# Profit and Loss
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Reports/ProfitAndLoss?fromDate=2026-01-01&toDate=2026-03-31"

# Balance Sheet
curl -s -H "Authorization: Bearer $XERO_ACCESS_TOKEN" -H "Xero-Tenant-Id: $XERO_TENANT" \
  "https://api.xero.com/api.xro/2.0/Reports/BalanceSheet?date=2026-03-25"
```

## Tips

- **Tenant ID required** on every request — get it from `GET /connections` first.
- **Invoice types**: `ACCREC` (accounts receivable/sales), `ACCPAY` (accounts payable/bills).
- **Pagination**: Page-based with `page=1`, 100 items per page.
- **Where filters**: Use URL-encoded OData-like syntax (e.g., `Status==%22AUTHORISED%22`).
- **Rate limit**: 60 calls/minute per tenant. Back off on 429.

---

*Based on [vm0-ai/vm0-skills/xero](https://skills.sh/vm0-ai/vm0-skills/xero), [cleanexpo/xero-api-integration](https://skills.sh/cleanexpo/ato/xero-api-integration), and [Xero API Reference](https://developer.xero.com/documentation/api/accounting/overview).*
