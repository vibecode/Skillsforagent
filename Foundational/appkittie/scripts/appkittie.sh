#!/usr/bin/env bash
# appkittie.sh - Wrapper for the AppKittie App Store intelligence API
# Usage: bash scripts/appkittie.sh <command> [options]
#
# Commands:
#   apps        Search / filter iOS apps (GET /apps) - 1 credit per returned row
#   app         Full detail for one app (GET /apps/:appId) - 1 credit
#   ads         Search Meta/Google ad creatives (GET /ads) - 1 credit per returned row
#   ad          Full detail for one ad creative (GET /ads/:adId) - 1 credit
#   reviews     User reviews for an app (POST /reviews) - 1 credit per review returned
#   keyword     Single keyword difficulty (GET /keywords/difficulty) - 10 credits
#   keywords    Batch keyword difficulty, max 10 (POST /keywords/difficulty) - 10 credits/keyword
#
# Global options:
#   --key KEY   Override APPKITTIE_API_KEY env var
#   --raw       Output raw JSON (skip jq formatting)
#   --help      Show this help
#
# Command options:
#   app:        --id APPID (required, numeric App Store id)
#   ad:         --id ADID (required, ad_doc_id from an ads search)
#   reviews:    --id APPID (required), --country US, --maxReviews 100, --offset 0
#   keyword:    --keyword "phrase" (required), --country US
#   keywords:   --keywords "a,b,c" (required, comma-separated, max 10), --country US
#   apps/ads:   all other options pass through as query parameters:
#               --search "fitness"    -> search=fitness
#               --sortBy revenue      -> sortBy=revenue
#               --minRevenue 10000    -> minRevenue=10000
#
# Examples:
#   appkittie.sh apps --sortBy trending --limit 20
#   appkittie.sh apps --categories "Health & Fitness" --sortBy revenue --sortOrder desc --limit 10
#   appkittie.sh apps --growthPeriod 7d --sortBy growth --sortOrder desc --limit 20
#   appkittie.sh apps --search meditation --minRevenue 10000 --hasMetaAds true
#   appkittie.sh app --id 1234567890
#   appkittie.sh ads --appSlug headspace-meditation-sleep --status active --limit 10
#   appkittie.sh reviews --id 1234567890 --maxReviews 50
#   appkittie.sh keyword --keyword "sleep tracker" --country US
#   appkittie.sh keywords --keywords "meditation,sleep tracker,mindfulness" --country US

set -euo pipefail

API_KEY="${APPKITTIE_API_KEY:?Set APPKITTIE_API_KEY environment variable}"
BASE_URL="${APPKITTIE_BASE_URL:-https://www.appkittie.com.proxy.chorus.com}/api/v1"
USE_JQ=true

die() { echo "ERROR: $*" >&2; exit 1; }

show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  exit 0
}

urlencode() {
  printf '%s' "$1" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe=''))" 2>/dev/null \
    || printf '%s' "$1" | sed 's/ /%20/g;s/&/%26/g;s/=/%3D/g;s/?/%3F/g;s/#/%23/g;s/+/%2B/g'
}

[[ $# -eq 0 ]] && show_help
COMMAND="$1"
shift

[[ "$COMMAND" == "--help" || "$COMMAND" == "-h" ]] && show_help

APP_ID=""
KEYWORD=""
KEYWORDS=""
COUNTRY=""
MAX_REVIEWS=""
OFFSET=""
declare -a PARAMS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help
      ;;
    --key)
      API_KEY="$2"
      shift 2
      ;;
    --raw)
      USE_JQ=false
      shift
      ;;
    --id)
      APP_ID="$2"
      shift 2
      ;;
    --keyword)
      KEYWORD="$2"
      shift 2
      ;;
    --keywords)
      KEYWORDS="$2"
      shift 2
      ;;
    --country)
      COUNTRY="$2"
      shift 2
      ;;
    --maxReviews)
      MAX_REVIEWS="$2"
      # Also add to PARAMS so it passes through as a query param for apps/ads commands
      PARAMS+=("maxReviews=$(urlencode "$2")")
      shift 2
      ;;
    --offset)
      OFFSET="$2"
      shift 2
      ;;
    --*)
      # Convert --param_name value to param_name=value
      param="${1#--}"
      if [[ $# -ge 2 && ! "$2" =~ ^-- ]]; then
        PARAMS+=("${param}=$(urlencode "$2")")
        shift 2
      else
        # Flag without value (treat as boolean true)
        PARAMS+=("${param}=true")
        shift
      fi
      ;;
    *)
      die "Unexpected argument: $1. Use --param value format."
      ;;
  esac
done

query_string() {
  local joined=""
  for p in "${PARAMS[@]+"${PARAMS[@]}"}"; do
    joined="${joined}&${p}"
  done
  printf '%s' "${joined#&}"
}

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

get() {
  curl -sSw '%{http_code}' --connect-timeout 20 --max-time 60 -o "$tmpfile" -H "Authorization: Bearer ${API_KEY}" "$1"
}

case "$COMMAND" in
  apps)
    http_code=$(get "${BASE_URL}/apps?$(query_string)")
    ;;
  app)
    [[ -n "$APP_ID" ]] || die "app requires --id APPID"
    http_code=$(get "${BASE_URL}/apps/${APP_ID}")
    ;;
  ads)
    http_code=$(get "${BASE_URL}/ads?$(query_string)")
    ;;
  ad)
    [[ -n "$APP_ID" ]] || die "ad requires --id ADID (ad_doc_id from an ads search)"
    AD_ID="$APP_ID"
    http_code=$(get "${BASE_URL}/ads/${AD_ID}")
    ;;
  reviews)
    [[ -n "$APP_ID" ]] || die "reviews requires --id APPID"
    command -v jq &>/dev/null || die "reviews requires jq to build the JSON body"
    body=$(jq -cn --arg id "$APP_ID" --arg country "${COUNTRY:-US}" \
      --argjson max "${MAX_REVIEWS:-100}" --argjson offset "${OFFSET:-0}" \
      '{appId: $id, country: $country, maxReviews: $max, offset: $offset}')
    http_code=$(curl -sSw '%{http_code}' --connect-timeout 20 --max-time 60 -o "$tmpfile" -X POST \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" \
      "${BASE_URL}/reviews")
    ;;
  keyword)
    [[ -n "$KEYWORD" ]] || die "keyword requires --keyword \"phrase\""
    query="keyword=$(urlencode "$KEYWORD")"
    [[ -n "$COUNTRY" ]] && query="${query}&country=${COUNTRY}"
    http_code=$(get "${BASE_URL}/keywords/difficulty?${query}")
    ;;
  keywords)
    [[ -n "$KEYWORDS" ]] || die "keywords requires --keywords \"a,b,c\""
    command -v jq &>/dev/null || die "keywords (batch) requires jq to build the JSON body"
    body=$(jq -cn --arg kw "$KEYWORDS" --arg country "${COUNTRY:-US}" \
      '{keywords: ($kw | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))), country: $country}')
    http_code=$(curl -sSw '%{http_code}' --connect-timeout 20 --max-time 60 -o "$tmpfile" -X POST \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" \
      "${BASE_URL}/keywords/difficulty")
    ;;
  *)
    die "Unknown command: $COMMAND. Run with --help for usage."
    ;;
esac

if [[ "$http_code" -ge 400 ]]; then
  case "$http_code" in
    401) echo "HTTP 401: missing or invalid API key (check APPKITTIE_API_KEY)" >&2 ;;
    402) echo "HTTP 402: out of credits - stop retrying" >&2 ;;
    404)
      case "$COMMAND" in
        ad)      echo "HTTP 404: unknown ad id - verify the ad_doc_id with an ads search" >&2 ;;
        keyword|keywords) echo "HTTP 404: keyword endpoint not found - check your API key permissions" >&2 ;;
        *)       echo "HTTP 404: unknown app id - verify it with an apps search" >&2 ;;
      esac
      ;;
    429) echo "HTTP 429: rate limited - wait for the 60s window to roll, then retry" >&2 ;;
    *)   echo "HTTP $http_code error:" >&2 ;;
  esac
  if command -v jq &>/dev/null; then
    jq -r '.error // .' "$tmpfile" 2>/dev/null || cat "$tmpfile"
  else
    cat "$tmpfile"
  fi >&2
  exit 1
fi

if [[ "$USE_JQ" == true ]] && command -v jq &>/dev/null; then
  jq '.' "$tmpfile"
else
  cat "$tmpfile"
fi
