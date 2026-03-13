# fal Popular Models Quick Reference

Common model endpoint IDs organized by category. Each model has its own input schema — use the Platform API to discover exact parameters: `GET https://api.fal.ai.cloudproxy.vibecodeapp.com/v1/models?endpoint_id={id}&expand=openapi-3.0`

Browse all models: https://fal.ai/models

---

## Image Generation (Text-to-Image)

| Model ID | Description |
|----------|-------------|
| `fal-ai/flux/dev` | FLUX.1 [dev] — 12B param, high quality, 1-4 steps |
| `fal-ai/flux/schnell` | FLUX.1 [schnell] — fast, optimized |
| `fal-ai/flux-pro/v1.1-ultra` | FLUX1.1 [pro] ultra — up to 2K, best photo realism |
| `fal-ai/fast-sdxl` | Fast SDXL — optimized Stable Diffusion XL |
| `fal-ai/fast-turbo-diffusion` | SDXL Turbo — real-time speed |
| `fal-ai/fast-lcm-diffusion` | LCM Diffusion — sub-100ms real-time |

**Common input fields** (vary by model):

```json
{
  "prompt": "a cat wearing sunglasses",
  "negative_prompt": "blurry, low quality",
  "image_size": "landscape_4_3",
  "num_images": 1,
  "seed": 42,
  "num_inference_steps": 28,
  "guidance_scale": 7.5
}
```

Image size presets: `square_hd` (1024x1024), `square` (512x512), `portrait_4_3`, `portrait_16_9`, `landscape_4_3`, `landscape_16_9`, or `{"width": W, "height": H}`

---

## Image-to-Image / Editing

| Model ID | Description |
|----------|-------------|
| `fal-ai/flux/dev/image-to-image` | FLUX image-to-image |
| `fal-ai/imageutils/rembg` | Background removal |
| `fal-ai/face-to-sticker` | Face to sticker |

Input typically includes `image_url` (URL or data URI) plus model-specific params.

---

## Video Generation

| Model ID | Description |
|----------|-------------|
| `fal-ai/wan/v2.2-a14b/text-to-video` | Wan 2.2 text-to-video |
| `fal-ai/minimax/video-01/image-to-video` | Minimax image-to-video |
| `fal-ai/kling-video/v1/standard/text-to-video` | Kling text-to-video |

Video generation is slow (30s–5min). Always use queue mode.

---

## Audio / Speech

| Model ID | Description |
|----------|-------------|
| `fal-ai/whisper` | Speech-to-text (Whisper) |

---

## LLMs

| Model ID | Description |
|----------|-------------|
| `fal-ai/any-llm` | Universal LLM endpoint (routes to multiple providers) |

```json
{
  "model": "google/gemini-flash-1.5",
  "prompt": "What is the meaning of life?"
}
```

---

## Discovering Model Schemas

To get the exact input/output schema for any model:

```bash
# Get OpenAPI schema for a model
curl "https://api.fal.ai.cloudproxy.vibecodeapp.com/v1/models?endpoint_id=fal-ai/flux/dev&expand=openapi-3.0" \
  -H "Authorization: Key $FAL_API_KEY"
```

The response includes the full OpenAPI 3.0 spec with input parameters, types, defaults, and output schema. This is the authoritative source for model-specific fields.

You can also search by category:

```bash
curl "https://api.fal.ai.cloudproxy.vibecodeapp.com/v1/models?query=text-to-video&limit=10" \
  -H "Authorization: Key $FAL_API_KEY"
```