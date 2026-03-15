# Proposed Improved Descriptions

## Current Description (Baseline)

```
Foundational skill for Google's Gemini image generation API, also known as Nano Banana. Use
when: (1) generating images from text prompts, (2) editing or transforming existing images
with text instructions, (3) generating images with specific aspect ratios or sizes, (4) any
task involving the Gemini image generation model (gemini-3-pro-image-preview) or Nano Banana,
(5) combining multiple reference images with a prompt. This is the base Gemini image skill —
specialized skills may reference it for specific image workflows.
```

**Character count:** 521
**Expected failures on eval set:** Queries 11–17 likely false-trigger (7/20 = 35% error rate)

---

## Candidate A: Explicit Exclusion Strategy

```
Use this skill for AI-powered image creation and creative image editing via Google's Gemini API (Nano Banana / gemini-3-pro-image-preview). Use when: (1) generating new images from text descriptions, (2) AI-powered creative edits to existing images — style transfer, object removal, inpainting, adding/changing visual elements, background replacement, (3) generating image variations or remixes from reference images, (4) any task that explicitly mentions Gemini image generation or Nano Banana. Do NOT use for mechanical image operations like resizing, cropping, rotating, format conversion, compression, thumbnail generation, or metadata stripping — those are handled by standard image processing tools (ImageMagick, sharp, PIL), not AI generation.
```

**Character count:** 700
**Strategy:** Keeps all valid trigger cases, replaces vague language with specific AI-edit verbs, adds an explicit exclusion list for mechanical operations. The "Do NOT use" section gives the agent a clear negative signal.
**Tradeoff:** The exclusion list is the highest-ROI change — agents pattern-match well against explicit negatives.

---

## Candidate B: Intent-Focused (No Exclusion List)

```
AI image generation and creative editing via Google's Gemini API (Nano Banana / gemini-3-pro-image-preview). Use when the task requires AI understanding of image content: generating images from text prompts, creative style transfer, modifying what's depicted in an image (adding objects, removing elements, changing backgrounds, artistic transformations), or generating variations from reference images. The key signal is whether the task needs the model to understand or create visual content — if it's a mechanical operation like resizing or format conversion, standard tools handle it better.
```

**Character count:** 569
**Strategy:** Frames the trigger criterion as "does this need AI understanding of image content?" — a general principle rather than an exhaustive list. Mentions resize/format conversion as counter-examples but doesn't enumerate every possible mechanical operation.
**Tradeoff:** More elegant and generalizable, but the agent has to do more reasoning to decide if a task is "mechanical." May miss some edge cases.

---

## Candidate C: Hybrid (Recommended)

```
AI image generation and creative image editing via Google's Gemini API (Nano Banana / gemini-3-pro-image-preview). Use when: (1) generating new images from text descriptions or prompts, (2) AI-powered edits that change image content — style transfer, background replacement, object removal/addition, inpainting, visual attribute changes, (3) creating image variations from reference photos, (4) tasks explicitly requesting Gemini image generation or Nano Banana. This skill is for tasks requiring AI to understand or create visual content. Do NOT use for resizing, cropping, rotating, compressing, format-converting, or other mechanical image operations — use standard tools for those.
```

**Character count:** 639
**Strategy:** Combines the best of A and B — specific AI-edit verbs (from A), the general principle about AI understanding (from B), and a concise exclusion line (from A but shorter). Leads with what the skill IS rather than what it isn't.
**Tradeoff:** Best balance of precision and conciseness. The exclusion list is shorter than A but covers the key false-trigger terms.

---

## Comparison Matrix

| Query | Current | Candidate A | Candidate B | Candidate C |
|-------|---------|-------------|-------------|-------------|
| Sunset generation | ✅ | ✅ | ✅ | ✅ |
| Dog with top hat | ✅ | ✅ | ✅ | ✅ |
| Background removal | ✅ | ✅ | ✅ | ✅ |
| Oil painting style | ✅ | ✅ | ✅ | ✅ |
| Hero banner | ✅ | ✅ | ✅ | ✅ |
| Cat on moon (refs) | ✅ | ✅ | ✅ | ✅ |
| Nano Banana logo | ✅ | ✅ | ✅ | ✅ |
| Add rainbow | ✅ | ✅ | ✅ | ✅ |
| Logo variations | ✅ | ✅ | ✅ | ✅ |
| Before/after house | ✅ | ✅ | ✅ | ✅ |
| **Resize 800x600** | ❌ FIRES | ✅ blocked | ✅ blocked | ✅ blocked |
| **Avatar resize** | ❌ FIRES | ✅ blocked | ✅ blocked | ✅ blocked |
| **PNG to JPEG** | ❌ FIRES | ✅ blocked | ✅ blocked | ✅ blocked |
| **Crop center** | ❌ FIRES | ✅ blocked | ✅ blocked | ✅ blocked |
| **Batch resize** | ❌ FIRES | ✅ blocked | ✅ blocked | ✅ blocked |
| **Rotate/flip** | ❌ FIRES | ✅ blocked | ✅ blocked | ✅ blocked |
| **Letterbox aspect** | ❌ FIRES | ✅ blocked | ✅ blocked | ✅ blocked |
| **Thumbnail** | ❌ FIRES | ✅ blocked | ✅ likely blocked | ✅ blocked |
| **Optimize/webp** | ⚠️ maybe | ✅ blocked | ✅ blocked | ✅ blocked |
| **Strip EXIF** | ✅ no fire | ✅ blocked | ✅ blocked | ✅ blocked |

**Expected scores:**
- Current: ~13/20 (65%) — all should-trigger correct but most should-not-trigger fail
- Candidate A: 20/20 (100%) — explicit exclusion list catches all mechanical ops
- Candidate B: 19-20/20 (95-100%) — principle-based, small risk on ambiguous edge cases
- Candidate C: 20/20 (100%) — combines principle + exclusion for maximum coverage

## Recommendation

**Candidate C** is the recommended description. It:
1. Preserves all valid trigger cases (no regressions on should-trigger queries)
2. Eliminates false triggers via both a general principle AND explicit exclusion terms
3. Stays well under the 1024-character limit (639 chars)
4. Leads with positive capability (what the skill IS) before exclusions
5. Uses the specific AI-edit verbs that distinguish creative editing from mechanical transformation
