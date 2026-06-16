#!/usr/bin/env bash
# youtube-video-download.sh - create and poll a YouTube Video Downloader job.
#
# Examples:
#   bash scripts/youtube-video-download.sh --url "https://www.youtube.com/watch?v=OxFyVcO1Yow&t=73s"
#   bash scripts/youtube-video-download.sh --url "https://youtu.be/OxFyVcO1Yow" --quality 720

set -euo pipefail

BASE_URL="${CLIPPER_BASE_URL:-https://clipper.chorus.com}"
PROJECT_ID="${VIBECODE_PROJECT_ID:-${CHORUS_PROJECT_ID:-${PROJECT_ID:-}}}"
PROJECT_HEADER="${CLIPPER_PROJECT_HEADER:-X-Chorus-Project-ID}"
POLL_SECONDS="${CLIPPER_POLL_SECONDS:-15}"
TIMEOUT_SECONDS="${CLIPPER_TIMEOUT_SECONDS:-900}"
URL=""
QUALITY=""
CREATE_ONLY=false
RAW=false
RESPONSE_BODY=""
RESPONSE_STATUS=""

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
  --base-url URL          Downloader base URL
  --project-id ID         Project attribution value
  --project-header NAME   Project header name, default X-Chorus-Project-ID
  --poll-seconds N        Poll interval, default 15
  --timeout-seconds N     Overall wait timeout, default 900
  --create-only           Create the job and do not poll
  --raw                   Print compact JSON
  --help                  Show this help
USAGE
}

require_next() {
  local flag="$1"
  local value="${2:-}"

  [[ $# -ge 2 && -n "$value" ]] || die "${flag} requires a value"
  [[ "$value" != --* ]] || die "${flag} requires a value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) require_next "$@"; URL="$2"; shift 2 ;;
    --quality) require_next "$@"; QUALITY="$2"; shift 2 ;;
    --base-url) require_next "$@"; BASE_URL="$2"; shift 2 ;;
    --project-id) require_next "$@"; PROJECT_ID="$2"; shift 2 ;;
    --project-header) require_next "$@"; PROJECT_HEADER="$2"; shift 2 ;;
    --poll-seconds) require_next "$@"; POLL_SECONDS="$2"; shift 2 ;;
    --timeout-seconds) require_next "$@"; TIMEOUT_SECONDS="$2"; shift 2 ;;
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
[[ -n "$PROJECT_ID" ]] || die "Set VIBECODE_PROJECT_ID, CHORUS_PROJECT_ID, or pass --project-id"
command -v jq >/dev/null 2>&1 || die "jq is required"
command -v curl >/dev/null 2>&1 || die "curl is required"

http_status_allowed() {
  local status="$1"
  shift

  [[ "$status" =~ ^[0-9][0-9][0-9]$ ]] || return 1
  if [[ "$status" -ge 200 && "$status" -lt 300 ]]; then
    return 0
  fi
  for allowed in "$@"; do
    [[ "$status" == "$allowed" ]] && return 0
  done
  return 1
}

api_request() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  shift 3
  local tmp status
  RESPONSE_BODY=""
  RESPONSE_STATUS=""
  tmp="$(mktemp)"

  if [[ -n "$body" ]]; then
    if ! status="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$url" \
      -H "Content-Type: application/json" \
      -H "${PROJECT_HEADER}: ${PROJECT_ID}" \
      -d "$body")"; then
      rm -f "$tmp"
      return 1
    fi
  else
    if ! status="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$url" \
      -H "${PROJECT_HEADER}: ${PROJECT_ID}")"; then
      rm -f "$tmp"
      return 1
    fi
  fi

  RESPONSE_STATUS="$status"
  RESPONSE_BODY="$(cat "$tmp")"
  rm -f "$tmp"

  if ! http_status_allowed "$status" "$@"; then
    echo "HTTP $status from $url" >&2
    printf '%s' "$RESPONSE_BODY" >&2
    return 1
  fi
}

print_json() {
  if $RAW; then
    jq -c .
  else
    jq .
  fi
}

exit_if_terminal() {
  local response="$1"
  local http_status="$2"
  local status
  status="$(jq -r '.download.status // empty' <<<"$response")"

  case "$status" in
    failed)
      print_json <<<"$response" >&2
      exit 2
      ;;
    expired)
      print_json <<<"$response" >&2
      exit 3
      ;;
  esac

  case "$http_status" in
    409)
      print_json <<<"$response" >&2
      exit 2
      ;;
    410)
      print_json <<<"$response" >&2
      exit 3
      ;;
  esac
}

payload="$(
  jq -cn --arg url "$URL" --arg quality "$QUALITY" \
    'if $quality == "" then {url: $url} else {url: $url, quality: $quality} end'
)"

api_request POST "${BASE_URL%/}/v1/youtube/downloads" "$payload" 409
create_response="$RESPONSE_BODY"
exit_if_terminal "$create_response" "$RESPONSE_STATUS"
download_id="$(jq -er '.download.id' <<<"$create_response")"

if $CREATE_ONLY; then
  print_json <<<"$create_response"
  exit 0
fi

deadline=$((SECONDS + TIMEOUT_SECONDS))
while true; do
  api_request GET "${BASE_URL%/}/v1/youtube/downloads/${download_id}" "" 409 410
  status_response="$RESPONSE_BODY"
  exit_if_terminal "$status_response" "$RESPONSE_STATUS"
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
