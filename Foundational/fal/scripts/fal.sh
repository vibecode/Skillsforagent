#!/usr/bin/env bash
# fal.sh — Wrapper for fal.ai Model API (600+ generative models)
# Usage: bash scripts/fal.sh <command> [options]
#
# Commands:
#   run                  Synchronous model execution (fast, simple)
#   queue                Queue-based async execution (reliable, recommended)
#   status               Poll queue request status
#   result               Get queue request result
#   cancel               Cancel a queued request
#   search               Search/list available models
#   schema               Get a model's OpenAPI input/output schema
#   pricing              Get model pricing
#   estimate             Estimate cost for model usage
#
# Global options:
#   --key KEY            Override FAL_API_KEY env var
#   --raw                Output raw JSON (skip jq formatting)
#   --timeout SECS       Curl timeout (default: 120)
#   --help               Show this help
#
# Model execution options (run, queue):
#   --model MODEL_ID     Model endpoint ID (required). e.g. fal-ai/flux/dev
#   --data JSON          Full JSON body as string
#   --prompt TEXT         Shorthand: sets {"prompt": "TEXT"} (merged with --data)
#   --image_url URL      Shorthand: sets {"image_url": "URL"} (merged with --data)
#
# Special headers (run, queue):
#   --request-timeout S  X-Fal-Request-Timeout header (fail-fast seconds)
#   --no-retry           X-Fal-No-Retry: 1 (disable queue auto-retries)
#   --expire SECS        X-Fal-Object-Lifecycle-Preference expiration_duration_seconds
#   --webhook URL        Webhook URL for queue completion notification
#
# Queue management options:
#   --model MODEL_ID     Model endpoint ID (required for status/result/cancel)
#   --request-id ID      Request ID from queue submit response
#   --logs               Include logs in status polling (adds ?logs=1)
#
# Platform API options (search, schema, pricing, estimate):
#   --query TEXT         Search query for model search (e.g. "text-to-video")
#   --endpoint-id ID     Filter by exact endpoint ID (e.g. fal-ai/flux/dev)
#   --limit N            Results per page (default: 20)
#   --cursor TOKEN       Pagination cursor from previous response
#   --unit-quantity N    Units for cost estimate (default: 1)
#
# Examples:
#   # Quick image generation (sync)
#   fal.sh run --model fal-ai/flux/dev --prompt "a cat in a spacesuit"
#
#   # Image generation with full control
#   fal.sh run --model fal-ai/flux/dev --data '{"prompt":"a cat","image_size":"landscape_4_3","num_images":2}'
#
#   # Queue a slow video generation job
#   fal.sh queue --model fal-ai/wan/v2.2-a14b/text-to-video --prompt "a timelapse of a flower blooming"
#
#   # Poll queue status (with logs)
#   fal.sh status --model fal-ai/wan/v2.2-a14b/text-to-video --request-id abc-123 --logs
#
#   # Get queue result
#   fal.sh result --model fal-ai/wan/v2.2-a14b/text-to-video --request-id abc-123
#
#   # Cancel a queued request
#   fal.sh cancel --model fal-ai/wan/v2.2-a14b/text-to-video --request-id abc-123
#
#   # Search for models
#   fal.sh search --query "text-to-video" --limit 10
#
#   # Get model schema (input/output specification)
#   fal.sh schema --endpoint-id fal-ai/flux/dev
#
#   # Get pricing for a model
#   fal.sh pricing --endpoint-id fal-ai/flux/dev
#
#   # Estimate cost
#   fal.sh estimate --endpoint-id fal-ai/flux/dev --unit-quantity 10

set -euo pipefail

API_KEY="${FAL_API_KEY:-}"
SYNC_BASE="https://fal.run.cloudproxy.vibecodeapp.com"
QUEUE_BASE="https://queue.fal.run.cloudproxy.vibecodeapp.com"
PLATFORM_BASE="https://api.fal.ai.cloudproxy.vibecodeapp.com/v1"
USE_JQ=true
TIMEOUT=120

die() { echo "ERROR: $*" >&2; exit 1; }

show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  exit 0
}

# ---------- Argument parsing ----------
COMMAND=""
MODEL=""
DATA=""
PROMPT=""
IMAGE_URL=""
REQUEST_ID=""
REQUEST_TIMEOUT=""
NO_RETRY=""
EXPIRE=""
WEBHOOK=""
QUERY=""
ENDPOINT_ID=""
LIMIT=""
CURSOR=""
UNIT_QUANTITY=""
LOGS=""

[[ $# -eq 0 ]] && show_help

COMMAND="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)          API_KEY="$2"; shift 2 ;;
    --raw)          USE_JQ=false; shift ;;
    --timeout)      TIMEOUT="$2"; shift 2 ;;
    --help)         show_help ;;
    --model)        MODEL="$2"; shift 2 ;;
    --data)         DATA="$2"; shift 2 ;;
    --prompt)       PROMPT="$2"; shift 2 ;;
    --image_url|--image-url) IMAGE_URL="$2"; shift 2 ;;
    --request-id)   REQUEST_ID="$2"; shift 2 ;;
    --request-timeout) REQUEST_TIMEOUT="$2"; shift 2 ;;
    --no-retry)     NO_RETRY=1; shift ;;
    --expire)       EXPIRE="$2"; shift 2 ;;
    --webhook)      WEBHOOK="$2"; shift 2 ;;
    --query)        QUERY="$2"; shift 2 ;;
    --endpoint-id)  ENDPOINT_ID="$2"; shift 2 ;;
    --limit)        LIMIT="$2"; shift 2 ;;
    --cursor)       CURSOR="$2"; shift 2 ;;
    --unit-quantity) UNIT_QUANTITY="$2"; shift 2 ;;
    --logs)         LOGS=1; shift ;;
    *)              die "Unknown option: $1" ;;
  esac
done

[[ -z "$API_KEY" ]] && die "Set FAL_API_KEY environment variable or use --key"

fmt() {
  if $USE_JQ && command -v jq &>/dev/null; then
    jq .
  else
    cat
  fi
}

# ---------- Build JSON body from shortcuts ----------
build_body() {
  local body="${DATA:-{\}}"
  if [[ -n "$PROMPT" ]]; then
    body=$(echo "$body" | jq --arg p "$PROMPT" '. + {prompt: $p}')
  fi
  if [[ -n "$IMAGE_URL" ]]; then
    body=$(echo "$body" | jq --arg u "$IMAGE_URL" '. + {image_url: $u}')
  fi
  echo "$body"
}

# ---------- Build extra headers ----------
build_headers() {
  local -a hdrs=()
  if [[ -n "$REQUEST_TIMEOUT" ]]; then
    hdrs+=(-H "X-Fal-Request-Timeout: $REQUEST_TIMEOUT")
  fi
  if [[ -n "$NO_RETRY" ]]; then
    hdrs+=(-H "X-Fal-No-Retry: 1")
  fi
  if [[ -n "$EXPIRE" ]]; then
    hdrs+=(-H "X-Fal-Object-Lifecycle-Preference: {\"expiration_duration_seconds\": $EXPIRE}")
  fi
  printf '%s\n' "${hdrs[@]+"${hdrs[@]}"}"
}

# ---------- Commands ----------

cmd_run() {
  [[ -z "$MODEL" ]] && die "run requires --model MODEL_ID"
  local body
  body=$(build_body)
  local -a extra_hdrs=()
  while IFS= read -r h; do [[ -n "$h" ]] && extra_hdrs+=("$h"); done < <(build_headers)

  curl -sS --max-time "$TIMEOUT" \
    -X POST "${SYNC_BASE}/${MODEL}" \
    -H "Authorization: Key $API_KEY" \
    -H "Content-Type: application/json" \
    "${extra_hdrs[@]+"${extra_hdrs[@]}"}" \
    -d "$body" | fmt
}

cmd_queue() {
  [[ -z "$MODEL" ]] && die "queue requires --model MODEL_ID"
  local body
  body=$(build_body)
  local -a extra_hdrs=()
  while IFS= read -r h; do [[ -n "$h" ]] && extra_hdrs+=("$h"); done < <(build_headers)

  local url="${QUEUE_BASE}/${MODEL}"
  if [[ -n "$WEBHOOK" ]]; then
    url="${url}?fal_webhook=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$WEBHOOK', safe=''))" 2>/dev/null || echo "$WEBHOOK")"
  fi

  curl -sS --max-time "$TIMEOUT" \
    -X POST "$url" \
    -H "Authorization: Key $API_KEY" \
    -H "Content-Type: application/json" \
    "${extra_hdrs[@]+"${extra_hdrs[@]}"}" \
    -d "$body" | fmt
}

cmd_status() {
  [[ -z "$MODEL" ]] && die "status requires --model MODEL_ID"
  [[ -z "$REQUEST_ID" ]] && die "status requires --request-id ID"

  local url="${QUEUE_BASE}/${MODEL}/requests/${REQUEST_ID}/status"
  [[ -n "$LOGS" ]] && url="${url}?logs=1"

  curl -sS --max-time "$TIMEOUT" \
    -H "Authorization: Key $API_KEY" \
    "$url" | fmt
}

cmd_result() {
  [[ -z "$MODEL" ]] && die "result requires --model MODEL_ID"
  [[ -z "$REQUEST_ID" ]] && die "result requires --request-id ID"

  curl -sS --max-time "$TIMEOUT" \
    -H "Authorization: Key $API_KEY" \
    "${QUEUE_BASE}/${MODEL}/requests/${REQUEST_ID}" | fmt
}

cmd_cancel() {
  [[ -z "$MODEL" ]] && die "cancel requires --model MODEL_ID"
  [[ -z "$REQUEST_ID" ]] && die "cancel requires --request-id ID"

  curl -sS --max-time "$TIMEOUT" \
    -X PUT \
    -H "Authorization: Key $API_KEY" \
    "${QUEUE_BASE}/${MODEL}/requests/${REQUEST_ID}/cancel" | fmt
}

cmd_search() {
  local params=()
  [[ -n "$QUERY" ]] && params+=("query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))" 2>/dev/null || echo "$QUERY")")
  [[ -n "$ENDPOINT_ID" ]] && params+=("endpoint_id=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$ENDPOINT_ID'))" 2>/dev/null || echo "$ENDPOINT_ID")")
  [[ -n "$LIMIT" ]] && params+=("limit=$LIMIT")
  [[ -n "$CURSOR" ]] && params+=("cursor=$CURSOR")

  local qs=""
  if [[ ${#params[@]} -gt 0 ]]; then
    qs="?$(IFS='&'; echo "${params[*]}")"
  fi

  curl -sS --max-time "$TIMEOUT" \
    -H "Authorization: Key $API_KEY" \
    "${PLATFORM_BASE}/models${qs}" | fmt
}

cmd_schema() {
  [[ -z "$ENDPOINT_ID" ]] && die "schema requires --endpoint-id MODEL_ID"

  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$ENDPOINT_ID'))" 2>/dev/null || echo "$ENDPOINT_ID")

  curl -sS --max-time "$TIMEOUT" \
    -H "Authorization: Key $API_KEY" \
    "${PLATFORM_BASE}/models?endpoint_id=${encoded}&expand=openapi-3.0" | fmt
}

cmd_pricing() {
  [[ -z "$ENDPOINT_ID" ]] && die "pricing requires --endpoint-id MODEL_ID"

  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$ENDPOINT_ID'))" 2>/dev/null || echo "$ENDPOINT_ID")

  curl -sS --max-time "$TIMEOUT" \
    -H "Authorization: Key $API_KEY" \
    "${PLATFORM_BASE}/models/pricing?endpoint_id=${encoded}" | fmt
}

cmd_estimate() {
  [[ -z "$ENDPOINT_ID" ]] && die "estimate requires --endpoint-id MODEL_ID"
  local qty="${UNIT_QUANTITY:-1}"

  curl -sS --max-time "$TIMEOUT" \
    -X POST "${PLATFORM_BASE}/models/pricing/estimate" \
    -H "Authorization: Key $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"estimate_type\":\"unit_price\",\"endpoints\":{\"${ENDPOINT_ID}\":{\"unit_quantity\":${qty}}}}" | fmt
}

# ---------- Dispatch ----------
case "$COMMAND" in
  run)       cmd_run ;;
  queue)     cmd_queue ;;
  status)    cmd_status ;;
  result)    cmd_result ;;
  cancel)    cmd_cancel ;;
  search)    cmd_search ;;
  schema)    cmd_schema ;;
  pricing)   cmd_pricing ;;
  estimate)  cmd_estimate ;;
  --help|-h) show_help ;;
  *)         die "Unknown command: $COMMAND. Run with --help for usage." ;;
esac
