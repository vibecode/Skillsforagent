#!/usr/bin/env bash
# elevenlabs.sh — Wrapper for ElevenLabs API via cloud proxy
# Usage: bash scripts/elevenlabs.sh <command> [options]
#
# Commands:
#   voices                     List available voices
#   models                     List available models
#   tts                        Text-to-speech
#   tts-timestamps             Text-to-speech with word timestamps (JSON)
#   dialogue                   Multi-voice dialogue
#   sts                        Speech-to-speech (voice conversion)
#   sound                      Generate sound effect
#   music                      Generate music (simple prompt)
#   music-plan                 Generate music (composition plan JSON)
#   music-stems                Separate stems from audio
#   isolate                    Isolate vocals / remove background
#   transcribe                 Speech-to-text transcription
#   dub                        Dub video/audio to another language
#   dub-status                 Check dubbing job status
#   dub-download               Download dubbed audio
#   clone                      Clone a voice from audio samples

set -euo pipefail

BASE="https://api.elevenlabs.io.cloudproxy.vibecodeapp.com/v1"
API_KEY="${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY}"

# Defaults
FORMAT="mp3_44100_128"
MODEL_TTS="eleven_multilingual_v2"
MODEL_STS="eleven_english_sts_v2"
MODEL_STT="scribe_v2"
MODEL_DIALOGUE="eleven_v3"

die() { echo "ERROR: $*" >&2; exit 1; }

# Static voice ID table — fallback when /voices API is inaccessible
# Verified working 2026-03-13. IDs sourced from ElevenLabs premade voices docs.
# Retired voices removed: Josh, Sam, Emily, Charlotte (all return 404 as of 2026-03).
# Replacements added: Alice, Bill, Brian, Chris, Daniel, Sarah.
# "Bella" renamed to "Sarah" (same ID, ElevenLabs renamed the voice).
declare -A VOICE_IDS=(
  ["adam"]="pNInz6obpgDQGcFmaJgB"
  ["alice"]="Xb7hH8MSUJpSbSDYk0k2"
  ["antoni"]="ErXwobaYiN019PkySvjV"
  ["arnold"]="VR6AewLTigWG4xSOukaG"
  ["bill"]="pqHfZKP75CvOlQylNhV4"
  ["brian"]="nPczCjzI2devNBz1zQrb"
  ["callum"]="N2lVS1w4EtoT3dr4eOWO"
  ["charlie"]="IKne3meq5aSn9XLyUdCD"
  ["chris"]="iP95p4xoKVk53GoZ742B"
  ["daniel"]="onwK4e9ZLuTAKqWW03F9"
  ["domi"]="AZnzlk1XvdvUeBnXmlld"
  ["elli"]="MF3mGyEYCl7XYWbV9V6O"
  ["george"]="JBFqnCBsd6RMkjVDRZzb"
  ["liam"]="TX3LPaxmHKxFdv7VOQHJ"
  ["lily"]="pFZP5JQG7iQjIQuC4Bku"
  ["matilda"]="XrExE9yKIg1WjnnlVkGX"
  ["rachel"]="21m00Tcm4TlvDq8ikWAM"  # verified 2026-03-13 (intermittent 404s are proxy-side, not stale)
  ["sarah"]="EXAVITQu4vr4xnSDxMaL"
  ["will"]="bIHbv24MWmeRgasZH58o"
)

# Resolve voice name to ID. Accepts a voice ID (alphanumeric) or name (looked up).
resolve_voice() {
  local input="$1"
  # Try static table first (fast, no API call)
  local lower="${input,,}"
  if [[ -n "${VOICE_IDS[$lower]:-}" ]]; then
    echo "${VOICE_IDS[$lower]}"
    return
  fi
  # If it looks like a raw voice ID (exactly 20 mixed-case alphanumeric), pass through
  if [[ "$input" =~ ^[a-zA-Z0-9]{20}$ ]]; then
    echo "$input"
    return
  fi
  # Fall back to API lookup (case-insensitive)
  local vid
  vid=$(curl -sf "${BASE}/voices" \
    -H "xi-api-key: ${API_KEY}" | \
    jq -r --arg name "$input" '.voices[] | select(.name | ascii_downcase == ($name | ascii_downcase)) | .voice_id' | head -1) || true
  [[ -n "$vid" ]] || die "Voice not found: $input. Run: elevenlabs.sh voices"
  echo "$vid"
}

cmd_voices() {
  local tmpfile
  tmpfile=$(mktemp)
  local status
  status=$(curl -sw '%{http_code}' "${BASE}/voices" \
    -H "xi-api-key: ${API_KEY}" -o "$tmpfile")
  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$tmpfile" >&2
    rm -f "$tmpfile"
    exit 1
  fi
  jq -r '.voices[] | "\(.voice_id)\t\(.name)\t\(.labels | to_entries | map("\(.key)=\(.value)") | join(", "))"' "$tmpfile" | \
    column -t -s $'\t' 2>/dev/null || cat
  rm -f "$tmpfile"
}

cmd_models() {
  local tmpfile
  tmpfile=$(mktemp)
  local status
  status=$(curl -sw '%{http_code}' "${BASE}/models" \
    -H "xi-api-key: ${API_KEY}" -o "$tmpfile")
  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$tmpfile" >&2
    rm -f "$tmpfile"
    exit 1
  fi
  jq -r '.[] | "\(.model_id)\t\(.name)\t\(.can_do_text_to_speech // false)\t\(.can_do_voice_conversion // false)"' "$tmpfile" | \
    (echo -e "MODEL_ID\tNAME\tTTS\tSTS"; cat) | \
    column -t -s $'\t' 2>/dev/null || cat
  rm -f "$tmpfile"
}

cmd_tts() {
  local voice="" text="" out="" model="$MODEL_TTS" fmt="$FORMAT" speed="" lang=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --voice)  voice="$2"; shift 2;;
      --text)   text="$2"; shift 2;;
      --file)   text=$(cat "$2"); shift 2;;
      --out)    out="$2"; shift 2;;
      --model)  model="$2"; shift 2;;
      --format) fmt="$2"; shift 2;;
      --speed)  speed="$2"; shift 2;;
      --lang)   lang="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$voice" ]] || die "Required: --voice <name|id>"
  [[ -n "$text" ]]  || die "Required: --text <text> or --file <path>"
  [[ -n "$out" ]]   || die "Required: --out <path>"

  local vid
  vid=$(resolve_voice "$voice")

  local body
  body=$(jq -n \
    --arg text "$text" \
    --arg model "$model" \
    '{text: $text, model_id: $model}')

  # Add optional fields
  [[ -n "$speed" ]] && body=$(echo "$body" | jq --argjson speed "$speed" '.voice_settings = {speed: $speed}')
  [[ -n "$lang" ]]  && body=$(echo "$body" | jq --arg lang "$lang" '.language_code = $lang')

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/text-to-speech/${vid}?output_format=${fmt}" \
    -H "xi-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_tts_timestamps() {
  local voice="" text="" out="" model="$MODEL_TTS" fmt="$FORMAT" lang=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --voice)  voice="$2"; shift 2;;
      --text)   text="$2"; shift 2;;
      --file)   text=$(cat "$2"); shift 2;;
      --out)    out="$2"; shift 2;;
      --model)  model="$2"; shift 2;;
      --format) fmt="$2"; shift 2;;
      --lang)   lang="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$voice" ]] || die "Required: --voice <name|id>"
  [[ -n "$text" ]]  || die "Required: --text <text> or --file <path>"
  [[ -n "$out" ]]   || die "Required: --out <path>"

  local vid
  vid=$(resolve_voice "$voice")

  local body
  body=$(jq -n \
    --arg text "$text" \
    --arg model "$model" \
    '{text: $text, model_id: $model}')

  [[ -n "$lang" ]] && body=$(echo "$body" | jq --arg lang "$lang" '.language_code = $lang')

  curl -sf \
    "${BASE}/text-to-speech/${vid}/with-timestamps?output_format=${fmt}" \
    -H "xi-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    -o "$out"

  echo "Saved: $out (JSON with base64 audio + word timestamps)"
}

cmd_dialogue() {
  local inputs="" out="" model="$MODEL_DIALOGUE" fmt="$FORMAT" lang=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --inputs) inputs="$2"; shift 2;;
      --out)    out="$2"; shift 2;;
      --model)  model="$2"; shift 2;;
      --format) fmt="$2"; shift 2;;
      --lang)   lang="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$inputs" ]] || die 'Required: --inputs <json-array> e.g. [{"text":"Hi","voice_id":"..."}]'
  [[ -n "$out" ]]    || die "Required: --out <path>"

  local body
  body=$(jq -n \
    --argjson inputs "$inputs" \
    --arg model "$model" \
    '{inputs: $inputs, model_id: $model}')

  [[ -n "$lang" ]] && body=$(echo "$body" | jq --arg lang "$lang" '.language_code = $lang')

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/text-to-dialogue?output_format=${fmt}" \
    -H "xi-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_sts() {
  local voice="" audio="" out="" model="$MODEL_STS" fmt="$FORMAT" denoise="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --voice)   voice="$2"; shift 2;;
      --audio)   audio="$2"; shift 2;;
      --out)     out="$2"; shift 2;;
      --model)   model="$2"; shift 2;;
      --format)  fmt="$2"; shift 2;;
      --denoise) denoise="true"; shift;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$voice" ]] || die "Required: --voice <name|id>"
  [[ -n "$audio" ]] || die "Required: --audio <path>"
  [[ -n "$out" ]]   || die "Required: --out <path>"

  local vid
  vid=$(resolve_voice "$voice")

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/speech-to-speech/${vid}?output_format=${fmt}" \
    -H "xi-api-key: ${API_KEY}" \
    -F "audio=@${audio}" \
    -F "model_id=${model}" \
    -F "remove_background_noise=${denoise}" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_sound() {
  local text="" out="" duration="" influence="" fmt="$FORMAT" loop="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --text)      text="$2"; shift 2;;
      --out)       out="$2"; shift 2;;
      --duration)  duration="$2"; shift 2;;
      --influence) influence="$2"; shift 2;;
      --format)    fmt="$2"; shift 2;;
      --loop)      loop="true"; shift;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$text" ]] || die "Required: --text <description>"
  [[ -n "$out" ]]  || die "Required: --out <path>"

  local body
  body=$(jq -n \
    --arg text "$text" \
    --argjson loop "$loop" \
    '{text: $text, loop: $loop}')

  [[ -n "$duration" ]]  && body=$(echo "$body" | jq --argjson d "$duration" '.duration_seconds = $d')
  [[ -n "$influence" ]] && body=$(echo "$body" | jq --argjson i "$influence" '.prompt_influence = $i')

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/sound-generation?output_format=${fmt}" \
    -H "xi-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_music() {
  local prompt="" out="" length="" fmt="$FORMAT" instrumental="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt)       prompt="$2"; shift 2;;
      --out)          out="$2"; shift 2;;
      --length)       length="$2"; shift 2;;
      --format)       fmt="$2"; shift 2;;
      --instrumental) instrumental="true"; shift;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$prompt" ]] || die "Required: --prompt <description>"
  [[ -n "$out" ]]    || die "Required: --out <path>"

  local body
  body=$(jq -n \
    --arg prompt "$prompt" \
    --argjson instrumental "$instrumental" \
    '{prompt: $prompt, model_id: "music_v1", force_instrumental: $instrumental}')

  [[ -n "$length" ]] && body=$(echo "$body" | jq --argjson l "$length" '.music_length_ms = $l')

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/music?output_format=${fmt}" \
    -H "xi-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_music_plan() {
  local plan="" out="" fmt="$FORMAT"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plan)   plan="$2"; shift 2;;
      --out)    out="$2"; shift 2;;
      --format) fmt="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$plan" ]] || die "Required: --plan <path-to-json>"
  [[ -n "$out" ]]  || die "Required: --out <path>"

  local plan_json
  plan_json=$(cat "$plan")

  local body
  body=$(jq -n \
    --argjson plan "$plan_json" \
    '{composition_plan: $plan, model_id: "music_v1"}')

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/music?output_format=${fmt}" \
    -H "xi-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_music_stems() {
  local audio="" out="" fmt="$FORMAT"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --audio)  audio="$2"; shift 2;;
      --out)    out="$2"; shift 2;;
      --format) fmt="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$audio" ]] || die "Required: --audio <path>"
  [[ -n "$out" ]]   || die "Required: --out <path> (JSON with base64 stems)"

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/music/stem-separation" \
    -H "xi-api-key: ${API_KEY}" \
    -F "audio=@${audio}" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_isolate() {
  local audio="" out="" fmt="$FORMAT"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --audio)  audio="$2"; shift 2;;
      --out)    out="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$audio" ]] || die "Required: --audio <path>"
  [[ -n "$out" ]]   || die "Required: --out <path>"

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/audio-isolation" \
    -H "xi-api-key: ${API_KEY}" \
    -F "audio=@${audio}" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_transcribe() {
  local audio="" out="" model="$MODEL_STT" lang="" diarize="false" speakers="" tags="true"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --audio)    audio="$2"; shift 2;;
      --url)      audio="URL:$2"; shift 2;;
      --out)      out="$2"; shift 2;;
      --model)    model="$2"; shift 2;;
      --lang)     lang="$2"; shift 2;;
      --diarize)  diarize="true"; shift;;
      --speakers) speakers="$2"; shift 2;;
      --no-tags)  tags="false"; shift;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$audio" ]] || die "Required: --audio <path> or --url <https://...>"
  [[ -n "$out" ]]   || die "Required: --out <path>"

  local args=()
  args+=(-F "model_id=${model}")
  args+=(-F "tag_audio_events=${tags}")
  args+=(-F "diarize=${diarize}")

  if [[ "$audio" == URL:* ]]; then
    args+=(-F "cloud_storage_url=${audio#URL:}")
  else
    args+=(-F "file=@${audio}")
  fi

  [[ -n "$lang" ]]     && args+=(-F "language_code=${lang}")
  [[ -n "$speakers" ]] && args+=(-F "num_speakers=${speakers}")

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/speech-to-text" \
    -H "xi-api-key: ${API_KEY}" \
    "${args[@]}" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out (JSON transcript)"
}

cmd_dub() {
  local file="" url="" out_json="" source="auto" target="" speakers="0" name=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file)     file="$2"; shift 2;;
      --url)      url="$2"; shift 2;;
      --source)   source="$2"; shift 2;;
      --target)   target="$2"; shift 2;;
      --speakers) speakers="$2"; shift 2;;
      --name)     name="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$target" ]] || die "Required: --target <language-code>"
  [[ -n "$file" || -n "$url" ]] || die "Required: --file <path> or --url <url>"

  local args=()
  args+=(-F "source_lang=${source}")
  args+=(-F "target_lang=${target}")
  args+=(-F "num_speakers=${speakers}")

  [[ -n "$file" ]] && args+=(-F "file=@${file}")
  [[ -n "$url" ]]  && args+=(-F "source_url=${url}")
  [[ -n "$name" ]] && args+=(-F "name=${name}")

  curl -sf \
    "${BASE}/dubbing" \
    -H "xi-api-key: ${API_KEY}" \
    "${args[@]}"

  echo ""
  echo "Dubbing job created. Use 'dub-status --id <dubbing_id>' to check progress."
}

cmd_dub_status() {
  local id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id) id="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$id" ]] || die "Required: --id <dubbing_id>"

  curl -sf "${BASE}/dubbing/${id}" \
    -H "xi-api-key: ${API_KEY}" | jq .
}

cmd_dub_download() {
  local id="" lang="" out=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)   id="$2"; shift 2;;
      --lang) lang="$2"; shift 2;;
      --out)  out="$2"; shift 2;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$id" ]]   || die "Required: --id <dubbing_id>"
  [[ -n "$lang" ]] || die "Required: --lang <language_code>"
  [[ -n "$out" ]]  || die "Required: --out <path>"

  local status
  status=$(curl -sw '%{http_code}' \
    "${BASE}/dubbing/${id}/audio/${lang}" \
    -H "xi-api-key: ${API_KEY}" \
    -o "$out")

  if [[ "$status" -ge 400 ]]; then
    echo "API error (HTTP $status):" >&2
    cat "$out" >&2
    rm -f "$out"
    exit 1
  fi
  echo "Saved: $out"
}

cmd_clone() {
  local name="" files=() description="" denoise="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)        name="$2"; shift 2;;
      --file)        files+=("$2"); shift 2;;
      --description) description="$2"; shift 2;;
      --denoise)     denoise="true"; shift;;
      *) die "Unknown option: $1";;
    esac
  done
  [[ -n "$name" ]]          || die "Required: --name <voice-name>"
  [[ ${#files[@]} -gt 0 ]]  || die "Required: --file <path> (repeatable)"

  local args=()
  args+=(-F "name=${name}")
  args+=(-F "remove_background_noise=${denoise}")
  for f in "${files[@]}"; do
    args+=(-F "files=@${f}")
  done
  [[ -n "$description" ]] && args+=(-F "description=${description}")

  curl -sf \
    "${BASE}/voices/add" \
    -H "xi-api-key: ${API_KEY}" \
    "${args[@]}" | jq .

  echo "Voice cloned. Use 'voices' to see it."
}

# --- Dispatch ---
CMD="${1:-}"
shift || true

case "$CMD" in
  voices)         cmd_voices "$@";;
  models)         cmd_models "$@";;
  tts)            cmd_tts "$@";;
  tts-timestamps) cmd_tts_timestamps "$@";;
  dialogue)       cmd_dialogue "$@";;
  sts)            cmd_sts "$@";;
  sound)          cmd_sound "$@";;
  music)          cmd_music "$@";;
  music-plan)     cmd_music_plan "$@";;
  music-stems)    cmd_music_stems "$@";;
  isolate)        cmd_isolate "$@";;
  transcribe)     cmd_transcribe "$@";;
  dub)            cmd_dub "$@";;
  dub-status)     cmd_dub_status "$@";;
  dub-download)   cmd_dub_download "$@";;
  clone)          cmd_clone "$@";;
  *)
    echo "Usage: elevenlabs.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  voices              List available voices"
    echo "  models              List available models"
    echo "  tts                 Text-to-speech → audio file"
    echo "  tts-timestamps      Text-to-speech → JSON with timestamps"
    echo "  dialogue            Multi-voice dialogue → audio file"
    echo "  sts                 Speech-to-speech voice conversion"
    echo "  sound               Generate sound effect"
    echo "  music               Generate music (simple prompt)"
    echo "  music-plan          Generate music (composition plan)"
    echo "  music-stems         Separate stems from audio"
    echo "  isolate             Isolate vocals / remove background"
    echo "  transcribe          Speech-to-text transcription"
    echo "  dub                 Dub video/audio to another language"
    echo "  dub-status          Check dubbing job status"
    echo "  dub-download        Download dubbed audio"
    echo "  clone               Clone a voice from audio samples"
    echo ""
    echo "Run 'elevenlabs.sh <command> --help' for command-specific options."
    exit 1
    ;;
esac
