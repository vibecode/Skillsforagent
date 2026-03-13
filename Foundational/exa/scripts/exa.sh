#!/usr/bin/env bash
# exa.sh — Wrapper for Exa API (search, content extraction, answers, research, websets)
# Usage: bash scripts/exa.sh <command> [options]
#
# Commands:
#   search                     Web search with inline content retrieval
#   contents                   Extract content from known URLs
#   find-similar               Find pages similar to a URL
#   answer                     Search-grounded AI answer with citations
#   research                   Start async multi-step research task
#   research-poll              Poll research task status
#   research-list              List research tasks
#   chat                       OpenAI-compatible chat completions
#
#   webset-create              Create a Webset (entity sourcing)
#   webset-preview             Preview Webset (dry run)
#   webset-get                 Get Webset by ID
#   webset-list                List Websets
#   webset-update              Update Webset metadata
#   webset-cancel              Cancel a running Webset
#   webset-delete              Delete a Webset
#   webset-search              Add a search to existing Webset
#   webset-search-get          Get search status
#   webset-search-cancel       Cancel a search
#   webset-items               List Webset items
#   webset-item                Get a single item
#   webset-item-delete         Delete an item
#   webset-enrichment-add      Add enrichment column to Webset
#   webset-enrichment-get      Get enrichment status
#   webset-enrichment-delete   Delete enrichment
#   webset-enrichment-cancel   Cancel enrichment
#   webset-monitor-create      Create a monitor (scheduled re-search)
#   webset-monitor-list        List monitors
#   webset-monitor-get         Get monitor
#   webset-monitor-update      Update monitor
#   webset-monitor-delete      Delete monitor
#   webset-monitor-runs        List monitor runs
#   webset-import-create       Import external data into Webset
#   webset-import-list         List imports
#   webset-import-get          Get import
#   webset-import-delete       Delete import
#   webset-export              Schedule Webset export
#   webset-export-get          Get export status
#   webset-webhook-create      Create webhook
#   webset-webhook-list        List webhooks
#   webset-webhook-get         Get webhook
#   webset-webhook-update      Update webhook
#   webset-webhook-delete      Delete webhook
#   webset-webhook-attempts    List webhook delivery attempts
#   webset-events              List Webset events
#   webset-event               Get a single event
#   webset-team                Get team info / concurrency usage
#
# Global options:
#   --key KEY           Override EXA_API_KEY env var
#   --raw               Output raw JSON (skip jq formatting)
#   --timeout SECS      Curl timeout (default: 120)
#   --help              Show this help
#
# All command-specific options are passed as JSON body fields:
#   --query "AI startups"             → {"query": "AI startups"}
#   --numResults 10                   → {"numResults": 10}
#   --type auto                       → {"type": "auto"}
#   --ids '["https://example.com"]'   → {"ids": ["https://example.com"]}
#   --contents '{"text":true}'        → {"contents": {"text": true}}
#   --text true                       → {"text": true}
#   --stream true                     → {"stream": true}
#   --outputSchema '{"type":"object","properties":{"name":{"type":"string"}}}'
#   --includeDomains '["arxiv.org"]'  → {"includeDomains": ["arxiv.org"]}
#
# Path parameters use dedicated flags:
#   --id <websetId>                   Webset/resource ID for get/update/delete
#   --searchId <id>                   Search ID
#   --itemId <id>                     Item ID
#   --enrichmentId <id>               Enrichment ID
#   --monitorId <id>                  Monitor ID
#   --importId <id>                   Import ID
#   --exportId <id>                   Export ID
#   --webhookId <id>                  Webhook ID
#   --eventId <id>                    Event ID
#   --runId <id>                      Monitor run ID
#   --researchId <id>                 Research task ID
#
# Query string params (for GET endpoints):
#   --limit 50                        Pagination limit
#   --cursor <cursor>                 Pagination cursor
#   --expand items                    Expand sub-resources
#   --events true                     Include events in research poll
#
# Examples:
#   exa.sh search --query "AI startups Series A 2025" --numResults 10 --contents '{"highlights":{"maxCharacters":4000}}'
#   exa.sh search --query "agtech companies" --category company --type deep
#   exa.sh contents --ids '["https://example.com/article"]' --text true
#   exa.sh find-similar --url "https://arxiv.org/abs/2307.06435" --contents '{"text":true}'
#   exa.sh answer --query "What is SpaceX's latest valuation?" --text true
#   exa.sh research --instructions "Analyze the AI safety landscape" --model exa-research
#   exa.sh research-poll --researchId abc123
#   exa.sh research-poll --researchId abc123 --stream true
#   exa.sh chat --model exa --messages '[{"role":"user","content":"Latest AI news"}]'
#   exa.sh webset-create --search '{"query":"Marketing agencies in US","count":25}' --enrichments '[{"description":"City?","format":"text"}]'
#   exa.sh webset-get --id ws_abc123
#   exa.sh webset-items --id ws_abc123 --limit 100
#   exa.sh webset-enrichment-add --id ws_abc123 --description "Annual revenue?" --format text

set -euo pipefail

BASE="https://api.exa.ai.cloudproxy.vibecodeapp.com"
WEBSETS_BASE="${BASE}/websets/v0"
API_KEY="${EXA_API_KEY:-}"
USE_JQ=true
TIMEOUT=120

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

# Path parameter holders
RESOURCE_ID=""
SEARCH_ID=""
ITEM_ID=""
ENRICHMENT_ID=""
MONITOR_ID=""
IMPORT_ID=""
EXPORT_ID=""
WEBHOOK_ID=""
EVENT_ID=""
RUN_ID=""
RESEARCH_ID=""

# Query string params for GET requests
QS_PARAMS=()

# Body args for POST/PATCH requests
BODY_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)            API_KEY="$2"; shift 2 ;;
    --raw)            USE_JQ=false; shift ;;
    --timeout)        TIMEOUT="$2"; shift 2 ;;
    --help)           show_help ;;
    --id)             RESOURCE_ID="$2"; shift 2 ;;
    --searchId)       SEARCH_ID="$2"; shift 2 ;;
    --itemId)         ITEM_ID="$2"; shift 2 ;;
    --enrichmentId)   ENRICHMENT_ID="$2"; shift 2 ;;
    --monitorId)      MONITOR_ID="$2"; shift 2 ;;
    --importId)       IMPORT_ID="$2"; shift 2 ;;
    --exportId)       EXPORT_ID="$2"; shift 2 ;;
    --webhookId)      WEBHOOK_ID="$2"; shift 2 ;;
    --eventId)        EVENT_ID="$2"; shift 2 ;;
    --runId)          RUN_ID="$2"; shift 2 ;;
    --researchId)     RESEARCH_ID="$2"; shift 2 ;;
    # GET query params
    --limit)          QS_PARAMS+=("limit=$2"); shift 2 ;;
    --cursor)         QS_PARAMS+=("cursor=$2"); shift 2 ;;
    --expand)         QS_PARAMS+=("expand=$2"); shift 2 ;;
    --events)         QS_PARAMS+=("events=$2"); shift 2 ;;
    --stream)
      # stream goes in both QS (for research-poll GET) and body (for POST)
      QS_PARAMS+=("stream=$2")
      BODY_ARGS+=("stream" "$2")
      shift 2 ;;
    --*)
      key="${1#--}"
      if [[ $# -ge 2 && ! "$2" =~ ^-- ]]; then
        BODY_ARGS+=("$key" "$2")
        shift 2
      else
        BODY_ARGS+=("$key" "true")
        shift
      fi
      ;;
    *) die "Unexpected argument: $1" ;;
  esac
done

[[ -n "$API_KEY" ]] || die "Set EXA_API_KEY environment variable or pass --key"

# Build query string from QS_PARAMS
build_qs() {
  local qs=""
  for p in "${QS_PARAMS[@]+"${QS_PARAMS[@]}"}"; do
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
       [[ "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || \
       [[ "$v" == "true" ]] || [[ "$v" == "false" ]] || [[ "$v" == "null" ]]; then
      json+="\"${k}\":${v}"
    else
      # Escape double quotes and backslashes in string values
      v="${v//\\/\\\\}"
      v="${v//\"/\\\"}"
      json+="\"${k}\":\"${v}\""
    fi
  done
  json+="}"
  echo "$json"
}

# Format output
fmt() {
  if $USE_JQ && command -v jq &>/dev/null; then
    jq .
  else
    cat
  fi
}

# POST request with x-api-key auth
api_post() {
  local url="$1"
  local body
  body=$(build_json)

  curl -sf --max-time "$TIMEOUT" -X POST "$url" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" | fmt || {
    echo "Request failed. Retrying with error output:" >&2
    curl -s --max-time "$TIMEOUT" -X POST "$url" \
      -H "x-api-key: ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" >&2
    exit 1
  }
}

# POST request with Bearer auth (OpenAI-compatible endpoints)
api_post_bearer() {
  local url="$1"
  local body
  body=$(build_json)

  curl -sf --max-time "$TIMEOUT" -X POST "$url" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" | fmt || {
    echo "Request failed. Retrying with error output:" >&2
    curl -s --max-time "$TIMEOUT" -X POST "$url" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" >&2
    exit 1
  }
}

# GET request
api_get() {
  local url="$1"
  local qs
  qs=$(build_qs)

  curl -sf --max-time "$TIMEOUT" "${url}${qs}" \
    -H "x-api-key: ${API_KEY}" | fmt || {
    echo "Request failed. Retrying with error output:" >&2
    curl -s --max-time "$TIMEOUT" "${url}${qs}" \
      -H "x-api-key: ${API_KEY}" >&2
    exit 1
  }
}

# DELETE request
api_delete() {
  local url="$1"

  curl -sf --max-time "$TIMEOUT" -X DELETE "$url" \
    -H "x-api-key: ${API_KEY}" | fmt || {
    echo "Request failed. Retrying with error output:" >&2
    curl -s --max-time "$TIMEOUT" -X DELETE "$url" \
      -H "x-api-key: ${API_KEY}" >&2
    exit 1
  }
}

# PATCH request (for webhook update)
api_patch() {
  local url="$1"
  local body
  body=$(build_json)

  curl -sf --max-time "$TIMEOUT" -X PATCH "$url" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" | fmt || {
    echo "Request failed. Retrying with error output:" >&2
    curl -s --max-time "$TIMEOUT" -X PATCH "$url" \
      -H "x-api-key: ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" >&2
    exit 1
  }
}

# ── Command dispatch ─────────────────────────────────────────────

case "$CMD" in

  # ── Core Search & Content ──────────────────────────────────────

  search)
    api_post "${BASE}/search"
    ;;

  contents)
    api_post "${BASE}/contents"
    ;;

  find-similar)
    api_post "${BASE}/findSimilar"
    ;;

  # ── Answer ─────────────────────────────────────────────────────

  answer)
    api_post "${BASE}/answer"
    ;;

  # ── Research (Async) ───────────────────────────────────────────

  research)
    api_post "${BASE}/research/v1"
    ;;

  research-poll)
    [[ -n "$RESEARCH_ID" ]] || die "Required: --researchId <id>"
    api_get "${BASE}/research/v1/${RESEARCH_ID}"
    ;;

  research-list)
    api_get "${BASE}/research/v1"
    ;;

  # ── Chat Completions (OpenAI-compatible) ───────────────────────

  chat)
    api_post_bearer "${BASE}/chat/completions"
    ;;

  # ── Webset CRUD ────────────────────────────────────────────────

  webset-create)
    api_post "${WEBSETS_BASE}/websets"
    ;;

  webset-preview)
    api_post "${WEBSETS_BASE}/websets/preview"
    ;;

  webset-get)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}"
    ;;

  webset-list)
    api_get "${WEBSETS_BASE}/websets"
    ;;

  webset-update)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}"
    ;;

  webset-cancel)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/cancel"
    ;;

  webset-delete)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_delete "${WEBSETS_BASE}/websets/${RESOURCE_ID}"
    ;;

  # ── Webset Searches ────────────────────────────────────────────

  webset-search)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/searches"
    ;;

  webset-search-get)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$SEARCH_ID" ]] || die "Required: --searchId <id>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/searches/${SEARCH_ID}"
    ;;

  webset-search-cancel)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$SEARCH_ID" ]] || die "Required: --searchId <id>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/searches/${SEARCH_ID}/cancel"
    ;;

  # ── Webset Items ───────────────────────────────────────────────

  webset-items)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/items"
    ;;

  webset-item)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$ITEM_ID" ]] || die "Required: --itemId <id>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/items/${ITEM_ID}"
    ;;

  webset-item-delete)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$ITEM_ID" ]] || die "Required: --itemId <id>"
    api_delete "${WEBSETS_BASE}/websets/${RESOURCE_ID}/items/${ITEM_ID}"
    ;;

  # ── Webset Enrichments ─────────────────────────────────────────

  webset-enrichment-add)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/enrichments"
    ;;

  webset-enrichment-get)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$ENRICHMENT_ID" ]] || die "Required: --enrichmentId <id>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/enrichments/${ENRICHMENT_ID}"
    ;;

  webset-enrichment-delete)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$ENRICHMENT_ID" ]] || die "Required: --enrichmentId <id>"
    api_delete "${WEBSETS_BASE}/websets/${RESOURCE_ID}/enrichments/${ENRICHMENT_ID}"
    ;;

  webset-enrichment-cancel)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$ENRICHMENT_ID" ]] || die "Required: --enrichmentId <id>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/enrichments/${ENRICHMENT_ID}/cancel"
    ;;

  # ── Webset Monitors ────────────────────────────────────────────

  webset-monitor-create)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/monitors"
    ;;

  webset-monitor-list)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/monitors"
    ;;

  webset-monitor-get)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$MONITOR_ID" ]] || die "Required: --monitorId <id>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/monitors/${MONITOR_ID}"
    ;;

  webset-monitor-update)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$MONITOR_ID" ]] || die "Required: --monitorId <id>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/monitors/${MONITOR_ID}"
    ;;

  webset-monitor-delete)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$MONITOR_ID" ]] || die "Required: --monitorId <id>"
    api_delete "${WEBSETS_BASE}/websets/${RESOURCE_ID}/monitors/${MONITOR_ID}"
    ;;

  webset-monitor-runs)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$MONITOR_ID" ]] || die "Required: --monitorId <id>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/monitors/${MONITOR_ID}/runs"
    ;;

  # ── Webset Imports ─────────────────────────────────────────────

  webset-import-create)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/imports"
    ;;

  webset-import-list)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/imports"
    ;;

  webset-import-get)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$IMPORT_ID" ]] || die "Required: --importId <id>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/imports/${IMPORT_ID}"
    ;;

  webset-import-delete)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$IMPORT_ID" ]] || die "Required: --importId <id>"
    api_delete "${WEBSETS_BASE}/websets/${RESOURCE_ID}/imports/${IMPORT_ID}"
    ;;

  # ── Webset Exports ─────────────────────────────────────────────

  webset-export)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    api_post "${WEBSETS_BASE}/websets/${RESOURCE_ID}/exports"
    ;;

  webset-export-get)
    [[ -n "$RESOURCE_ID" ]] || die "Required: --id <websetId>"
    [[ -n "$EXPORT_ID" ]] || die "Required: --exportId <id>"
    api_get "${WEBSETS_BASE}/websets/${RESOURCE_ID}/exports/${EXPORT_ID}"
    ;;

  # ── Webset Webhooks ────────────────────────────────────────────

  webset-webhook-create)
    api_post "${WEBSETS_BASE}/webhooks"
    ;;

  webset-webhook-list)
    api_get "${WEBSETS_BASE}/webhooks"
    ;;

  webset-webhook-get)
    [[ -n "$WEBHOOK_ID" ]] || die "Required: --webhookId <id>"
    api_get "${WEBSETS_BASE}/webhooks/${WEBHOOK_ID}"
    ;;

  webset-webhook-update)
    [[ -n "$WEBHOOK_ID" ]] || die "Required: --webhookId <id>"
    api_patch "${WEBSETS_BASE}/webhooks/${WEBHOOK_ID}"
    ;;

  webset-webhook-delete)
    [[ -n "$WEBHOOK_ID" ]] || die "Required: --webhookId <id>"
    api_delete "${WEBSETS_BASE}/webhooks/${WEBHOOK_ID}"
    ;;

  webset-webhook-attempts)
    [[ -n "$WEBHOOK_ID" ]] || die "Required: --webhookId <id>"
    api_get "${WEBSETS_BASE}/webhooks/${WEBHOOK_ID}/attempts"
    ;;

  # ── Webset Events ──────────────────────────────────────────────

  webset-events)
    api_get "${WEBSETS_BASE}/events"
    ;;

  webset-event)
    [[ -n "$EVENT_ID" ]] || die "Required: --eventId <id>"
    api_get "${WEBSETS_BASE}/events/${EVENT_ID}"
    ;;

  # ── Webset Team ────────────────────────────────────────────────

  webset-team)
    api_get "${WEBSETS_BASE}/team"
    ;;

  # ── Unknown ────────────────────────────────────────────────────

  *)
    die "Unknown command: $CMD. Run: exa.sh --help"
    ;;
esac
