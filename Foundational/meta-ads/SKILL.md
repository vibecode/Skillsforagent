---
name: meta-ads
display_name: Meta Ads
description: >
  Inspect connected Meta Ads accounts and safely create or update campaigns
  through the installed CLI. Consult this skill whenever the user asks about
  Meta Ads, Facebook Ads, Instagram
  Ads, Ads Manager, ad accounts, campaigns, ad sets, ads, spend, impressions,
  clicks, CTR, CPC, CPM, conversions, CPA, ROAS, or marketing performance—even
  if they do not explicitly ask for a Meta Ads skill. It discovers ad accounts
  and runs bounded Marketing API reports without exposing OAuth credentials.
  It supports approval-gated campaign creation, activation, pausing, renaming,
  and budget changes while keeping credentials out of the agent runtime.
provider_skill: true
integration_dependencies:
  - meta-ads
metadata: {"openclaw": {"emoji": "📊", "requires": {"bins": ["bun", "masterclaw"]}}}
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

## Reporting commands

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

## Campaign management

Campaign mutations use two phases because creating, activating, or changing a
budget affects an external system and may spend money:

1. Create a plan. The CLI sends Meta `execution_options=["validate_only"]`, so
   Meta validates the exact payload without changing the account. The CLI then
   stores an immutable plan for 30 minutes and prints its fields, plan ID, and
   approval phrase.
2. Show the complete plan to the user and wait for explicit approval. Do not
   treat an earlier general request to "manage my ads" as approval of a newly
   generated plan.
3. Only after the user approves that exact plan ID, apply it with the matching
   `--plan-id` and `--confirm` values. Applying consumes the plan so it cannot
   be replayed.

Create a campaign plan:

```bash
bun "$META_ADS_CLI" campaign-plan-create \
  --account-id act_123456789 \
  --name 'July product launch' \
  --objective OUTCOME_TRAFFIC \
  --special-ad-categories NONE \
  --daily-budget 20000
```

Budget values are positive integers in the ad account currency's smallest
unit. Confirm the account currency and restate the human-readable amount before
requesting approval. `--daily-budget` and `--lifetime-budget` are mutually
exclusive. New campaigns are always created `PAUSED`; activation requires a
separate approved update plan.

The special-ad-category classification is required. Never guess it. Ask the
user whether the campaign concerns employment, housing, credit, political or
social issues, online gambling/gaming, or financial products/services. Use
`NONE` only when the user confirms none apply.

Optional creation flags are `--lifetime-budget`, `--spend-cap`,
`--bid-strategy`, and `--adset-budget-sharing true|false`. If the objective,
special category, budget ownership, or bidding choice is unclear, ask before
planning.

Plan an update to an existing campaign:

```bash
bun "$META_ADS_CLI" campaign-plan-update \
  --campaign-id 987654321 \
  --status ACTIVE \
  --daily-budget 25000
```

Supported update fields are `--name`, `--status ACTIVE|PAUSED|ARCHIVED`,
`--daily-budget`, `--lifetime-budget`, and `--spend-cap`. Read the campaign and
account currency first so the plan includes the current state and an accurate
before/after explanation.

After the user explicitly says `Approve Meta Ads plan <planId>` or otherwise
unambiguously approves that displayed ID, apply it exactly once:

```bash
bun "$META_ADS_CLI" campaign-apply \
  --plan-id '<planId>' \
  --confirm '<planId>'
```

If the plan expired, validation failed, the user changed any field, or the
account state changed materially, generate a new plan and request approval
again. Never apply a different payload under an earlier approval.

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

- Reporting is read-only. Campaign creation and updates are available only
  through the plan/validate/approve/apply workflow above.
- Never apply a plan without explicit user approval of the exact plan ID.
- New campaigns must remain paused until a separate activation plan is
  approved. The current integration does not create ad sets, creatives, ads,
  audiences, or pixels; do not imply those were created.
- Do not call Graph API with ad-hoc `curl`. The wrapper uses `masterclaw
  integrations request`; Chorus owns authorization, API versioning, allowlists,
  response bounds, timeouts, and error redaction.
- Do not pass credentials as command-line flags or attempt to recover them from
  the runtime.
- Treat ad account IDs and pagination cursors as selectors, not credentials,
  while avoiding unnecessary disclosure.
- Report structured Meta error codes and request IDs without exposing headers,
  tokens, or raw authorization responses.
