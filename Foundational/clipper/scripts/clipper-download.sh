#!/usr/bin/env bash
# clipper-download.sh - create and poll a Clipper YouTube download job.
#
# Examples:
#   bash scripts/clipper-download.sh --url "https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s"
#   bash scripts/clipper-download.sh --url "https://youtu.be/OxFyVcO1Yow" --quality 720

set -euo pipefail

BASE_URL="${CLIPPER_BASE_URL:-https://clipper.chorus.com}"
PROJECT_ID="${CLIPPER_PROJECT_ID:-${VIBECODE_PROJECT_ID:-${CHORUS_PROJECT_ID:-${PROJECT_ID:-}}}}"
PROJECT_HEADER="${CLIPPER_PROJECT_HEADER:-X-Vibecode-Project}"
POLL_SECONDS="${CLIPPER_POLL_SECONDS:-15}"
TIMEOUT_SECONDS="${CLIPPER_TIMEOUT_SECONDS:-900}"
URL=""
QUALITY=""
CREATE_ONLY=false
RAW=false

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  cat <<'USAGE'

Options:
  --url URL               YouTube URL or video ID to download
  --quality QUALITY       Optional target quality, for example 720
  --base-url URL          Clipper base URL
  --project-id ID         Project attribution value
  --project-header NAME   Project header name, default X-Vibecode-Project
  --poll-seconds N        Poll interval, default 15
  --timeout-seconds N     Overall wait timeout, default 900
  --create-only           Create the job and do not poll
  --raw                   Print compact JSON
  --help                  Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="${2:-}"; shift 2 ;;
    --quality) QUALITY="${2:-}"; shift 2 ;;
    --base-url) BASE_URL="${2:-}"; shift 2 ;;
    --project-id) PROJECT_ID="${2:-}"; shift 2 ;;
    --project-header) PROJECT_HEADER="${2:-}"; shift 2 ;;
    --poll-seconds) POLL_SECONDS="${2:-}"; shift 2 ;;
    --timeout-seconds) TIMEOUT_SECONDS="${2:-}"; shift 2 ;;
    --create-only) CREATE_ONLY=true; shift ;;
    --raw) RAW=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *)
      if [[ -z "$URL" ]]; then
        URL="$1"
        shift
      else
        die "Unexpected argument: $1"
      fi
      ;;
  esac
done

[[ -n "$URL" ]] || die "Pass --url or provide a YouTube URL as the first positional argument"
[[ -n "$PROJECT_ID" ]] || die "Set CLIPPER_PROJECT_ID, VIBECODE_PROJECT_ID, CHORUS_PROJECT_ID, or pass --project-id"
command -v jq >/dev/null 2>&1 || die "jq is required"
command -v curl >/dev/null 2>&1 || die "curl is required"

api_request() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local tmp status
  tmp="$(mktemp)"

  if [[ -n "$body" ]]; then
    status="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$url" \
      -H "Content-Type: application/json" \
      -H "${PROJECT_HEADER}: ${PROJECT_ID}" \
      -d "$body")"
  else
    status="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$url" \
      -H "${PROJECT_HEADER}: ${PROJECT_ID}")"
  fi

  if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
    echo "HTTP $status from $url" >&2
    cat "$tmp" >&2
    rm -f "$tmp"
    exit 1
  fi

  cat "$tmp"
  rm -f "$tmp"
}

print_json() {
  if $RAW; then
    jq -c .
  else
    jq .
  fi
}

payload="$(
  jq -cn --arg url "$URL" --arg quality "$QUALITY" \
    'if $quality == "" then {url: $url} else {url: $url, quality: $quality} end'
)"

create_response="$(api_request POST "${BASE_URL%/}/v1/youtube/downloads" "$payload")"
download_id="$(jq -er '.download.id' <<<"$create_response")"

if $CREATE_ONLY; then
  print_json <<<"$create_response"
  exit 0
fi

deadline=$((SECONDS + TIMEOUT_SECONDS))
while true; do
  status_response="$(api_request GET "${BASE_URL%/}/v1/youtube/downloads/${download_id}")"
  status="$(jq -r '.download.status // empty' <<<"$status_response")"
  progress="$(jq -r '.download.progress // empty' <<<"$status_response")"

  case "$status" in
    ready)
      print_json <<<"$status_response"
      exit 0
      ;;
    failed)
      print_json <<<"$status_response" >&2
      exit 2
      ;;
    expired)
      print_json <<<"$status_response" >&2
      exit 3
      ;;
    pending|processing|queued|"")
      if [[ "$SECONDS" -ge "$deadline" ]]; then
        echo "Timed out waiting for ${download_id}" >&2
        print_json <<<"$status_response" >&2
        exit 4
      fi
      if [[ -n "$progress" && "$progress" != "null" ]]; then
        echo "${download_id}: ${status:-pending} (${progress}%)" >&2
      else
        echo "${download_id}: ${status:-pending}" >&2
      fi
      sleep "$POLL_SECONDS"
      ;;
    *)
      echo "Unexpected status '${status}' for ${download_id}" >&2
      print_json <<<"$status_response" >&2
      exit 5
      ;;
  esac
done
