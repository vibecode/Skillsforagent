---
name: vibecode-integration-clerk
display_name: Clerk
provider_skill: true
integration_dependencies:
  - clerk
description: >
  Clerk Backend API for managing users, organizations, sessions, and authentication.
  Consult this skill:
  1. When the user asks to manage users, roles, or organizations
  2. When the user needs to check sessions, invitations, or auth status
  3. When the user wants to manage user metadata or permissions
  4. When the user mentions Clerk, user management, or authentication
metadata: {"openclaw": {"emoji": "🔐", "requires": {"env": ["CLERK_SECRET_KEY"]}}}
---

# Clerk Integration

Backend API for users, organizations, sessions, invitations, and authentication management.

**Auth**: Bearer token via `CLERK_SECRET_KEY`.
**Base URL**: `https://api.clerk.com/v1`

```bash
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" "https://api.clerk.com/v1/<endpoint>"
```

## Users

```bash
# List users
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/users?limit=20&order_by=-created_at"

# Search users by email
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/users?email_address=alice@example.com"

# Get user
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/users/{userId}"

# Update user metadata
curl -s -X PATCH -H "Authorization: Bearer $CLERK_SECRET_KEY" -H "Content-Type: application/json" \
  "https://api.clerk.com/v1/users/{userId}/metadata" \
  -d '{"public_metadata":{"role":"admin"},"private_metadata":{"plan":"enterprise"}}'

# Ban user
curl -s -X POST -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/users/{userId}/ban"

# Unban user
curl -s -X POST -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/users/{userId}/unban"

# Get user count
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/users/count"
```

## Organizations

```bash
# List organizations
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/organizations?limit=20"

# Get organization
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/organizations/{orgId}"

# List organization members
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/organizations/{orgId}/memberships"

# Create organization
curl -s -X POST -H "Authorization: Bearer $CLERK_SECRET_KEY" -H "Content-Type: application/json" \
  "https://api.clerk.com/v1/organizations" \
  -d '{"name":"Acme Inc","created_by":"{userId}"}'
```

## Sessions

```bash
# List sessions for a user
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/sessions?user_id={userId}&status=active"

# Revoke session
curl -s -X POST -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/sessions/{sessionId}/revoke"
```

## Invitations

```bash
# List invitations
curl -s -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/invitations"

# Create invitation
curl -s -X POST -H "Authorization: Bearer $CLERK_SECRET_KEY" -H "Content-Type: application/json" \
  "https://api.clerk.com/v1/invitations" \
  -d '{"email_address":"new@example.com","public_metadata":{"role":"member"}}'

# Revoke invitation
curl -s -X POST -H "Authorization: Bearer $CLERK_SECRET_KEY" \
  "https://api.clerk.com/v1/invitations/{invitationId}/revoke"
```

## Tips

- **Secret key** (starts with `sk_`) — this is the backend key, not the publishable key.
- **User IDs** start with `user_` (e.g., `user_2abc123`).
- **Metadata**: `public_metadata` is visible to frontend, `private_metadata` is server-only, `unsafe_metadata` is user-writable.
- **Pagination**: `limit` + `offset` params.
- **Rate limit**: Varies by plan. Back off on 429.

---

*Based on [clerk/skills/clerk](https://skills.sh/clerk/skills/clerk), [clerk/skills/clerk-setup](https://skills.sh/clerk/skills/clerk-setup), and [Clerk Backend API Reference](https://clerk.com/docs/reference/backend-api).*
