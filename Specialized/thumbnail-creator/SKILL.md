---
name: thumbnail-creator
description: >
  Specialized skill for generating YouTube-style thumbnails from a topic description, video
  title, or video URL. Use when: (1) creating a YouTube thumbnail for a video, (2) generating
  a click-worthy thumbnail image from a topic or title, (3) designing thumbnails with text
  overlays, faces, and bold visuals, (4) creating multiple thumbnail variations for A/B testing,
  (5) making social media or blog thumbnails optimized for clicks. Builds on: gemini-image.
metadata: {"openclaw": {"emoji": "🖼️"}}
---

# Thumbnail Creator

Generate high-CTR YouTube-style thumbnails from a topic, title, or video URL. Uses AI image generation to produce bold, attention-grabbing visuals optimized for click-through.

## Foundational Skills Used

- **gemini-image** — Image generation and editing via Gemini (Nano Banana). Read it for API details.

## Thumbnail Design Principles

Before generating, understand what makes thumbnails click-worthy:

1. **Bold, simple composition** — One clear focal point. No clutter. Readable at 168×94px (mobile size).
2. **High contrast colors** — Bright backgrounds, saturated tones. Avoid muted palettes.
3. **Emotional faces** — Expressive human faces increase CTR by up to 30%. Exaggerated surprise, excitement, curiosity.
4. **Minimal text** — Under 5 words max. Large, bold, high-contrast text. Often ALL CAPS.
5. **Visual tension** — Before/after, contrast, unexpected juxtaposition, mystery elements.
6. **Brand consistency** — Recurring color scheme, text style, and layout across a channel's thumbnails.

### What NOT to do

- Don't overcrowd — if you can't describe the thumbnail in one sentence, it's too busy
- Don't use small text — it must be readable on a phone
- Don't use generic stock-photo compositions — they look like ads, not content
- Don't put important elements in the bottom-right corner — YouTube's timestamp overlay covers it

## Workflow

### Step 1: Understand the Content

If given a **video URL**, extract context about the video first:
- Use the **supadata** or **serpapi-youtube** skill to get the video title, description, and key topics
- If a transcript is available, scan it for the main hook or surprise

If given a **topic or title**, work directly with that.

Identify:
- **The hook** — What's the one thing that would make someone click?
- **The emotion** — Surprise? Curiosity? Excitement? Fear of missing out?
- **Key visual element** — What single image captures the concept?

### Step 2: Craft the Image Prompt

Build a detailed prompt for the **gemini-image** skill. The prompt should describe a thumbnail, not a generic image.

**Prompt formula:**

```
A YouTube thumbnail showing [MAIN VISUAL ELEMENT]. [COMPOSITION DETAILS].
[COLOR/STYLE DETAILS]. The image is bold, high-contrast, and designed to
grab attention at small sizes. YouTube thumbnail style.
```

**Prompt tips:**
- Always include "YouTube thumbnail style" or "YouTube thumbnail" in the prompt
- Specify the emotional tone: "dramatic", "exciting", "shocking", "curious"
- Describe the composition: "close-up face on the left, [object] on the right"
- Request bold colors: "vibrant", "saturated", "neon accents", "bright background"
- If faces are relevant, specify expression: "person with an shocked/excited/amazed expression"
- Mention contrast: "dark subject on bright background" or "glowing text effect"

**Example prompts by category:**

| Category | Prompt Pattern |
|----------|---------------|
| Tutorial | "YouTube thumbnail of a person looking excited pointing at [SUBJECT], bright colorful background, bold and clean composition" |
| Listicle | "YouTube thumbnail showing [NUMBER] items arranged dramatically, bright gradient background, bold visual hierarchy" |
| Reaction | "YouTube thumbnail of a person with an exaggerated shocked expression looking at [SUBJECT], split composition, vibrant colors" |
| Comparison | "YouTube thumbnail showing [THING A] vs [THING B] in a split-screen style, dramatic lighting, VS text in the center" |
| Story/Drama | "YouTube thumbnail with a dramatic cinematic scene of [SUBJECT], moody lighting with one bright focal point, dark background" |
| How-to | "YouTube thumbnail of [END RESULT] looking impressive, before/after split, bright clean background" |

### Step 3: Generate the Image

Use the **gemini-image** skill to generate the thumbnail.

- **Aspect ratio:** Always use **16:9** — this is YouTube's thumbnail ratio
- **Generate 2-3 variations** with slightly different prompts (swap emotion, change composition, alter colors) so the user can pick the best one
- If the first result isn't right, iterate — adjust the prompt and regenerate

### Step 4: Add Text Overlay (If Needed)

Gemini can generate images with text baked in, but AI-generated text is often unreliable (misspelled, distorted). Two approaches:

**Option A: Bake text into the prompt** (quick, sometimes imperfect)
- Add the text to the prompt: "...with bold white text saying 'TOP 10' in the upper left"
- Works best for very short text (1-3 words, common phrases)
- Always verify the output text is correct

**Option B: Generate image without text, add text programmatically** (reliable)
- Generate the base image without any text
- Use ImageMagick to add text overlay:

```bash
convert base-thumbnail.png \
  -gravity Center \
  -font Impact \
  -pointsize 80 \
  -fill white \
  -stroke black \
  -strokewidth 3 \
  -annotate +0+0 'YOUR TEXT' \
  final-thumbnail.png
```

- Option B is recommended for any text longer than 2 words or text that must be exact

**Text placement guidelines:**
- Top-left or center for primary text
- Avoid bottom-right (YouTube timestamp covers it)
- Maximum 5 words
- Use Impact, Arial Black, or any bold sans-serif font

### Step 5: Deliver

Save the thumbnail(s) and present to the user. Default save location: `~/Photos/thumbnails/`.

- Name files descriptively: `thumbnail-[topic]-v1.png`, `thumbnail-[topic]-v2.png`
- If the user wants to host it, use the **cloud-storage** skill for a CDN URL
- Show all variations so the user can pick

## Quick Reference: Common Requests

| User Says | What To Do |
|-----------|-----------|
| "Make a thumbnail for [topic]" | Steps 2→3→5 (skip transcript extraction) |
| "Make a thumbnail for this video [URL]" | Steps 1→2→3→5 (extract context first) |
| "Add text to this thumbnail" | Step 4 only (use gemini-image to edit, or ImageMagick) |
| "Make variations" | Regenerate Step 3 with prompt tweaks |
| "Make it more clickbaity" | Increase emotional language, add more contrast, exaggerate expressions |
| "Make it cleaner/professional" | Reduce elements, use more whitespace, softer colors, remove text |

## Tips

- **Generate before perfecting.** Get a rough version fast, then iterate. Don't spend 10 minutes on the perfect prompt.
- **Mobile-first.** Shrink the image mentally to phone size. If the focal point is lost, simplify.
- **Study the niche.** If the user has a specific channel style, ask for examples and match the vibe.
- **Contrast is king.** The thumbnail competes with dozens of others. High contrast wins attention.
- **Iterate with editing.** Use gemini-image's editing mode to refine — change backgrounds, swap colors, adjust composition — rather than regenerating from scratch each time.
