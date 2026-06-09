#!/usr/bin/env bash
# foreplay.sh - generic GET wrapper for the Foreplay Public API.
# Usage: bash scripts/foreplay.sh <command-or-path> [--param value ...]

set -euo pipefail

BASE_URL="${FOREPLAY_BASE_URL:-https://public.api.foreplay.co.proxy.chorus.com}"
API_KEY="${FOREPLAY_API_KEY:-}"
TIMEOUT=60
USE_JQ=true

die() {
  echo "ERROR: $*" >&2
  exit 1
}

show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
  cat <<'USAGE'

Commands:
  usage                       /api/usage
  swipefile-ads               /api/swipefile/ads
  boards                      /api/boards
  board-brands                /api/board/brands
  board-ads                   /api/board/ads
  spyder-brands               /api/spyder/brands
  spyder-brand                /api/spyder/brand
  spyder-brand-ads            /api/spyder/brand/ads
  ad                          /api/ad
  brand-ads                   /api/brand/getAdsByBrandId
  page-ads                    /api/brand/getAdsByPageId
  brand-domain                /api/brand/getBrandsByDomain
  brand-analytics             /api/brand/analytics
  discovery-ads               /api/discovery/ads
  discovery-brands            /api/discovery/brands
  discovery-brands-explore    /api/discovery/brands/explore

You may also pass a documented path directly, such as /api/ad/duplicates/ad_123.

Global options:
  --key KEY          Override FOREPLAY_API_KEY
  --base-url URL     Override FOREPLAY_BASE_URL
  --timeout SECS     Curl max time, default 60
  --raw              Print raw JSON without jq formatting
  --help             Show this help

All other --name value pairs become query parameters. Repeat a flag to send
multiple values, e.g. --display_format video --display_format carousel.
USAGE
}

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

resolve_path() {
  case "$1" in
    usage) echo "/api/usage" ;;
    swipefile-ads) echo "/api/swipefile/ads" ;;
    boards) echo "/api/boards" ;;
    board-brands) echo "/api/board/brands" ;;
    board-ads) echo "/api/board/ads" ;;
    spyder-brands) echo "/api/spyder/brands" ;;
    spyder-brand) echo "/api/spyder/brand" ;;
    spyder-brand-ads) echo "/api/spyder/brand/ads" ;;
    ad) echo "/api/ad" ;;
    brand-ads) echo "/api/brand/getAdsByBrandId" ;;
    page-ads) echo "/api/brand/getAdsByPageId" ;;
    brand-domain) echo "/api/brand/getBrandsByDomain" ;;
    brand-analytics) echo "/api/brand/analytics" ;;
    discovery-ads) echo "/api/discovery/ads" ;;
    discovery-brands) echo "/api/discovery/brands" ;;
    discovery-brands-explore) echo "/api/discovery/brands/explore" ;;
    /api/*) echo "$1" ;;
    *) die "Unknown command or path: $1" ;;
  esac
}

[[ $# -eq 0 ]] && { show_help; exit 0; }

COMMAND="$1"
shift
[[ "$COMMAND" == "--help" || "$COMMAND" == "-h" ]] && { show_help; exit 0; }

PATH_PART="$(resolve_path "$COMMAND")"
PARAMS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help
      exit 0
      ;;
    --key)
      [[ $# -ge 2 ]] || die "--key needs a value"
      API_KEY="$2"
      shift 2
      ;;
    --base-url)
      [[ $# -ge 2 ]] || die "--base-url needs a value"
      BASE_URL="$2"
      shift 2
      ;;
    --timeout)
      [[ $# -ge 2 ]] || die "--timeout needs a value"
      TIMEOUT="$2"
      shift 2
      ;;
    --raw)
      USE_JQ=false
      shift
      ;;
    --*)
      key="${1#--}"
      if [[ $# -ge 2 && "$2" != --* ]]; then
        PARAMS+=("${key}=$2")
        shift 2
      else
        PARAMS+=("${key}=true")
        shift
      fi
      ;;
    *)
      die "Unexpected argument: $1. Use --param value."
      ;;
  esac
done

[[ -n "$API_KEY" ]] || die "Set FOREPLAY_API_KEY or pass --key"

URL="${BASE_URL%/}${PATH_PART}"
if [[ ${#PARAMS[@]} -gt 0 ]]; then
  sep="?"
  for pair in "${PARAMS[@]}"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    URL="${URL}${sep}${key}=$(urlencode "$value")"
    sep="&"
  done
fi

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

http_code="$(
  curl --silent --show-error --location \
    --connect-timeout 20 --max-time "$TIMEOUT" \
    --header "Accept: application/json" \
    --header "Authorization: ${API_KEY}" \
    --write-out '%{http_code}' \
    --output "$tmpfile" \
    "$URL"
)"

if [[ "$http_code" -ge 400 ]]; then
  echo "HTTP ${http_code} error:" >&2
  cat "$tmpfile" >&2
  echo >&2
  exit 1
fi

if $USE_JQ && command -v jq >/dev/null 2>&1; then
  jq . "$tmpfile"
else
  cat "$tmpfile"
  echo
fi
