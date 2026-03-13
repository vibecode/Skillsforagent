---
name: elevenlabs
description: >
  Foundational skill for the ElevenLabs audio AI API — text-to-speech, multi-voice dialogue,
  voice conversion, sound effects, music generation, audio isolation, speech-to-text, dubbing,
  and voice cloning. Use this skill when: (1) converting text to speech or generating voiceover,
  (2) creating multi-speaker dialogue or podcast audio, (3) converting audio from one voice to
  another (speech-to-speech), (4) generating sound effects from text descriptions, (5) composing
  music or songs with lyrics, (6) isolating vocals or removing background noise, (7) transcribing
  audio to text, (8) dubbing video/audio into other languages, (9) cloning a voice from audio
  samples, (10) listing or searching available voices. Includes a wrapper script for direct use.
  This is the base ElevenLabs skill — specialized skills may reference it.
metadata: {"openclaw": {"emoji": "🔊", "requires": {"env": ["ELEVENLABS_API_KEY"]}, "primaryEnv": "ELEVENLABS_API_KEY"}}
---

# ElevenLabs

Audio AI platform: speech, sound effects, music, dubbing, transcription. All via HTTP.

## Authentication

```
Base URL: https://api.elevenlabs.io.cloudproxy.vibecodeapp.com/v1
Header:   xi-api-key: ${ELEVENLABS_API_KEY}
```

The cloud proxy handles credentials. Use `$ELEVENLABS_API_KEY` as-is.

> **Proxy key limitation:** Cloud proxy keys may lack `voices_read` and `models_read` scopes. If `voices` or `models` commands return HTTP 401, use the static voice ID table built into the wrapper script (19 verified premade voices including Rachel, Adam, Sarah, Brian, etc.) and the model table in this doc. TTS, sound effects, music, and all generation endpoints work regardless.

## Wrapper Script

The fastest way to use this API. Handles auth, voice name→ID resolution, binary responses, and error handling.

```bash
SCRIPT="$(dirname "$0")/scripts/elevenlabs.sh"  # or use full skill path
```

### Quick Reference

```bash
# List voices and models
bash $SCRIPT voices
bash $SCRIPT models

# Text-to-speech
bash $SCRIPT tts --voice "Rachel" --text "Hello world" --out hello.mp3
bash $SCRIPT tts --voice "Adam" --text "Long narration..." --out narration.mp3 --speed 1.2

# Multi-voice dialogue
bash $SCRIPT dialogue \
  --inputs '[{"text":"Welcome!","voice_id":"21m00Tcm4TlvDq8ikWAM"},{"text":"Thanks!","voice_id":"pNInz6obpgDQGcFmaJgB"}]' \
  --out dialogue.mp3

# Voice conversion
bash $SCRIPT sts --voice "Rachel" --audio input.wav --out converted.mp3 --denoise

# Sound effects
bash $SCRIPT sound --text "Thunder rolling across mountain valley" --duration 8 --out thunder.mp3
bash $SCRIPT sound --text "Gentle rain on window" --loop --out rain_loop.mp3

# Music
bash $SCRIPT music --prompt "Upbeat electronic with synths" --length 30000 --out track.mp3
bash $SCRIPT music --prompt "Acoustic ballad about the ocean" --instrumental --out instrumental.mp3
bash $SCRIPT music-plan --plan composition.json --out song.mp3

# Audio isolation (extract vocals)
bash $SCRIPT isolate --audio noisy.mp3 --out clean_vocals.mp3

# Transcription
bash $SCRIPT transcribe --audio recording.mp3 --out transcript.json
bash $SCRIPT transcribe --url "https://example.com/audio.mp3" --out transcript.json --diarize

# Dubbing
bash $SCRIPT dub --file video.mp4 --target es --out dubbed.mp4
bash $SCRIPT dub --url "https://youtube.com/watch?v=..." --target fr
bash $SCRIPT dub-status --id <dubbing_id>
bash $SCRIPT dub-download --id <dubbing_id> --lang es --out dubbed_es.mp4

# Voice cloning
bash $SCRIPT clone --name "My Voice" --file sample1.mp3 --file sample2.mp3 --denoise
```

### Script Flags Reference

All commands accept `--format <output_format>` (default: `mp3_44100_128`).

| Command | Required Flags | Optional Flags |
|---------|---------------|----------------|
| `tts` | `--voice`, `--text`/`--file`, `--out` | `--model`, `--format`, `--speed`, `--lang` |
| `tts-timestamps` | `--voice`, `--text`/`--file`, `--out` | `--model`, `--format`, `--lang` |
| `dialogue` | `--inputs` (JSON), `--out` | `--model`, `--format`, `--lang` |
| `sts` | `--voice`, `--audio`, `--out` | `--model`, `--format`, `--denoise` |
| `sound` | `--text`, `--out` | `--duration`, `--influence`, `--format`, `--loop` |
| `music` | `--prompt`, `--out` | `--length` (ms), `--format`, `--instrumental` |
| `music-plan` | `--plan` (JSON file), `--out` | `--format` |
| `music-stems` | `--audio`, `--out` | — |
| `isolate` | `--audio`, `--out` | — |
| `transcribe` | `--audio`/`--url`, `--out` | `--model`, `--lang`, `--diarize`, `--speakers`, `--no-tags` |
| `dub` | `--file`/`--url`, `--target` | `--source`, `--speakers`, `--name` |
| `dub-status` | `--id` | — |
| `dub-download` | `--id`, `--lang`, `--out` | — |
| `clone` | `--name`, `--file` (repeatable) | `--description`, `--denoise` |

## Model Discovery

```bash
bash $SCRIPT models
```

Key models (convenience, not exhaustive — always query live):

| Model | Capabilities | Notes |
|-------|-------------|-------|
| `eleven_v3` | TTS | Latest, most expressive. Dialogue default |
| `eleven_multilingual_v2` | TTS | 29 languages. TTS default |
| `eleven_flash_v2_5` | TTS | Low latency |
| `eleven_english_sts_v2` | STS | English voice conversion |
| `eleven_multilingual_sts_v2` | STS | Multilingual voice conversion |
| `music_v1` | Music | Music generation |
| `scribe_v2` | STT | Transcription |

## Output Formats

| Format | Quality | Tier Required |
|--------|---------|---------------|
| `mp3_44100_128` | Standard MP3 (default) | Free |
| `mp3_44100_192` | High-quality MP3 | Creator+ |
| `mp3_44100_64` | Low bitrate MP3 | Free |
| `mp3_22050_32` | Minimal MP3 | Free |
| `opus_48000_128` | Good for streaming | Free |
| `pcm_44100` | Uncompressed PCM | Pro+ |
| `wav_44100` | WAV | Pro+ |
| `ulaw_8000` | μ-law (Twilio) | Free |
| `alaw_8000` | A-law (telephony) | Free |

## Voice Settings

Control voice characteristics per-request:

| Setting | Range | Default | Effect |
|---------|-------|---------|--------|
| `stability` | 0.0–1.0 | 0.5 | Low = emotional range, High = consistent |
| `similarity_boost` | 0.0–1.0 | 0.75 | How close to original voice |
| `style` | 0.0–1.0 | 0.0 | Style amplification (adds latency >0) |
| `speed` | 0.7–1.2 | 1.0 | Playback speed |
| `use_speaker_boost` | boolean | true | Similarity boost (slight latency cost) |

## Error Handling

All endpoints return JSON errors on failure:

```json
{
  "detail": {
    "status": "error_type",
    "message": "Human-readable description"
  }
}
```

| HTTP Code | Common Cause |
|-----------|-------------|
| 401 | Invalid or missing API key |
| 422 | Invalid parameters (check message for details) |
| 429 | Rate limited — back off and retry |

## References

For full parameter tables and advanced usage:

- **[references/tts-dialogue-api.md](references/tts-dialogue-api.md)** — TTS params (stitching, timestamps, normalization), multi-voice dialogue, speech-to-speech
- **[references/audio-generation-api.md](references/audio-generation-api.md)** — Sound effects, music composition plans, stem separation
- **[references/voices-api.md](references/voices-api.md)** — Voice listing, cloning, settings, design from description, shared library search
- **[references/dubbing-api.md](references/dubbing-api.md)** — Dubbing lifecycle, studio resource editing, transcripts
