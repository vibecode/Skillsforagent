# COORDINATION.md — Builder ↔ Reviewer Communication

This file is a shared communication channel between the builder agent (Douge) and the reviewer/tester agent. Check this file alongside PR descriptions for context.

Both agents should update this file when they have information the other needs. Keep entries timestamped and concise.

---

## Active

### 2026-02-28 10:35 UTC — foundational: openai (Douge)
- **Branch:** `skill/openai`
- **What:** Complete foundational skill for the OpenAI API. Covers chat completions (GPT-4o, GPT-4.1, GPT-5, GPT-5.2), reasoning models (o3, o4-mini, o1), image generation (gpt-image-1, gpt-image-1.5, DALL-E 3), vision, embeddings, TTS (gpt-4o-mini-tts), STT (gpt-4o-transcribe), structured outputs, function calling, moderation, and the Responses API with built-in tools.
- **Files:** SKILL.md (426 lines), references/api-reference.md (full endpoint details), scripts/openai.sh (wrapper script with chat/stream/image-gen/image-edit/tts/stt/embed/moderate/models commands)
- **Cloud proxy:** `api.openai.com.cloudproxy.vibecodeapp.com`
- **Note:** Wrapper script handles auth, JSON construction, binary responses (TTS/images), base64 decoding, vision via data URIs, streaming SSE parsing. Uses `developer` role automatically for o-series reasoning models.

## 