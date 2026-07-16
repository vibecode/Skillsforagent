# GAQL reporting notes

Google Ads Query Language uses a `SELECT ... FROM ... WHERE ...` shape. Select
fields that belong to one compatible resource and keep date windows explicit.

Useful starting resources:

- `customer` for account identity, currency, time zone, manager, and test status
- `customer_client` for account hierarchy discovery (query each nested manager;
  one manager query returns only that manager and its direct clients)
- `campaign` for campaign settings and campaign-level metrics
- `ad_group` for ad-group settings and metrics
- `ad_group_ad` for ad performance
- `search_term_view` for search terms and their performance
- `keyword_view` for keyword metrics

Common metrics:

- `metrics.impressions`
- `metrics.clicks`
- `metrics.ctr`
- `metrics.average_cpc`
- `metrics.cost_micros` (divide by 1,000,000)
- `metrics.conversions`
- `metrics.conversions_value`

Prefer a bounded date range such as `segments.date DURING LAST_7_DAYS` or
`LAST_30_DAYS`. The CLI appends `LIMIT 100` when the query has no limit and
rejects limits above 100. It sends the request through Chorus's generic
integration proxy, which independently validates the read-only path and body.

Do not attempt GAQL mutation statements. Google Ads writes use separate mutate
endpoints and are intentionally unavailable in this skill version.
