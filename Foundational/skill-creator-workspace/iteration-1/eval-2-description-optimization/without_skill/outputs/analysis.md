# Description Optimization Analysis — Gemini Image Skill

## Problem Statement

The Gemini Image skill is triggering on user requests that involve **image manipulation** (resizing, cropping, format conversion, compression) rather than **image generation** (creating new images from text prompts or creatively transforming images with AI). This is a false-positive triggering problem rooted in the skill's description being too broad.

## Current Description (verbatim)

```
Foundational skill for Google's Gemini image generation API, also known as Nano Banana. Use
when: (1) generating images from text prompts, (2) editing or transforming existing images
with text instructions, (3) generating images with specific aspect ratios or sizes, (4) any
task involving the Gemini image generation model (gemini-3-pro-image-preview) or Nano Banana,
(5) combining multiple reference images with a prompt. This is the base Gemini image skill —
specialized skills may reference it for specific image workflows.
```

## Root Cause Analysis

### Primary Issues

1. **"editing or transforming existing images" is dangerously broad.** Resizing an image is technically "transforming" it. Cropping is "editing." The description doesn't distinguish between AI-powered creative transformation (e.g., "remove the background and add a beach scene") and mechanical pixel operations (e.g., "make this 800x600").

2. **"generating images with specific aspect ratios or sizes" overlaps with resize semantics.** A user saying "I need this image in 16:9" could mean either "generate a new image at 16:9" or "crop/resize this existing image to 16:9." The description pulls both interpretations into scope.

3. **"any task involving the Gemini image generation model" is a catch-all.** This clause makes the description maximally permissive — if the agent thinks the task *might* relate to Gemini images, it triggers.

4. **No explicit exclusions.** The description never says what it's NOT for. Since the agent is choosing among skills based on description matching, the absence of boundaries means any image-adjacent request can match.

### Secondary Issues

5. **The word "editing" appears without qualification.** In common usage, "edit an image" covers everything from Photoshop-style AI inpainting to simply adjusting brightness in ImageMagick. The description needs to scope "editing" to AI-generative editing specifically.

6. **No mention of the key differentiator:** This skill calls an AI model that *generates pixels from scratch* (or uses AI to creatively reinterpret images). Standard image operations (resize, crop, rotate, compress, convert format) are handled by tools like ImageMagick, ffmpeg, or sharp — not by a generative AI API.

## Overlap Analysis with Other Skills/Tools

| Request Type | Should Trigger? | Why/Why Not |
|---|---|---|
| "Generate an image of a cat in space" | ✅ Yes | Text-to-image generation |
| "Edit this photo to remove the person in the background" | ✅ Yes | AI-powered creative editing |
| "Make this image 800x600" | ❌ No | Mechanical resize — use ImageMagick/sharp |
| "Crop this photo to square" | ❌ No | Geometric operation — no AI needed |
| "Convert this PNG to JPEG" | ❌ No | Format conversion — use CLI tools |
| "Compress this image to under 500KB" | ❌ No | Compression — use CLI tools |
| "Resize all images in this folder to thumbnails" | ❌ No | Batch resize — scripting task |
| "Make this image brighter" | ⚠️ Edge case | Could be ImageMagick (simple adjustment) or AI (artistic reinterpretation). Default: not this skill. |
| "Change the background to a sunset" | ✅ Yes | AI-powered creative transformation |
| "Upscale this image to 4K" | ⚠️ Edge case | AI upscaling exists on fal.ai, but basic upscale can be done with waifu2x or ffmpeg. Lean toward AI skill if quality matters. |
| "Create a logo for my company" | ✅ Yes | Image generation |
| "Add text overlay to this image" | ❌ No | Compositing — use ImageMagick/PIL |

## Proposed Fix Strategy

1. **Replace "editing or transforming" with "AI-powered creative editing"** — explicitly scope to generative operations.
2. **Remove "generating images with specific aspect ratios or sizes"** as a standalone trigger — fold it into the generation trigger as a parameter, not a use case.
3. **Add explicit exclusions** for resize, crop, format conversion, and compression.
4. **Tighten the catch-all** from "any task involving..." to "when the user explicitly requests the Gemini image model."
5. **Add intent-signaling language** — words like "create," "generate," "imagine," "design," "AI-generated" to prime the matching toward creative intent.

## Expected Impact

- **False positives reduced:** Resize/crop/convert/compress requests should stop triggering this skill.
- **True positives preserved:** Text-to-image, AI editing, and creative transformation requests should still trigger.
- **Edge cases clarified:** Aspect ratio changes, brightness adjustments, and upscaling are pushed toward non-AI tools unless the user explicitly requests AI quality.
