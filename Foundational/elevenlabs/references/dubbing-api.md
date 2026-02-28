# Dubbing API Reference

Complete reference for video/audio dubbing (translation) and the dubbing studio resource API.

## Create Dubbing Job

`POST /v1/dubbing` (multipart/form-data)

Translates video or audio from one language to another, preserving speaker voices.

### Form Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `file` | file | no* | — | Video/audio file to dub |
| `source_url` | string | no* | — | URL of source (alternative to file) |
| `source_lang` | string | no | `auto` | ISO 639-1/3 source language |
| `target_lang` | string | **yes** | — | ISO 639-1/3 target language |
| `num_speakers` | integer | no | 0 | 0 = auto-detect. Max 32 |
| `name` | string | no | — | Project name |
| `watermark` | boolean | no | false | Add watermark to output |
| `highest_resolution` | boolean | no | false | Use highest available resolution |
| `start_time` | integer | no | — | Start time in seconds |
| `end_time` | integer | no | — | End time in seconds |
| `drop_background_audio` | boolean | no | false | Remove background audio (better for speeches) |
| `disable_voice_cloning` | boolean | no | false | Use library voices instead of cloning |

*One of `file` or `source_url` is required.

### Response

```json
{
  "dubbing_id": "abc123",
  "expected_duration_sec": 120
}
```

---

## Check Status

`GET /v1/dubbing/{dubbing_id}`

### Response

```json
{
  "dubbing_id": "abc123",
  "name": "My Video",
  "status": "dubbed",
  "target_languages": ["es"],
  "error": null
}
```

| Status | Meaning |
|--------|---------|
| `dubbing` | In progress |
| `dubbed` | Complete, ready to download |
| `failed` | Error occurred |

---

## Download Dubbed Audio

`GET /v1/dubbing/{dubbing_id}/audio/{language_code}`

Returns the dubbed audio/video binary. Save directly to file.

---

## Get Transcript

`GET /v1/dubbing/{dubbing_id}/transcript/{language_code}`

Returns the transcript for the dubbed content.

### Formatted Transcript

`GET /v1/dubbing/{dubbing_id}/transcripts/{language_code}/format/{format_type}`

| format_type | Output |
|-------------|--------|
| `srt` | SubRip subtitle format |
| `webvtt` | WebVTT subtitle format |

---

## Delete Dubbing

`DELETE /v1/dubbing/{dubbing_id}`

---

## Dubbing Studio (Advanced)

The resource API provides fine-grained control over the dubbing process: editing segments, managing speakers, re-dubbing specific parts.

### Get Resource

`GET /v1/dubbing/resource/{dubbing_id}`

Returns the full dubbing resource with speakers, segments, and metadata.

### Speakers

| Action | Method | Path |
|--------|--------|------|
| Create speaker | POST | `/v1/dubbing/resource/{dubbing_id}/speaker` |
| Update speaker | PATCH | `/v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}` |
| Find similar voices | GET | `/v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}/similar-voices` |

### Segments

| Action | Method | Path |
|--------|--------|------|
| Create segment | POST | `/v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}/segment` |
| Edit segment | PATCH | `/v1/dubbing/resource/{dubbing_id}/segment/{segment_id}/{language}` |
| Delete segment | DELETE | `/v1/dubbing/resource/{dubbing_id}/segment/{segment_id}` |
| Move segments between speakers | POST | `/v1/dubbing/resource/{dubbing_id}/migrate-segments` |

### Re-processing

| Action | Method | Path |
|--------|--------|------|
| Transcribe | POST | `/v1/dubbing/resource/{dubbing_id}/transcribe` |
| Translate | POST | `/v1/dubbing/resource/{dubbing_id}/translate` |
| Re-dub | POST | `/v1/dubbing/resource/{dubbing_id}/dub` |
| Add language | POST | `/v1/dubbing/resource/{dubbing_id}/language` |
| Render final | POST | `/v1/dubbing/resource/{dubbing_id}/render/{language}` |

### Typical Studio Workflow

1. Create dub with `dubbing_studio: true`
2. Get resource to inspect speakers/segments
3. Edit segments (fix translations, adjust timing)
4. Re-dub changed segments
5. Render final output
6. Download
