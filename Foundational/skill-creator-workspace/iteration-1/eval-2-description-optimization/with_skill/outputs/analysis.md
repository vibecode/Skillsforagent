# Description Optimization Analysis: Gemini Image

## The Problem

The Gemini Image skill is false-triggering on image **resize** and **format conversion** requests — tasks that don't require AI image generation at all and can be handled by standard image processing tools (ImageMagick, sharp, PIL, ffmpeg, etc.).

## Current Description

```
Foundational skill for Google's Gemini image generation API, also known as Nano Banana. Use
when: (1) generating images from text prompts, (2) editing or transforming existing images
with text instructions, (3) generating images with specific aspect ratios or sizes, (4) any
task involving the Gemini image generation model (gemini-3-pro-image-preview) or Nano Banana,
(5) combining multiple reference images with a prompt. This is the base Gemini image skill —
specialized skills may reference it for specific image workflows.
```

## Root Cause Analysis

Three phrases in the current description cause false triggers:

### 1. "editing or transforming existing images" (clause 2)
This is the **primary culprit**. "Transforming" is extremely broad — resizing, cropping, rotating, and format conversion are all "transformations." The agent sees "transform this image" and matches it to this skill, even though the user just wants a mechanical resize.

### 2. "generating images with specific aspect ratios or sizes" (clause 3)
The words "aspect ratios" and "sizes" directly overlap with resize vocabulary. A user saying "make this image 800x600" or "change the aspect ratio to 16:9" could easily match here, even though they want a simple crop/resize, not AI generation.

### 3. "any task involving... image" (clause 4)
The broad catch-all "any task involving" + the word "image" casts an extremely wide net. Resizing involves images. Format conversion involves images. Compression involves images. None of these need an AI generation model.

## What Makes This Tricky

The Gemini API *can* do AI-powered image editing (e.g., "remove the background" or "make the sky more dramatic"). So the description can't completely exclude "editing." The key distinction is:

- **Should trigger**: Creative/AI-powered edits that require understanding image content (style transfer, inpainting, object removal, adding elements, changing visual attributes)
- **Should NOT trigger**: Mechanical/deterministic operations (resize, crop, rotate, compress, format convert, thumbnail generation)

## Fix Strategy

1. **Replace "editing or transforming"** with specific AI-edit verbs: "modifying image content," "AI-powered editing," "creative edits"
2. **Reframe clause 3** from "specific aspect ratios or sizes" to "controlling output dimensions for AI-generated images"
3. **Remove the broad catch-all** or scope it narrowly to the model name
4. **Add explicit exclusion language** for mechanical operations — this is the highest-ROI change since the agent can directly pattern-match "resize" → "not this skill"
5. **Lead with the core capability**: text-to-image generation and AI-powered creative editing, making the intent unmistakable
