---
name: gemini-image
description: >
  Foundational skill for Google's Gemini image generation API, also known as Nano Banana. Use
  when: (1) generating images from text prompts, (2) editing or transforming existing images
  with text instructions, (3) generating images with specific aspect ratios or sizes, (4) any
  task involving the Gemini image generation model (gemini-3-pro-image-preview) or Nano Banana,
  (5) combining multiple reference images with a prompt. This is the base Gemini image skill —
  specialized skills may reference it for specific image workflows.
metadata: {"openclaw": {"emoji": "🎨", "requires": {"env": ["GOOGLE_API_KEY"]}, "primaryEnv": "GOOGLE_API_KEY"}}
---

# Gemini Image Generation (Nano Banana)

Generate and edit images via Google's Gemini API using the `scripts/gemini-image.sh` wrapper. Also known as Nano Banana. Two commands: text-to-image and image editing.

## Authentication

Set `GOOGLE_API_KEY` in your environment. The script handles auth headers automatically.

## Quick Reference

### Text-to-Image

```bash
bash scripts/gemini-image.sh generate "A photorealistic sunset over mountains" --aspect 16:9 --output sunset.png
```

### Image Editing

```bash
bash scripts/gemini-image.sh edit "Remove the background and replace with a beach scene" \
  --image photo.png --output edited.png
```

### Multi-Image Editing

Supports up to **14 reference images** in a single request:

```bash
bash scripts/gemini-image.sh edit "Combine these into a collage" \
  --image a.png --image b.png --image c.png --output collage.png
```

## Script Commands

| Command | Description |
|---------|-------------|
| `generate "prompt"` | Text-to-image generation |
| `edit "instruction" --image PATH` | Edit image(s) with text instruction |

## Options

| Option | Values | Description |
|--------|--------|-------------|
| `--aspect RATIO` | `1:1`, `16:9`, `9:16` | Aspect ratio |
| `--size SIZE` | `1K`, `2K`, `4K` | Image resolution |
| `--output PATH` | file path | Save decoded image to file (default: prints base64 to stdout) |
| `--image PATH` | file path | Input image for editing (repeatable, up to 14) |
| `--json` | — | Output full JSON response instead of extracted image |

## Working with Output

By default, the script prints raw base64 to stdout (useful for piping). Use `--output` to save directly to a file.

Default save location when not specified: `~/Photos/`

### Upload to Cloud Storage

Save to file first, then use the `cloud-storage` skill for a CDN URL:

```bash
bash scripts/gemini-image.sh generate "A cat in a top hat" --output /tmp/cat.png
# Then upload with cloud-storage skill
```

### Iterative Editing

Save a generated image, then edit it:

```bash
bash scripts/gemini-image.sh generate "A simple logo" --output /tmp/logo.png
bash scripts/gemini-image.sh edit "Make it blue and add a gradient" --image /tmp/logo.png --output /tmp/logo-v2.png
```

## Important Notes

- **~30 second generation time** — the script sets a 120-second timeout
- **All field names are camelCase** internally — the script handles this
- **Up to 14 reference images** per edit request
- **API returns JPEG data** regardless of the file extension you specify in `--output`. Files saved as `.png` will actually contain JPEG data. Images display correctly but `file` will report JPEG
- **Model may return text** instead of an image if it refuses a prompt — the script reports this as an error

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `Set GOOGLE_API_KEY` | Missing env var | Export GOOGLE_API_KEY |
| `API request failed` | Bad key, network, or quota | Check key validity and quota |
| `Model returned text instead of image` | Prompt was refused or too ambiguous | Rephrase the prompt |
| `Image not found` | --image path doesn't exist | Check the file path |

## References

- [references/api-reference.md](references/api-reference.md) — Raw API endpoint details, request/response schemas, manual curl usage
