#!/usr/bin/env bash
# gemini-image.sh — Wrapper for Google Gemini Image Generation API (Nano Banana)
# Usage: bash scripts/gemini-image.sh <command> [options]
#
# Commands:
#   generate       Generate an image from a text prompt
#   edit           Edit an image with a text instruction + reference image(s)
#
# Global options:
#   --aspect RATIO   Aspect ratio: 1:1, 16:9, 9:16 (default: none/auto)
#   --size SIZE      Image size: 1K, 2K, 4K (default: none/auto)
#   --output PATH    Save decoded image to PATH (default: prints base64)
#   --json           Output full JSON response instead of extracted base64
#
# Examples:
#   bash scripts/gemini-image.sh generate "A cat wearing a top hat" --aspect 1:1 --output cat.png
#   bash scripts/gemini-image.sh edit "Remove the background" --image photo.png --output edited.png
#   bash scripts/gemini-image.sh edit "Combine these into a collage" --image a.png --image b.png --image c.png

set -euo pipefail

BASE="https://generativelanguage.googleapis.com.cloudproxy.vibecodeapp.com/v1beta"
MODEL="gemini-3-pro-image-preview"
API_KEY="${GOOGLE_API_KEY:?Set GOOGLE_API_KEY}"

die() { echo "ERROR: $*" >&2; exit 1; }

# ── Generate: text → image ──────────────────────────────────────────────
cmd_generate() {
  local prompt="" aspect="" size="" output="" json_mode=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --aspect)  aspect="$2"; shift 2;;
      --size)    size="$2"; shift 2;;
      --output)  output="$2"; shift 2;;
      --json)    json_mode=true; shift;;
      -*)        die "Unknown option: $1";;
      *)
        if [[ -z "$prompt" ]]; then prompt="$1"; else prompt="$prompt $1"; fi
        shift;;
    esac
  done

  [[ -z "$prompt" ]] && die "Usage: gemini-image.sh generate \"prompt\" [--aspect RATIO] [--size SIZE] [--output PATH]"

  local image_config
  image_config=$(build_image_config "$aspect" "$size")

  local body
  body=$(cat <<EOF
{
  "contents": [{"parts": [{"text": $(json_string "$prompt")}]}],
  "generationConfig": {
    "responseModalities": ["Image"]${image_config}
  }
}
EOF
  )

  local tmpbody
  tmpbody=$(mktemp /tmp/gemini-body-XXXXXX.json)
  echo "$body" > "$tmpbody"

  local response
  response=$(curl -sf --max-time 120 -X POST \
    "${BASE}/models/${MODEL}:generateContent" \
    -H "x-goog-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d @"$tmpbody") || { rm -f "$tmpbody"; die "API request failed (check GOOGLE_API_KEY and network)"; }
  rm -f "$tmpbody"

  handle_response "$response" "$output" "$json_mode"
}

# ── Edit: image(s) + text → image ───────────────────────────────────────
cmd_edit() {
  local prompt="" aspect="" size="" output="" json_mode=false
  local -a images=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --image)   images+=("$2"); shift 2;;
      --aspect)  aspect="$2"; shift 2;;
      --size)    size="$2"; shift 2;;
      --output)  output="$2"; shift 2;;
      --json)    json_mode=true; shift;;
      -*)        die "Unknown option: $1";;
      *)
        if [[ -z "$prompt" ]]; then prompt="$1"; else prompt="$prompt $1"; fi
        shift;;
    esac
  done

  [[ -z "$prompt" ]] && die "Usage: gemini-image.sh edit \"instruction\" --image PATH [--image PATH2 ...] [--aspect RATIO] [--output PATH]"
  [[ ${#images[@]} -eq 0 ]] && die "At least one --image is required for editing"

  # Build parts array: text prompt + inline images
  local parts_json
  parts_json="[{\"text\": $(json_string "$prompt")}"

  for img_path in "${images[@]}"; do
    [[ -f "$img_path" ]] || die "Image not found: $img_path"
    local mime
    mime=$(detect_mime "$img_path")
    local b64
    b64=$(base64 -w0 "$img_path")
    parts_json="${parts_json}, {\"inlineData\": {\"mimeType\": \"${mime}\", \"data\": \"${b64}\"}}"
  done
  parts_json="${parts_json}]"

  local image_config
  image_config=$(build_image_config "$aspect" "$size")

  local body
  body=$(cat <<EOF
{
  "contents": [{"parts": ${parts_json}}],
  "generationConfig": {
    "responseModalities": ["Image"]${image_config}
  }
}
EOF
  )

  local tmpbody
  tmpbody=$(mktemp /tmp/gemini-body-XXXXXX.json)
  echo "$body" > "$tmpbody"

  local response
  response=$(curl -sf --max-time 120 -X POST \
    "${BASE}/models/${MODEL}:generateContent" \
    -H "x-goog-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d @"$tmpbody") || { rm -f "$tmpbody"; die "API request failed (check GOOGLE_API_KEY and network)"; }
  rm -f "$tmpbody"

  handle_response "$response" "$output" "$json_mode"
}

# ── Helpers ──────────────────────────────────────────────────────────────

json_string() {
  # Properly JSON-encode a string
  printf '%s' "$1" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))"
}

detect_mime() {
  local path="$1"
  case "${path##*.}" in
    png)  echo "image/png";;
    jpg|jpeg) echo "image/jpeg";;
    gif)  echo "image/gif";;
    webp) echo "image/webp";;
    *)    echo "image/png";;
  esac
}

build_image_config() {
  local aspect="$1" size="$2"
  local config=""
  local fields=""

  [[ -n "$aspect" ]] && fields="${fields}\"aspectRatio\": \"${aspect}\""
  if [[ -n "$size" ]]; then
    [[ -n "$fields" ]] && fields="${fields}, "
    fields="${fields}\"imageSize\": \"${size}\""
  fi

  if [[ -n "$fields" ]]; then
    config=", \"imageConfig\": {${fields}}"
  fi

  echo "$config"
}

handle_response() {
  local response="$1" output="$2" json_mode="$3"

  if [[ "$json_mode" == "true" ]]; then
    echo "$response"
    return
  fi

  # Extract base64 image data
  local b64
  b64=$(echo "$response" | python3 -c "
import sys, json
r = json.load(sys.stdin)
parts = r.get('candidates', [{}])[0].get('content', {}).get('parts', [])
for p in parts:
    if 'inlineData' in p:
        print(p['inlineData']['data'])
        sys.exit(0)
# If no image part, check for text (error/refusal)
for p in parts:
    if 'text' in p:
        print('TEXT_RESPONSE:' + p['text'], file=sys.stderr)
        sys.exit(1)
print('No image data in response', file=sys.stderr)
sys.exit(1)
" 2>&1) || {
    # Check if it was a text response (refusal/error)
    if [[ "$b64" == TEXT_RESPONSE:* ]]; then
      echo "Model returned text instead of image: ${b64#TEXT_RESPONSE:}" >&2
      exit 1
    fi
    die "Failed to extract image from response: $b64"
  }

  if [[ -n "$output" ]]; then
    # Ensure output directory exists
    mkdir -p "$(dirname "$output")" 2>/dev/null || true
    echo "$b64" | base64 -d > "$output"
    echo "Saved: $output"
  else
    # Print base64 to stdout for piping
    echo "$b64"
  fi
}

# ── Usage ────────────────────────────────────────────────────────────────
usage() {
  cat <<'USAGE'
gemini-image.sh — Google Gemini Image Generation (Nano Banana)

Commands:
  generate "prompt"          Text-to-image generation
  edit "instruction" --image PATH   Edit image(s) with text instruction

Options:
  --aspect RATIO     Aspect ratio: 1:1, 16:9, 9:16
  --size SIZE        Image size: 1K, 2K, 4K
  --output PATH      Save decoded image to file (default: prints base64)
  --json             Output full JSON response
  --image PATH       Input image for editing (repeatable, up to 14)

Examples:
  gemini-image.sh generate "A sunset over mountains" --aspect 16:9 --output sunset.png
  gemini-image.sh edit "Make it watercolor style" --image photo.png --output watercolor.png
  gemini-image.sh edit "Merge these photos" --image a.jpg --image b.jpg --output merged.png

Environment:
  GOOGLE_API_KEY     Required. Google AI API key.
USAGE
}

# ── Main ─────────────────────────────────────────────────────────────────
cmd="${1:-}"
shift 2>/dev/null || true

case "$cmd" in
  generate)  cmd_generate "$@";;
  edit)      cmd_edit "$@";;
  help|-h|--help) usage;;
  *)         usage; exit 1;;
esac
