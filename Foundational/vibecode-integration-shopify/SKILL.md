---
name: vibecode-integration-shopify
description: >
  Shopify Admin API for managing products, orders, customers, and store operations.
  Consult this skill:
  1. When the user asks to manage products, inventory, or collections
  2. When the user needs to view or manage orders, fulfillments, or shipping
  3. When the user wants to look up or manage customers
  4. When the user mentions Shopify, e-commerce, store, or orders
metadata: {"openclaw": {"emoji": "🛍️", "requires": {"env": ["SHOPIFY_ACCESS_TOKEN"]}}}
---

# Shopify Integration

Admin REST API for products, orders, customers, inventory, and store management.

**Auth**: `X-Shopify-Access-Token` header via `SHOPIFY_ACCESS_TOKEN`.
**Base URL**: `https://${SHOPIFY_STORE_DOMAIN}/admin/api/2024-10`

```bash
SHOP="https://${SHOPIFY_STORE_DOMAIN}/admin/api/2024-10"

# Shopify uses X-Shopify-Access-Token header (NOT Bearer)
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" "$SHOP/<endpoint>.json"
```

**Important**: All endpoints end with `.json`.

## Products

```bash
# List products
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/products.json?limit=20"

# Get product
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/products/{productId}.json"

# Search products by title
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/products.json?title=T-Shirt"

# Create product
curl -s -X POST -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SHOP/products.json" \
  -d '{"product":{"title":"New Product","body_html":"<p>Description</p>","vendor":"My Store","product_type":"Apparel","variants":[{"price":"29.99","sku":"NP-001","inventory_quantity":100}]}}'

# Update product
curl -s -X PUT -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SHOP/products/{productId}.json" \
  -d '{"product":{"title":"Updated Title","tags":"sale, featured"}}'

# Delete product
curl -s -X DELETE -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/products/{productId}.json"

# List product variants
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/products/{productId}/variants.json"

# Count products
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/products/count.json"
```

## Orders

```bash
# List recent orders
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/orders.json?status=any&limit=20"

# List open/unfulfilled orders
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/orders.json?status=open&fulfillment_status=unfulfilled&limit=20"

# Get order
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/orders/{orderId}.json"

# Search orders by date range
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/orders.json?created_at_min=2026-03-01T00:00:00Z&created_at_max=2026-03-25T23:59:59Z&limit=50"

# List order fulfillments
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/orders/{orderId}/fulfillments.json"

# Create fulfillment
curl -s -X POST -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SHOP/fulfillments.json" \
  -d '{"fulfillment":{"line_items_by_fulfillment_order":[{"fulfillment_order_id":"{fulfillmentOrderId}"}],"tracking_info":{"number":"1Z999AA10123456784","company":"UPS","url":"https://www.ups.com/track?tracknum=1Z999AA10123456784"}}}'

# Cancel order
curl -s -X POST -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SHOP/orders/{orderId}/cancel.json"

# Count orders
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/orders/count.json?status=any"
```

## Customers

```bash
# List customers
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/customers.json?limit=20"

# Search customers
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/customers/search.json?query=email:alice@example.com"

# Get customer
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/customers/{customerId}.json"

# Get customer orders
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/customers/{customerId}/orders.json"

# Create customer
curl -s -X POST -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SHOP/customers.json" \
  -d '{"customer":{"first_name":"Alice","last_name":"Smith","email":"alice@example.com","tags":"vip"}}'
```

## Inventory

```bash
# List inventory levels for a location
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/inventory_levels.json?location_ids={locationId}&limit=50"

# Adjust inventory
curl -s -X POST -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "$SHOP/inventory_levels/adjust.json" \
  -d '{"location_id":{locationId},"inventory_item_id":{inventoryItemId},"available_adjustment":10}'

# List locations
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/locations.json"
```

## Collections

```bash
# List custom collections
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/custom_collections.json"

# List smart collections
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/smart_collections.json"

# List products in collection
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/products.json?collection_id={collectionId}"
```

## Store info

```bash
# Get shop details
curl -s -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" \
  "$SHOP/shop.json"
```

## GraphQL (for complex queries)

```bash
# Shopify also supports GraphQL for more efficient queries
curl -s -X POST -H "X-Shopify-Access-Token: $SHOPIFY_ACCESS_TOKEN" -H "Content-Type: application/json" \
  "https://${SHOPIFY_STORE_DOMAIN}/admin/api/2024-10/graphql.json" \
  -d '{"query":"{ products(first: 10) { edges { node { id title totalInventory variants(first: 5) { edges { node { sku price inventoryQuantity } } } } } } }"}'
```

## Tips

- **Auth is `X-Shopify-Access-Token` header** — not Bearer. This is Shopify-specific.
- **All REST endpoints end with `.json`** — don't forget the extension.
- **`SHOPIFY_STORE_DOMAIN`** is the full domain (e.g., `mystore.myshopify.com`).
- **Pagination**: Link header-based. Check `Link` response header for `rel="next"` URL with `page_info` param.
- **Rate limit**: 40 requests/second for REST (leaky bucket). Check `X-Shopify-Shop-Api-Call-Limit` header.
- **GraphQL**: 1,000 cost points per second. Use for complex nested queries.
- **Order status**: `open`, `closed`, `cancelled`. Fulfillment status: `fulfilled`, `unfulfilled`, `partial`.
- **Amounts in strings**: Shopify prices are strings (e.g., `"29.99"` not `29.99`).

---

*Based on [Microck/shopify-api skill](https://github.com/Microck/ordinary-claude-skills/blob/main/skills_all/shopify-api/SKILL.md), [Shopify Admin REST API Reference](https://shopify.dev/docs/api/admin-rest), and [Nango Shopify integration](https://nango.dev/docs/integrations/all/shopify-api-key).*
