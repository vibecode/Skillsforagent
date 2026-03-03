---
name: alpha-vantage
description: >
  Foundational skill for the Alpha Vantage financial data API — stocks,
  fundamentals, forex, crypto, commodities, economic indicators, 50+ technical
  indicators, options, news sentiment, and earnings transcripts. Use when:
  (1) fetching stock quotes or OHLCV time series, (2) company fundamentals
  (income, balance sheet, cash flow, earnings), (3) forex or crypto exchange
  rates, (4) commodity prices (gold, oil, natural gas), (5) economic indicators
  (GDP, CPI, treasury yield, unemployment), (6) technical indicators (SMA, EMA,
  RSI, MACD, BBANDS), (7) ticker search, (8) market news/sentiment,
  (9) earnings call transcripts, (10) gainers/losers, insider transactions,
  institutional holdings, (11) any task involving Alpha Vantage. Wrapper script
  included. Base Alpha Vantage skill — specialized skills may reference it.
metadata: {"openclaw": {"emoji": "📈", "requires": {"env": ["ALPHA_VANTAGE_API_KEY"]}, "primaryEnv": "ALPHA_VANTAGE_API_KEY"}}
---

# Alpha Vantage

Financial data API: stocks, fundamentals, forex, crypto, commodities, economic indicators, technical analysis, news, and more. Single REST endpoint, JSON/CSV output.

## Authentication

```
Base URL: https://www.alphavantage.co/query
Auth:     apikey=YOUR_KEY (query parameter on every request)
```

Set `ALPHA_VANTAGE_API_KEY` in your environment. Free keys available at [alphavantage.co/support/#api-key](https://www.alphavantage.co/support/#api-key).

### Rate Limits

| Plan | Requests/day | Requests/min |
|------|-------------|--------------|
| Free | 25 | 5 |
| Premium (various) | Varies | 75–1200 |

Free tier is limited. If you get a `"Note"` about rate limits or an `"Information"` message about premium, you've hit the cap. Wait or upgrade. **Always space calls ≥2 seconds apart on the free tier** — parallel calls will almost always trigger the rate limit.

### Premium vs Free

Most endpoints work on free tier with the `compact` outputsize (100 data points). Premium features:
- Intraday data, daily adjusted, bulk quotes
- Options (realtime + historical)
- `outputsize=full` (20+ years of history)
- Realtime/delayed entitlement data
- Higher rate limits

## Wrapper Script

Handles auth, parameter mapping, friendly subcommand names, and JSON formatting.

```bash
SCRIPT="$(dirname "$0")/scripts/alphavantage.sh"
```

### Core Stock Data

```bash
# Latest price quote
bash $SCRIPT quote --symbol IBM

# Daily OHLCV (last 100 days)
bash $SCRIPT daily --symbol AAPL

# Daily adjusted (includes dividends/splits) — full history
bash $SCRIPT daily --symbol AAPL --adjusted --full

# Intraday (5-min bars, last 100)
bash $SCRIPT intraday --symbol MSFT --interval 5min

# Intraday for a specific historical month
bash $SCRIPT intraday --symbol MSFT --interval 5min --month 2024-06 --full

# Weekly / monthly
bash $SCRIPT weekly --symbol TSLA
bash $SCRIPT monthly --symbol GOOG --adjusted

# Search for a ticker
bash $SCRIPT search --keywords "tesla"

# Global market status
bash $SCRIPT market-status
```

### Fundamental Data

```bash
# Company overview (sector, market cap, PE, EPS, description)
bash $SCRIPT overview --symbol AAPL

# Financial statements
bash $SCRIPT income --symbol MSFT
bash $SCRIPT balance --symbol MSFT
bash $SCRIPT cashflow --symbol MSFT

# Earnings and estimates
bash $SCRIPT earnings --symbol NVDA
bash $SCRIPT earnings-estimates --symbol NVDA

# Corporate actions
bash $SCRIPT dividends --symbol JNJ
bash $SCRIPT splits --symbol TSLA

# ETF profile
bash $SCRIPT etf --symbol SPY

# Calendars & listings (CSV output)
bash $SCRIPT earnings-calendar --horizon 3month
bash $SCRIPT ipo-calendar
bash $SCRIPT listing --state active
```

### Alpha Intelligence

```bash
# Market news & sentiment
bash $SCRIPT news --tickers AAPL
bash $SCRIPT news --topics technology,ipo --limit 100
bash $SCRIPT news --tickers "COIN,CRYPTO:BTC,FOREX:USD" --time_from 20240101T0000

# Earnings call transcript
bash $SCRIPT transcript --symbol IBM --quarter 2024Q1

# Top gainers/losers
bash $SCRIPT gainers-losers

# Insider transactions
bash $SCRIPT insiders --symbol AAPL

# Institutional holdings
bash $SCRIPT holdings --symbol TSLA
```

### Forex & Crypto

```bash
# Forex exchange rate
bash $SCRIPT fx-rate --from USD --to EUR

# Forex daily history
bash $SCRIPT fx-daily --from USD --to JPY --full

# Crypto exchange rate
bash $SCRIPT crypto-rate --from BTC --to USD

# Crypto daily history
bash $SCRIPT crypto-daily --symbol ETH --market USD
```

### Commodities & Economic Indicators

```bash
# Gold & Silver — Spot (live price)
bash $SCRIPT gold-spot --symbol GOLD
bash $SCRIPT gold-spot --symbol SILVER

# Gold & Silver — Historical
bash $SCRIPT gold-history --symbol GOLD --interval daily
bash $SCRIPT gold-history --symbol SILVER --interval monthly

# Other commodities
bash $SCRIPT commodity --name wti --interval monthly
bash $SCRIPT commodity --name brent
bash $SCRIPT commodity --name natural-gas --interval daily

# Available: wti, brent, natural-gas, copper, aluminum, wheat,
# corn, cotton, sugar, coffee, all-commodities

# Economic indicators
bash $SCRIPT economy --indicator real-gdp
bash $SCRIPT economy --indicator treasury-yield --interval daily
bash $SCRIPT economy --indicator cpi --interval monthly
bash $SCRIPT economy --indicator unemployment

# Available: real-gdp, real-gdp-per-capita, treasury-yield,
# interest-rate, cpi, inflation, retail-sales, durable-goods,
# unemployment, nonfarm-payroll
```

### Technical Indicators

```bash
# Moving averages
bash $SCRIPT indicator --function SMA --symbol IBM --interval daily --time_period 50 --series_type close
bash $SCRIPT indicator --function EMA --symbol IBM --interval daily --time_period 20 --series_type close

# Momentum
bash $SCRIPT indicator --function RSI --symbol AAPL --interval daily --time_period 14 --series_type close
bash $SCRIPT indicator --function MACD --symbol AAPL --interval daily --series_type close  # Premium only

# Volatility
bash $SCRIPT indicator --function BBANDS --symbol MSFT --interval daily --time_period 20 --series_type close
bash $SCRIPT indicator --function ATR --symbol MSFT --interval daily --time_period 14

# Volume
bash $SCRIPT indicator --function OBV --symbol TSLA --interval daily
bash $SCRIPT indicator --function AD --symbol TSLA --interval daily

# 50+ indicators supported — see references/api-reference.md for full list
```

### Global Flags

```bash
# Get CSV output instead of JSON
bash $SCRIPT daily --symbol IBM --csv

# Skip jq formatting
bash $SCRIPT quote --symbol IBM --raw

# Pass arbitrary extra parameters
bash $SCRIPT indicator --function BBANDS --symbol IBM --interval daily \
  --time_period 20 --series_type close --nbdevup 2 --nbdevdn 2
```

## Global Symbols

Alpha Vantage covers 100,000+ tickers across global exchanges. Use `search` to find the right symbol:

| Suffix | Exchange |
|--------|----------|
| (none) | US (NYSE, NASDAQ) |
| `.LON` | London |
| `.TRT` | Toronto |
| `.DEX` | XETRA (Germany) |
| `.BSE` | Bombay |
| `.SHH` | Shanghai |
| `.SHZ` | Shenzhen |

## Error Handling

| Error | Meaning | Action |
|-------|---------|--------|
| `"Error Message"` | Invalid function/params | Check function name and required params |
| `"Note"` with rate limit text | Rate limit hit | Wait 60s (free) or check plan limits |
| `"Information"` about premium | Premium-only endpoint | Upgrade plan or use free alternative |
| Empty/malformed JSON | Symbol not found or API issue | Verify symbol with `search` |

## Raw API Fallback

For edge cases the wrapper doesn't cover, call the API directly:

```bash
curl -s "https://www.alphavantage.co/query?function=FUNCTION_NAME&symbol=SYM&apikey=${ALPHA_VANTAGE_API_KEY}" | jq .
```

All endpoints accept the same base pattern: `function=` + endpoint-specific params + `apikey=`.

## References

- [references/api-reference.md](references/api-reference.md) — Complete parameter tables for all endpoints, technical indicator list, matype values, global exchange suffixes
- [Alpha Vantage Documentation](https://www.alphavantage.co/documentation/) — Official docs
