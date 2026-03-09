#!/usr/bin/env bash
# serpapi.sh — Wrapper for SerpApi search engine APIs
# Usage: bash scripts/serpapi.sh <engine> [options]
#
# Engines:
#   google              Google Web Search
#   google_images       Google Images Search
#   google_maps         Google Maps Search / Place Details
#   google_maps_reviews Google Maps Reviews
#   google_flights      Google Flights
#   google_flights_autocomplete  Flights airport autocomplete
#   google_hotels       Google Hotels
#   google_hotels_autocomplete   Hotels autocomplete
#   google_hotels_reviews        Hotel property reviews
#   google_scholar      Google Scholar
#   google_news         Google News
#   google_shopping     Google Shopping
#   google_jobs         Google Jobs
#   google_finance      Google Finance
#   google_trends       Google Trends
#   google_autocomplete Google Autocomplete
#   google_local_services  Google Local Services
#   google_events       Google Events
#   google_ads_transparency_center  Ads Transparency Center
#   youtube             YouTube Search
#   youtube_video       YouTube Video Details
#   youtube_video_transcript  YouTube Transcript
#   tripadvisor         Tripadvisor Search
#   tripadvisor_place   Tripadvisor Place Details
#   open_table_reviews  OpenTable Reviews
#   bing                Bing Search
#   duckduckgo          DuckDuckGo Search
#   yahoo               Yahoo Search
#   baidu               Baidu Search
#   yandex              Yandex Search
#   naver               Naver Search
#   walmart             Walmart Product Search
#   ebay                eBay Search
#   home_depot          Home Depot Search
#   apple_app_store     Apple App Store Search
#   google_play         Google Play Store Search
#
# Global options:
#   --key KEY           Override SERPAPI_API_KEY env var
#   --no-cache          Force fresh results (costs a credit)
#   --raw               Output raw JSON (skip jq formatting)
#   --help              Show this help
#
# All other options are passed as query parameters:
#   --q "coffee"        → q=coffee
#   --gl us             → gl=us
#   --departure_id JFK  → departure_id=JFK
#
# Examples:
#   serpapi.sh google --q "best coffee beans" --gl us --num 10
#   serpapi.sh google_flights --departure_id JFK --arrival_id LAX --outbound_date 2026-04-15 --type 2
#   serpapi.sh google_hotels --q "hotels in Paris" --check_in_date 2026-06-01 --check_out_date 2026-06-05
#   serpapi.sh google_maps --q "pizza" --ll "@40.7455,-74.0083,14z" --type search
#   serpapi.sh google_images --q "mountain landscape" --imgsz l
#   serpapi.sh youtube --search_query "learn python" --gl us
#   serpapi.sh youtube_video --v dQw4w9WgXcQ
#   serpapi.sh youtube_video_transcript --v dQw4w9WgXcQ --language_code en
#   serpapi.sh google_scholar --q "machine learning" --as_ylo 2023
#   serpapi.sh tripadvisor --q "restaurants Barcelona" --ssrc r
#   serpapi.sh open_table_reviews --rid "r/central-park-boathouse-new-york-2"
#   serpapi.sh google_trends --q "bitcoin,ethereum" --data_type TIMESERIES
#   serpapi.sh google_ads_transparency_center --advertiser_id AR17828074650563772417

set -euo pipefail

API_KEY="${SERPAPI_API_KEY:?Set SERPAPI_API_KEY environment variable}"
BASE_URL="https://serpapi.com.cloudproxy.vibecodeapp.com/search"
USE_JQ=true
NO_CACHE=""

die() { echo "ERROR: $*" >&2; exit 1; }

show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  exit 0
}

# --- Parse arguments ---
ENGINE=""
declare -a PARAMS=()

[[ $# -eq 0 ]] && show_help

# First positional argument is the engine
ENGINE="$1"
shift

[[ "$ENGINE" == "--help" || "$ENGINE" == "-h" ]] && show_help

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help
      ;;
    --key)
      API_KEY="$2"
      shift 2
      ;;
    --no-cache)
      NO_CACHE="true"
      shift
      ;;
    --raw)
      USE_JQ=false
      shift
      ;;
    --*)
      # Convert --param_name value to param_name=value
      param="${1#--}"
      if [[ $# -ge 2 && ! "$2" =~ ^-- ]]; then
        PARAMS+=("${param}=$(printf '%s' "$2")")
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

# --- Build URL ---
build_url() {
  local url="${BASE_URL}?engine=${ENGINE}&api_key=${API_KEY}"

  if [[ -n "$NO_CACHE" ]]; then
    url="${url}&no_cache=true"
  fi

  for p in "${PARAMS[@]}"; do
    local key="${p%%=*}"
    local val="${p#*=}"
    # URL-encode the value
    local encoded
    encoded=$(printf '%s' "$val" | python3 -c "import sys,urllib.parse;print(urllib.parse.quote(sys.stdin.read(),safe=''))" 2>/dev/null || printf '%s' "$val" | sed 's/ /%20/g;s/&/%26/g;s/=/%3D/g;s/?/%3F/g;s/#/%23/g;s/+/%2B/g')
    url="${url}&${key}=${encoded}"
  done

  echo "$url"
}

# --- Execute request ---
url=$(build_url)

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

http_code=$(curl -sw '%{http_code}' -o "$tmpfile" "$url")

if [[ "$http_code" -ge 400 ]]; then
  echo "HTTP $http_code error:" >&2
  if command -v jq &>/dev/null; then
    jq -r '.error // .' "$tmpfile" 2>/dev/null || cat "$tmpfile"
  else
    cat "$tmpfile"
  fi >&2
  exit 1
fi

# --- Output ---
if [[ "$USE_JQ" == true ]] && command -v jq &>/dev/null; then
  jq '.' "$tmpfile"
else
  cat "$tmpfile"
fi
