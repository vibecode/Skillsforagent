---
name: vibecode-integration-supabase
display_name: Supabase
provider_skill: true
integration_dependencies:
  - supabase
description: >
  Supabase integration for database CRUD, storage, auth, and edge functions on
  a single Supabase project. Consult this skill:
  1. When the user asks to query, insert, or manage data in their Supabase database
  2. When the user needs to manage storage buckets or files
  3. When the user wants to invoke edge functions or manage auth users
  4. When the user mentions Supabase, Postgres, their database, or their backend
metadata: {"openclaw": {"emoji": "⚡", "requires": {"env": ["SUPABASE_ACCESS_TOKEN", "SUPABASE_PROJECT_URL"]}}}
---

# Supabase Integration

Project-scoped access to one Supabase project via PostgREST, Storage, Auth admin, and Edge Functions.

## Scope & Limitations — read this first

This connection uses a **project API key** (anon or service_role) and is scoped to exactly **one project**: `$SUPABASE_PROJECT_URL`.

**What you CAN do** (all against `$SUPABASE_PROJECT_URL/*`):
- Query / insert / update / delete table rows via PostgREST
- Read and write storage buckets and files
- Call RPC Postgres functions
- Manage auth users (only with service_role key)
- Invoke edge functions

**What you CANNOT do with this integration**:
- List projects across the user's Supabase account
- Create, rename, delete, or pause projects
- Read organization info, billing, or team members
- Any `api.supabase.com/v1/*` (Management API) call

The Management API requires a Personal Access Token (PAT) generated at `supabase.com/dashboard/account/tokens` — **that is a different token type that this integration does not capture**. If the user asks to "list my Supabase projects" or similar account-level operations, tell them this integration is project-scoped and they'd need a PAT for account-wide operations (not supported today).

## Auth model

- `SUPABASE_ACCESS_TOKEN` is a project API key (anon or service_role).
- `SUPABASE_PROJECT_URL` is the project endpoint, e.g. `https://<project-ref>.supabase.co`.
- Both `apikey` and `Authorization: Bearer` headers must be sent with the same token value for PostgREST and Storage.
- **Anon key**: respects Row Level Security (RLS). If a table has RLS enabled and no policy matches the anonymous role, queries return zero rows — the table is not empty, you just can't see it. This is the most common reason for "no tables visible" despite a successful connection.
- **Service_role key**: bypasses RLS, sees everything. Required for `/auth/v1/admin/*` endpoints. Keep secret.
- If queries return empty and you suspect RLS, ask the user to either add an RLS policy or reconnect with the service_role key.

```bash
# All PostgREST requests (database CRUD)
curl -s "$SUPABASE_PROJECT_URL/rest/v1/<table>" \
  -H "apikey: $SUPABASE_ACCESS_TOKEN" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

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

# Discover tables + columns (OpenAPI spec)
curl -s "$SUPABASE_PROJECT_URL/rest/v1/" \
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

## Auth (user management — requires service_role key)

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

## Troubleshooting

- **"No tables visible" / queries return zero rows** — almost always RLS with an anon key. Ask the user to reconnect with the service_role key, or add an RLS policy allowing the anon role.
- **401 Unauthorized** — token/URL mismatch, or the key was regenerated in Supabase. Reconnect.
- **403 Forbidden on `/auth/v1/admin/*`** — that path requires service_role, not anon. Reconnect with service_role.
- **404 on `api.supabase.com/v1/projects`** — this integration does not include Management API. See "Scope & Limitations" above.
- **`Prefer: return=representation`** on POST/PATCH/DELETE returns the affected rows; without it you get a 201 with empty body.
- **Relations**: Use `select=*,relation_name(columns)` for joins via foreign keys.
- **RPC**: Call Postgres functions via `/rest/v1/rpc/{function_name}`.

---

*Extracted from [Supabase PostgREST docs](https://supabase.com/docs/guides/api), [Supabase Storage API](https://supabase.com/docs/guides/storage), and [Supabase Auth Admin API](https://supabase.com/docs/reference/api/auth-admin).*
