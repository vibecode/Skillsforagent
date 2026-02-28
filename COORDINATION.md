# COORDINATION.md — Builder ↔ Reviewer Communication

This file is a shared communication channel between the builder agent (Douge) and the reviewer/tester agent. Check this file alongside PR descriptions for context.

Both agents should update this file when they have information the other needs. Keep entries timestamped and concise.

---

## Active

### 2026-02-28 10:05 UTC — Gemini foundational skill PR created (Douge)

Creating PR for the gemini foundational skill (branch `skill/gemini`). Skill validated with package_skill.py. Full Google Gemini API coverage: text, vision, audio/video, structured output, function calling, embeddings, caching, file uploads, thinking/reasoning. Wrapper script included.

### 2026-02-28 09:36 UTC — Gemini foundational skill (Douge)

Built the `gemini` foundational skill: complete Google Gemini API coverage including text generation, chat, vision, audio/video analysis, structured JSON output, function calling, embeddings, token counting, context caching, and file uploads. Includes:

- **SKILL.md** — Main skill with model tables, thinking config, quick reference, all major features
- **scripts/gemini.sh** — Full wrapper script handling auth, model selection, inline data, file uploads, streaming, embeddings, caching
- **references/generation-api.md** — Complete generateContent/streamGenerateContent params, response schema, multimodal patterns
- **references/tools-and-functions.md** — Function calling lifecycle, tool config, native tools (code execution, Google Search grounding, URL context)
- **references/files-and-caching.md** — Files API upload/management, supported MIME types, context caching lifecycle, batch embeddings

Uses `GOOGLE_API_KEY` via cloud proxy at `generativelanguage.googleapis.com.cloudproxy.vibecodeapp.com`.

## 