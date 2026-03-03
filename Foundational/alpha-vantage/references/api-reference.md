# Alpha Vantage API Reference

Complete endpoint reference for all Alpha Vantage `function=` values. All requests are GET to `https://www.alphavantage.co/query` with `apikey` required on every call.

## Table of Contents

1. [Core Stock APIs](#core-stock-apis)
2. [Fundamental Data](#fundamental-data)
3. [Alpha Intelligence](#alpha-intelligence)
4. [Options Data](#options-data)
5. [Forex](#forex)
6. [Cryptocurrencies](#cryptocurrencies)
7. [Commodities](#commodities)
8. [Economic Indicators](#economic-indicators)
9. [Technical Indicators](#technical-indicators)

---

## Core Stock APIs

### TIME_SERIES_INTRADAY (Premium)

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `TIME_SERIES_INTRADAY` |
| symbol | Yes | Ticker symbol (e.g., `IBM`) |
| interval | Yes | `1min`, `5min`, `15min`, `30min`, `60min` |
| adjusted | No | `true` (default) or `false` for raw data |
| extended_hours | No | `true` (default) includes pre/post-market |
| month | No | `YYYY-MM` format, any month since 2000-01 |
| outputsize | No | `compact` (100 points, default) or `full` (30 days or full month) |
| datatype | No | `json` (default) or `csv` |
| entitlement | No | Not set=historical, `realtime`, `delayed` (15-min) |

### TIME_SERIES_DAILY

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `TIME_SERIES_DAILY` |
| symbol | Yes | Ticker (e.g., `IBM`, `TSCO.LON`, `600104.SHH`) |
| outputsize | No | `compact` (100 points, default) or `full` (20+ years, premium) |
| datatype | No | `json` (default) or `csv` |

### TIME_SERIES_DAILY_ADJUSTED (Premium)

Same as DAILY plus: returns adjusted close, split coefficient, dividend amount.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `TIME_SERIES_DAILY_ADJUSTED` |
| symbol | Yes | Ticker |
| outputsize | No | `compact` or `full` |
| datatype | No | `json` or `csv` |
| entitlement | No | Not set=historical, `realtime`, `delayed` |

### TIME_SERIES_WEEKLY / TIME_SERIES_WEEKLY_ADJUSTED

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `TIME_SERIES_WEEKLY` or `TIME_SERIES_WEEKLY_ADJUSTED` |
| symbol | Yes | Ticker |
| datatype | No | `json` or `csv` |

### TIME_SERIES_MONTHLY / TIME_SERIES_MONTHLY_ADJUSTED

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `TIME_SERIES_MONTHLY` or `TIME_SERIES_MONTHLY_ADJUSTED` |
| symbol | Yes | Ticker |
| datatype | No | `json` or `csv` |

### GLOBAL_QUOTE

Returns latest price, volume, change, change%.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `GLOBAL_QUOTE` |
| symbol | Yes | Ticker |
| datatype | No | `json` or `csv` |
| entitlement | No | Not set=historical, `realtime`, `delayed` |

### REALTIME_BULK_QUOTES (Premium)

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `REALTIME_BULK_QUOTES` |
| symbol | Yes | Comma-separated, up to 100 (e.g., `MSFT,AAPL,IBM`) |
| datatype | No | `json` or `csv` |

### SYMBOL_SEARCH

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `SYMBOL_SEARCH` |
| keywords | Yes | Search text (e.g., `microsoft`, `AAPL`) |
| datatype | No | `json` or `csv` |

### MARKET_STATUS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `MARKET_STATUS` |

No additional params. Returns global market open/close status for all exchanges.

---

## Fundamental Data

### OVERVIEW

Company overview: description, sector, market cap, PE ratio, EPS, dividend yield, 52-week range, analyst target price, etc.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `OVERVIEW` |
| symbol | Yes | Ticker |

### ETF_PROFILE

ETF details: holdings, sector weights, top holdings.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `ETF_PROFILE` |
| symbol | Yes | ETF ticker |

### Financial Statements

All return annual and quarterly reports:

| Function | Description |
|----------|-------------|
| `INCOME_STATEMENT` | Revenue, net income, operating income, EPS |
| `BALANCE_SHEET` | Assets, liabilities, equity |
| `CASH_FLOW` | Operating, investing, financing cash flows |

Parameters: `function`, `symbol` (both required).

### EARNINGS

Quarterly and annual EPS (reported vs estimated).

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `EARNINGS` |
| symbol | Yes | Ticker |

### EARNINGS_ESTIMATE

Forward-looking analyst EPS estimates.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `EARNINGS_ESTIMATE` |
| symbol | Yes | Ticker |

### DIVIDENDS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `DIVIDENDS` |
| symbol | Yes | Ticker |

### SPLITS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `SPLITS` |
| symbol | Yes | Ticker |

### SHARES_OUTSTANDING

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `SHARES_OUTSTANDING` |
| symbol | Yes | Ticker |

### LISTING_STATUS

Returns CSV of listed/delisted tickers.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `LISTING_STATUS` |
| date | No | `YYYY-MM-DD` for historical snapshot |
| state | No | `active` (default) or `delisted` |

### EARNINGS_CALENDAR

Returns CSV of upcoming earnings.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `EARNINGS_CALENDAR` |
| symbol | No | Filter by ticker |
| horizon | No | `3month` (default), `6month`, `12month` |

### IPO_CALENDAR

Returns CSV of upcoming IPOs. No additional params besides `function` and `apikey`.

---

## Alpha Intelligence

### NEWS_SENTIMENT

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `NEWS_SENTIMENT` |
| tickers | No | Comma-separated tickers; prefix crypto with `CRYPTO:`, forex with `FOREX:` |
| topics | No | Comma-separated: `blockchain`, `earnings`, `ipo`, `mergers_and_acquisitions`, `financial_markets`, `economy_fiscal`, `economy_monetary`, `economy_macro`, `energy_transportation`, `finance`, `life_sciences`, `manufacturing`, `real_estate`, `retail_wholesale`, `technology` |
| time_from | No | `YYYYMMDDTHHMM` format |
| time_to | No | `YYYYMMDDTHHMM` format |
| sort | No | `LATEST` (default), `EARLIEST`, `RELEVANCE` |
| limit | No | 1-1000 (default: 50) |

### EARNINGS_CALL_TRANSCRIPT

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `EARNINGS_CALL_TRANSCRIPT` |
| symbol | Yes | Ticker |
| quarter | Yes | `YYYYQN` format (e.g., `2024Q1`). Since 2010Q1. |

### TOP_GAINERS_LOSERS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `TOP_GAINERS_LOSERS` |
| entitlement | No | Not set=historical, `realtime`, `delayed` |

### INSIDER_TRANSACTIONS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `INSIDER_TRANSACTIONS` |
| symbol | Yes | Ticker |

### INSTITUTIONAL_HOLDINGS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `INSTITUTIONAL_HOLDINGS` |
| symbol | Yes | Ticker |

### ANALYTICS_FIXED_WINDOW / ANALYTICS_SLIDING_WINDOW

Advanced analytics on price data.

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `ANALYTICS_FIXED_WINDOW` or `ANALYTICS_SLIDING_WINDOW` |
| SYMBOLS | Yes | Comma-separated tickers |
| RANGE | Yes | Date range (e.g., `2024-01-01` to `2024-12-31` or relative like `full`) |
| INTERVAL | No | `DAILY`, `WEEKLY`, `MONTHLY` |
| CALCULATIONS | Yes | Comma-separated: `MEAN`, `STDDEV`, `CORRELATION`, `MAX`, `MIN`, etc. |

---

## Options Data (Premium)

### REALTIME_OPTIONS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `REALTIME_OPTIONS` |
| symbol | Yes | Ticker |
| require_greeks | No | `true`/`false` (default: false) — enables delta, gamma, theta, vega, rho, IV |
| contract | No | Specific option contract ID (e.g., `IBM270115C00390000`) |
| datatype | No | `json` or `csv` |

### HISTORICAL_OPTIONS

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `HISTORICAL_OPTIONS` |
| symbol | Yes | Ticker |
| date | No | `YYYY-MM-DD` (default: previous trading day). Since 2008-01-01. |
| datatype | No | `json` or `csv` |

---

## Forex

### CURRENCY_EXCHANGE_RATE

Realtime exchange rate for any currency pair (physical or crypto).

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `CURRENCY_EXCHANGE_RATE` |
| from_currency | Yes | Source currency code (e.g., `USD`, `BTC`) |
| to_currency | Yes | Target currency code (e.g., `EUR`, `GBP`) |

### FX_INTRADAY (Premium)

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `FX_INTRADAY` |
| from_symbol | Yes | Source currency |
| to_symbol | Yes | Target currency |
| interval | Yes | `1min`, `5min`, `15min`, `30min`, `60min` |
| outputsize | No | `compact` or `full` |
| datatype | No | `json` or `csv` |

### FX_DAILY

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `FX_DAILY` |
| from_symbol | Yes | Source currency |
| to_symbol | Yes | Target currency |
| outputsize | No | `compact` or `full` |
| datatype | No | `json` or `csv` |

### FX_WEEKLY / FX_MONTHLY

Same pattern. `from_symbol`, `to_symbol`, `datatype`.

---

## Cryptocurrencies

### DIGITAL_CURRENCY_DAILY / WEEKLY / MONTHLY

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | `DIGITAL_CURRENCY_DAILY`, `DIGITAL_CURRENCY_WEEKLY`, or `DIGITAL_CURRENCY_MONTHLY` |
| symbol | Yes | Crypto symbol (e.g., `BTC`, `ETH`) |
| market | Yes | Market/exchange currency (e.g., `USD`, `EUR`) |

---

## Commodities

All commodity endpoints return time series data. Optional `interval` param: `daily`, `weekly`, `monthly` (default varies).

| Function | Commodity |
|----------|-----------|
| `GOLD_SPOT` | Gold spot price (per troy ounce) |
| `SILVER_SPOT` | Silver spot price |
| `GOLD` | Gold historical |
| `SILVER` | Silver historical |
| `WTI` | Crude oil (West Texas Intermediate) |
| `BRENT` | Crude oil (Brent) |
| `NATURAL_GAS` | Natural gas (Henry Hub) |
| `COPPER` | Copper |
| `ALUMINUM` | Aluminum |
| `WHEAT` | Wheat |
| `CORN` | Corn |
| `COTTON` | Cotton |
| `SUGAR` | Sugar |
| `COFFEE` | Coffee |
| `ALL_COMMODITIES` | Global Commodities Index |

---

## Economic Indicators

All return time series. Optional `interval`: `quarterly`, `annual` (default varies), or `monthly`/`semiannual` for some.

| Function | Description |
|----------|-------------|
| `REAL_GDP` | US Real GDP (quarterly or annual) |
| `REAL_GDP_PER_CAPITA` | US Real GDP per capita (quarterly) |
| `TREASURY_YIELD` | US Treasury yield. Optional `maturity`: `3month`, `2year`, `5year`, `7year`, `10year` (default), `30year`. Optional `interval`: `daily`, `weekly`, `monthly`. |
| `FEDERAL_FUNDS_RATE` | Fed funds rate. `interval`: `daily`, `weekly`, `monthly`. |
| `CPI` | Consumer Price Index. `interval`: `monthly`, `semiannual`. |
| `INFLATION` | Annual inflation rate. |
| `RETAIL_SALES` | Monthly retail sales. |
| `DURABLES` | Durable goods orders. |
| `UNEMPLOYMENT` | Monthly unemployment rate. |
| `NONFARM_PAYROLL` | Monthly nonfarm payroll. |

---

## Technical Indicators

All technical indicators share a common parameter pattern:

| Parameter | Required | Description |
|-----------|----------|-------------|
| function | Yes | Indicator name (e.g., `SMA`, `EMA`, `RSI`) |
| symbol | Yes | Ticker |
| interval | Yes | `1min`, `5min`, `15min`, `30min`, `60min`, `daily`, `weekly`, `monthly` |
| time_period | Most | Number of data points (e.g., `14` for RSI-14) |
| series_type | Most | `close`, `open`, `high`, `low` |
| datatype | No | `json` or `csv` |

### Popular Indicators

| Indicator | Extra Params | Description |
|-----------|-------------|-------------|
| `SMA` | time_period, series_type | Simple Moving Average |
| `EMA` | time_period, series_type | Exponential Moving Average |
| `WMA` | time_period, series_type | Weighted Moving Average |
| `DEMA` | time_period, series_type | Double EMA |
| `TEMA` | time_period, series_type | Triple EMA |
| `RSI` | time_period, series_type | Relative Strength Index |
| `MACD` | series_type, fastperiod, slowperiod, signalperiod | Moving Average Convergence Divergence (Premium) |
| `BBANDS` | time_period, series_type, nbdevup, nbdevdn, matype | Bollinger Bands |
| `STOCH` | fastkperiod, slowkperiod, slowdperiod, slowkmatype, slowdmatype | Stochastic Oscillator |
| `ADX` | time_period | Average Directional Index |
| `CCI` | time_period | Commodity Channel Index |
| `AROON` | time_period | Aroon Indicator |
| `OBV` | — | On Balance Volume |
| `AD` | — | Chaikin A/D Line |
| `VWAP` | — | Volume Weighted Average Price (Premium) |
| `ATR` | time_period | Average True Range |
| `MFI` | time_period | Money Flow Index |
| `SAR` | acceleration, maximum | Parabolic SAR |

### All 50+ Supported Indicators

SMA, EMA, WMA, DEMA, TEMA, TRIMA, KAMA, MAMA, T3, VWAP, MACD, MACDEXT, STOCH, STOCHF, RSI, STOCHRSI, WILLR, ADX, ADXR, APO, PPO, MOM, BOP, CCI, CMO, ROC, ROCR, AROON, AROONOSC, MFI, TRIX, ULTOSC, DX, MINUS_DI, PLUS_DI, MINUS_DM, PLUS_DM, BBANDS, MIDPOINT, MIDPRICE, SAR, TRANGE, ATR, NATR, AD, ADOSC, OBV, HT_TRENDLINE, HT_SINE, HT_TRENDMODE, HT_DCPERIOD, HT_DCPHASE, HT_PHASOR

### matype Values

Used in BBANDS, MACDEXT, STOCH, etc:

| Value | Type |
|-------|------|
| 0 | SMA (default) |
| 1 | EMA |
| 2 | WMA |
| 3 | DEMA |
| 4 | TEMA |
| 5 | TRIMA |
| 6 | T3 |
| 7 | KAMA |
| 8 | MAMA |

---

## Global Symbols

Alpha Vantage covers 100,000+ symbols across global exchanges:

| Suffix | Exchange |
|--------|----------|
| (none) | US (NYSE, NASDAQ) |
| `.LON` | London Stock Exchange |
| `.TRT` | Toronto Stock Exchange |
| `.TRV` | Toronto Venture Exchange |
| `.DEX` | XETRA (Germany) |
| `.BSE` | Bombay Stock Exchange |
| `.SHH` | Shanghai Stock Exchange |
| `.SHZ` | Shenzhen Stock Exchange |

Use `SYMBOL_SEARCH` to discover the correct symbol for any global ticker.
