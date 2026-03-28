---
name: vibecode-integration-cloudflare
description: >
  Cloudflare API for managing DNS, zones, Workers, tunnels, and security settings.
  Consult this skill:
  1. When the user asks to manage DNS records or domains
  2. When the user needs to deploy or manage Cloudflare Workers
  3. When the user wants to manage tunnels, firewall rules, or security settings
  4. When the user mentions Cloudflare, DNS, CDN, or edge computing
metadata: {"openclaw": {"emoji": "☁️", "requires": {"env": ["CLOUDFLARE_API_TOKEN"]}}}
---

# Cloudflare Integration

REST API v4 for zones, DNS, Workers, Pages, tunnels, and security.

**Auth**: Bearer token via `CLOUDFLARE_API_TOKEN`.
**Base URL**: `https://api.cloudflare.com/client/v4`

```bash
CF="https://api.cloudflare.com/client/v4"

curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" "$CF/<endpoint>"
```

## Zones (domains)

```bash
# List zones
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" "$CF/zones?per_page=20"

# Search zone by name
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" "$CF/zones?name=example.com"

# Get zone details
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" "$CF/zones/{zoneId}"
```

## DNS records

```bash
# List DNS records for a zone
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" "$CF/zones/{zoneId}/dns_records?per_page=50"

# Search DNS records
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" "$CF/zones/{zoneId}/dns_records?name=app.example.com"

# Create DNS record
curl -s -X POST -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" \
  "$CF/zones/{zoneId}/dns_records" \
  -d '{"type":"A","name":"app","content":"1.2.3.4","ttl":1,"proxied":true}'

# Create CNAME
curl -s -X POST -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" \
  "$CF/zones/{zoneId}/dns_records" \
  -d '{"type":"CNAME","name":"www","content":"example.com","ttl":1,"proxied":true}'

# Update DNS record
curl -s -X PATCH -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" \
  "$CF/zones/{zoneId}/dns_records/{recordId}" \
  -d '{"content":"5.6.7.8"}'

# Delete DNS record
curl -s -X DELETE -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/zones/{zoneId}/dns_records/{recordId}"
```

## Workers

```bash
# List Workers
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/accounts/{accountId}/workers/scripts"

# Get Worker script
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/accounts/{accountId}/workers/scripts/{scriptName}"

# Deploy Worker
curl -s -X PUT -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/javascript" \
  "$CF/accounts/{accountId}/workers/scripts/{scriptName}" \
  --data-binary @worker.js

# List Worker routes
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/zones/{zoneId}/workers/routes"
```

## Tunnels

```bash
# List tunnels
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/accounts/{accountId}/cfd_tunnel"

# Get tunnel details
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/accounts/{accountId}/cfd_tunnel/{tunnelId}"
```

## Firewall / WAF

```bash
# List firewall rules
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/zones/{zoneId}/firewall/rules"

# List WAF custom rules
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/zones/{zoneId}/rulesets"
```

## Cache

```bash
# Purge everything
curl -s -X POST -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" \
  "$CF/zones/{zoneId}/purge_cache" \
  -d '{"purge_everything":true}'

# Purge specific URLs
curl -s -X POST -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" \
  "$CF/zones/{zoneId}/purge_cache" \
  -d '{"files":["https://example.com/styles.css","https://example.com/app.js"]}'
```

## Analytics

```bash
# Zone analytics
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "$CF/zones/{zoneId}/analytics/dashboard?since=-1440&until=0"
```

## Tips

- **Get zone ID first** — list zones, find the one matching the domain.
- **`proxied: true`** means traffic goes through Cloudflare (orange cloud). `false` = DNS only (grey cloud).
- **`ttl: 1`** means automatic TTL (when proxied).
- **Account ID** needed for Workers, Pages, Tunnels — find it in Cloudflare dashboard URL or zone details.
- **Pagination**: `per_page` (max 100) + `page` params.
- **Official skill**: Cloudflare publishes a first-party skill at [cloudflare/skills](https://skills.sh/cloudflare/skills/cloudflare).

---

*Based on [cloudflare/skills/cloudflare](https://skills.sh/cloudflare/skills/cloudflare), [lucassynnott/cloudflare-api](https://skills.sh/lucassynnott/cloudflare-api), and [Cloudflare API Reference](https://developers.cloudflare.com/api/).*
