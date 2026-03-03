---
name: Gemini Image
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

Generate and edit images via Google's Gemini API. Also known as Nano Banana. One endpoint, two patterns: text-to-image and image editing.

## Authentication

```
x-goog-api-key: $GOOGLE_API_KEY
```

## Endpoint

```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent
```

Single endpoint for both generation and editing. Generation takes ~30 seconds — set timeouts accordingly.

## Text-to-Image

```bash
curl -s -X POST \
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent' \
  -H "x-goog-api-key: $GOOGLE_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": [{"parts": [{"text": "A photorealistic sunset over mountains"}]}],
    "generationConfig": {
      "responseModalities": ["Image"],
      "imageConfig": {"aspectRatio": "16:9"}
    }
  }'
```

## Image Editing

Send a prompt + one or more base64-encoded images. The model applies the text instruction to the image(s).

```bash
# Encode an image to base64
IMAGE_B64=$(base64 -w0 input.png)

curl -s -X POST \
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent' \
  -H "x-goog-api-key: $GOOGLE_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": [{"parts": [
      {"text": "Remove the background and replace with a beach scene"},
      {"inlineData": {"mimeType": "image/png", "data": "'"$IMAGE_B64"'"}}
    ]}],
    "generationConfig": {
      "responseModalities": ["Image"],
      "imageConfig": {"aspectRatio": "16:9"}
    }
  }'
```

Supports up to **14 reference images** in a single request — add multiple `inlineData` parts.

## Generation Config

| Parameter | Values | Default |
|-----------|--------|---------|
| `responseModalities` | `["Image"]` | Required for image output |
| `imageConfig.aspectRatio` | `"1:1"`, `"16:9"`, `"9:16"` | — |
| `imageConfig.imageSize` | `"1K"`, `"2K"`, `"4K"` | — |

## Response Format

```json
{
  "candidates": [{
    "content": {
      "parts": [{
        "inlineData": {
          "data": "<base64-encoded-image>",
          "mimeType": "image/png"
        }
      }]
    }
  }]
}
```

Extract the image:

```bash
# With jq — extract base64 from response
IMAGE_B64=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].inlineData.data')
```

## Working with Output

The API returns images as base64. Three ways to use it:

### Save to File

Default save location is `~/Photos/` when not specified otherwise.

```bash
echo "$IMAGE_B64" | base64 -d > ~/Photos/generated-image.png
```

### Upload to Cloud Storage

Use the `cloud-storage` skill for a CDN URL. Save to a temp file first, then upload:

```bash
echo "$IMAGE_B64" | base64 -d > /tmp/generated.png
curl -s -X POST https://storage.vibecodeapp.com/v1/files/upload \
  -F "file=@/tmp/generated.png"
# Returns: {"file": {"url": "https://staticfiles.net/..."}}
```

### Use Base64 Directly

Pass to another API, embed as a data URI, or feed back into this API for iterative editing:

```
data:image/png;base64,<base64-data>
```

## Preparing Input Images

### From a local file

```bash
base64 -w0 image.png
```

### From a URL

```bash
curl -s "https://example.com/photo.jpg" | base64 -w0
```

### From a previous generation

The base64 output from one generation can be passed directly as `inlineData.data` in the next request — no decoding needed.

## Important Notes

- **~30 second generation time** — set HTTP timeouts to at least 60 seconds
- **All field names are camelCase** — `inlineData`, `mimeType`, `aspectRatio`, `responseModalities`, `imageConfig`. Never snake_case.
- **Up to 14 reference images** per request
- **Image output is always base64** in the response — decode or upload as needed
