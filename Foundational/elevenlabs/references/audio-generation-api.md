# Sound Effects & Music API Reference

> **Prefer the wrapper script** (`scripts/elevenlabs.sh sound`, `music`, `music-plan`, `music-stems`) for common operations. This reference is for advanced parameters and edge cases the script doesn't cover.

Complete parameter reference for sound generation, music composition, and stem separation.

## Sound Effects

Generate sound effects from text descriptions.

### Endpoint

`POST /v1/sound-generation`

Query param: `output_format` (default `mp3_44100_128`)

### Request Body

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `text` | string | **yes** | — | Description of the sound effect |
| `duration_seconds` | number | no | auto | 0.5–30. Auto if omitted |
| `prompt_influence` | number | no | 0.3 | 0.0–1.0. Higher = follows prompt more closely, less variation |
| `loop` | boolean | no | false | Seamless looping (only with `eleven_text_to_sound_v2`) |
| `model_id` | string | no | `eleven_text_to_sound_v2` | Model to use |

### Tips

- Be specific: "Large wooden door creaking open slowly in stone castle" > "Door opening"
- `prompt_influence` at 0.3 gives good variety; raise to 0.7+ for precision
- Response is raw audio binary — save directly to file
- For loopable ambient sound (rain, fire, engine hum), use `--loop`

---

## Music Generation

Compose full songs with vocals or instrumentals.

### Endpoints

| Variant | Method | Path | Response |
|---------|--------|------|----------|
| Standard | POST | `/v1/music` | Audio binary |
| Streaming | POST | `/v1/music/stream` | Chunked audio |
| Detailed | POST | `/v1/music/detailed` | JSON with metadata + audio |
| Plan only | POST | `/v1/music/plan` | Composition plan JSON (no audio) |

Query param: `output_format` (default `mp3_44100_128`)

### Request Body (Simple Prompt Mode)

Use `prompt` for quick generation. Cannot combine with `composition_plan`.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `prompt` | string | no* | — | Text description (max 4100 chars). *Required if no composition_plan |
| `music_length_ms` | integer | no | auto | 3000–600000 (3s to 10min) |
| `model_id` | string | no | `music_v1` | Only `music_v1` currently |
| `force_instrumental` | boolean | no | false | Guarantees no vocals |
| `seed` | integer | no | — | 0–2147483647 |

### Request Body (Composition Plan Mode)

Use `composition_plan` for detailed control over song structure. Cannot combine with `prompt`.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `composition_plan` | object | no* | — | Structured song plan (see below) |
| `model_id` | string | no | `music_v1` | Only `music_v1` |
| `seed` | integer | no | — | 0–2147483647 |
| `respect_sections_durations` | boolean | no | true | false = model adjusts durations for quality |

### Composition Plan Object

```json
{
  "positive_global_styles": ["pop", "electronic", "upbeat"],
  "negative_global_styles": ["metal", "country"],
  "sections": [
    {
      "section_name": "Intro",
      "duration_ms": 8000,
      "positive_local_styles": ["ambient", "building"],
      "negative_local_styles": ["drums"],
      "lines": []
    },
    {
      "section_name": "Verse 1",
      "duration_ms": 20000,
      "positive_local_styles": ["rhythmic"],
      "negative_local_styles": [],
      "lines": ["Walking through the city lights", "Every shadow tells a story"]
    },
    {
      "section_name": "Chorus",
      "duration_ms": 15000,
      "positive_local_styles": ["powerful", "anthemic"],
      "negative_local_styles": [],
      "lines": ["We are the ones who shine", "Breaking through the night"]
    }
  ]
}
```

| Field | Type | Max | Description |
|-------|------|-----|-------------|
| `positive_global_styles` | string[] | 50 | Styles for the whole song |
| `negative_global_styles` | string[] | 50 | Styles to avoid |
| `sections` | array | 30 | Song sections in order |
| `sections[].section_name` | string | — | e.g. "Intro", "Verse 1", "Chorus" |
| `sections[].duration_ms` | integer | — | Duration of this section |
| `sections[].positive_local_styles` | string[] | — | Styles for this section |
| `sections[].negative_local_styles` | string[] | — | Styles to avoid in this section |
| `sections[].lines` | string[] | — | Lyrics for this section (empty = instrumental) |

### Generate a Plan First

Use the wrapper script's `music-plan` command to generate from a composition plan:

```bash
# 1. Generate a plan (save as JSON, then edit as needed)
# Use the API's /v1/music/plan endpoint via the script's plan workflow:
bash $SCRIPT music --prompt "Upbeat pop song about summer" --out song.mp3

# For full plan control: create a composition plan JSON, then generate from it
bash $SCRIPT music-plan --plan plan.json --out song.mp3
```

---

## Stem Separation

Separate audio into individual stems (vocals, drums, bass, other).

### Endpoint

`POST /v1/music/stem-separation` (multipart/form-data)

### Form Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `audio` | file | **yes** | Audio file to separate |

### Response

JSON with base64-encoded stems:

```json
{
  "vocals": "base64...",
  "drums": "base64...",
  "bass": "base64...",
  "other": "base64..."
}
```

Decode each stem with `base64 -d` and save as audio files.
