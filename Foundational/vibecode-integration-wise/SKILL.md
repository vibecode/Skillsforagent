---
name: vibecode-integration-wise
display_name: Wise
provider_skill: true
integration_dependencies:
  - wise
description: >
  Wise API for managing international transfers, balances, and currency exchange.
  Consult this skill:
  1. When the user asks to check balances or exchange rates
  2. When the user needs to create or manage international transfers
  3. When the user wants to manage recipients or payment methods
  4. When the user mentions Wise, international transfers, or currency exchange
metadata: {"openclaw": {"emoji": "🌍", "requires": {"env": ["WISE_API_TOKEN"]}}}
---

# Wise Integration

REST API for profiles, balances, transfers, recipients, and exchange rates.

**Auth**: Bearer token via `WISE_API_TOKEN` (API key from Wise Settings).
**Base URL**: `https://api.wise.com`

```bash
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" "https://api.wise.com/<endpoint>"
```

## Profiles

```bash
# List profiles (personal + business)
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v1/profiles"
```

## Balances

```bash
# List balances for a profile
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v4/profiles/{profileId}/balances?types=STANDARD"

# Get balance for a specific currency
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v4/profiles/{profileId}/balances/{balanceId}"
```

## Exchange rates

```bash
# Get live rate
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v1/rates?source=USD&target=EUR"

# Get rate for specific amount
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v1/rates?source=USD&target=GBP&amount=1000"
```

## Transfers

```bash
# List transfers
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v1/transfers?profile={profileId}&limit=20"

# Get transfer
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v1/transfers/{transferId}"

# Create quote (step 1)
curl -s -X POST -H "Authorization: Bearer $WISE_API_TOKEN" -H "Content-Type: application/json" \
  "https://api.wise.com/v3/profiles/{profileId}/quotes" \
  -d '{"sourceCurrency":"USD","targetCurrency":"EUR","sourceAmount":1000}'

# Create transfer (step 2, needs quote + recipient)
curl -s -X POST -H "Authorization: Bearer $WISE_API_TOKEN" -H "Content-Type: application/json" \
  "https://api.wise.com/v1/transfers" \
  -d '{"targetAccount":{recipientId},"quoteUuid":"{quoteId}","customerTransactionId":"unique-uuid","details":{"reference":"Invoice 123"}}'
```

## Recipients

```bash
# List recipients
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v1/accounts?profile={profileId}"

# Get recipient
curl -s -H "Authorization: Bearer $WISE_API_TOKEN" \
  "https://api.wise.com/v1/accounts/{recipientId}"
```

## Tips

- **Transfer flow**: Create quote → create recipient (if new) → create transfer → fund transfer. Each step depends on the previous.
- **Profile ID required** for most endpoints — get from `GET /v1/profiles` first.
- **Amounts**: Decimal format (e.g., `1000.50`), not cents.
- **Rate limit**: Back off on 429.

---

*Based on [Wise API Reference](https://docs.wise.com/api-reference) and [Nango Wise integration](https://nango.dev/docs/api-integrations/wise-api-key).*
