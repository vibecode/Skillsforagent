#!/usr/bin/env bash
# openai.sh — Wrapper script for the OpenAI API
# Handles auth, JSON construction, binary responses, streaming, and error handling.
#
# Usage: bash openai.sh <command> [flags]
# Commands: chat, stream, image-gen, image-edit, tts, stt, embed, moderate, models

set -euo pipefail

BASE="https://api.openai.com.cloudproxy.vibecodeapp.com/v1"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "Error: OPENAI_API_KEY is not set" >&2
  exit 1
fi

AUTH="Authorization: Bearer ${OPENAI_API_KEY}"
CT_JSON="Content-Type: application/json"

# --- helpers ---

die() { echo "Error: $*" >&2; exit 1; }

json_escape() {
  python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$1"
}

# Encode a local image to a data URI for vision
image_to_data_uri() {
  local file="$1"
  local mime
  mime=$(file --mime-type -b "$file" 2>/dev/null || echo "image/png")
  local b64
  b64=$(base64 -w0 "$file" 2>/dev/null || base64 "$file" 2>/dev/null)
  printf 'data:%s;base64,%s' "$mime" "$b64"
}

# Read text from file or stdin
read_text_from_file() {
  local file="$1"
  if [[ "$file" == "-" ]]; then
    cat
  elif [[ -f "$file" ]]; then
    cat "$file"
  else
    die "File not found: $file"
  fi
}

# --- commands ---

cmd_chat() {
  local model="gpt-4o" text="" system="" image="" file="" max_tokens="" temp=""
  local top_p="" reasoning="" schema="" schema_name="response" json_mode="" tools=""
  local seed="" n=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --text) text="$2"; shift 2 ;;
      --system) system="$2"; shift 2 ;;
      --image) image="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      --max-tokens) max_tokens="$2"; shift 2 ;;
      --temp) temp="$2"; shift 2 ;;
      --top-p) top_p="$2"; shift 2 ;;
      --reasoning) reasoning="$2"; shift 2 ;;
      --schema) schema="$2"; shift 2 ;;
      --schema-name) schema_name="$2"; shift 2 ;;
      --json) json_mode="true"; shift ;;
      --tools) tools="$2"; shift 2 ;;
      --seed) seed="$2"; shift 2 ;;
      --n) n="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  # Read text from file if --file provided
  if [[ -n "$file" && -z "$text" ]]; then
    text=$(read_text_from_file "$file")
  fi

  [[ -z "$text" ]] && die "Provide --text or --file"

  # Build messages array
  local messages="["

  # System message (use "developer" for o-series reasoning models)
  if [[ -n "$system" ]]; then
    local sys_escaped
    sys_escaped=$(json_escape "$system")
    local sys_role="system"
    if [[ "$model" == o1* || "$model" == o3* || "$model" == o4* ]]; then
      sys_role="developer"
    fi
    messages+="{\"role\":\"${sys_role}\",\"content\":${sys_escaped}},"
  fi

  # User message
  local text_escaped
  text_escaped=$(json_escape "$text")

  if [[ -n "$image" ]]; then
    # Vision: content is an array of parts
    local image_url
    if [[ "$image" == http* ]]; then
      image_url="$image"
    elif [[ -f "$image" ]]; then
      image_url=$(image_to_data_uri "$image")
    else
      die "Image not found: $image"
    fi
    local img_escaped
    img_escaped=$(json_escape "$image_url")
    messages+="{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":${text_escaped}},{\"type\":\"image_url\",\"image_url\":{\"url\":${img_escaped},\"detail\":\"auto\"}}]}"
  else
    messages+="{\"role\":\"user\",\"content\":${text_escaped}}"
  fi

  messages+="]"

  # Build request body
  local body="{\"model\":\"${model}\",\"messages\":${messages}"

  # Optional parameters
  [[ -n "$max_tokens" ]] && body+=",\"max_completion_tokens\":${max_tokens}"
  [[ -n "$temp" ]] && body+=",\"temperature\":${temp}"
  [[ -n "$top_p" ]] && body+=",\"top_p\":${top_p}"
  [[ -n "$reasoning" ]] && body+=",\"reasoning_effort\":\"${reasoning}\""
  [[ -n "$seed" ]] && body+=",\"seed\":${seed}"
  [[ -n "$n" ]] && body+=",\"n\":${n}"

  # Structured output (JSON schema)
  if [[ -n "$schema" ]]; then
    body+=",\"response_format\":{\"type\":\"json_schema\",\"json_schema\":{\"name\":\"${schema_name}\",\"strict\":true,\"schema\":${schema}}}"
  elif [[ -n "$json_mode" ]]; then
    body+=",\"response_format\":{\"type\":\"json_object\"}"
  fi

  # Tools from JSON file
  if [[ -n "$tools" ]]; then
    if [[ -f "$tools" ]]; then
      local tools_json
      tools_json=$(cat "$tools")
      body+=",\"tools\":${tools_json}"
    else
      die "Tools file not found: $tools"
    fi
  fi

  body+="}"

  local result
  result=$(curl -s "${BASE}/chat/completions" -H "$AUTH" -H "$CT_JSON" -d "$body")

  # Check for errors
  local error
  error=$(echo "$result" | jq -r '.error.message // empty' 2>/dev/null)
  if [[ -n "$error" ]]; then
    echo "API Error: $error" >&2
    exit 1
  fi

  # Check for tool calls
  local tool_calls
  tool_calls=$(echo "$result" | jq -r '.choices[0].message.tool_calls // empty' 2>/dev/null)
  if [[ -n "$tool_calls" && "$tool_calls" != "null" ]]; then
    echo "$result" | jq '.choices[0].message.tool_calls'
    return
  fi

  # Extract content
  local content
  content=$(echo "$result" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
  if [[ -n "$content" ]]; then
    echo "$content"
  else
    echo "$result" | jq . 2>/dev/null || echo "$result"
  fi
}

cmd_stream() {
  local model="gpt-4o" text="" system="" file="" max_tokens="" temp=""
  local top_p="" reasoning=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --text) text="$2"; shift 2 ;;
      --system) system="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      --max-tokens) max_tokens="$2"; shift 2 ;;
      --temp) temp="$2"; shift 2 ;;
      --top-p) top_p="$2"; shift 2 ;;
      --reasoning) reasoning="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  if [[ -n "$file" && -z "$text" ]]; then
    text=$(read_text_from_file "$file")
  fi
  [[ -z "$text" ]] && die "Provide --text or --file"

  local messages="["
  if [[ -n "$system" ]]; then
    local sys_escaped
    sys_escaped=$(json_escape "$system")
    local sys_role="system"
    if [[ "$model" == o1* || "$model" == o3* || "$model" == o4* ]]; then
      sys_role="developer"
    fi
    messages+="{\"role\":\"${sys_role}\",\"content\":${sys_escaped}},"
  fi

  local text_escaped
  text_escaped=$(json_escape "$text")
  messages+="{\"role\":\"user\",\"content\":${text_escaped}}]"

  local body="{\"model\":\"${model}\",\"messages\":${messages},\"stream\":true"
  [[ -n "$max_tokens" ]] && body+=",\"max_completion_tokens\":${max_tokens}"
  [[ -n "$temp" ]] && body+=",\"temperature\":${temp}"
  [[ -n "$top_p" ]] && body+=",\"top_p\":${top_p}"
  [[ -n "$reasoning" ]] && body+=",\"reasoning_effort\":\"${reasoning}\""
  body+="}"

  curl -sN "${BASE}/chat/completions" -H "$AUTH" -H "$CT_JSON" -d "$body" | \
    while IFS= read -r line; do
      if [[ "$line" == data:\ * ]]; then
        local data="${line#data: }"
        [[ "$data" == "[DONE]" ]] && break
        local delta
        delta=$(echo "$data" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
        [[ -n "$delta" ]] && printf '%s' "$delta"
      fi
    done
  echo  # trailing newline
}

cmd_image_gen() {
  local model="gpt-image-1" prompt="" out="" size="1024x1024" quality="auto"
  local n="" background="" output_format=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      --size) size="$2"; shift 2 ;;
      --quality) quality="$2"; shift 2 ;;
      --n) n="$2"; shift 2 ;;
      --background) background="$2"; shift 2 ;;
      --output-format) output_format="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$prompt" ]] && die "Provide --prompt"
  [[ -z "$out" ]] && die "Provide --out"

  local prompt_escaped
  prompt_escaped=$(json_escape "$prompt")

  local body="{\"model\":\"${model}\",\"prompt\":${prompt_escaped},\"size\":\"${size}\",\"quality\":\"${quality}\""
  [[ -n "$n" ]] && body+=",\"n\":${n}"
  [[ -n "$background" ]] && body+=",\"background\":\"${background}\""
  [[ -n "$output_format" ]] && body+=",\"output_format\":\"${output_format}\""
  body+="}"

  local result
  result=$(curl -s "${BASE}/images/generations" -H "$AUTH" -H "$CT_JSON" -d "$body")

  # Check for errors
  local error
  error=$(echo "$result" | jq -r '.error.message // empty' 2>/dev/null)
  if [[ -n "$error" ]]; then
    echo "API Error: $error" >&2
    exit 1
  fi

  # Extract b64_json or URL
  local b64
  b64=$(echo "$result" | jq -r '.data[0].b64_json // empty' 2>/dev/null)
  if [[ -n "$b64" ]]; then
    echo "$b64" | base64 -d > "$out"
    echo "Saved to $out"
    return
  fi

  local url
  url=$(echo "$result" | jq -r '.data[0].url // empty' 2>/dev/null)
  if [[ -n "$url" ]]; then
    curl -s "$url" -o "$out"
    echo "Saved to $out"
    return
  fi

  echo "Unexpected response:" >&2
  echo "$result" | jq . 2>/dev/null || echo "$result" >&2
  exit 1
}

cmd_image_edit() {
  local model="gpt-image-1" prompt="" image="" mask="" out="" size="1024x1024"
  local quality="auto" n=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --image) image="$2"; shift 2 ;;
      --mask) mask="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      --size) size="$2"; shift 2 ;;
      --quality) quality="$2"; shift 2 ;;
      --n) n="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$prompt" ]] && die "Provide --prompt"
  [[ -z "$image" ]] && die "Provide --image"
  [[ -z "$out" ]] && die "Provide --out"

  local cmd=(curl -s "${BASE}/images/edits" -H "$AUTH"
    -F "model=${model}"
    -F "prompt=${prompt}"
    -F "image[]=@${image}"
    -F "size=${size}"
  )
  [[ -n "$quality" ]] && cmd+=(-F "quality=${quality}")
  [[ -n "$n" ]] && cmd+=(-F "n=${n}")
  [[ -n "$mask" ]] && cmd+=(-F "mask=@${mask}")

  local result
  result=$("${cmd[@]}")

  local error
  error=$(echo "$result" | jq -r '.error.message // empty' 2>/dev/null)
  if [[ -n "$error" ]]; then
    echo "API Error: $error" >&2
    exit 1
  fi

  local b64
  b64=$(echo "$result" | jq -r '.data[0].b64_json // empty' 2>/dev/null)
  if [[ -n "$b64" ]]; then
    echo "$b64" | base64 -d > "$out"
    echo "Saved to $out"
    return
  fi

  local url
  url=$(echo "$result" | jq -r '.data[0].url // empty' 2>/dev/null)
  if [[ -n "$url" ]]; then
    curl -s "$url" -o "$out"
    echo "Saved to $out"
    return
  fi

  echo "Unexpected response:" >&2
  echo "$result" | jq . 2>/dev/null || echo "$result" >&2
  exit 1
}

cmd_tts() {
  local model="gpt-4o-mini-tts" text="" file="" voice="alloy" instructions=""
  local speed="" format="" out=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --text) text="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      --voice) voice="$2"; shift 2 ;;
      --instructions) instructions="$2"; shift 2 ;;
      --speed) speed="$2"; shift 2 ;;
      --format) format="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  if [[ -n "$file" && -z "$text" ]]; then
    text=$(read_text_from_file "$file")
  fi
  [[ -z "$text" ]] && die "Provide --text or --file"
  [[ -z "$out" ]] && die "Provide --out"

  local text_escaped
  text_escaped=$(json_escape "$text")

  local body="{\"model\":\"${model}\",\"input\":${text_escaped},\"voice\":\"${voice}\""
  if [[ -n "$instructions" ]]; then
    local inst_escaped
    inst_escaped=$(json_escape "$instructions")
    body+=",\"instructions\":${inst_escaped}"
  fi
  [[ -n "$speed" ]] && body+=",\"speed\":${speed}"
  [[ -n "$format" ]] && body+=",\"response_format\":\"${format}\""
  body+="}"

  curl -s "${BASE}/audio/speech" -H "$AUTH" -H "$CT_JSON" -d "$body" --output "$out"

  # Check if the output is an error (JSON) instead of audio
  if file "$out" 2>/dev/null | grep -q "text\|JSON"; then
    echo "API Error:" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi

  echo "Saved to $out"
}

cmd_stt() {
  local model="gpt-4o-transcribe" audio="" out="" language="" prompt=""
  local format="" timestamps=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --audio) audio="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      --language) language="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --format) format="$2"; shift 2 ;;
      --timestamps) timestamps="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$audio" ]] && die "Provide --audio"
  [[ ! -f "$audio" ]] && die "Audio file not found: $audio"

  local cmd=(curl -s "${BASE}/audio/transcriptions" -H "$AUTH"
    -F "model=${model}"
    -F "file=@${audio}"
  )
  [[ -n "$language" ]] && cmd+=(-F "language=${language}")
  [[ -n "$prompt" ]] && cmd+=(-F "prompt=${prompt}")
  [[ -n "$format" ]] && cmd+=(-F "response_format=${format}")
  [[ -n "$timestamps" ]] && cmd+=(-F "timestamp_granularities[]=${timestamps}")

  local result
  result=$("${cmd[@]}")

  if [[ -n "$out" ]]; then
    echo "$result" > "$out"
    echo "Saved to $out"
  else
    echo "$result"
  fi
}

cmd_embed() {
  local model="text-embedding-3-small" text="" file="" dimensions="" encoding_format=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --model) model="$2"; shift 2 ;;
      --text) text="$2"; shift 2 ;;
      --file) file="$2"; shift 2 ;;
      --dimensions) dimensions="$2"; shift 2 ;;
      --encoding-format) encoding_format="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  if [[ -n "$file" && -z "$text" ]]; then
    # File mode: read JSONL (one text per line) for batch embedding
    [[ ! -f "$file" ]] && die "File not found: $file"
    local inputs
    inputs=$(jq -Rs 'split("\n") | map(select(length > 0))' "$file")

    local body="{\"model\":\"${model}\",\"input\":${inputs}"
    [[ -n "$dimensions" ]] && body+=",\"dimensions\":${dimensions}"
    [[ -n "$encoding_format" ]] && body+=",\"encoding_format\":\"${encoding_format}\""
    body+="}"

    curl -s "${BASE}/embeddings" -H "$AUTH" -H "$CT_JSON" -d "$body" | jq '.data'
  elif [[ -n "$text" ]]; then
    local text_escaped
    text_escaped=$(json_escape "$text")

    local body="{\"model\":\"${model}\",\"input\":${text_escaped}"
    [[ -n "$dimensions" ]] && body+=",\"dimensions\":${dimensions}"
    [[ -n "$encoding_format" ]] && body+=",\"encoding_format\":\"${encoding_format}\""
    body+="}"

    curl -s "${BASE}/embeddings" -H "$AUTH" -H "$CT_JSON" -d "$body" | jq '.data[0].embedding'
  else
    die "Provide --text or --file"
  fi
}

cmd_moderate() {
  local text="" model=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --text) text="$2"; shift 2 ;;
      --model) model="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [[ -z "$text" ]] && die "Provide --text"

  local text_escaped
  text_escaped=$(json_escape "$text")

  local body="{\"input\":${text_escaped}"
  [[ -n "$model" ]] && body+=",\"model\":\"${model}\""
  body+="}"

  curl -s "${BASE}/moderations" -H "$AUTH" -H "$CT_JSON" -d "$body" | jq '.results[0]'
}

cmd_models() {
  curl -s "${BASE}/models" -H "$AUTH" | jq '.data | sort_by(.id) | .[] | {id, owned_by}'
}

# --- dispatch ---

command="${1:-}"
shift || true

case "$command" in
  chat)        cmd_chat "$@" ;;
  stream)      cmd_stream "$@" ;;
  image-gen)   cmd_image_gen "$@" ;;
  image-edit)  cmd_image_edit "$@" ;;
  tts)         cmd_tts "$@" ;;
  stt)         cmd_stt "$@" ;;
  embed)       cmd_embed "$@" ;;
  moderate)    cmd_moderate "$@" ;;
  models)      cmd_models "$@" ;;
  -h|--help|help|"")
    echo "Usage: openai.sh <command> [flags]"
    echo ""
    echo "Commands:"
    echo "  chat        Chat completion (text, vision, structured output, tools)"
    echo "  stream      Streaming chat completion"
    echo "  image-gen   Generate images (GPT image / DALL-E)"
    echo "  image-edit  Edit images"
    echo "  tts         Text-to-speech"
    echo "  stt         Speech-to-text transcription"
    echo "  embed       Create text embeddings"
    echo "  moderate    Content moderation"
    echo "  models      List available models"
    echo ""
    echo "Use --model to specify model (default varies by command)"
    ;;
  *) die "Unknown command: $command. Run with --help for usage." ;;
esac
