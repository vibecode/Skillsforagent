---
name: stripe
description: >
  Use this skill whenever the user wants to interact with Stripe for payment processing,
  subscription management, customer management, invoice handling, or any billing-related
  tasks. This includes creating customers, setting up subscriptions, generating invoices,
  processing refunds, managing payment methods, viewing transaction history, handling
  disputes, creating products and prices, managing coupons and discounts, setting up
  webhooks, and any other Stripe API operations. Also use when the user mentions
  "payments", "billing", "subscriptions", "invoices", "charges", or "Stripe" directly.
metadata: {"openclaw": {"emoji": "💳", "env": ["STRIPE_SECRET_KEY"]}}
---

# Stripe Integration Skill

This skill enables the agent to interact with the Stripe API for payment processing, subscription management, customer management, and billing operations.

## Prerequisites and Environment Setup

Before performing ANY Stripe operation, you MUST complete all of the following steps:

### Step 1: Verify Environment Variables

First, check that the STRIPE_SECRET_KEY environment variable is set:

```bash
echo $STRIPE_SECRET_KEY | head -c 7
```

This should print `sk_test` or `sk_live`. If it does not, STOP and tell the user that the Stripe secret key is not configured.

### Step 2: Verify curl is Available

Check that curl is installed and available:

```bash
which curl
```

If curl is not available, install it using the appropriate package manager.

### Step 3: Verify jq is Available

Check that jq is installed and available:

```bash
which jq
```

If jq is not available, install it. jq is required for parsing all Stripe API responses.

### Step 4: Test API Connectivity

Before proceeding with any operation, always verify that the Stripe API is reachable and the key is valid:

```bash
curl -s https://api.stripe.com/v1/balance \
  -u "$STRIPE_SECRET_KEY:" | jq .
```

This should return a balance object. If it returns an error, STOP and inform the user about the connectivity issue.

### Step 5: Determine API Mode

After verifying connectivity, you MUST determine whether the key is a test key or live key:

```bash
if [[ "$STRIPE_SECRET_KEY" == sk_test_* ]]; then
  echo "TEST MODE - Safe to experiment"
elif [[ "$STRIPE_SECRET_KEY" == sk_live_* ]]; then
  echo "LIVE MODE - Exercise extreme caution"
fi
```

If in live mode, ALWAYS confirm with the user before making any write operations (create, update, delete).

## Important Safety Rules

1. NEVER log or display the full Stripe secret key
2. NEVER store the secret key in any file
3. ALWAYS confirm destructive operations with the user before executing
4. ALWAYS use the --fail flag with curl to catch HTTP errors
5. NEVER create test data in a live environment without explicit user permission
6. ALWAYS check the response status code after every API call
7. ALWAYS parse the response to check for error objects before proceeding
8. NEVER assume an API call succeeded without checking the response
9. ALWAYS include proper error handling in every curl command
10. NEVER send sensitive customer data (like full credit card numbers) to the Stripe API directly — use tokens instead

## API Call Pattern

For EVERY Stripe API call, you MUST follow this exact pattern:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/ENDPOINT \
  -u "$STRIPE_SECRET_KEY:" \
  -d "param1=value1" \
  -d "param2=value2")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error: HTTP $http_code"
  echo "$body" | jq .
  # STOP and inform the user about the error
else
  echo "$body" | jq .
fi
```

This pattern ensures proper error handling for every single API call. Do not skip any part of this pattern.

## Customer Operations

### Creating a Customer

To create a new Stripe customer, you need at minimum an email address. Follow these steps:

1. First, ask the user for the customer details (name, email, phone, address, metadata)
2. Verify that the email is in a valid format
3. Check if a customer with this email already exists by searching:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/customers/search \
  -u "$STRIPE_SECRET_KEY:" \
  -G \
  -d "query=email:'customer@example.com'")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error searching customers: HTTP $http_code"
  echo "$body" | jq .
else
  count=$(echo "$body" | jq '.data | length')
  if [ "$count" -gt 0 ]; then
    echo "WARNING: Customer with this email already exists!"
    echo "$body" | jq '.data[0]'
    # Ask user if they want to proceed or use existing customer
  fi
fi
```

4. If no duplicate found, create the customer:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/customers \
  -u "$STRIPE_SECRET_KEY:" \
  -d "email=customer@example.com" \
  -d "name=John Doe" \
  -d "phone=+15551234567" \
  -d "description=Customer created via agent")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error creating customer: HTTP $http_code"
  echo "$body" | jq .
else
  customer_id=$(echo "$body" | jq -r '.id')
  echo "Customer created: $customer_id"
  echo "$body" | jq .
fi
```

5. After creating the customer, ALWAYS confirm the creation by retrieving the customer:

```bash
curl -s https://api.stripe.com/v1/customers/$customer_id \
  -u "$STRIPE_SECRET_KEY:" | jq .
```

6. Display the customer details to the user in a readable format

### Listing Customers

To list customers:

```bash
response=$(curl -s -w "\n%{http_code}" "https://api.stripe.com/v1/customers?limit=10" \
  -u "$STRIPE_SECRET_KEY:")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error listing customers: HTTP $http_code"
  echo "$body" | jq .
else
  echo "$body" | jq '.data[] | {id, name, email, created: (.created | todate)}'
fi
```

### Retrieving a Customer

To retrieve a specific customer by ID:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/customers/cus_XXXXX \
  -u "$STRIPE_SECRET_KEY:")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error retrieving customer: HTTP $http_code"
  echo "$body" | jq .
else
  echo "$body" | jq .
fi
```

### Updating a Customer

To update a customer's details:

1. First retrieve the current customer data to show the user what will change
2. Confirm the changes with the user
3. Make the update:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/customers/cus_XXXXX \
  -u "$STRIPE_SECRET_KEY:" \
  -d "name=Updated Name" \
  -d "email=newemail@example.com")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error updating customer: HTTP $http_code"
  echo "$body" | jq .
else
  echo "Customer updated successfully"
  echo "$body" | jq .
fi
```

4. Verify the update by retrieving the customer again

### Deleting a Customer

ALWAYS confirm with the user before deleting a customer. Deletion is permanent.

1. First retrieve the customer to show the user what they're about to delete
2. Check if the customer has any active subscriptions
3. Ask for explicit confirmation
4. Delete:

```bash
response=$(curl -s -w "\n%{http_code}" -X DELETE https://api.stripe.com/v1/customers/cus_XXXXX \
  -u "$STRIPE_SECRET_KEY:")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error deleting customer: HTTP $http_code"
  echo "$body" | jq .
else
  echo "$body" | jq .
fi
```

## Subscription Operations

### Creating a Subscription

To create a subscription, you need a customer ID and a price ID. Follow these steps:

1. First verify the customer exists by retrieving them
2. Verify the price exists:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/prices/price_XXXXX \
  -u "$STRIPE_SECRET_KEY:")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error retrieving price: HTTP $http_code"
  echo "$body" | jq .
else
  echo "Price details:"
  echo "$body" | jq '{id, currency, unit_amount, recurring}'
fi
```

3. Check if the customer already has an active subscription to this price
4. Confirm with the user: show them the price details and ask if they want to proceed
5. Create the subscription:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/subscriptions \
  -u "$STRIPE_SECRET_KEY:" \
  -d "customer=cus_XXXXX" \
  -d "items[0][price]=price_XXXXX")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error creating subscription: HTTP $http_code"
  echo "$body" | jq .
else
  sub_id=$(echo "$body" | jq -r '.id')
  echo "Subscription created: $sub_id"
  echo "$body" | jq '{id, status, current_period_start: (.current_period_start | todate), current_period_end: (.current_period_end | todate)}'
fi
```

6. Verify the subscription was created by retrieving it
7. Display the subscription details to the user

### Canceling a Subscription

1. First retrieve the subscription to show its current status
2. Ask the user if they want immediate cancellation or at period end
3. Confirm with the user
4. Cancel:

For immediate cancellation:
```bash
response=$(curl -s -w "\n%{http_code}" -X DELETE https://api.stripe.com/v1/subscriptions/sub_XXXXX \
  -u "$STRIPE_SECRET_KEY:")
```

For cancellation at period end:
```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/subscriptions/sub_XXXXX \
  -u "$STRIPE_SECRET_KEY:" \
  -d "cancel_at_period_end=true")
```

5. Verify the cancellation by retrieving the subscription again

## Product and Price Operations

### Creating a Product

1. Ask the user for product details (name, description, images, metadata)
2. Create the product:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/products \
  -u "$STRIPE_SECRET_KEY:" \
  -d "name=Product Name" \
  -d "description=Product description")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error creating product: HTTP $http_code"
  echo "$body" | jq .
else
  product_id=$(echo "$body" | jq -r '.id')
  echo "Product created: $product_id"
fi
```

3. Then create a price for the product:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/prices \
  -u "$STRIPE_SECRET_KEY:" \
  -d "product=$product_id" \
  -d "unit_amount=2000" \
  -d "currency=usd" \
  -d "recurring[interval]=month")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error creating price: HTTP $http_code"
  echo "$body" | jq .
else
  price_id=$(echo "$body" | jq -r '.id')
  echo "Price created: $price_id"
fi
```

4. Verify both the product and price were created

## Invoice Operations

### Creating an Invoice

1. Verify the customer exists
2. Create invoice items first:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/invoiceitems \
  -u "$STRIPE_SECRET_KEY:" \
  -d "customer=cus_XXXXX" \
  -d "amount=5000" \
  -d "currency=usd" \
  -d "description=Consulting services")
```

3. Create the invoice:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/invoices \
  -u "$STRIPE_SECRET_KEY:" \
  -d "customer=cus_XXXXX" \
  -d "auto_advance=true")
```

4. Finalize and optionally send the invoice:

```bash
# Finalize
curl -s -X POST https://api.stripe.com/v1/invoices/in_XXXXX/finalize \
  -u "$STRIPE_SECRET_KEY:" | jq .

# Send
curl -s -X POST https://api.stripe.com/v1/invoices/in_XXXXX/send \
  -u "$STRIPE_SECRET_KEY:" | jq .
```

5. Verify the invoice status

### Listing Invoices

```bash
response=$(curl -s -w "\n%{http_code}" "https://api.stripe.com/v1/invoices?limit=10&customer=cus_XXXXX" \
  -u "$STRIPE_SECRET_KEY:")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error listing invoices: HTTP $http_code"
  echo "$body" | jq .
else
  echo "$body" | jq '.data[] | {id, status, amount_due: (.amount_due / 100), currency, created: (.created | todate)}'
fi
```

## Refund Operations

### Processing a Refund

1. First retrieve the charge or payment intent
2. Show the user the charge details and ask for confirmation
3. Ask if it's a full or partial refund
4. Process:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/refunds \
  -u "$STRIPE_SECRET_KEY:" \
  -d "charge=ch_XXXXX" \
  -d "amount=1000")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error processing refund: HTTP $http_code"
  echo "$body" | jq .
else
  echo "Refund processed:"
  echo "$body" | jq '{id, amount: (.amount / 100), currency, status}'
fi
```

5. Verify the refund status
6. Inform the user about the refund timeline

## Balance and Reporting

### Checking Balance

```bash
curl -s https://api.stripe.com/v1/balance \
  -u "$STRIPE_SECRET_KEY:" | jq .
```

### Listing Recent Charges

```bash
response=$(curl -s -w "\n%{http_code}" "https://api.stripe.com/v1/charges?limit=10" \
  -u "$STRIPE_SECRET_KEY:")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -ne 200 ]; then
  echo "Error listing charges: HTTP $http_code"
  echo "$body" | jq .
else
  echo "$body" | jq '.data[] | {id, amount: (.amount / 100), currency, status, description, created: (.created | todate)}'
fi
```

## Webhook Operations

### Listing Webhook Endpoints

```bash
curl -s https://api.stripe.com/v1/webhook_endpoints \
  -u "$STRIPE_SECRET_KEY:" | jq '.data[] | {id, url, enabled_events, status}'
```

### Creating a Webhook Endpoint

1. Ask the user for the webhook URL and events to subscribe to
2. Validate the URL format
3. Create:

```bash
response=$(curl -s -w "\n%{http_code}" https://api.stripe.com/v1/webhook_endpoints \
  -u "$STRIPE_SECRET_KEY:" \
  -d "url=https://example.com/webhook" \
  -d "enabled_events[]=payment_intent.succeeded" \
  -d "enabled_events[]=customer.subscription.deleted")
```

4. Display the webhook secret (only shown once!) and remind the user to save it

## Error Reference

Common Stripe API errors and how to handle them:

| Error Code | Meaning | Action |
|-----------|---------|--------|
| 400 | Bad request | Check parameter format and values |
| 401 | Authentication failed | Check STRIPE_SECRET_KEY |
| 402 | Card declined | Inform user, suggest different payment method |
| 404 | Not found | Verify the resource ID is correct |
| 409 | Conflict | Resource was modified concurrently |
| 429 | Rate limited | Wait and retry with exponential backoff |
| 500 | Stripe error | Retry once, then inform user |

## Formatting Output

When displaying Stripe data to the user:
1. ALWAYS convert amounts from cents to dollars (divide by 100)
2. ALWAYS convert Unix timestamps to human-readable dates
3. ALWAYS format currency amounts with proper symbols
4. Use clean, readable formatting — not raw JSON dumps
5. Summarize large lists and offer pagination
