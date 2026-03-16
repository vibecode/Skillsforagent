#!/usr/bin/env bash
# alphavantage.sh — Wrapper for Alpha Vantage financial data API
# Usage: bash scripts/alphavantage.sh <command> [options]
#
# Commands:
#   # Core Stock APIs
#   quote         --symbol SYM                      Latest price quote
#   daily         --symbol SYM [--full] [--adjusted] Daily OHLCV
#   intraday      --symbol SYM --interval INT [--full] [--month YYYY-MM]  Intraday OHLCV
#   weekly        --symbol SYM [--adjusted]          Weekly OHLCV
#   monthly       --symbol SYM [--adjusted]          Monthly OHLCV
#   search        --keywords KW                      Ticker search
#   market-status                                    Global market open/close status
#
#   # Fundamental Data
#   overview      --symbol SYM                      Company overview
#   income        --symbol SYM                      Income statement
#   balance       --symbol SYM                      Balance sheet
#   cashflow      --symbol SYM                      Cash flow
#   earnings      --symbol SYM                      Earnings history
#   dividends     --symbol SYM                      Dividend history
#   splits        --symbol SYM                      Stock split history
#   etf           --symbol SYM                      ETF profile & holdings
#   listing       [--state active|delisted]          Listing/delisting status (CSV)
#   ipo-calendar                                     IPO calendar (CSV)
#   earnings-calendar [--symbol SYM] [--horizon 3month|6month|12month]
#
#   # Alpha Intelligence
#   news          [--tickers T] [--topics T] [--sort LATEST|EARLIEST|RELEVANCE] [--limit N]
#   transcript    --symbol SYM --quarter YYYYQN      Earnings call transcript
#   gainers-losers                                   Top gainers, losers, most active
#   insiders      --symbol SYM                      Insider transactions
#   holdings      --symbol SYM                      Institutional holdings
#   analytics     --symbol SYM --range R --calc C   Fixed-window analytics
#   analytics-sw  --symbol SYM --range R --calc C   Sliding-window analytics
#
#   # Forex
#   fx-rate       --from CUR --to CUR               Exchange rate
#   fx-daily      --from CUR --to CUR [--full]      Daily FX
#   fx-weekly     --from CUR --to CUR               Weekly FX
#   fx-monthly    --from CUR --to CUR               Monthly FX
#
#   # Crypto
#   crypto-rate   --from CUR --to CUR               Exchange rate
#   crypto-daily  --symbol SYM --market MKT          Daily crypto
#   crypto-weekly --symbol SYM --market MKT          Weekly crypto
#   crypto-monthly --symbol SYM --market MKT         Monthly crypto
#
#   # Commodities
#   commodity     --name NAME [--interval daily|weekly|monthly]
#                 NAME: wti, brent, natural-gas, copper, aluminum, wheat,
#                       corn, cotton, sugar, coffee, all-commodities
#   gold-spot     --symbol GOLD|SILVER|XAU|XAG       Live spot price
#   gold-history  --symbol GOLD|SILVER|XAU|XAG --interval daily|weekly|monthly
#
#   # Economic Indicators
#   economy       --indicator IND [--interval INT]
#                 IND: real-gdp, real-gdp-per-capita, treasury-yield, interest-rate,
#                      cpi, inflation, retail-sales, durable-goods, unemployment,
#                      nonfarm-payroll
#
#   # Technical Indicators
#   indicator     --function FUNC --symbol SYM --interval INT --time_period N --series_type T [extra params...]
#                 FUNC: SMA, EMA, RSI, MACD, BBANDS, STOCH, ADX, CCI, AROON,
#                       OBV, VWAP, AD, WMA, DEMA, TEMA, etc. (50+ supported)
#
# Global options:
#   --csv         Return CSV instead of JSON
#   --raw         Skip jq formatting (output raw JSON)
#   --demo        Use Alpha Vantage demo key (only GLOBAL_QUOTE for IBM works)
#
# Exit codes:
#   0  Success (or per-second burst rate limit — wait 2+ seconds and retry)
#   1  Error (invalid params, missing args, API error, demo key limitation)
#   2  Daily limit exhausted (25 requests/day on free tier) — stop retrying
#   3  Premium-only endpoint — requires paid plan ("This is a premium endpoint")

set -euo pipefail

BASE="https://www.alphavantage.co.cloudproxy.vibecodeapp.com/query"
USE_DEMO="false"
API_KEY="${ALPHA_VANTAGE_API_KEY:-}"

die() { echo "ERROR: $*" >&2; exit 1; }

# Build URL from params array (apikey appended last — required for demo key)
call_api() {
  local url="${BASE}?"
  local first=true
  while [[ $# -gt 0 ]]; do
    # Skip datatype param for demo key (breaks demo responses)
    if [[ "$USE_DEMO" == "true" ]] && [[ "$1" == datatype=* ]]; then
      shift
      continue
    fi
    if [[ "$first" == "true" ]]; then
      url="${url}${1}"
      first=false
    else
      url="${url}&${1}"
    fi
    shift
  done
  url="${url}&apikey=${API_KEY}"
  
  local response
  response=$(curl -sfS "$url" 2>&1) || die "API request failed: $response"
  
  # Check for API error messages
  if echo "$response" | grep -q '"Error Message"'; then
    echo "$response" >&2
    exit 1
  fi
  
  # Check for rate limit / informational messages
  # Alpha Vantage uses the "Information" key for: rate limits, premium-only, and demo notices.
  # There are 3 distinct messages (detection order matters):
  #   1. Premium: "This is a premium endpoint" — exit 3 (never works on free tier)
  #   2. Burst:   "spreading out your free API requests" — exit 0 (wait 2-15s and retry)
  #   3. Daily:   "standard API rate limit is 25 requests per day" — exit 2 (stop, done for today)
  # All three contain the word "premium" somewhere, so we match specific phrases, not just "premium".
  if echo "$response" | grep -q '"Information"'; then
    local info_msg
    info_msg=$(echo "$response" | grep -o '"Information": *"[^"]*"' | head -1)

    if [[ "$USE_DEMO" == "true" ]] && echo "$info_msg" | grep -q "demo.*API key"; then
      echo "DEMO_LIMIT: This endpoint is not available with the demo key. Only GLOBAL_QUOTE for IBM works with --demo." >&2
      echo "$response"
      exit 1
    elif echo "$info_msg" | grep -q "This is a premium endpoint"; then
      echo "PREMIUM_ONLY: This endpoint requires a premium Alpha Vantage plan. See SKILL.md Premium-Only Features list." >&2
      echo "$response"
      exit 3
    elif echo "$info_msg" | grep -q "spreading out your free API requests"; then
      echo "RATE_LIMIT_BURST: Per-second burst rate limit. Wait 2+ seconds between calls and retry." >&2
      echo "$response"
      exit 0
    elif echo "$info_msg" | grep -q "standard API rate limit is 25 requests per day"; then
      echo "RATE_LIMIT_DAILY: Daily quota (25 requests) exhausted. Do NOT retry — wait until tomorrow or use a premium key." >&2
      echo "$response"
      exit 2
    else
      # Unknown "Information" message — treat as daily limit (safer to stop than retry endlessly)
      echo "RATE_LIMIT_UNKNOWN: API returned an unrecognized informational message. Stopping retries to be safe." >&2
      echo "$response"
      exit 2
    fi
  fi
  
  if echo "$response" | grep -q '"Note"'; then
    # Legacy per-minute burst limit format — retriable after a short wait
    echo "RATE_LIMIT_BURST: Per-minute rate limit hit. Wait 15-60 seconds and retry." >&2
  fi
  
  if [[ "$OUTPUT_CSV" == "true" ]]; then
    echo "$response"
  elif [[ "$OUTPUT_RAW" == "true" ]]; then
    echo "$response"
  else
    echo "$response" | jq . 2>/dev/null || echo "$response"
  fi
}

# Parse global flags
OUTPUT_CSV="false"
OUTPUT_RAW="false"
CMD="${1:-}"
[[ -z "$CMD" ]] && die "Usage: bash alphavantage.sh <command> [options]. Run with --help for commands."
shift

# Collect remaining args
declare -A OPTS
EXTRA_PARAMS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv) OUTPUT_CSV="true"; shift ;;
    --raw) OUTPUT_RAW="true"; shift ;;
    --demo) USE_DEMO="true"; shift ;;
    --symbol) OPTS[symbol]="$2"; shift 2 ;;
    --symbols) OPTS[symbols]="$2"; shift 2 ;;
    --interval) OPTS[interval]="$2"; shift 2 ;;
    --keywords) OPTS[keywords]="$2"; shift 2 ;;
    --full) OPTS[outputsize]="full"; shift ;;
    --adjusted) OPTS[adjusted]="true"; shift ;;
    --month) OPTS[month]="$2"; shift 2 ;;
    --from) OPTS[from_currency]="$2"; shift 2 ;;
    --to) OPTS[to_currency]="$2"; shift 2 ;;
    --market) OPTS[market]="$2"; shift 2 ;;
    --tickers) OPTS[tickers]="$2"; shift 2 ;;
    --topics) OPTS[topics]="$2"; shift 2 ;;
    --sort) OPTS[sort]="$2"; shift 2 ;;
    --limit) OPTS[limit]="$2"; shift 2 ;;
    --time_from) OPTS[time_from]="$2"; shift 2 ;;
    --time_to) OPTS[time_to]="$2"; shift 2 ;;
    --quarter) OPTS[quarter]="$2"; shift 2 ;;
    --date) OPTS[date]="$2"; shift 2 ;;
    --state) OPTS[state]="$2"; shift 2 ;;
    --horizon) OPTS[horizon]="$2"; shift 2 ;;
    --name) OPTS[name]="$2"; shift 2 ;;
    --indicator) OPTS[indicator]="$2"; shift 2 ;;
    --function) OPTS[function]="$2"; shift 2 ;;
    --time_period) OPTS[time_period]="$2"; shift 2 ;;
    --series_type) OPTS[series_type]="$2"; shift 2 ;;
    --range) OPTS[range]="$2"; shift 2 ;;
    --calc) OPTS[calculations]="$2"; shift 2 ;;
    --contract) OPTS[contract]="$2"; shift 2 ;;
    --require_greeks) OPTS[require_greeks]="$2"; shift 2 ;;
    --entitlement) OPTS[entitlement]="$2"; shift 2 ;;
    --*) # Pass through any extra params
      key="${1#--}"
      EXTRA_PARAMS+=("${key}=$2")
      shift 2 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

DATATYPE="json"
[[ "$OUTPUT_CSV" == "true" ]] && DATATYPE="csv"

# Resolve API key
if [[ "$USE_DEMO" == "true" ]]; then
  API_KEY="demo"
  echo "NOTE: Using demo API key — only GLOBAL_QUOTE for IBM is guaranteed to work." >&2
elif [[ -z "$API_KEY" ]]; then
  die "Set ALPHA_VANTAGE_API_KEY or use --demo for basic testing"
fi

# Route commands
case "$CMD" in
  # ── Core Stock APIs ──
  quote)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=GLOBAL_QUOTE" "symbol=${OPTS[symbol]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  daily)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    local_fn="TIME_SERIES_DAILY"
    [[ "${OPTS[adjusted]:-}" == "true" ]] && local_fn="TIME_SERIES_DAILY_ADJUSTED"
    params=("function=${local_fn}" "symbol=${OPTS[symbol]}" "datatype=${DATATYPE}")
    [[ -n "${OPTS[outputsize]:-}" ]] && params+=("outputsize=${OPTS[outputsize]}")
    [[ -n "${OPTS[entitlement]:-}" ]] && params+=("entitlement=${OPTS[entitlement]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  intraday)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    [[ -z "${OPTS[interval]:-}" ]] && die "--interval required (1min|5min|15min|30min|60min)"
    params=("function=TIME_SERIES_INTRADAY" "symbol=${OPTS[symbol]}" "interval=${OPTS[interval]}" "datatype=${DATATYPE}")
    [[ -n "${OPTS[outputsize]:-}" ]] && params+=("outputsize=${OPTS[outputsize]}")
    [[ -n "${OPTS[month]:-}" ]] && params+=("month=${OPTS[month]}")
    [[ -n "${OPTS[entitlement]:-}" ]] && params+=("entitlement=${OPTS[entitlement]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  weekly)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    local_fn="TIME_SERIES_WEEKLY"
    [[ "${OPTS[adjusted]:-}" == "true" ]] && local_fn="TIME_SERIES_WEEKLY_ADJUSTED"
    call_api "function=${local_fn}" "symbol=${OPTS[symbol]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  monthly)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    local_fn="TIME_SERIES_MONTHLY"
    [[ "${OPTS[adjusted]:-}" == "true" ]] && local_fn="TIME_SERIES_MONTHLY_ADJUSTED"
    call_api "function=${local_fn}" "symbol=${OPTS[symbol]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  search)
    [[ -z "${OPTS[keywords]:-}" ]] && die "--keywords required"
    call_api "function=SYMBOL_SEARCH" "keywords=${OPTS[keywords]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  market-status)
    call_api "function=MARKET_STATUS" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  bulk-quotes)
    [[ -z "${OPTS[symbols]:-}" ]] && die "--symbols required (comma-separated, up to 100)"
    call_api "function=REALTIME_BULK_QUOTES" "symbol=${OPTS[symbols]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Fundamental Data ──
  overview)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=OVERVIEW" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  income)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=INCOME_STATEMENT" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  balance)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=BALANCE_SHEET" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  cashflow)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=CASH_FLOW" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  earnings)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=EARNINGS" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  earnings-estimates)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=EARNINGS_ESTIMATE" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  dividends)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=DIVIDENDS" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  splits)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=SPLITS" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  shares)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=SHARES_OUTSTANDING" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  etf)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=ETF_PROFILE" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  listing)
    state="${OPTS[state]:-active}"
    call_api "function=LISTING_STATUS" "state=${state}" "datatype=csv" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  ipo-calendar)
    call_api "function=IPO_CALENDAR" "datatype=csv" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  earnings-calendar)
    params=("function=EARNINGS_CALENDAR" "datatype=csv")
    [[ -n "${OPTS[symbol]:-}" ]] && params+=("symbol=${OPTS[symbol]}")
    [[ -n "${OPTS[horizon]:-}" ]] && params+=("horizon=${OPTS[horizon]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Alpha Intelligence ──
  news)
    params=("function=NEWS_SENTIMENT")
    [[ -n "${OPTS[tickers]:-}" ]] && params+=("tickers=${OPTS[tickers]}")
    [[ -n "${OPTS[topics]:-}" ]] && params+=("topics=${OPTS[topics]}")
    [[ -n "${OPTS[sort]:-}" ]] && params+=("sort=${OPTS[sort]}")
    [[ -n "${OPTS[limit]:-}" ]] && params+=("limit=${OPTS[limit]}")
    [[ -n "${OPTS[time_from]:-}" ]] && params+=("time_from=${OPTS[time_from]}")
    [[ -n "${OPTS[time_to]:-}" ]] && params+=("time_to=${OPTS[time_to]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  transcript)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    [[ -z "${OPTS[quarter]:-}" ]] && die "--quarter required (e.g., 2024Q1)"
    call_api "function=EARNINGS_CALL_TRANSCRIPT" "symbol=${OPTS[symbol]}" "quarter=${OPTS[quarter]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  gainers-losers)
    params=("function=TOP_GAINERS_LOSERS")
    [[ -n "${OPTS[entitlement]:-}" ]] && params+=("entitlement=${OPTS[entitlement]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  insiders)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=INSIDER_TRANSACTIONS" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  holdings)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    call_api "function=INSTITUTIONAL_HOLDINGS" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  analytics)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    params=("function=ANALYTICS_FIXED_WINDOW" "SYMBOLS=${OPTS[symbol]}")
    [[ -n "${OPTS[range]:-}" ]] && params+=("RANGE=${OPTS[range]}")
    [[ -n "${OPTS[calculations]:-}" ]] && params+=("CALCULATIONS=${OPTS[calculations]}")
    [[ -n "${OPTS[interval]:-}" ]] && params+=("INTERVAL=${OPTS[interval]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  analytics-sw)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    params=("function=ANALYTICS_SLIDING_WINDOW" "SYMBOLS=${OPTS[symbol]}")
    [[ -n "${OPTS[range]:-}" ]] && params+=("RANGE=${OPTS[range]}")
    [[ -n "${OPTS[calculations]:-}" ]] && params+=("CALCULATIONS=${OPTS[calculations]}")
    [[ -n "${OPTS[interval]:-}" ]] && params+=("INTERVAL=${OPTS[interval]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Options ──
  options)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    params=("function=REALTIME_OPTIONS" "symbol=${OPTS[symbol]}" "datatype=${DATATYPE}")
    [[ -n "${OPTS[require_greeks]:-}" ]] && params+=("require_greeks=${OPTS[require_greeks]}")
    [[ -n "${OPTS[contract]:-}" ]] && params+=("contract=${OPTS[contract]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  options-history)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    params=("function=HISTORICAL_OPTIONS" "symbol=${OPTS[symbol]}" "datatype=${DATATYPE}")
    [[ -n "${OPTS[date]:-}" ]] && params+=("date=${OPTS[date]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Forex ──
  fx-rate)
    [[ -z "${OPTS[from_currency]:-}" ]] && die "--from required"
    [[ -z "${OPTS[to_currency]:-}" ]] && die "--to required"
    call_api "function=CURRENCY_EXCHANGE_RATE" "from_currency=${OPTS[from_currency]}" "to_currency=${OPTS[to_currency]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  fx-daily)
    [[ -z "${OPTS[from_currency]:-}" ]] && die "--from required"
    [[ -z "${OPTS[to_currency]:-}" ]] && die "--to required"
    params=("function=FX_DAILY" "from_symbol=${OPTS[from_currency]}" "to_symbol=${OPTS[to_currency]}" "datatype=${DATATYPE}")
    [[ -n "${OPTS[outputsize]:-}" ]] && params+=("outputsize=${OPTS[outputsize]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  fx-weekly)
    [[ -z "${OPTS[from_currency]:-}" ]] && die "--from required"
    [[ -z "${OPTS[to_currency]:-}" ]] && die "--to required"
    call_api "function=FX_WEEKLY" "from_symbol=${OPTS[from_currency]}" "to_symbol=${OPTS[to_currency]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  fx-monthly)
    [[ -z "${OPTS[from_currency]:-}" ]] && die "--from required"
    [[ -z "${OPTS[to_currency]:-}" ]] && die "--to required"
    call_api "function=FX_MONTHLY" "from_symbol=${OPTS[from_currency]}" "to_symbol=${OPTS[to_currency]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Crypto ──
  crypto-rate)
    [[ -z "${OPTS[from_currency]:-}" ]] && die "--from required"
    [[ -z "${OPTS[to_currency]:-}" ]] && die "--to required"
    call_api "function=CURRENCY_EXCHANGE_RATE" "from_currency=${OPTS[from_currency]}" "to_currency=${OPTS[to_currency]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  crypto-daily)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required (e.g., BTC)"
    [[ -z "${OPTS[market]:-}" ]] && die "--market required (e.g., USD)"
    call_api "function=DIGITAL_CURRENCY_DAILY" "symbol=${OPTS[symbol]}" "market=${OPTS[market]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  crypto-weekly)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required (e.g., BTC)"
    [[ -z "${OPTS[market]:-}" ]] && die "--market required (e.g., USD)"
    call_api "function=DIGITAL_CURRENCY_WEEKLY" "symbol=${OPTS[symbol]}" "market=${OPTS[market]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  crypto-monthly)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required (e.g., BTC)"
    [[ -z "${OPTS[market]:-}" ]] && die "--market required (e.g., USD)"
    call_api "function=DIGITAL_CURRENCY_MONTHLY" "symbol=${OPTS[symbol]}" "market=${OPTS[market]}" "datatype=${DATATYPE}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Commodities ──
  commodity)
    [[ -z "${OPTS[name]:-}" ]] && die "--name required (wti, brent, natural-gas, copper, aluminum, wheat, corn, cotton, sugar, coffee, all-commodities). For gold/silver use: gold-spot, gold-history"
    # Map friendly names to API functions
    declare -A COMMODITY_MAP=(
      ["wti"]="WTI"
      ["brent"]="BRENT"
      ["natural-gas"]="NATURAL_GAS"
      ["copper"]="COPPER"
      ["aluminum"]="ALUMINUM"
      ["wheat"]="WHEAT"
      ["corn"]="CORN"
      ["cotton"]="COTTON"
      ["sugar"]="SUGAR"
      ["coffee"]="COFFEE"
      ["all-commodities"]="ALL_COMMODITIES"
    )
    func="${COMMODITY_MAP[${OPTS[name]}]:-}"
    [[ -z "$func" ]] && die "Unknown commodity: ${OPTS[name]}. Valid: ${!COMMODITY_MAP[*]}. For gold/silver use: gold-spot, gold-history"
    params=("function=${func}")
    [[ -n "${OPTS[interval]:-}" ]] && params+=("interval=${OPTS[interval]}")
    [[ -n "${OPTS[datatype]:-}" ]] && params+=("datatype=${OPTS[datatype]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  gold-spot)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required (GOLD, XAU, SILVER, XAG)"
    call_api "function=GOLD_SILVER_SPOT" "symbol=${OPTS[symbol]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;
  gold-history)
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required (GOLD, XAU, SILVER, XAG)"
    [[ -z "${OPTS[interval]:-}" ]] && die "--interval required (daily, weekly, monthly)"
    params=("function=GOLD_SILVER_HISTORY" "symbol=${OPTS[symbol]}" "interval=${OPTS[interval]}")
    [[ -n "${OPTS[datatype]:-}" ]] && params+=("datatype=${OPTS[datatype]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Economic Indicators ──
  economy)
    [[ -z "${OPTS[indicator]:-}" ]] && die "--indicator required"
    declare -A ECON_MAP=(
      ["real-gdp"]="REAL_GDP"
      ["real-gdp-per-capita"]="REAL_GDP_PER_CAPITA"
      ["treasury-yield"]="TREASURY_YIELD"
      ["interest-rate"]="FEDERAL_FUNDS_RATE"
      ["cpi"]="CPI"
      ["inflation"]="INFLATION"
      ["retail-sales"]="RETAIL_SALES"
      ["durable-goods"]="DURABLES"
      ["unemployment"]="UNEMPLOYMENT"
      ["nonfarm-payroll"]="NONFARM_PAYROLL"
    )
    func="${ECON_MAP[${OPTS[indicator]}]:-}"
    [[ -z "$func" ]] && die "Unknown indicator: ${OPTS[indicator]}. Valid: ${!ECON_MAP[*]}"
    params=("function=${func}")
    [[ -n "${OPTS[interval]:-}" ]] && params+=("interval=${OPTS[interval]}")
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  # ── Technical Indicators ──
  indicator)
    [[ -z "${OPTS[function]:-}" ]] && die "--function required (e.g., SMA, EMA, RSI, MACD, BBANDS)"
    [[ -z "${OPTS[symbol]:-}" ]] && die "--symbol required"
    [[ -z "${OPTS[interval]:-}" ]] && die "--interval required (1min|5min|15min|30min|60min|daily|weekly|monthly)"
    params=("function=${OPTS[function]}" "symbol=${OPTS[symbol]}" "interval=${OPTS[interval]}" "datatype=${DATATYPE}")
    [[ -n "${OPTS[time_period]:-}" ]] && params+=("time_period=${OPTS[time_period]}")
    [[ -n "${OPTS[series_type]:-}" ]] && params+=("series_type=${OPTS[series_type]}")
    # Pass through all extra params for indicator-specific options
    call_api "${params[@]}" "${EXTRA_PARAMS[@]+"${EXTRA_PARAMS[@]}"}"
    ;;

  *)
    die "Unknown command: $CMD. See script header for available commands."
    ;;
esac
