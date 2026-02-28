# TTS, Dialogue & Speech-to-Speech API Reference

Complete parameter reference for text-to-speech, multi-voice dialogue, and voice conversion endpoints.

## Text-to-Speech

### Endpoints

| Variant | Method | Path | Response |
|---------|--------|------|----------|
| Standard | POST | `/v1/text-to-speech/{voice_id}` | Audio binary |
| Streaming | POST | `/v1/text-to-speech/{voice_id}/stream` | Chunked audio |
| With timestamps | POST | `/v1/text-to-speech/{voice_id}/with-timestamps` | JSON (base64 audio + word timestamps) |
| Streaming + timestamps | POST | `/v1/text-to-speech/{voice_id}/stream/with-timestamps` | Chunked JSON |

### Query Parameters

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `output_format` | string | `mp3_44100_128` | See output formats in SKILL.md |
| `enable_logging` | boolean | `true` | `false` = zero retention (enterprise only) |

### Request Body

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `text` | string | **yes** | — | Text to convert. Max ~5000 chars (model-dependent) |
| `model_id` | string | no | `eleven_multilingual_v2` | Model ID. Query `GET /v1/models` for options |
| `language_code` | string | no | auto | ISO 639-1 code. Helps with pronunciation in multilingual models |
| `voice_settings` | object | no | voice defaults | Override voice settings (see below) |
| `seed` | integer | no | — | 0–4294967295. Best-effort determinism |
| `apply_text_normalization` | string | no | `auto` | `auto`, `on`, `off`. Controls number/date spelling |
| `previous_text` | string | no | — | Text before this chunk (improves continuity) |
| `next_text` | string | no | — | Text after this chunk (improves continuity) |
| `previous_request_ids` | string[] | no | — | Up to 3 prior request IDs (overrides previous_text) |
| `next_request_ids` | string[] | no | — | Up to 3 next request IDs (overrides next_text) |
| `pronunciation_dictionary_locators` | array | no | — | Up to 3 `{pronunciation_dictionary_id, version_id}` |

### Voice Settings Object

Controls voice characteristics. Pass in `voice_settings` to override the voice's stored defaults.

| Field | Type | Range | Default | Description |
|-------|------|-------|---------|-------------|
| `stability` | number | 0.0–1.0 | 0.5 | Higher = more consistent, less emotional range |
| `similarity_boost` | number | 0.0–1.0 | 0.75 | Higher = closer to original voice |
| `style` | number | 0.0–1.0 | 0.0 | Style exaggeration. >0 increases latency |
| `speed` | number | 0.5–2.0 | 1.0 | Playback speed multiplier |
| `use_speaker_boost` | boolean | — | true | Boosts similarity, increases latency slightly |

### Request Stitching (Long Text)

For text longer than the model limit, split into chunks and use stitching for natural continuity:

```bash
# Method 1: previous_text / next_text
{"text": "chunk 2...", "previous_text": "chunk 1...", "next_text": "chunk 3..."}

# Method 2: previous_request_ids (better quality, uses actual audio context)
# First request returns request_id in x-request-id header
{"text": "chunk 2...", "previous_request_ids": ["id-from-chunk-1"]}
```

### Timestamps Response Format

The `/with-timestamps` variants return JSON:

```json
{
  "audio_base64": "//uQxAAA...",
  "alignment": {
    "characters": ["H","e","l","l","o"],
    "character_start_times_seconds": [0.0, 0.05, 0.1, 0.15, 0.2],
    "character_end_times_seconds": [0.05, 0.1, 0.15, 0.2, 0.3]
  },
  "normalized_alignment": {
    "characters": ["H","e","l","l","o"],
    "character_start_times_seconds": [0.0, 0.05, 0.1, 0.15, 0.2],
    "character_end_times_seconds": [0.05, 0.1, 0.15, 0.2, 0.3]
  }
}
```

---

## Text-to-Dialogue (Multi-Voice)

Generate a single audio file with multiple speakers taking turns.

### Endpoints

| Variant | Method | Path | Response |
|---------|--------|------|----------|
| Standard | POST | `/v1/text-to-dialogue` | Audio binary |
| Streaming | POST | `/v1/text-to-dialogue/stream` | Chunked audio |
| With timestamps | POST | `/v1/text-to-dialogue/with-timestamps` | JSON |
| Streaming + timestamps | POST | `/v1/text-to-dialogue/stream/with-timestamps` | Chunked JSON |

### Request Body

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `inputs` | array | **yes** | — | Array of `{text, voice_id}` objects. Max 10 unique voices |
| `model_id` | string | no | `eleven_v3` | Must support TTS |
| `language_code` | string | no | auto | ISO 639-1 |
| `settings` | object | no | — | `{stability: 0.5}` — model-level settings |
| `seed` | integer | no | — | 0–4294967295 |
| `apply_text_normalization` | string | no | `auto` | `auto`, `on`, `off` |
| `pronunciation_dictionary_locators` | array | no | — | Up to 3 |

### Example

```json
{
  "inputs": [
    {"text": "Welcome to the show, Sarah!", "voice_id": "21m00Tcm4TlvDq8ikWAM"},
    {"text": "Thanks for having me!", "voice_id": "pNInz6obpgDQGcFmaJgB"},
    {"text": "So tell us about your new book.", "voice_id": "21m00Tcm4TlvDq8ikWAM"}
  ],
  "model_id": "eleven_v3"
}
```

---

## Speech-to-Speech (Voice Conversion)

Convert audio from one voice to another while preserving emotion and delivery.

### Endpoints

| Variant | Method | Path | Content-Type | Response |
|---------|--------|------|-------------|----------|
| Standard | POST | `/v1/speech-to-speech/{voice_id}` | multipart/form-data | Audio binary |
| Streaming | POST | `/v1/speech-to-speech/{voice_id}/stream` | multipart/form-data | Chunked audio |

### Form Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `audio` | file | **yes** | — | Source audio (wav, mp3, m4a, webm) |
| `model_id` | string | no | `eleven_english_sts_v2` | Must support voice conversion |
| `voice_settings` | string | no | — | JSON-encoded voice settings string |
| `seed` | integer | no | — | 0–4294967295 |
| `remove_background_noise` | boolean | no | false | Denoise input before conversion |

### Models for STS

| Model | Languages | Notes |
|-------|-----------|-------|
| `eleven_english_sts_v2` | English | Default, best for English |
| `eleven_multilingual_sts_v2` | 29 languages | Use for non-English |

Query `GET /v1/models` and filter by `can_do_voice_conversion: true` for the current list.
