---
name: google-ads
display_name: Google Ads
description: >
  Operate connected Google Ads accounts through the installed read-only CLI.
  Consult this skill: 1. When the user asks about Google Ads, Ads Manager,
  campaigns, ad groups, keywords, search terms, spend, conversions, ROAS, CPA,
  CTR, or performance reporting. 2. When the user needs direct or manager
  account discovery or a bounded GAQL report. 3. When a Google Ads connection
  is missing or needs verification. 4. When the user asks to create or mutate
  Google Ads resources, so the current read-only boundary must be explained.
  The workflow never exposes credentials.
provider_skill: true
integration_dependencies:
  - google-ads
metadata: {"openclaw": {"emoji": "📈"}}
---

# Google Ads

Use the installed CLI for Google Ads work. Chorus keeps user authorization in
Nango and adds platform credentials in the backend integration proxy. The
agent runtime receives neither credential. Never ask the user to paste tokens
or inspect the environment for Google Ads credentials.

```bash
GOOGLE_ADS_CLI="${CHORUS_DATA_DIR:-/home/vibecode/.chorus}/skills/google-ads/scripts/google_ads.ts"
bun "$GOOGLE_ADS_CLI" status
```

## Connection workflow

Run `status` before the first API call in a task.

- If `connected` is false, run this once and return the capability
  link exactly as printed:

  ```bash
  masterclaw connections ensure --provider google-ads
  ```

  Stop after returning the link. The user must complete Google authorization.
- If `connected` is true, continue with account discovery. The backend reports
  any platform-configuration problem during the first request; do not ask the
  user for an application credential.

## Read-only commands

List accounts directly accessible to the connected Google identity:

```bash
bun "$GOOGLE_ADS_CLI" accounts
```

List the bounded hierarchy beneath a directly accessible manager:

```bash
bun "$GOOGLE_ADS_CLI" accounts --login-customer-id 123-456-7890
```

The CLI follows nested manager accounts recursively. `immediateClients` contains
the selected manager's direct children and `descendants` contains the flattened
bounded hierarchy with `parentManagerCustomerId` and `hierarchyDepth`. If
`truncated` is true, say the hierarchy is partial rather than implying every
account was discovered.

Run one bounded GAQL report against a customer:

```bash
bun "$GOOGLE_ADS_CLI" report \
  --customer-id 123-456-7890 \
  --query 'SELECT campaign.id, campaign.name, metrics.cost_micros, metrics.conversions FROM campaign WHERE segments.date DURING LAST_30_DAYS'
```

When querying a client beneath a manager, add the manager ID:

```bash
bun "$GOOGLE_ADS_CLI" report \
  --customer-id 111-222-3333 \
  --login-customer-id 123-456-7890 \
  --query 'SELECT campaign.id, campaign.name, campaign.status, metrics.clicks, metrics.impressions FROM campaign WHERE segments.date DURING LAST_7_DAYS'
```

The CLI accepts only a single `SELECT`, rejects semicolons and multiple limits,
and caps each response at 100 rows. It prints JSON to stdout. Explain monetary
metrics such as `cost_micros` in normal currency units and preserve the account
currency code when it is available.

## Safety boundary

- This version is read-only. Do not imply that a campaign, budget, ad, keyword,
  or status was changed.
- Do not call Google Ads with ad-hoc `curl`; the wrapper uses
  `masterclaw integrations request`, while Chorus owns authorization, platform
  headers, timeout, query bounds, customer-ID normalization, and error
  redaction.
- Do not pass credentials as command-line flags or attempt to recover them from
  the runtime.
- Treat manager IDs and customer IDs as account selectors, not secrets.
- If Google returns an authorization or platform-configuration error, report
  the structured code and request ID without exposing headers or credentials.

Read `references/gaql.md` when constructing a report beyond the examples.
