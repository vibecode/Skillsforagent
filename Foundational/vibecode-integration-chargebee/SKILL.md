---
name: vibecode-integration-chargebee
display_name: Chargebee
provider_skill: true
integration_dependencies:
  - chargebee
description: >
  Chargebee API for managing subscriptions, customers, invoices, and billing.
  Consult this skill:
  1. When the user asks to manage subscriptions or billing
  2. When the user needs to look up customers, invoices, or plans
  3. When the user wants to handle subscription changes, cancellations, or renewals
  4. When the user mentions Chargebee, subscriptions, or recurring billing
metadata: {"openclaw": {"emoji": "🔄", "requires": {"env": ["CHARGEBEE_API_KEY"]}}}
---

# Chargebee Integration

REST API for subscriptions, customers, invoices, plans, and billing operations.

**Auth**: Basic auth with API key as username (NOT Bearer). Password is empty.
**Base URL**: `https://${CHARGEBEE_SUBDOMAIN}.chargebee.com/api/v2`

```bash
CB="https://${CHARGEBEE_SUBDOMAIN}.chargebee.com/api/v2"

# Chargebee uses Basic auth (API key as username, empty password)
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/<endpoint>"
```

## Subscriptions

```bash
# List subscriptions
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/subscriptions?limit=20"

# Get subscription
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/subscriptions/{subscriptionId}"

# List active subscriptions
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/subscriptions?status[is]=active&limit=20"

# Cancel subscription (end of term)
curl -s -X POST -u "$CHARGEBEE_API_KEY:" "$CB/subscriptions/{subscriptionId}/cancel_for_items" \
  -d "end_of_term=true"

# Cancel immediately
curl -s -X POST -u "$CHARGEBEE_API_KEY:" "$CB/subscriptions/{subscriptionId}/cancel_for_items"
```

## Customers

```bash
# List customers
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/customers?limit=20"

# Get customer
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/customers/{customerId}"

# Search by email
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/customers?email[is]=alice@example.com"

# Create customer
curl -s -X POST -u "$CHARGEBEE_API_KEY:" "$CB/customers" \
  -d "first_name=Alice" -d "last_name=Smith" -d "email=alice@example.com" -d "company=Acme Inc"
```

## Invoices

```bash
# List invoices
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/invoices?limit=20"

# List unpaid invoices
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/invoices?status[is]=payment_due&limit=20"

# Get invoice
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/invoices/{invoiceId}"

# Download invoice PDF
curl -s -X POST -u "$CHARGEBEE_API_KEY:" "$CB/invoices/{invoiceId}/pdf"
```

## Plans / Item Prices

```bash
# List item prices (plans)
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/item_prices?limit=20"

# List items
curl -s -u "$CHARGEBEE_API_KEY:" "$CB/items?limit=20"
```

## Tips

- **Basic auth, NOT Bearer** — use `-u "$CHARGEBEE_API_KEY:"` (colon after key, empty password).
- **`CHARGEBEE_SUBDOMAIN`** is your site name (e.g., `mycompany` for `mycompany.chargebee.com`).
- **Form-encoded writes** — POST requests use `-d "key=value"` pairs like Stripe.
- **Filter syntax**: `field[operator]=value` — operators: `is`, `is_not`, `in`, `not_in`, `starts_with`, `gt`, `gte`, `lt`, `lte`, `between`.
- **Pagination**: Offset-based with `offset` param from response.
- **Rate limit**: 750 API calls per 5 minutes. Back off on 429.

---

*Based on [chargebee/ai/chargebee-integration](https://skills.sh/chargebee/ai/chargebee-integration), [membranedev/chargebee](https://skills.sh/membranedev/application-skills/chargebee), and [Chargebee API Reference](https://apidocs.chargebee.com/docs/api).*
