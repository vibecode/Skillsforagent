---
name: vibecode-integration-stripe
display_name: Stripe
provider_skill: true
integration_dependencies:
  - stripe
description: >
  Stripe API for managing payments, customers, subscriptions, invoices, and billing.
  Consult this skill:
  1. When the user asks to look up customers, payments, or charges
  2. When the user needs to manage subscriptions, invoices, or billing
  3. When the user wants to issue refunds, check balances, or view payouts
  4. When the user mentions Stripe, payments, billing, or revenue
metadata: {"openclaw": {"emoji": "💰", "requires": {"env": ["STRIPE_API_KEY"]}}}
---

# Stripe Integration

REST API for payments, customers, subscriptions, invoices, products, and billing.

**Auth**: Bearer token via `STRIPE_API_KEY` (Stripe Connect OAuth via Nango).
**Base URL**: `https://api.stripe.com/v1`

```bash
# Stripe uses form-encoded bodies (not JSON) for writes
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" "https://api.stripe.com/v1/<endpoint>"
```

**Important**: Stripe POST/PATCH requests use `application/x-www-form-urlencoded` (not JSON).

## Customers

```bash
# List customers
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/customers?limit=20"

# Get customer
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/customers/{customerId}"

# Search customers by email
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/customers/search?query=email:'alice@example.com'"

# Search by name
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/customers/search?query=name~'Alice'"

# Create customer
curl -s -X POST -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/customers" \
  -d "email=alice@example.com" \
  -d "name=Alice Smith" \
  -d "metadata[company]=Acme Inc"

# Update customer
curl -s -X POST -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/customers/{customerId}" \
  -d "metadata[plan]=enterprise"
```

## Charges & payments

```bash
# List recent charges
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/charges?limit=20"

# List charges for a customer
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/charges?customer={customerId}&limit=20"

# Get charge
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/charges/{chargeId}"

# List payment intents
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/payment_intents?limit=20"

# Get payment intent
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/payment_intents/{piId}"
```

## Subscriptions

```bash
# List subscriptions
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/subscriptions?limit=20"

# List active subscriptions
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/subscriptions?status=active&limit=20"

# Get subscription
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/subscriptions/{subId}"

# List subscriptions for a customer
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/subscriptions?customer={customerId}"

# Cancel subscription (at period end)
curl -s -X POST -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/subscriptions/{subId}" \
  -d "cancel_at_period_end=true"

# Cancel immediately
curl -s -X DELETE -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/subscriptions/{subId}"

# Search subscriptions
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/subscriptions/search?query=status:'active' AND metadata['plan']:'enterprise'"
```

## Invoices

```bash
# List invoices
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/invoices?limit=20"

# List unpaid invoices
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/invoices?status=open&limit=20"

# Get invoice
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/invoices/{invoiceId}"

# List invoices for a customer
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/invoices?customer={customerId}"

# Search invoices
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/invoices/search?query=total>10000 AND status:'open'"
```

## Products & prices

```bash
# List products
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/products?limit=20&active=true"

# Get product
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/products/{productId}"

# List prices for a product
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/prices?product={productId}&active=true"

# Search products
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/products/search?query=name~'Pro'"
```

## Refunds

```bash
# Create refund
curl -s -X POST -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/refunds" \
  -d "charge={chargeId}" \
  -d "reason=requested_by_customer"

# Partial refund
curl -s -X POST -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/refunds" \
  -d "charge={chargeId}" \
  -d "amount=500"

# List refunds
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/refunds?limit=20"
```

## Balance & payouts

```bash
# Get current balance
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/balance"

# List balance transactions
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/balance_transactions?limit=20"

# List payouts
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/payouts?limit=20"
```

## Disputes

```bash
# List disputes
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/disputes?limit=20"

# Get dispute
curl -s -H "Authorization: Bearer $STRIPE_API_KEY" \
  "https://api.stripe.com/v1/disputes/{disputeId}"
```

## Search query syntax

Stripe search supports these operators across customers, subscriptions, invoices, charges, payment intents, and products:

| Operator | Example |
|---|---|
| Exact match | `email:'alice@example.com'` |
| Prefix/contains | `name~'Alice'` |
| Numeric | `amount>5000`, `amount>=1000` |
| Metadata | `metadata['key']:'value'` |
| Date | `created>1711382400` (Unix timestamp) |
| AND/OR | `status:'active' AND amount>1000` |
| Negation | `-status:'canceled'` |

## Tips

- **Form-encoded, not JSON**: POST requests use `-d "key=value"` pairs, not JSON bodies. This is Stripe-specific.
- **Amounts are in cents**: `amount=5000` = $50.00 USD. Always in the smallest currency unit.
- **Pagination**: Cursor-based with `starting_after` and `ending_before` params + `has_more` boolean.
- **Expand related objects**: Add `expand[]=customer` or `expand[]=data.customer` to include nested objects inline.
- **Idempotency**: Add `-H "Idempotency-Key: unique-key"` to POST requests to prevent double-charges.
- **Test vs live**: Stripe Connect OAuth tokens are scoped to the connected account's live/test mode.
- **IDs are prefixed**: `cus_` (customer), `ch_` (charge), `pi_` (payment intent), `sub_` (subscription), `in_` (invoice), `prod_` (product), `price_` (price), `re_` (refund).

---

*Based on [Stripe API Reference](https://docs.stripe.com/api), [vm0-ai/vm0-skills](https://skills.sh/vm0-ai/vm0-skills), and [Nango Stripe integration](https://nango.dev/docs/api-integrations/stripe).*
