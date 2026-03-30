---
name: vibecode-integration-snowflake
display_name: Snowflake
provider_skill: true
integration_dependencies:
  - snowflake
description: >
  Snowflake SQL API for querying data warehouses, managing databases, and running analytics.
  Consult this skill:
metadata: {"openclaw": {"emoji": "❄️", "requires": {"env": ["SNOWFLAKE_ACCESS_TOKEN", "SNOWFLAKE_ACCOUNT_URL"]}}}
  2. When the user needs to list databases, schemas, tables, or views
  3. When the user wants to run analytics queries or check warehouse status
  4. When the user mentions Snowflake, data warehouse, or SQL queries on their data
metadata: {"openclaw": {"emoji": "❄️", "requires": {"env": ["SNOWFLAKE_ACCESS_TOKEN"]}}}
---

# Snowflake Integration

SQL API for executing queries, managing databases, and running analytics against Snowflake data warehouses.

**Auth**: Bearer token via `SNOWFLAKE_ACCESS_TOKEN` (JWT via Nango).
**Base URL**: `${SNOWFLAKE_ACCOUNT_URL}/api/v2`

```bash
SF_BASE="${SNOWFLAKE_ACCOUNT_URL}/api/v2"

curl -s -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/<endpoint>"
```

## Execute SQL statements

```bash
# Submit a SQL statement
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"SELECT * FROM my_database.my_schema.my_table LIMIT 20","timeout":60,"database":"MY_DATABASE","schema":"MY_SCHEMA","warehouse":"MY_WAREHOUSE"}'

# Simple query
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"SELECT current_user(), current_role(), current_warehouse()","timeout":30}'

# List databases
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"SHOW DATABASES","timeout":30}'

# List schemas in a database
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"SHOW SCHEMAS IN DATABASE my_database","timeout":30}'

# List tables in a schema
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"SHOW TABLES IN my_database.my_schema","timeout":30}'

# Describe a table
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"DESCRIBE TABLE my_database.my_schema.my_table","timeout":30}'

# Aggregation query
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"SELECT DATE_TRUNC('\''day'\'', created_at) as day, COUNT(*) as cnt FROM my_table WHERE created_at > DATEADD(day, -7, CURRENT_TIMESTAMP()) GROUP BY 1 ORDER BY 1","timeout":60,"database":"MY_DATABASE","schema":"MY_SCHEMA","warehouse":"MY_WAREHOUSE"}'
```

## Check statement status

```bash
# Get statement status / results (for async queries)
curl -s -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements/{statementHandle}"

# Cancel a running statement
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements/{statementHandle}/cancel"
```

## Warehouse management

```bash
# List warehouses
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"SHOW WAREHOUSES","timeout":30}'

# Resume a warehouse
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"ALTER WAREHOUSE MY_WAREHOUSE RESUME","timeout":30}'

# Suspend a warehouse
curl -s -X POST -H "Authorization: Bearer $SNOWFLAKE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT" \
  "$SF_BASE/statements" \
  -d '{"statement":"ALTER WAREHOUSE MY_WAREHOUSE SUSPEND","timeout":30}'
```

## Tips

- **All queries go through `/api/v2/statements`** — there's one endpoint for all SQL operations.
- **`X-Snowflake-Authorization-Token-Type: KEYPAIR_JWT`** header is required for JWT auth.
- **`SNOWFLAKE_ACCOUNT_URL`** is the account URL (e.g., `https://abc123.snowflakecomputing.com`).
- **Specify `database`, `schema`, `warehouse`** in the request body or use fully qualified table names.
- **Async queries**: Statements return a `statementHandle`. Poll `GET /statements/{handle}` until `status` is `SUCCEEDED`.
- **Result pagination**: Large results include `resultSetMetaData.partitionInfo`. Fetch partitions via `GET /statements/{handle}?partition={n}`.
- **Single quotes in SQL**: Escape with `'\''` in bash, or use `$$` quoting for complex strings.
- **Read-only recommended**: Use a read-only role/warehouse for safety unless writes are explicitly requested.

---

*Based on [jezweb/snowflake-platform](https://skills.sh/jezweb/claude-skills/snowflake-platform), [Snowflake SQL API Reference](https://docs.snowflake.com/en/developer-guide/sql-api/about-endpoints), and [Nango Snowflake JWT integration](https://nango.dev/docs/integrations/all/snowflake-jwt).*
