#!/usr/bin/env bash
# openai.sh — Wrapper for OpenAI Chat Completions API via cloud proxy
# Usage: bash scripts/openai.sh <command> [options]
#
# Commands:
#   chat       Send a chat completion request
#   stream     Stream a chat completion (prints tokens as they arrive)
#   models     List available models

set -euo pipefail

BASE="https://api.openai.com.cloudproxy.vibecodeapp.com/v1"
API_KEY="${OPENAI_API_KEY:?Set OPENAI_API_KEY}"
DEFAULT_MODEL="gpt-5.2"

die() { echo "ERROR: $*" >&2; exit 1; }

cmd_models() {
  curl -sf "${BASE}/models" \
    -H "Authorization: Bearer ${API_KEY}" | \
    jq -r '.data[] | .id' | sort | grep -E "^(gpt-5|gpt-4\.1|o[0-9])" | \
    grep -v "audio\|transcrib\|tts\|embed\|moderat\|image\|whisper\|realtime\|search\|codex\|willow\|nano"
}

cmd_chat() {
  local text="" file="" system="" model="$DEFAULT_MODEL" max_tokens="" temp="" top_p=""
  local reasoning="" schema="" schema_name="response" json_mode="false" image="" tools=""
  local seed="" n=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --text)        text="$2"; shift 2;;
      --file)        text=$(cat "$2"); shift 2;;
      --system)      system="$2"; shift 2;;
      --model)       model="$2"; shift 2;;
      --max-tokens)  max_tokens="$2"; shift 2;;
      --temp)        temp="$2"; shift 2;;
      --top-p)       top_p="$2"; shift 2;;
      --reasoning)   reasoning="$2"; shift 2;;
      --schema)      schema="$2"; shift 2;;
      --schema-name) schema_name="$2"; shift 2;;
      --json)        json_mode="true"; shift;;
      --image)       image="$2"; shift 2;;
      --tools)       tools="$2"; shift 2;;
      --seed)        seed="$2"; shift 2;;
      --n)           n="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$text" ]] || die "Required: --text <text> or --file <path>"

  # Build messages array
  local messages="[]"

  if [[ -n "$system" ]]; then
    # Use developer role for o-series, system for GPT
    local sys_role="system"
    if [[ "$model" == o* ]]; then
      sys_role="developer"
    fi
    messages=$(echo "$messages" | jq --arg role "$sys_role" --arg content "$system" '. + [{"role": $role, "content": $content}]')
  fi

  # User message (with optional image)
  if [[ -n "$image" ]]; then
    local img_data
    img_data=$(base64 -w0 "$image")
    local ext="${image##*.}"
    local mime="image/${ext}"
    [[ "$ext" == "jpg" ]] && mime="image/jpeg"
    messages=$(echo "$messages" | jq \
      --arg text "$text" \
      --arg img "data:${mime};base64,${img_data}" \
      '. + [{"role": "user", "content": [{"type": "text", "text": $text}, {"type": "image_url", "image_url": {"url": $img, "detail": "auto"}}]}]')
  else
    messages=$(echo "$messages" | jq --arg text "$text" '. + [{"role": "user", "content": $text}]')
  fi

  # Build request body
  local body
  body=$(jq -n --arg model "$model" --argjson messages "$messages" '{model: $model, messages: $messages}')

  [[ -n "$max_tokens" ]] && body=$(echo "$body" | jq --argjson v "$max_tokens" '.max_completion_tokens = $v')
  [[ -n "$temp" ]]       && body=$(echo "$body" | jq --argjson v "$temp" '.temperature = $v')
  [[ -n "$top_p" ]]      && body=$(echo "$body" | jq --argjson v "$top_p" '.top_p = $v')
  [[ -n "$reasoning" ]]  && body=$(echo "$body" | jq --arg v "$reasoning" '.reasoning_effort = $v')
  [[ -n "$seed" ]]       && body=$(echo "$body" | jq --argjson v "$seed" '.seed = $v')
  [[ -n "$n" ]]          && body=$(echo "$body" | jq --argjson v "$n" '.n = $v')

  # Structured output
  if [[ -n "$schema" ]]; then
    body=$(echo "$body" | jq --arg name "$schema_name" --argjson schema "$schema" \
      '.response_format = {"type": "json_schema", "json_schema": {"name": $name, "strict": true, "schema": $schema}}')
  elif [[ "$json_mode" == "true" ]]; then
    body=$(echo "$body" | jq '.response_format = {"type": "json_object"}')
  fi

  # Tools
  if [[ -n "$tools" ]]; then
    local tools_json
    tools_json=$(cat "$tools")
    body=$(echo "$body" | jq --argjson t "$tools_json" '.tools = $t')
  fi

  local response
  response=$(curl -sf "${BASE}/chat/completions" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body")

  local finish_reason
  finish_reason=$(echo "$response" | jq -r '.choices[0].finish_reason')

  if [[ "$finish_reason" == "tool_calls" ]]; then
    echo "$response" | jq '.choices[0].message.tool_calls'
  else
    echo "$response" | jq -r '.choices[0].message.content'
  fi
}

cmd_stream() {
  local text="" file="" system="" model="$DEFAULT_MODEL" max_tokens="" temp="" top_p=""
  local reasoning="" image=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --text)       text="$2"; shift 2;;
      --file)       text=$(cat "$2"); shift 2;;
      --system)     system="$2"; shift 2;;
      --model)      model="$2"; shift 2;;
      --max-tokens) max_tokens="$2"; shift 2;;
      --temp)       temp="$2"; shift 2;;
      --top-p)      top_p="$2"; shift 2;;
      --reasoning)  reasoning="$2"; shift 2;;
      --image)      image="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$text" ]] || die "Required: --text <text> or --file <path>"

  local messages="[]"

  if [[ -n "$system" ]]; then
    local sys_role="system"
    [[ "$model" == o* ]] && sys_role="developer"
    messages=$(echo "$messages" | jq --arg role "$sys_role" --arg content "$system" '. + [{"role": $role, "content": $content}]')
  fi

  if [[ -n "$image" ]]; then
    local img_data
    img_data=$(base64 -w0 "$image")
    local ext="${image##*.}"
    local mime="image/${ext}"
    [[ "$ext" == "jpg" ]] && mime="image/jpeg"
    messages=$(echo "$messages" | jq \
      --arg text "$text" \
      --arg img "data:${mime};base64,${img_data}" \
      '. + [{"role": "user", "content": [{"type": "text", "text": $text}, {"type": "image_url", "image_url": {"url": $img, "detail": "auto"}}]}]')
  else
    messages=$(echo "$messages" | jq --arg text "$text" '. + [{"role": "user", "content": $text}]')
  fi

  local body
  body=$(jq -n --arg model "$model" --argjson messages "$messages" '{model: $model, messages: $messages, stream: true}')

  [[ -n "$max_tokens" ]] && body=$(echo "$body" | jq --argjson v "$max_tokens" '.max_completion_tokens = $v')
  [[ -n "$temp" ]]       && body=$(echo "$body" | jq --argjson v "$temp" '.temperature = $v')
  [[ -n "$top_p" ]]      && body=$(echo "$body" | jq --argjson v "$top_p" '.top_p = $v')
  [[ -n "$reasoning" ]]  && body=$(echo "$body" | jq --arg v "$reasoning" '.reasoning_effort = $v')

  curl -sfN "${BASE}/chat/completions" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" | while IFS= read -r line; do
      # Strip "data: " prefix
      line="${line#data: }"
      [[ "$line" == "[DONE]" ]] && break
      [[ -z "$line" ]] && continue
      local content
      content=$(echo "$line" | jq -r '.choices[0].delta.content // empty' 2>/dev/null) || continue
      [[ -n "$content" ]] && printf '%s' "$content"
    done
  echo ""
}

# --- Dispatch ---
CMD="${1:-}"
shift || true

case "$CMD" in
  chat)    cmd_chat "$@";;
  stream)  cmd_stream "$@";;
  models)  cmd_models "$@";;
  *)
    echo "Usage: openai.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  chat       Chat completion → text response"
    echo "  stream     Chat completion → streaming text"
    echo "  models     List available LLM models"
    echo ""
    echo "Common flags:"
    echo "  --text <text>       Input text"
    echo "  --file <path>       Input from file"
    echo "  --model <id>        Model (default: gpt-5.2)"
    echo "  --system <text>     System/developer prompt"
    echo "  --reasoning <level> low/medium/high (for o3, o4-mini)"
    echo "  --image <path>      Attach image for vision"
    echo "  --schema <json>     Structured output JSON schema"
    echo "  --json              Simple JSON mode"
    echo "  --tools <file>      Tools JSON file for function calling"
    echo "  --max-tokens <n>    Max output tokens"
    echo "  --temp <float>      Temperature (0-2)"
    exit 1
    ;;
esac
