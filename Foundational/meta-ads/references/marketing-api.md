# Meta Marketing API reporting reference

Use this reference when interpreting Meta Ads insight rows.

## Object levels

- `account`: one aggregate row for the selected ad account.
- `campaign`: campaign-level rows and campaign identifiers.
- `adset`: ad-set rows with both campaign and ad-set identifiers.
- `ad`: individual-ad rows with campaign, ad-set, and ad identifiers.

The CLI requests identification fields for every supported level, so group and
label results using the most specific populated ID and name.

Business Portfolio discovery uses `me/businesses`, `owned_ad_accounts`, and
`client_ad_accounts` and requires the `business_management` permission. Basic
ad-account discovery uses `me/adaccounts` with `ads_read`.

## Metrics

- `spend`: account-currency amount spent during the requested date range.
- `impressions`: delivered impressions.
- `reach`: estimated unique people reached.
- `frequency`: average impressions per reached person.
- `clicks`: all clicks attributed by Meta.
- `inline_link_clicks`: link clicks within the ad.
- `ctr`, `cpc`, `cpm`: Meta-computed click-through rate, cost per click, and
  cost per thousand impressions.
- `actions`: counts grouped by `action_type`.
- `cost_per_action_type`: cost values grouped by `action_type`.
- `action_values`: attributed value grouped by `action_type`.
- `purchase_roas`: purchase return on ad spend grouped by `action_type`.

## Conversion discipline

There is no universally correct single conversion count. Pick an action type
that matches the user's business outcome, such as a purchase or lead, and name
it in the answer. Do not sum overlapping action types. When the intended action
is ambiguous, show the relevant action types separately.

Use a matching entry in `cost_per_action_type` for CPA when available. If it is
absent and calculation is necessary, divide spend by the selected action count
and label the result as calculated. Never divide by zero.

ROAS is also action-type specific. Use `purchase_roas` only for purchase
analysis and preserve Meta's attribution semantics; do not present it as
finance-ledger revenue.

## Pagination and bounds

The backend accepts at most 100 rows per request and reports at most 90 days for
custom ranges. Follow `nextCursor` only as far as needed for the user's task.
The CLI intentionally discards Graph API `next` and `previous` URLs so tokens
embedded by upstream responses cannot enter model context.

## Campaign mutation semantics

- Meta creates campaigns with `POST /act_{ad_account_id}/campaigns` and updates
  them with `POST /{campaign_id}`.
- `special_ad_categories` is required when creating a campaign. Although Meta
  accepts an empty array for no special category, Chorus requires the explicit
  `NONE` value so the classification cannot be omitted accidentally. It must
  not be mixed with another category.
- The CLI forces every newly created campaign to `PAUSED`. Activation is a
  separate update because it can begin spending.
- Meta's `execution_options=["validate_only"]` validates a mutation without
  applying it. Every Chorus mutation plan uses this before asking for approval.
- Daily budget, lifetime budget, and spend cap are expressed as integer account
  currency subunits. Campaign-level daily and lifetime budgets are mutually
  exclusive.
- Updating a campaign supports only the fields explicitly exposed by the CLI.
  Deletion is intentionally unsupported.
