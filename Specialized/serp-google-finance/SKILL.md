---
name: serp-google-finance
display_name: Google Finance
description: >
  Specialized skill for Google Finance workflows via SerpApi — stock quotes, crypto prices,
  currency conversion, mutual fund details, price history, news, financials, and market movers.
  Use when: (1) looking up a stock quote (price, change, market cap, P/E), (2) checking crypto
  prices (BTC-USD, ETH-USD, etc.), (3) converting between currencies or pulling FX rates,
  (4) researching mutual funds or ETFs by ticker, (5) pulling price history across time windows
  (1D, 5D, 1M, 6M, YTD, 1Y, 5Y, MAX), (6) gathering news for a ticker or company,
  (7) reading financials (income statement, balance sheet, cash flow), (8) comparing multiple
  tickers side by side, (9) getting market overview — indexes, top gainers, losers, most active,
  (10) discovering related stocks or peer companies, (11) tracking key corporate events with
  price impact, (12) any task involving stock, crypto, currency, or futures quote data.
  This skill builds on the foundational serpapi skill for all API details.
dependencies:
  - serpapi
metadata: {"openclaw": {"emoji": "💹"}}
---

# Google Finance Workflows

Stock, crypto, currency, mutual fund, and market data via SerpApi's Google Finance engines. This skill covers workflow logic — load the **serpapi** foundational skill for API details, parameters, and wrapper script usage.

## Dependencies

This skill builds on:
- **serpapi** — SerpApi wrapper script and full API reference (engines: `google_finance`, `google_finance_markets`)

## Core Concepts

### Query Format

The `q` parameter uses `TICKER:EXCHANGE` for stocks and indexes, and `BASE-QUOTE` for crypto and FX pairs.

| Asset Type | Format | Example |
|---|---|---|
| US stock (NASDAQ) | `TICKER:NASDAQ` | `GOOGL:NASDAQ`, `AAPL:NASDAQ` |
| US stock (NYSE) | `TICKER:NYSE` | `WMT:NYSE`, `JPM:NYSE` |
| OTC stock | `TICKER:OTCMKTS` | `NSRGY:OTCMKTS` |
| Mutual fund | `TICKER:MUTF` | `VFIAX:MUTF`, `FXAIX:MUTF` |
| Index (US) | `TICKER:INDEXDJX` / `INDEXSP` / `INDEXNASDAQ` | `.DJI:INDEXDJX`, `.INX:INDEXSP` |
| Index (intl) | `TICKER:INDEXNIKKEI` / `INDEXFTSE` / etc. | `NI225:INDEXNIKKEI` |
| Crypto | `BASE-QUOTE` | `BTC-USD`, `ETH-USD`, `SOL-USD` |
| Currency pair | `BASE-QUOTE` | `EUR-USD`, `USD-JPY`, `GBP-EUR` |
| Futures | `TICKER:CBOT` (or relevant futures exchange) | `ZC:CBOT` (corn) |

**Tip:** If you don't know the exchange, search without the suffix first — Google Finance often resolves common tickers (`AAPL`, `BTC-USD`) without one. For ambiguous tickers, always include the exchange.

### Time Windows

The `window` parameter controls the price-history range returned in `graph`:

| Value | Range |
|---|---|
| `1D` | One trading day (intraday) |
| `5D` | Five trading days |
| `1M` | One month |
| `6M` | Six months |
| `YTD` | Year to date |
| `1Y` | One year (default) |
| `5Y` | Five years |
| `MAX` | All available history |

### Response Structure (`google_finance`)

| Section | Contents |
|---|---|
| `summary` | `title`, `stock`, `exchange`, `price`, `extracted_price`, `currency`, `price_movement` (`percentage`, `value`, `movement`), `date`, `market` (after-hours snapshot), `extensions` |
| `graph[]` | Time-series points: `price`, `currency`, `date`, `volume`, optional `key_event` |
| `markets` | Sibling-market snapshot: `us`, `europe`, `asia`, `currencies`, `crypto`, `futures`, `top_news` |
| `knowledge_graph` | `about[]` (description, info pairs), `key_stats` (`tags[]`, `stats[]` with label/description/value), `climate_change` (`score`, `link`) |
| `news_results[]` | Categorized news. Each category has `title` + `items[]` (`snippet`, `link`, `source`, `date`, optional `thumbnail`) |
| `financials[]` | Income Statement / Balance Sheet / Cash Flow. Each has `results[]` with `date`, `period_type`, `table[]` (`title`, `description`, `value`, `change`) |
| `key_events[]` | Corporate events: `title`, `link`, `source`, `source_date`, `date`, `price_movement` |
| `discover_more[]` | Related/peer assets grouped by category, with `stock`, `name`, `price`, `extracted_price`, `currency`, `price_movement`, `link` |
| `futures_chain` | Present for futures queries — chain of related contracts |
| `suggestions` | Returned when the query yields no direct match |

### Response Structure (`google_finance_markets`)

| Section | Contents |
|---|---|
| `market_trends[]` | Region-grouped lists (US / Europe / Asia, etc.) with `stock`, `name`, `price`, `extracted_price`, `currency`, `price_movement`, `link` |
| `markets` | Same shape as in `google_finance` — overview across `us`, `europe`, `asia`, `currencies`, `crypto`, `futures` |
| `news_results` | Financial news headlines |
| `discover_more` | Related categories and assets |

### Price Movement

`price_movement` appears throughout the response with three fields:
- `percentage` — Numeric percent change
- `value` — Absolute change in the asset's currency
- `movement` — `"Up"` or `"Down"` (sign indicator)

Always render the sign explicitly (`+1.4%` / `-2.7%`) — the raw numbers may not include it.

## Workflows

### 1. Stock Quote Lookup

Use the **serpapi** wrapper with engine `google_finance` and `q=TICKER:EXCHANGE`.

**Extract from `summary`:**
- `price` + `currency` — current price
- `price_movement.percentage` + `.movement` — daily change
- `extensions` — trading session info (e.g., "Closed: Jan 5, 4:00 PM EST")
- `market` — after-hours / pre-market price if active

**Extract from `knowledge_graph.key_stats.stats`:**
- Market cap, P/E ratio, dividend yield, 52-wk range, EPS, beta, volume, etc.

**Presentation pattern** (see "Ticker Summary Card" below).

### 2. Crypto Quote

Same engine, but `q=BTC-USD` (no exchange suffix). The response shape is identical to a stock.

- `summary.price` — Current price (often USD)
- `graph` — Use `window=1D` for intraday, `window=1Y` for context
- `discover_more` — Lists related crypto (ETH, SOL, etc.) for portfolio context

**Tip:** Crypto trades 24/7, so `summary.market` (after-hours) is usually absent — use only `summary` for live price.

### 3. Currency Conversion / FX Rates

Query `BASE-QUOTE` (e.g., `EUR-USD`). `summary.extracted_price` is the exchange rate (1 BASE = X QUOTE).

**For a conversion:**
1. Fetch `EUR-USD` → multiply user's EUR amount by `extracted_price`
2. For inverse, fetch `USD-EUR` directly rather than computing `1/rate` (Google's quote may differ slightly)
3. Use `window=5D` or `1M` to show recent trend

### 4. Mutual Fund / ETF Lookup

Use `TICKER:MUTF` for mutual funds (e.g., `VFIAX:MUTF`) and standard `TICKER:NASDAQ`/`:NYSE` for ETFs (`VOO:NYSE`, `QQQ:NASDAQ`).

- `summary.price` — NAV (mutual funds price once per day at close)
- `knowledge_graph.key_stats` — Expense ratio, AUM, category, yield
- `financials` — Often empty for funds; rely on `knowledge_graph` instead

### 5. Price History Across Time Windows

Fetch the same ticker multiple times varying `window` to build a multi-horizon view.

**Strategy:**
- `window=1D` → intraday candles (volatility today)
- `window=1M` → recent trend
- `window=1Y` → annual performance
- `window=5Y` → long-term shape

**Each `graph[]` item:** `date`, `price`, `volume`. Use `volume` to spot unusual trading days. Watch for `key_event` markers — Google flags earnings, splits, and major news inline.

### 6. News for a Ticker

`news_results[]` is already included in a standard `google_finance` query — no separate call needed.

**Structure:**
- Top-level: array of categories (each with `title` and `items[]`)
- Items: `snippet`, `link`, `source`, `date`, optional `thumbnail`

**Presentation:** Group by category, sort items by `date` (most recent first), present 5-10 headlines with source and snippet.

### 7. Financials (Income / Balance / Cash Flow)

`financials[]` contains three statement types. Each statement has `results[]` for multiple reporting periods.

| Statement | Key Line Items (`table[].title`) |
|---|---|
| Income Statement | Revenue, Cost of revenue, Gross profit, Operating income, Net income, EPS |
| Balance Sheet | Cash & equivalents, Total assets, Total liabilities, Total equity |
| Cash Flow | Operating cash flow, Investing cash flow, Financing cash flow, Free cash flow |

**Each row:** `title`, `description`, `value`, `change` (YoY or QoQ percent).

**Period selection:** Each `results[]` entry has `period_type` (`annual` / `quarterly`) and `date`. Filter to the period the user asked about.

### 8. Comparing Multiple Tickers

Run separate searches for each ticker (no batch endpoint), then assemble a comparison table.

**Strategy:**
1. Fetch each ticker with `window=1Y` (or whatever horizon the user cares about)
2. Pull from `summary`: price, % change, currency
3. Pull from `knowledge_graph.key_stats`: market cap, P/E, dividend yield
4. Optionally compute relative performance over the window from `graph[0]` vs `graph[-1]`

**Presentation pattern:** Table with one column per ticker, rows for price, daily change, YTD/1Y return, market cap, P/E, yield.

### 9. Market Overview (Indexes, Gainers, Losers, Most Active)

Switch to the `google_finance_markets` engine. Set `trend` to one of:

| Trend Value | Returns |
|---|---|
| `indexes` | Major market indexes (Dow, S&P, Nasdaq, FTSE, Nikkei, etc.) |
| `most-active` | Highest-volume stocks today |
| `gainers` | Top % gainers |
| `losers` | Top % losers |
| `climate-leaders` | Companies leading on climate metrics |
| `cryptocurrencies` | Top crypto by market cap / activity |
| `currencies` | Major FX pairs |

**Region filter (indexes only):** `index_market` = `americas`, `europe-middle-east-africa`, or `asia-pacific`.

**Use cases:**
- "What's the market doing today?" → `trend=indexes`
- "Biggest movers?" → `trend=gainers` and `trend=losers`
- "Crypto market?" → `trend=cryptocurrencies`

### 10. Discovering Related Assets

`discover_more` (in both engines) groups related assets by theme — peer companies, sector siblings, similar crypto, etc.

**Use cases:**
- Building a watchlist around a single name
- Suggesting alternatives when the user is researching a sector
- Finding ETFs that hold a given stock (sometimes surfaced here)

### 11. Key Corporate Events

`key_events[]` flags corporate events that moved the price — earnings beats/misses, product launches, regulatory news, executive changes.

**Each event:** `title`, `source`, `source_date`, `date`, `price_movement` (showing the price reaction).

**Use case:** "Why did NVDA jump last quarter?" → scan `key_events` for the matching date, then pull the linked article.

## Presenting Results

### Ticker Summary Card

For a single ticker, present:

```
💹 [Title] ([STOCK:EXCHANGE]) — [Currency][Price]
   [+/-X.XX%] ([+/-Value]) [Up/Down] today
   [Trading session info from extensions]

📊 Key Stats:
   Market Cap: [value]   P/E: [value]
   52W Range:  [low]–[high]
   Dividend:   [yield]%
   Volume:     [today] (avg [N])

📈 Performance:
   1D: [+/-%]   1M: [+/-%]   YTD: [+/-%]   1Y: [+/-%]

📰 Latest News:
   1. [Source, date] — [headline snippet]
   2. ...
```

### Comparison Table

```
💹 Ticker Comparison

| Metric        | AAPL      | MSFT      | GOOGL     |
|---------------|-----------|-----------|-----------|
| Price         | $185.42   | $412.30   | $142.18   |
| Daily Change  | +1.2%     | -0.4%     | +2.1%     |
| 1Y Return     | +28.4%    | +14.2%    | +35.7%    |
| Market Cap    | $2.85T    | $3.06T    | $1.78T    |
| P/E           | 31.2      | 36.8      | 26.4      |
| Dividend      | 0.51%     | 0.73%     | —         |
```

### Market Overview

```
💹 Market Snapshot — [Date]

📊 Major Indexes:
   S&P 500   [Price]  [+/-%]
   Dow       [Price]  [+/-%]
   Nasdaq    [Price]  [+/-%]

📈 Top Gainers:
   1. [TICKER] [Name] — [Price] [+X.X%]
   2. ...

📉 Top Losers:
   1. [TICKER] [Name] — [Price] [-X.X%]
   ...
```

## Common Patterns

### "What's [Ticker] trading at?"
1. `google_finance` with `q=TICKER:EXCHANGE` (or just `TICKER` if common)
2. Present price, daily change, after-hours if active
3. Add 1-2 line context from `knowledge_graph.about[0].description`

### "How has [Ticker] performed this year?"
1. `google_finance` with `window=YTD`
2. Compute return: `(graph[-1].price - graph[0].price) / graph[0].price`
3. Note volatility, any `key_event` markers in the graph
4. Show YTD chart points + summary stat

### "Convert [Amount] [Currency A] to [Currency B]"
1. `google_finance` with `q=A-B`
2. Multiply amount by `summary.extracted_price`
3. Note the timestamp and trend (`window=5D`)

### "What's Bitcoin doing?"
1. `google_finance` with `q=BTC-USD`
2. Price, 24h change, 1M and 1Y trend
3. Use `discover_more` to surface ETH, SOL, etc.

### "Compare AAPL, MSFT, GOOGL"
1. Three separate `google_finance` calls
2. Assemble comparison table (see pattern above)
3. Highlight the winner per metric

### "What's the market doing today?"
1. `google_finance_markets` with `trend=indexes`
2. Then `trend=gainers` and `trend=losers` for color
3. Present index snapshot + top movers

### "Why did [Ticker] move?"
1. `google_finance` for the ticker
2. Scan `key_events[]` for recent dated entries with `price_movement`
3. Cross-reference with `news_results[]` for the same date

### "Show me revenue and earnings trend for [Ticker]"
1. `google_finance` for the ticker
2. Pull `financials[]` → Income Statement → `results[]`
3. Extract Revenue and Net Income rows across periods
4. Present as a YoY trend table

## Tips

- **Always include the exchange suffix for ambiguous tickers.** `F` alone is ambiguous; `F:NYSE` is Ford. `TSLA` is unique but `TSLA:NASDAQ` is unambiguous.
- **Crypto and FX use the hyphen format**, not colon-exchange: `BTC-USD`, `EUR-JPY`.
- **`extracted_price` is the numeric version** of `price` — use it for math, use `price` (formatted string) for display.
- **`price_movement.movement`** is the sign indicator (`Up`/`Down`). Don't infer sign from absolute values.
- **`window=1D` is intraday** — many data points, useful for volatility but noisy. Default to `1Y` for general analysis.
- **News is bundled, not separate.** A single `google_finance` call returns ticker-specific news in `news_results[]` — no need for a separate news search.
- **Financials may be missing** for foreign ADRs, recent IPOs, or non-corporate assets (crypto, FX). Don't assume they're present — check before referencing.
- **`key_events` is gold for context** — when the user asks why a stock moved, this is the first place to look.
- **Mutual funds price once per day** at NAV close. Don't expect intraday movement in `summary` or `graph` with `window=1D`.
- **`markets` (sibling sections)** in a `google_finance` response gives you a free market snapshot — no extra call needed for "and how's the market overall?"
- **`gl` is not a `google_finance` param** — it only applies to `google_finance_markets`. For language on the per-ticker engine, use `hl`.
- **`climate_change.score`** in `knowledge_graph` is Google's ESG/climate score where available — surface it when the user asks about sustainability.
- **`discover_more` is your peer-finder** — use it instead of inventing a peer list yourself.
- **Suggestions on miss:** If a query returns `suggestions` instead of `summary`, the ticker resolved ambiguously — present suggestions to the user and re-query with the exact stock identifier.
