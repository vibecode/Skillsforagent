---
name: vibecode-integration-supabase
display_name: Supabase
description: >
  Supabase integration for database queries, storage, auth, and edge functions.
  Consult this skill:
  1. When the user asks to query, insert, or manage data in their Supabase database
  2. When the user needs to manage storage buckets or files
  3. When the user wants to work with edge functions or auth users
  4. When the user mentions Supabase, Postgres, database, or their backend data
metadata: {"openclaw": {"emoji": "⚡", "requires": {"env": ["SUPABASE_ACCESS_TOKEN"]}}}
---

# Supabase Integration

PostgREST API for database CRUD, plus Management API for storage, auth, and edge functions.

**Auth**: Access token via `SUPABASE_ACCESS_TOKEN` (OAuth via Nango MCP) + project URL via `SUPABASE_PROJECT_URL`.

```bash
# All PostgREST requests (database CRUD)
curl -s "$SUPABASE_PROJECT_URL/rest/v1/<table>" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

**Note**: OAuth token from Nango MCP. Access level depends on the scopes granted during OAuth flow.

## Database — Read

```bash
# List all rows from a table
curl -s "$SUPABASE_PROJECT_URL/rest/v1/users?select=*&limit=20" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Select specific columns
curl -s "$SUPABASE_PROJECT_URL/rest/v1/users?select=id,name,email" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Filter (eq, neq, gt, lt, gte, lte, like, ilike, in, is)
curl -s "$SUPABASE_PROJECT_URL/rest/v1/users?select=*&status=eq.active&age=gt.18" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Sort
curl -s "$SUPABASE_PROJECT_URL/rest/v1/users?select=*&order=created_at.desc&limit=10" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Full-text search
curl -s "$SUPABASE_PROJECT_URL/rest/v1/posts?select=*&title=fts.machine+learning" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Relations (foreign key joins)
curl -s "$SUPABASE_PROJECT_URL/rest/v1/posts?select=*,author:users(name,email)" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Count rows
curl -s "$SUPABASE_PROJECT_URL/rest/v1/users?select=count" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Prefer: count=exact"

# Pagination (offset-based)
curl -s "$SUPABASE_PROJECT_URL/rest/v1/users?select=*&limit=10&offset=20" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
```

## Database — Write

```bash
# Insert row(s)
curl -s -X POST "$SUPABASE_PROJECT_URL/rest/v1/users" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '[{"name":"Alice","email":"alice@example.com"}]'

# Update rows (matching filter)
curl -s -X PATCH "$SUPABASE_PROJECT_URL/rest/v1/users?id=eq.123" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"status":"inactive"}'

# Upsert (insert or update on conflict)
curl -s -X POST "$SUPABASE_PROJECT_URL/rest/v1/users" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=representation" \
  -d '[{"id":123,"name":"Alice Updated"}]'

# Delete rows
curl -s -X DELETE "$SUPABASE_PROJECT_URL/rest/v1/users?id=eq.123" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Call RPC function
curl -s -X POST "$SUPABASE_PROJECT_URL/rest/v1/rpc/my_function" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"arg1":"value1"}'
```

## Storage

```bash
# List buckets
curl -s "$SUPABASE_PROJECT_URL/storage/v1/bucket" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# List files in a bucket
curl -s -X POST "$SUPABASE_PROJECT_URL/storage/v1/object/list/my-bucket" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"prefix":"","limit":100}'

# Upload file
curl -s -X POST "$SUPABASE_PROJECT_URL/storage/v1/object/my-bucket/path/file.pdf" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/pdf" \
  --data-binary @file.pdf

# Download file
curl -s "$SUPABASE_PROJECT_URL/storage/v1/object/my-bucket/path/file.pdf" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -o file.pdf

# Get public URL (for public buckets)
echo "$SUPABASE_PROJECT_URL/storage/v1/object/public/my-bucket/path/file.pdf"

# Delete file
curl -s -X DELETE "$SUPABASE_PROJECT_URL/storage/v1/object/my-bucket/path/file.pdf" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
```

## Auth (user management)

```bash
# List users
curl -s "$SUPABASE_PROJECT_URL/auth/v1/admin/users" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Get user by ID
curl -s "$SUPABASE_PROJECT_URL/auth/v1/admin/users/{user_id}" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"

# Create user
curl -s -X POST "$SUPABASE_PROJECT_URL/auth/v1/admin/users" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"securepass","email_confirm":true}'

# Delete user
curl -s -X DELETE "$SUPABASE_PROJECT_URL/auth/v1/admin/users/{user_id}" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
```

## Edge Functions

```bash
# Invoke an edge function
curl -s -X POST "$SUPABASE_PROJECT_URL/functions/v1/{function_name}" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key":"value"}'
```

## PostgREST filter operators

| Operator | Meaning | Example |
|---|---|---|
| `eq` | Equals | `?status=eq.active` |
| `neq` | Not equals | `?status=neq.deleted` |
| `gt`, `gte` | Greater than (or equal) | `?age=gt.18` |
| `lt`, `lte` | Less than (or equal) | `?price=lt.100` |
| `like` | Pattern match (case-sensitive) | `?name=like.*alice*` |
| `ilike` | Pattern match (case-insensitive) | `?name=ilike.*alice*` |
| `in` | In list | `?id=in.(1,2,3)` |
| `is` | Is null/true/false | `?deleted_at=is.null` |
| `fts` | Full-text search | `?title=fts.machine+learning` |
| `not` | Negate | `?status=not.eq.deleted` |

## Tips

- **OAuth token** — access level depends on scopes granted. May not bypass RLS like the service_role key does.
- **Both headers required**: `apikey` and `Authorization: Bearer` must both contain the key.
- **`Prefer: return=representation`** on POST/PATCH/DELETE returns the affected rows.
- **Relations**: Use `select=*,relation_name(columns)` for joins via foreign keys.
- **RPC**: Call Postgres functions via `/rest/v1/rpc/{function_name}`.
- **Discover tables**: `GET /rest/v1/` returns the OpenAPI spec listing all tables and their columns.

---

*Extracted from [vm0-ai/vm0-skills/supabase](https://skills.sh/vm0-ai/vm0-skills/supabase), [Supabase PostgREST docs](https://supabase.com/docs/guides/api), [Supabase MCP docs](https://supabase.com/docs/guides/getting-started/mcp), and [Supabase Storage API](https://supabase.com/docs/guides/storage).*
