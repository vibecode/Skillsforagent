#!/usr/bin/env bash
# gemini.sh — Wrapper script for the Google Gemini API
# Handles auth, model selection, file uploads, JSON extraction, and streaming.
#
# Usage: bash gemini.sh <command> [flags]
# Commands: models, generate, stream, embed, count-tokens, upload, files, delete-file,
#           cache-create, cache-list, cache-delete

set -euo pipefail

BASE="https://generativelanguage.googleapis.com.cloudproxy.vibecodeapp.com/v1beta"

if [[ -z "${GOOGLE_API_KEY:-}" ]]; then
  echo "Error: GOOGLE_API_KEY is not set" >&2
  exit 1
fi

AUTH_HEADER="x-goog-api-key: ${GOOGLE_API_KEY}"
CT_JSON="Content-Type: application/json"

# --- helpers ---

die() { echo "Error: $*" >&2; exit 1; }

json_escape() {
  python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$1"
}

# Build inlineData part from a local file
inline_data_part() {
  local file="$1"
  local mime
  mime=$(file --mime-type -b "$file" 2>/dev/null || echo "application/octet-stream")
  local b64
  b64=$(base64 -w0 "$file" 2>/dev/null || base64 "$file" 2>/dev/null)
  printf '{"inlineData":{"mimeType":"%s","data":"%s"}}' "$mime" "$b64"
}

# Build fileData part from a previously uploaded file URI
file_data_part() {
  local uri="$1"
  local mime="${2:-application/octet-stream}"
  printf '{"fileData":{"mimeType":"%s","fileUri":"%s"}}' "$mime" "$uri"
}

# --- commands ---

cmd_models() {
  curl -s "${BASE}/models" -H "${AUTH_HEADER}" | \
    jq '.models[] | {name, displayName, supportedGenerationMethods, inputTokenLimit, outputTokenLimit}'
}

cmd_generate() {
  local model="gemini-2.5-flash" prompt="" system="" messages="" max_tokens="" temperature=""
  local top_p="" top_k="" stop="" json_schema="" thinking_budget="" thinking_level=""
  local tools="" cached_content=""
  local -a images=() files=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --system) system="$2"; shift 2 ;;
      --messages) messages="$2"; shift 2 ;;
      --image) images+=("$2"); shift 2 ;;
      --file) files+=("$2"); shift 2 ;;
      --max-tokens) max_tokens="$2"; shift 2 ;;
      --temperature) temperature="$2"; shift 2 ;;
      --top-p) top_p="$2"; shift 2 ;;
      --top-k) top_k="$2"; shift 2 ;;
      --stop) stop="$2"; shift 2 ;;
      --json-schema) json_schema="$2"; shift 2 ;;
      --thinking-budget) thinking_budget="$2"; shift 2 ;;
      --thinking-level) thinking_level="$2"; shift 2 ;;
      --tools) tools="$2"; shift 2 ;;
      --cached-content) cached_content="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$prompt" && -z "$messages" ]] && die "Provide --prompt or --messages"

  # Build contents
  local contents
  if [[ -n "$messages" ]]; then
    contents="$messages"
  else
    # Build parts array
    local parts_json
    parts_json=$(json_escape "$prompt")
    local parts="[{\"text\":${parts_json}}"

    # Inline images
    for img in "${images[@]}"; do
      parts+=",$(inline_data_part "$img")"
    done

    # Inline files (small) or uploaded file URIs
    for f in "${files[@]}"; do
      if [[ "$f" == https://* ]]; then
        # Already a fileUri
        parts+=",$(file_data_part "$f")"
      elif [[ -f "$f" ]]; then
        local fsize
        fsize=$(wc -c < "$f")
        if (( fsize > 20971520 )); then
          # >20MB: upload first
          echo "Uploading large file: $f ..." >&2
          local upload_result
          upload_result=$(cmd_upload --file "$f")
          local uri
          uri=$(echo "$upload_result" | jq -r '.file.uri // empty')
          local fmime
          fmime=$(echo "$upload_result" | jq -r '.file.mimeType // "application/octet-stream"')
          [[ -n "$uri" ]] && parts+=",$(file_data_part "$uri" "$fmime")"
        else
          parts+=",$(inline_data_part "$f")"
        fi
      else
        die "File not found: $f"
      fi
    done

    parts+="]"
    contents="[{\"role\":\"user\",\"parts\":${parts}}]"
  fi

  # Build request body
  local body="{\"contents\":${contents}"

  # System instruction
  if [[ -n "$system" ]]; then
    local sys_escaped
    sys_escaped=$(json_escape "$system")
    body+=",\"systemInstruction\":{\"parts\":[{\"text\":${sys_escaped}}]}"
  fi

  # Generation config
  local gen_config=""
  [[ -n "$max_tokens" ]] && gen_config+="\"maxOutputTokens\":${max_tokens},"
  [[ -n "$temperature" ]] && gen_config+="\"temperature\":${temperature},"
  [[ -n "$top_p" ]] && gen_config+="\"topP\":${top_p},"
  [[ -n "$top_k" ]] && gen_config+="\"topK\":${top_k},"
  [[ -n "$stop" ]] && gen_config+="\"stopSequences\":${stop},"

  if [[ -n "$json_schema" ]]; then
    gen_config+="\"responseMimeType\":\"application/json\",\"responseSchema\":${json_schema},"
  fi

  if [[ -n "$thinking_budget" ]]; then
    gen_config+="\"thinkingConfig\":{\"thinkingBudget\":${thinking_budget}},"
  elif [[ -n "$thinking_level" ]]; then
    gen_config+="\"thinkingConfig\":{\"thinkingLevel\":\"${thinking_level}\"},"
  fi

  if [[ -n "$gen_config" ]]; then
    gen_config="${gen_config%,}"  # remove trailing comma
    body+=",\"generationConfig\":{${gen_config}}"
  fi

  # Tools
  [[ -n "$tools" ]] && body+=",\"tools\":${tools}"

  # Cached content
  [[ -n "$cached_content" ]] && body+=",\"cachedContent\":\"${cached_content}\""

  body+="}"

  local endpoint="${BASE}/models/${model}:generateContent"
  local result
  result=$(curl -s "$endpoint" -H "${AUTH_HEADER}" -H "${CT_JSON}" -d "$body")

  # Extract text from response, or return full JSON if it's structured/function call
  local text
  text=$(echo "$result" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
  local fc
  fc=$(echo "$result" | jq -r '.candidates[0].content.parts[0].functionCall // empty' 2>/dev/null)

  if [[ -n "$fc" && "$fc" != "null" ]]; then
    echo "$result" | jq '.candidates[0].content.parts[0].functionCall'
  elif [[ -n "$text" ]]; then
    echo "$text"
  else
    # Return full response (error or unexpected format)
    echo "$result" | jq . 2>/dev/null || echo "$result"
  fi
}

cmd_stream() {
  local model="gemini-2.5-flash" prompt="" system="" messages="" max_tokens="" temperature=""
  local top_p="" top_k="" thinking_budget="" thinking_level=""
  local -a images=() files=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --system) system="$2"; shift 2 ;;
      --messages) messages="$2"; shift 2 ;;
      --image) images+=("$2"); shift 2 ;;
      --file) files+=("$2"); shift 2 ;;
      --max-tokens) max_tokens="$2"; shift 2 ;;
      --temperature) temperature="$2"; shift 2 ;;
      --top-p) top_p="$2"; shift 2 ;;
      --top-k) top_k="$2"; shift 2 ;;
      --thinking-budget) thinking_budget="$2"; shift 2 ;;
      --thinking-level) thinking_level="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$prompt" && -z "$messages" ]] && die "Provide --prompt or --messages"

  # Build contents (same logic as generate)
  local contents
  if [[ -n "$messages" ]]; then
    contents="$messages"
  else
    local parts_json
    parts_json=$(json_escape "$prompt")
    local parts="[{\"text\":${parts_json}}"
    for img in "${images[@]}"; do
      parts+=",$(inline_data_part "$img")"
    done
    for f in "${files[@]}"; do
      if [[ -f "$f" ]]; then
        parts+=",$(inline_data_part "$f")"
      fi
    done
    parts+="]"
    contents="[{\"role\":\"user\",\"parts\":${parts}}]"
  fi

  local body="{\"contents\":${contents}"
  if [[ -n "$system" ]]; then
    local sys_escaped
    sys_escaped=$(json_escape "$system")
    body+=",\"systemInstruction\":{\"parts\":[{\"text\":${sys_escaped}}]}"
  fi
  local gen_config=""
  [[ -n "$max_tokens" ]] && gen_config+="\"maxOutputTokens\":${max_tokens},"
  [[ -n "$temperature" ]] && gen_config+="\"temperature\":${temperature},"
  [[ -n "$top_p" ]] && gen_config+="\"topP\":${top_p},"
  [[ -n "$top_k" ]] && gen_config+="\"topK\":${top_k},"
  if [[ -n "$thinking_budget" ]]; then
    gen_config+="\"thinkingConfig\":{\"thinkingBudget\":${thinking_budget}},"
  elif [[ -n "$thinking_level" ]]; then
    gen_config+="\"thinkingConfig\":{\"thinkingLevel\":\"${thinking_level}\"},"
  fi
  if [[ -n "$gen_config" ]]; then
    gen_config="${gen_config%,}"
    body+=",\"generationConfig\":{${gen_config}}"
  fi
  body+="}"

  local endpoint="${BASE}/models/${model}:streamGenerateContent?alt=sse"
  curl -sN "$endpoint" -H "${AUTH_HEADER}" -H "${CT_JSON}" -d "$body" | \
    while IFS= read -r line; do
      if [[ "$line" == data:* ]]; then
        local data="${line#data: }"
        local text
        text=$(echo "$data" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
        [[ -n "$text" ]] && printf '%s' "$text"
      fi
    done
  echo  # trailing newline
}

cmd_embed() {
  local model="gemini-embedding-001" text="" texts="" task_type=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --text) text="$2"; shift 2 ;;
      --texts) texts="$2"; shift 2 ;;
      --task-type) task_type="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  if [[ -n "$texts" ]]; then
    # Batch embed
    local requests="[]"
    requests=$(echo "$texts" | jq -c --arg model "models/${model}" --arg tt "$task_type" '
      [.[] | {
        model: $model,
        content: {parts: [{text: .}]}
      } + (if $tt != "" then {taskType: $tt} else {} end)]
    ')
    curl -s "${BASE}/models/${model}:batchEmbedContents" \
      -H "${AUTH_HEADER}" -H "${CT_JSON}" \
      -d "{\"requests\":${requests}}" | jq '.embeddings'
  elif [[ -n "$text" ]]; then
    local text_escaped
    text_escaped=$(json_escape "$text")
    local body="{\"model\":\"models/${model}\",\"content\":{\"parts\":[{\"text\":${text_escaped}}]}"
    [[ -n "$task_type" ]] && body+=",\"taskType\":\"${task_type}\""
    body+="}"
    curl -s "${BASE}/models/${model}:embedContent" \
      -H "${AUTH_HEADER}" -H "${CT_JSON}" \
      -d "$body" | jq '.embedding'
  else
    die "Provide --text or --texts"
  fi
}

cmd_count_tokens() {
  local model="gemini-2.5-flash" prompt="" file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  local parts=""
  if [[ -n "$prompt" ]]; then
    local p_escaped
    p_escaped=$(json_escape "$prompt")
    parts="{\"text\":${p_escaped}}"
  elif [[ -n "$file" ]]; then
    parts=$(inline_data_part "$file")
  else
    die "Provide --prompt or --file"
  fi

  curl -s "${BASE}/models/${model}:countTokens" \
    -H "${AUTH_HEADER}" -H "${CT_JSON}" \
    -d "{\"contents\":[{\"parts\":[${parts}]}]}" | jq '.totalTokens'
}

cmd_upload() {
  local file="" display_name="" mime_type=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file) file="$2"; shift 2 ;;
      --display-name) display_name="$2"; shift 2 ;;
      --mime-type) mime_type="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$file" ]] && die "Provide --file"
  [[ ! -f "$file" ]] && die "File not found: $file"

  local fsize
  fsize=$(wc -c < "$file")
  [[ -z "$mime_type" ]] && mime_type=$(file --mime-type -b "$file" 2>/dev/null || echo "application/octet-stream")
  [[ -z "$display_name" ]] && display_name=$(basename "$file")

  # Resumable upload
  local upload_url
  upload_url=$(curl -s -D - "${BASE}/upload/v1beta/files" \
    -H "${AUTH_HEADER}" \
    -H "X-Goog-Upload-Protocol: resumable" \
    -H "X-Goog-Upload-Command: start" \
    -H "X-Goog-Upload-Header-Content-Length: ${fsize}" \
    -H "X-Goog-Upload-Header-Content-Type: ${mime_type}" \
    -H "Content-Type: application/json" \
    -d "{\"file\":{\"display_name\":\"${display_name}\"}}" 2>/dev/null | \
    grep -i "x-goog-upload-url" | cut -d' ' -f2 | tr -d '\r')

  if [[ -z "$upload_url" ]]; then
    die "Failed to initiate upload"
  fi

  curl -s "${upload_url}" \
    -H "X-Goog-Upload-Offset: 0" \
    -H "X-Goog-Upload-Command: upload, finalize" \
    --data-binary "@${file}" | jq .
}

cmd_files() {
  curl -s "${BASE}/files" -H "${AUTH_HEADER}" | jq '.files // []'
}

cmd_delete_file() {
  local name=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done
  [[ -z "$name" ]] && die "Provide --name (e.g., files/abc123)"
  curl -s -X DELETE "${BASE}/${name}" -H "${AUTH_HEADER}" | jq .
}

cmd_cache_create() {
  local model="" file="" text="" system="" ttl="3600" display_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      --text) text="$2"; shift 2 ;;
      --system) system="$2"; shift 2 ;;
      --ttl) ttl="$2"; shift 2 ;;
      --display-name) display_name="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$model" ]] && die "Provide --model"
  [[ -z "$file" && -z "$text" ]] && die "Provide --file or --text"

  local parts=""
  if [[ -n "$file" ]]; then
    if [[ -f "$file" ]]; then
      parts=$(inline_data_part "$file")
    else
      die "File not found: $file"
    fi
  else
    local t_escaped
    t_escaped=$(json_escape "$text")
    parts="{\"text\":${t_escaped}}"
  fi

  local body="{\"model\":\"models/${model}\",\"contents\":[{\"parts\":[${parts}],\"role\":\"user\"}],\"ttl\":\"${ttl}s\""
  if [[ -n "$system" ]]; then
    local sys_escaped
    sys_escaped=$(json_escape "$system")
    body+=",\"systemInstruction\":{\"parts\":[{\"text\":${sys_escaped}}]}"
  fi
  [[ -n "$display_name" ]] && body+=",\"displayName\":\"${display_name}\""
  body+="}"

  curl -s "${BASE}/cachedContents" \
    -H "${AUTH_HEADER}" -H "${CT_JSON}" \
    -d "$body" | jq .
}

cmd_cache_list() {
  curl -s "${BASE}/cachedContents" -H "${AUTH_HEADER}" | jq '.cachedContents // []'
}

cmd_cache_delete() {
  local name=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done
  [[ -z "$name" ]] && die "Provide --name (e.g., cachedContents/abc123)"
  curl -s -X DELETE "${BASE}/${name}" -H "${AUTH_HEADER}" | jq .
}

# --- dispatch ---

command="${1:-}"
shift || true

case "$command" in
  models)        cmd_models "$@" ;;
  generate)      cmd_generate "$@" ;;
  stream)        cmd_stream "$@" ;;
  embed)         cmd_embed "$@" ;;
  count-tokens)  cmd_count_tokens "$@" ;;
  upload)        cmd_upload "$@" ;;
  files)         cmd_files "$@" ;;
  delete-file)   cmd_delete_file "$@" ;;
  cache-create)  cmd_cache_create "$@" ;;
  cache-list)    cmd_cache_list "$@" ;;
  cache-delete)  cmd_cache_delete "$@" ;;
  -h|--help|help|"")
    echo "Usage: gemini.sh <command> [flags]"
    echo ""
    echo "Commands:"
    echo "  models             List available models"
    echo "  generate           Generate content (text, vision, multimodal)"
    echo "  stream             Stream generated content"
    echo "  embed              Create text embeddings"
    echo "  count-tokens       Count tokens in content"
    echo "  upload             Upload a file to the Files API"
    echo "  files              List uploaded files"
    echo "  delete-file        Delete an uploaded file"
    echo "  cache-create       Create a context cache"
    echo "  cache-list         List context caches"
    echo "  cache-delete       Delete a context cache"
    echo ""
    echo "Use --model to specify model (default: gemini-2.5-flash)"
    ;;
  *) die "Unknown command: $command. Run with --help for usage." ;;
esac
