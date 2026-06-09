#!/usr/bin/env bash
# scrapecreators.sh - generic GET wrapper for the ScrapeCreators API.
# Usage: bash scripts/scrapecreators.sh <command-or-path> [--param value ...]

set -euo pipefail

BASE_URL="${SCRAPECREATORS_BASE_URL:-https://api.scrapecreators.com.proxy.chorus.com}"
API_KEY="${SCRAPECREATORS_API_KEY:-}"
TIMEOUT=90
USE_JQ=true

die() {
  echo "ERROR: $*" >&2
  exit 1
}

show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
  cat <<'USAGE'

Examples:
  scrapecreators.sh tiktok-profile --handle stoolpresidente
  scrapecreators.sh youtube-search --query "ai tutorials" --type video
  scrapecreators.sh facebook-ad-search --query nike --country US
  scrapecreators.sh /v1/reddit/search --query "best laptops"

Global options:
  --key KEY          Override SCRAPECREATORS_API_KEY
  --base-url URL     Override SCRAPECREATORS_BASE_URL
  --timeout SECS     Curl max time, default 90
  --raw              Print raw JSON without jq formatting
  --help             Show this help

All other --name value pairs become query parameters.
USAGE
}

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

resolve_path() {
  case "$1" in
    tiktok-profile) echo "/v1/tiktok/profile" ;;
    tiktok-videos) echo "/v3/tiktok/profile/videos" ;;
    tiktok-video) echo "/v2/tiktok/video" ;;
    tiktok-transcript) echo "/v1/tiktok/video/transcript" ;;
    tiktok-search) echo "/v1/tiktok/search/keyword" ;;
    instagram-profile) echo "/v1/instagram/profile" ;;
    instagram-post) echo "/v1/instagram/post" ;;
    instagram-posts) echo "/v2/instagram/user/posts" ;;
    instagram-reels) echo "/v1/instagram/user/reels" ;;
    instagram-reels-search) echo "/v2/instagram/reels/search" ;;
    instagram-transcript) echo "/v2/instagram/media/transcript" ;;
    youtube-channel) echo "/v1/youtube/channel" ;;
    youtube-channel-videos) echo "/v1/youtube/channel-videos" ;;
    youtube-search) echo "/v1/youtube/search" ;;
    youtube-video) echo "/v1/youtube/video" ;;
    youtube-transcript) echo "/v1/youtube/video/transcript" ;;
    youtube-comments) echo "/v1/youtube/video/comments" ;;
    facebook-profile) echo "/v1/facebook/profile" ;;
    facebook-post) echo "/v1/facebook/post" ;;
    facebook-comments) echo "/v1/facebook/post/comments" ;;
    facebook-ad-search) echo "/v1/facebook/adLibrary/search/ads" ;;
    facebook-ad) echo "/v1/facebook/adLibrary/ad" ;;
    facebook-company-ads) echo "/v1/facebook/adLibrary/company/ads" ;;
    google-search) echo "/v1/google/search" ;;
    google-company-ads) echo "/v1/google/company/ads" ;;
    google-ad) echo "/v1/google/ad" ;;
    linkedin-profile) echo "/v1/linkedin/profile" ;;
    linkedin-company) echo "/v1/linkedin/company" ;;
    linkedin-post) echo "/v1/linkedin/post" ;;
    linkedin-ads-search) echo "/v1/linkedin/ads/search" ;;
    twitter-profile) echo "/v1/twitter/profile" ;;
    twitter-tweets) echo "/v1/twitter/user-tweets" ;;
    twitter-tweet) echo "/v1/twitter/tweet" ;;
    reddit-search) echo "/v1/reddit/search" ;;
    reddit-post-comments) echo "/v1/reddit/post/comments" ;;
    threads-profile) echo "/v1/threads/profile" ;;
    threads-search) echo "/v1/threads/search" ;;
    bluesky-profile) echo "/v1/bluesky/profile" ;;
    pinterest-search) echo "/v1/pinterest/search" ;;
    github-user) echo "/v1/github/user" ;;
    github-repo) echo "/v1/github/repository" ;;
    spotify-search) echo "/v1/spotify/search" ;;
    /v*) echo "$1" ;;
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

[[ -n "$API_KEY" ]] || die "Set SCRAPECREATORS_API_KEY or pass --key"

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
    --header "x-api-key: ${API_KEY}" \
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
