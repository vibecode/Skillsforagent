# Voices API Reference

> **Prefer the wrapper script** (`scripts/elevenlabs.sh voices`, `clone`) for common operations. This reference is for advanced parameters and edge cases the script doesn't cover.

Complete reference for voice discovery, management, and cloning.

## List Voices

`GET /v1/voices`

Returns all voices available to the account (built-in + cloned + shared).

### Response

```json
{
  "voices": [
    {
      "voice_id": "21m00Tcm4TlvDq8ikWAM",
      "name": "Rachel",
      "category": "premade",
      "labels": {
        "accent": "american",
        "description": "calm",
        "age": "young",
        "gender": "female",
        "use_case": "narration"
      },
      "preview_url": "https://...",
      "available_for_tiers": [],
      "settings": { "stability": 0.5, "similarity_boost": 0.75 },
      "high_quality_base_model_ids": ["eleven_multilingual_v2"]
    }
  ]
}
```

### Popular Built-in Voices (convenience, not exhaustive)

| Name | Voice ID | Gender | Accent | Use Case |
|------|----------|--------|--------|----------|
| Rachel | `21m00Tcm4TlvDq8ikWAM` | Female | American | Narration |
| Adam | `pNInz6obpgDQGcFmaJgB` | Male | American | Narration |
| Antoni | `ErXwobaYiN019PkySvjV` | Male | American | Narration |
| Bella | `EXAVITQu4vr4xnSDxMaL` | Female | American | Narration |
| Domi | `AZnzlk1XvdvUeBnXmlld` | Female | American | Narration |
| Elli | `MF3mGyEYCl7XYWbV9V6O` | Female | American | Narration |
| Josh | `TxGEqnHWrfWFTfGW9XjX` | Male | American | Narration |

Always use `GET /v1/voices` for the current list — voices change per account.

## Get Voice Details

`GET /v1/voices/{voice_id}`

Returns full details for a single voice including settings and labels.

## Voice Search (Shared Library)

`GET /v1/shared-voices`

Search the public voice library.

### Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `page_size` | integer | Results per page (default 30) |
| `gender` | string | `male`, `female`, `neutral` |
| `language` | string | ISO language code |
| `age` | string | `young`, `middle_aged`, `old` |
| `accent` | string | e.g. `american`, `british` |
| `search` | string | Free-text search |

---

## Add Voice (Instant Voice Cloning)

`POST /v1/voices/add` (multipart/form-data)

Clone a voice from audio samples. Minimum 1 sample, recommended 3+ minutes total.

### Form Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **yes** | Display name for the voice |
| `files` | file[] | **yes** | Audio samples (repeatable). WAV, MP3, M4A |
| `description` | string | no | Voice description |
| `labels` | string/object | no | JSON labels: `{"language":"en","gender":"male","accent":"british"}` |
| `remove_background_noise` | boolean | no | Denoise samples before cloning |

### Response

```json
{
  "voice_id": "new_voice_id_here"
}
```

### Best Practices for Cloning

- Use clean audio with minimal background noise
- 1–3 minutes minimum, more is better
- Consistent tone/style across samples
- If samples have noise, use `remove_background_noise: true`
- Multiple short clips often better than one long one

---

## Edit Voice

`POST /v1/voices/{voice_id}/edit` (multipart/form-data)

Update name, description, labels, or add new samples to an existing voice.

### Form Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **yes** | Updated name |
| `description` | string | no | Updated description |
| `labels` | string | no | JSON labels |
| `files` | file[] | no | Additional samples |

---

## Delete Voice

`DELETE /v1/voices/{voice_id}`

Permanently removes a cloned voice. Built-in voices cannot be deleted.

---

## Voice Settings

### Get Default Settings

`GET /v1/voices/settings/default`

### Get Voice Settings

`GET /v1/voices/{voice_id}/settings`

### Edit Voice Settings

`POST /v1/voices/{voice_id}/settings/edit`

```json
{
  "stability": 0.5,
  "similarity_boost": 0.75,
  "style": 0.0,
  "use_speaker_boost": true
}
```

### Settings Guide

| Setting | Low (0.0) | High (1.0) | When to adjust |
|---------|-----------|------------|----------------|
| `stability` | More emotional, varied | More consistent, monotone | Lower for acting, higher for audiobooks |
| `similarity_boost` | More creative | Closer to original | Higher for cloned voices to sound authentic |
| `style` | Neutral delivery | Exaggerated style | >0 adds latency, use sparingly |
| `speed` | 0.5x (slow) | 2.0x (fast) | Default 1.0, adjust for pacing |

---

## Voice Design (from Text Description)

Create a voice from a text description without audio samples.

### Generate Previews

`POST /v1/text-to-voice/create-previews`

```json
{
  "text": "Hello, this is a preview of the voice.",
  "voice_description": "A warm, mature female voice with a British accent. Calm and authoritative."
}
```

Returns generated previews to choose from.

### Create Voice from Preview

`POST /v1/text-to-voice`

```json
{
  "voice_name": "My Designed Voice",
  "voice_description": "Warm British female",
  "generated_voice_id": "preview_id_from_above"
}
```
