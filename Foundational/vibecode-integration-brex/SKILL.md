---
name: vibecode-integration-brex
description: >
  Brex API for managing corporate cards, expenses, accounts, and transactions.
  Consult this skill:
  1. When the user asks about Brex card transactions or expenses
  2. When the user needs to manage cards, users, or spend limits
  3. When the user wants to check account balances or vendor payments
  4. When the user mentions Brex or corporate banking
metadata: {"openclaw": {"emoji": "🏦", "requires": {"env": ["BREX_ACCESS_TOKEN"]}}}
---

# Brex Integration

REST API for accounts, cards, transactions, users, and vendors.

**Auth**: Bearer token via `BREX_ACCESS_TOKEN`.
**Base URL**: `https://platform.brexapis.com`

```bash
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" "https://platform.brexapis.com/<endpoint>"
```

## Accounts

```bash
# List accounts
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/accounts"

# Get primary account balance
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/accounts/{accountId}"
```

## Cards

```bash
# List cards
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/cards"

# Get card
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/cards/{cardId}"

# Lock card
curl -s -X POST -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/cards/{cardId}/lock"

# Unlock card
curl -s -X POST -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/cards/{cardId}/unlock"
```

## Transactions

```bash
# List card transactions
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/transactions/card/primary"

# List cash transactions
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/transactions/cash/primary"
```

## Users

```bash
# List users
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/users"

# Get current user
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/users/me"
```

## Vendors

```bash
# List vendors
curl -s -H "Authorization: Bearer $BREX_ACCESS_TOKEN" \
  "https://platform.brexapis.com/v2/vendors"
```

## Tips

- **Pagination**: Cursor-based with `cursor` param.
- **Amounts**: In cents (minor units). `amount: 5000` = $50.00.

---

*Based on [Brex Developer API Reference](https://developer.brex.com) and [Nango Brex integration](https://nango.dev/docs/api-integrations/brex-api-key).*
