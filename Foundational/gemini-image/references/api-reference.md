# Gemini Image Generation — API Reference

Raw API details for the Gemini image generation endpoint. In most cases, use the wrapper script `scripts/gemini-image.sh` instead of calling these directly.

## Endpoint

```
POST https://generativelanguage.googleapis.com.cloudproxy.vibecodeapp.com/v1beta/models/gemini-3-pro-image-preview:generateContent
```

## Authentication

```
Header: x-goog-api-key: $GOOGLE_API_KEY
```

## Request Body

### Text-to-Image

```json
{
  "contents": [{"parts": [{"text": "Your prompt here"}]}],
  "generationConfig": {
    "responseModalities": ["Image"],
    "imageConfig": {
      "aspectRatio": "16:9",
      "imageSize": "1K"
    }
  }
}
```

### Image Editing (Text + Image(s))

```json
{
  "contents": [{"parts": [
    {"text": "Remove the background and replace with a beach scene"},
    {"inlineData": {"mimeType": "image/png", "data": "<base64-encoded-image>"}}
  ]}],
  "generationConfig": {
    "responseModalities": ["Image"],
    "imageConfig": {"aspectRatio": "16:9"}
  }
}
```

Multiple images: add additional `inlineData` parts (up to 14 per request).

## Generation Config

| Parameter | Values | Notes |
|-----------|--------|-------|
| `responseModalities` | `["Image"]` | Required for image output |
| `imageConfig.aspectRatio` | `"1:1"`, `"16:9"`, `"9:16"` | Optional |
| `imageConfig.imageSize` | `"1K"`, `"2K"`, `"4K"` | Optional |

All field names are **camelCase** — `inlineData`, `mimeType`, `aspectRatio`, `responseModalities`, `imageConfig`. Never snake_case.

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

The response may also contain text parts (e.g., if the model refuses the request or provides a text explanation alongside the image).

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
- **Up to 14 reference images** per request
- **Image output is always base64** in the response — decode or upload as needed
- Model may return text instead of an image if it refuses a prompt or can't generate
