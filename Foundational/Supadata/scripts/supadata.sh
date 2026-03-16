#!/usr/bin/env bash
# supadata.sh — Wrapper for Supadata API (transcripts, metadata, web scraping, YouTube)
# Usage: bash scripts/supadata.sh <command> [options]
#
# Commands:
#   me                         Account info (credits, plan)
#   transcript                 Get transcript (YouTube, TikTok, Instagram, X, Facebook, file URL)
#   transcript-job             Poll async transcript job
#   metadata                   Get video/post metadata (any platform)
#   extract                    AI extraction from video (async)
#   extract-job                Poll AI extraction job
#   web-scrape                 Scrape webpage to markdown
#   web-map                    List all URLs on a website
#   web-crawl                  Async crawl entire website
#   web-crawl-job              Poll crawl job
#   yt-transcript              YouTube transcript (by URL or videoId)
#   yt-transcript-translate    Translate YouTube transcript
#   yt-transcript-batch        Batch transcripts (async)
#   yt-video                   YouTube video metadata
#   yt-video-batch             Batch video metadata (async)
#   yt-batch-job               Poll YouTube batch job (transcripts or videos)
#   yt-channel                 YouTube channel info
#   yt-channel-videos          List channel video IDs
#   yt-playlist                YouTube playlist info
#   yt-playlist-videos         List playlist video IDs
#   yt-search                  Search YouTube
#
# Global options:
#   --key KEY           Override SUPADATA_API_KEY env var
#   --raw               Output raw JSON (skip jq formatting)
#   --timeout SECS      Curl timeout (default: 60)
#   --help              Show this help
#
# GET endpoint options are passed as query parameters:
#   --url "https://..."         → url=<encoded>
#   --videoId dQw4w9WgXcQ       → videoId=dQw4w9WgXcQ
#   --lang en                   → lang=en
#   --text true                 → text=true
#   --limit 20                  → limit=20
#
# POST endpoint options are passed as JSON body fields:
#   --url "https://..."         → {"url": "..."}
#   --prompt "summarize"        → {"prompt": "summarize"}
#   --schema '{"type":"object"}'→ {"schema": {...}}
#   --videoIds '["id1","id2"]'  → {"videoIds": ["id1","id2"]}
#   --playlistId PLID           → {"playlistId": "PLID"}
#   --channelId @handle         → {"channelId": "@handle"}
#
# Examples:
#   supadata.sh me
#   supadata.sh transcript --url "https://youtu.be/dQw4w9WgXcQ" --text true --lang en
#   supadata.sh metadata --url "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
#   supadata.sh extract --url "https://youtube.com/watch?v=abc" --prompt "List all products"
#   supadata.sh extract-job --jobId abc-123
#   supadata.sh web-scrape --url "https://example.com"
#   supadata.sh web-map --url "https://example.com"
#   supadata.sh web-crawl --url "https://example.com" --limit 50
#   supadata.sh web-crawl-job --jobId abc-123
#   supadata.sh yt-transcript --videoId dQw4w9WgXcQ --lang en --text true
#   supadata.sh yt-transcript-translate --videoId dQw4w9WgXcQ --lang es --text true
#   supadata.sh yt-transcript-batch --videoIds '["dQw4w9WgXcQ","xvFZjo5PgG0"]' --lang en --text true
#   supadata.sh yt-video --id dQw4w9WgXcQ
#   supadata.sh yt-video-batch --videoIds '["dQw4w9WgXcQ"]'
#   supadata.sh yt-batch-job --jobId abc-123
#   supadata.sh yt-channel --id "@RickAstley"
#   supadata.sh yt-channel-videos --id "@RickAstley" --limit 50 --type video
#   supadata.sh yt-playlist --id PLlaN88a7y2_plecYoJxvRFTLHVbIVAOoc
#   supadata.sh yt-playlist-videos --id PLlaN88a7y2_plecYoJxvRFTLHVbIVAOoc --limit 100
#   supadata.sh yt-search --query "machine learning" --type video --limit 20 --sortBy views

set -euo pipefail

BASE="https://api.supadata.ai.cloudproxy.vibecodeapp.com/v1"
API_KEY="${SUPADATA_API_KEY:-}"
USE_JQ=true
TIMEOUT=60

die() { echo "ERROR: $*" >&2; exit 1; }

show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  exit 0
}

urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

# Parse global options and split out command-specific options
CMD="${1:-}"
[[ -z "$CMD" || "$CMD" == "--help" ]] && show_help
shift

PARAMS=()    # For GET query params: "key=value" pairs
BODY_ARGS=() # For POST JSON body: "--key value" pairs

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)      API_KEY="$2"; shift 2 ;;
    --raw)      USE_JQ=false; shift ;;
    --timeout)  TIMEOUT="$2"; shift 2 ;;
    --help)     show_help ;;
    --*)
      key="${1#--}"
      if [[ $# -ge 2 && ! "$2" =~ ^-- ]]; then
        PARAMS+=("${key}=$2")
        BODY_ARGS+=("$key" "$2")
        shift 2
      else
        PARAMS+=("${key}=true")
        BODY_ARGS+=("$key" "true")
        shift
      fi
      ;;
    *) die "Unexpected argument: $1" ;;
  esac
done

[[ -n "$API_KEY" ]] || die "Set SUPADATA_API_KEY environment variable or pass --key"

# Build query string from PARAMS (URL-encodes all values)
build_qs() {
  local qs=""
  for p in "${PARAMS[@]}"; do
    local k="${p%%=*}"
    local v="${p#*=}"
    v=$(urlencode "$v")
    if [[ -z "$qs" ]]; then
      qs="?${k}=${v}"
    else
      qs="${qs}&${k}=${v}"
    fi
  done
  echo "$qs"
}

# Build JSON body from BODY_ARGS pairs
build_json() {
  local json="{"
  local first=true
  local i=0
  while [[ $i -lt ${#BODY_ARGS[@]} ]]; do
    local k="${BODY_ARGS[$i]}"
    local v="${BODY_ARGS[$((i+1))]}"
    i=$((i+2))

    $first || json+=","
    first=false

    # Detect JSON values (arrays, objects, numbers, booleans, null)
    if [[ "$v" =~ ^\[.*\]$ ]] || [[ "$v" =~ ^\{.*\}$ ]] || \
       [[ "$v" =~ ^[0-9]+(\.[0-9]+)?$ ]] || \
       [[ "$v" == "true" ]] || [[ "$v" == "false" ]] || [[ "$v" == "null" ]]; then
      json+="\"${k}\":${v}"
    else
      # Escape double quotes in string values
      v="${v//\\/\\\\}"
      v="${v//\"/\\\"}"
      json+="\"${k}\":\"${v}\""
    fi
  done
  json+="}"
  echo "$json"
}

# GET request
api_get() {
  local path="$1"
  local qs
  qs=$(build_qs)
  local url="${BASE}${path}${qs}"

  local resp
  resp=$(curl -sf --max-time "$TIMEOUT" "$url" \
    -H "x-api-key: ${API_KEY}") || {
    # Retry with error output visible
    curl -s --max-time "$TIMEOUT" "$url" \
      -H "x-api-key: ${API_KEY}" >&2
    exit 1
  }

  if $USE_JQ && command -v jq &>/dev/null; then
    echo "$resp" | jq .
  else
    echo "$resp"
  fi
}

# POST request
api_post() {
  local path="$1"
  local body
  body=$(build_json)

  local resp
  resp=$(curl -sf --max-time "$TIMEOUT" -X POST "${BASE}${path}" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body") || {
    curl -s --max-time "$TIMEOUT" -X POST "${BASE}${path}" \
      -H "x-api-key: ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" >&2
    exit 1
  }

  if $USE_JQ && command -v jq &>/dev/null; then
    echo "$resp" | jq .
  else
    echo "$resp"
  fi
}

# Poll an async job until completed or failed
# Usage: poll_job <path_prefix> <jobId>
# e.g.: poll_job "/extract" "abc-123" → polls GET /extract/abc-123
poll_job() {
  local path_prefix="$1"
  local job_id="$2"
  local url="${BASE}${path_prefix}/${job_id}"
  local status=""
  local resp=""

  echo "Polling job ${job_id}..." >&2
  while true; do
    resp=$(curl -sf --max-time "$TIMEOUT" "$url" \
      -H "x-api-key: ${API_KEY}") || {
      curl -s --max-time "$TIMEOUT" "$url" \
        -H "x-api-key: ${API_KEY}" >&2
      exit 1
    }

    status=$(echo "$resp" | jq -r '.status // empty')
    echo "  Status: ${status:-unknown}" >&2

    case "$status" in
      completed|failed)
        if $USE_JQ && command -v jq &>/dev/null; then
          echo "$resp" | jq .
        else
          echo "$resp"
        fi
        return
        ;;
    esac
    sleep 1
  done
}

# Extract a named param from PARAMS array
get_param() {
  local target="$1"
  for p in "${PARAMS[@]}"; do
    local k="${p%%=*}"
    local v="${p#*=}"
    if [[ "$k" == "$target" ]]; then
      echo "$v"
      return
    fi
  done
}

# ── Command dispatch ─────────────────────────────────────────────

case "$CMD" in

  # ── Account ──
  me)
    PARAMS=()  # /me takes no params
    api_get "/me"
    ;;

  # ── Multi-platform transcript ──
  transcript)
    api_get "/transcript"
    ;;

  transcript-job)
    JOB_ID=$(get_param "jobId")
    [[ -n "$JOB_ID" ]] || die "Required: --jobId <id>"
    poll_job "/transcript" "$JOB_ID"
    ;;

  # ── Multi-platform metadata ──
  metadata)
    api_get "/metadata"
    ;;

  # ── AI extraction (async) ──
  extract)
    api_post "/extract"
    ;;

  extract-job)
    JOB_ID=$(get_param "jobId")
    [[ -n "$JOB_ID" ]] || die "Required: --jobId <id>"
    poll_job "/extract" "$JOB_ID"
    ;;

  # ── Web scraping ──
  web-scrape)
    api_get "/web/scrape"
    ;;

  web-map)
    api_get "/web/map"
    ;;

  web-crawl)
    api_post "/web/crawl"
    ;;

  web-crawl-job)
    JOB_ID=$(get_param "jobId")
    [[ -n "$JOB_ID" ]] || die "Required: --jobId <id>"
    poll_job "/web/crawl" "$JOB_ID"
    ;;

  # ── YouTube transcripts ──
  yt-transcript)
    api_get "/youtube/transcript"
    ;;

  yt-transcript-translate)
    api_get "/youtube/transcript/translate"
    ;;

  yt-transcript-batch)
    api_post "/youtube/transcript/batch"
    ;;

  # ── YouTube video metadata ──
  yt-video)
    api_get "/youtube/video"
    ;;

  yt-video-batch)
    api_post "/youtube/video/batch"
    ;;

  # ── YouTube batch job polling ──
  yt-batch-job)
    JOB_ID=$(get_param "jobId")
    [[ -n "$JOB_ID" ]] || die "Required: --jobId <id>"
    poll_job "/youtube/batch" "$JOB_ID"
    ;;

  # ── YouTube channels & playlists ──
  yt-channel)
    api_get "/youtube/channel"
    ;;

  yt-channel-videos)
    api_get "/youtube/channel/videos"
    ;;

  yt-playlist)
    api_get "/youtube/playlist"
    ;;

  yt-playlist-videos)
    api_get "/youtube/playlist/videos"
    ;;

  # ── YouTube search ──
  yt-search)
    api_get "/youtube/search"
    ;;

  # ── Unknown ──
  *)
    die "Unknown command: $CMD. Run: supadata.sh --help"
    ;;
esac
