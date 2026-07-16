---
name: meta-ads
display_name: Meta Ads
description: >
  Inspect connected Meta Ads accounts through the installed read-only CLI.
  Consult this skill: 1. When the user asks about Meta Ads, Facebook Ads,
  Instagram Ads, Ads Manager, campaigns, ad sets, ads, spend, impressions,
  clicks, CTR, CPC, CPM, conversions, CPA, ROAS, or performance. 2. When the
  user needs ad-account or Business Portfolio discovery. 3. When a Meta Ads
  connection or permission needs verification or in-place reconnection. 4.
  When the user asks to create or mutate Meta Ads resources, so the current
  read-only boundary must be explained. The workflow never exposes OAuth
  credentials.
provider_skill: true
integration_dependencies:
  - meta-ads
metadata: {"openclaw": {"emoji": "📊"}}
---

# Meta Ads

Use the installed CLI for Meta Ads work. Chorus keeps the user OAuth grant in
Nango and sends requests through the backend integration proxy. The agent
runtime receives no Meta access token or application secret. Never ask the
user to paste credentials or inspect the environment for them.

```bash
META_ADS_CLI="${CHORUS_DATA_DIR:-/home/vibecode/.chorus}/skills/meta-ads/scripts/meta_ads.ts"
bun "$META_ADS_CLI" status
```

## Connection workflow

Run `status` before the first API call in a task.

- If `connected` is false, run this once and return the capability link exactly
  as printed:

  ```bash
  masterclaw connections ensure --provider meta-ads
  ```

  Stop after returning the link. The user must complete Meta authorization.
- If `connected` is true, continue with account discovery.
- If Meta says the token expired or was invalidated, ask the user to reconnect
  Meta Ads in Chorus. Do not ask them for a token.
- Reconnect reauthorizes the existing Nango connection in place. It does not
  delete the connection or unlink it from any Chorus agent. Never tell the user
  to disconnect/delete first, and never claim that reconnect removes another
  agent's link. If an invalid credential is shared by multiple agents, those
  agents may be temporarily unable to use it until the in-place reconnect
  finishes, but their links remain intact.

## Read-only commands

List accessible ad accounts:

```bash
bun "$META_ADS_CLI" accounts
```

For another page, use the opaque cursor returned as `nextCursor`:

```bash
bun "$META_ADS_CLI" accounts --after '<nextCursor>'
```

Discover Business Portfolios and their owned or client ad accounts when the
connection includes Meta's `business_management` permission:

```bash
bun "$META_ADS_CLI" businesses
bun "$META_ADS_CLI" business-accounts --business-id 123456789 --relationship owned
bun "$META_ADS_CLI" business-accounts --business-id 123456789 --relationship client
```

If Meta rejects these commands for missing permissions, continue with
`accounts`; do not imply that an accessible ad account is inaccessible merely
because Business Portfolio discovery is unavailable.

If Business Portfolio discovery reports missing `business_management`:

- Explain that `accounts` shows ad accounts directly available to the connected
  Meta user, while `businesses` and `business-accounts` enumerate Business
  Portfolio ownership or partner relationships.
- Do not conclude that the user's Business Portfolio or organization accounts
  do not exist.
- A Chorus administrator must add `business_management` to the Nango Meta
  Marketing API integration scopes. The user must then use **Reconnect** on the
  existing Meta Ads connection so Meta can grant the expanded scope.
- Reconnect is in place and preserves every existing agent link. Do not use a
  delete, disconnect, unlink, or replacement flow for scope expansion.

List campaigns, ad sets, or ads for one account:

```bash
bun "$META_ADS_CLI" campaigns --account-id act_123456789
bun "$META_ADS_CLI" adsets --account-id act_123456789
bun "$META_ADS_CLI" ads --account-id act_123456789
```

Run a bounded performance report. The default level is `campaign`; valid
levels are `account`, `campaign`, `adset`, and `ad`:

```bash
bun "$META_ADS_CLI" insights \
  --account-id act_123456789 \
  --level campaign \
  --date-preset last_30d
```

Use a custom inclusive range of at most 90 days instead of a preset:

```bash
bun "$META_ADS_CLI" insights \
  --account-id act_123456789 \
  --level adset \
  --since 2026-06-15 \
  --until 2026-07-13
```

Every list is capped at 100 objects per call. If `nextCursor` is non-null,
repeat the same command with `--after '<nextCursor>'` until it is null or the
requested analysis has enough evidence.

## Reporting semantics

- Meta Business Portfolios can own or receive partner access to ad accounts;
  they are not a Google-style manager-account hierarchy.
- Monetary values such as `spend`, `cpc`, and `cpm` are strings in the ad
  account currency. Preserve the account currency in explanations.
- `actions`, `cost_per_action_type`, and `action_values` are arrays keyed by
  `action_type`. Do not add unrelated action types into a generic conversion
  total. State the action type used for conversions or CPA.
- Prefer Meta's returned `ctr`, `cpc`, `cpm`, and cost-per-action values. If you
  calculate a metric, state the formula and handle zero denominators.
- Read `references/marketing-api.md` before interpreting conversion or ROAS
  fields beyond the basic examples.

## Safety boundary

- This version is read-only. Do not imply that a campaign, budget, ad set, ad,
  audience, creative, or status was changed.
- Do not call Graph API with ad-hoc `curl`. The wrapper uses `masterclaw
  integrations request`; Chorus owns authorization, API versioning, allowlists,
  response bounds, timeouts, and error redaction.
- Do not pass credentials as command-line flags or attempt to recover them from
  the runtime.
- Treat ad account IDs and pagination cursors as selectors, not credentials,
  while avoiding unnecessary disclosure.
- Report structured Meta error codes and request IDs without exposing headers,
  tokens, or raw authorization responses.
