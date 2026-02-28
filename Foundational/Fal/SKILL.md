---
name: fal-visual
description: >
  FAL Visual skill for generating images and videos using fal.ai's API. Covers all major image generation models (FLUX.1 Schnell, FLUX.1 Dev, FLUX.2 Pro, FLUX Kontext, Recraft V4, Nano Banana Pro, Seedream, Ideogram) and video generation models (Veo 3, Kling 2.1/3, Sora 2, MiniMax Hailuo, LTX Video, PixVerse, Wan). Supports text-to-image, image-to-image editing, text-to-video, image-to-video, and utility operations like upscaling. Use this skill whenever you need to generate, edit, or transform images or videos using AI models.
metadata:
  {
    "openclaw":
      {
        "emoji": "🎨",
        "requires": { "env": ["FAL_KEY"] },
        "primaryEnv": "FAL_KEY",
      },
  }
---

# FAL Visual Skill

Generate images and videos using fal.ai — the fastest inference platform with 600+ AI models. This skill covers all major image and video generation models through a unified API.

---

## Authentication

- **API Key Header:** `Authorization: Key $FAL_KEY`
- The API key is stored in the environment variable `FAL_KEY`
- **Every request** must include the Authorization header

---

## API Patterns

fal.ai exposes two execution modes. **Use synchronous for fast models (images), queue for slow models (videos).**

### Synchronous (fast models — images)

```bash
curl -X POST "https://fal.run/{model_id}" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "your prompt"}'
```

Response comes directly with the result. Best for image generation (<30s).

### Queue (slow models — videos)

```bash
# 1. Submit to queue
curl -X POST "https://queue.fal.run/{model_id}" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "your prompt"}'

# Response: {"request_id": "uuid", "response_url": "...", "status_url": "...", "cancel_url": "..."}

# 2. Poll status
curl "https://queue.fal.run/{model_id}/requests/{request_id}/status" \
  -H "Authorization: Key $FAL_KEY"

# Status values: IN_QUEUE, IN_PROGRESS, COMPLETED

# 3. Get result when COMPLETED
curl "https://queue.fal.run/{model_id}/requests/{request_id}" \
  -H "Authorization: Key $FAL_KEY"

# 4. Cancel (optional)
curl -X PUT "https://queue.fal.run/{model_id}/requests/{request_id}/cancel" \
  -H "Authorization: Key $FAL_KEY"
```

### Queue Polling Script

```bash
MODEL="fal-ai/veo3"
REQUEST_ID=$(curl -s -X POST "https://queue.fal.run/$MODEL" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "..."}' | jq -r '.request_id')

while true; do
  STATUS=$(curl -s "https://queue.fal.run/$MODEL/requests/$REQUEST_ID/status" \
    -H "Authorization: Key $FAL_KEY" | jq -r '.status')
  echo "Status: $STATUS"
  [ "$STATUS" = "COMPLETED" ] && break
  [ "$STATUS" = "FAILED" ] && { echo "FAILED"; break; }
  sleep 3
done

# Get result
curl -s "https://queue.fal.run/$MODEL/requests/$REQUEST_ID" \
  -H "Authorization: Key $FAL_KEY" | jq .
```

### Optional Headers

| Header | Description |
|--------|-------------|
| `X-Fal-Object-Lifecycle-Preference` | JSON: `{"expiration_duration_seconds": 3600}` — control how long output URLs stay valid |
| `X-Fal-Request-Timeout` | Seconds to wait before failing if processing hasn't started |
| `X-Fal-No-Retry` | Set to `1` to disable automatic retries |

---

## Standard Response Formats

### Image Response

```json
{
  "images": [
    {"url": "https://v3.fal.media/files/...", "width": 1024, "height": 1024, "content_type": "image/jpeg"}
  ],
  "timings": {"inference": 1.2},
  "seed": 12345,
  "has_nsfw_concepts": [false],
  "prompt": "the prompt used"
}
```

### Video Response

```json
{
  "video": {"url": "https://v3.fal.media/files/...", "content_type": "video/mp4"}
}
```

### Common Image Sizes

Preset strings (used by FLUX, Recraft, etc.):
- `square_hd` (1024×1024)
- `square` (512×512)
- `portrait_4_3` (768×1024)
- `portrait_16_9` (576×1024)
- `landscape_4_3` (1024×768)
- `landscape_16_9` (1024×576)

Or use custom dimensions: `{"width": 1920, "height": 1080}`

---

## IMAGE GENERATION MODELS

---

### 1. FLUX.1 [schnell] — Fastest Image Gen

**Model ID:** `fal-ai/flux/schnell`

Ultra-fast 1-4 step generation. Best for rapid prototyping and high-volume use.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Text prompt |
| image_size | string/object | No | landscape_4_3 | Preset name or {width, height} |
| num_images | int (1-4) | No | 1 | Number of images |
| num_inference_steps | int (1-12) | No | 4 | Steps (1-4 recommended) |
| guidance_scale | float (1-20) | No | 3.5 | CFG scale |
| seed | int | No | random | Reproducibility seed |
| output_format | jpeg/png | No | jpeg | Output format |
| acceleration | none/regular/high | No | none | Speed mode |
| enable_safety_checker | bool | No | true | NSFW filter |

```bash
curl -X POST "https://fal.run/fal-ai/flux/schnell" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A cyberpunk city at sunset, neon lights reflecting on wet streets",
    "image_size": "landscape_16_9",
    "num_inference_steps": 4,
    "num_images": 1
  }'
```

---

### 2. FLUX.1 [dev] — High-Quality Open Model

**Model ID:** `fal-ai/flux/dev`

12B parameter model. Better quality than Schnell, still fast. Good balance of speed and quality.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Text prompt |
| image_size | string/object | No | landscape_4_3 | Preset or custom size |
| num_images | int (1-4) | No | 1 | Number of images |
| num_inference_steps | int (1-50) | No | 28 | More steps = better quality |
| guidance_scale | float (1-20) | No | 3.5 | CFG scale |
| seed | int | No | random | Seed |
| output_format | jpeg/png | No | jpeg | Format |
| enable_safety_checker | bool | No | true | NSFW filter |

```bash
curl -X POST "https://fal.run/fal-ai/flux/dev" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Professional headshot of a confident business woman, studio lighting, shallow depth of field",
    "image_size": "portrait_4_3",
    "num_inference_steps": 28
  }'
```

---

### 3. FLUX.2 [pro] — Studio-Grade Images

**Model ID:** `fal-ai/flux-2-pro`

32B parameter model by Black Forest Labs. Top-tier quality, zero configuration needed.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Text prompt |
| image_size | string/object | No | landscape_4_3 | Size preset or custom |
| output_format | jpeg/png | No | jpeg | Format |
| safety_tolerance | "1"-"5" | No | "2" | 1=strict, 5=permissive |
| enable_safety_checker | bool | No | true | NSFW filter |
| seed | int | No | random | Seed |

```bash
curl -X POST "https://fal.run/fal-ai/flux-2-pro" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Extreme close-up of a knight visor reflecting a battle scene, chiaroscuro lighting, hyper-detailed armor",
    "image_size": "square_hd",
    "safety_tolerance": "3"
  }'
```

---

### 4. FLUX.2 [flex] — Multi-Reference Editing

**Model ID:** `fal-ai/flux-2-flex`

Edit and transform images using one or more reference images. Style transfer, object placement, scene manipulation.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Edit instruction |
| image_url | string | No | — | Reference image URL |
| image_size | string/object | No | landscape_4_3 | Output size |
| output_format | jpeg/png | No | jpeg | Format |
| seed | int | No | random | Seed |

```bash
curl -X POST "https://fal.run/fal-ai/flux-2-flex" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Transform the scene into a watercolor painting style",
    "image_url": "https://example.com/photo.jpg",
    "image_size": "landscape_16_9"
  }'
```

---

### 5. FLUX Kontext [pro] — Context-Aware Editing

**Model ID:** `fal-ai/flux-pro/kontext`

Handles both text and reference images. Targeted local edits, complex scene transformations, consistent characters.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Edit/generation prompt |
| image_url | string | No | — | Input image for editing |
| num_images | int (1-4) | No | 1 | Number of outputs |
| aspect_ratio | string | No | — | 21:9, 16:9, 4:3, 3:2, 1:1, 2:3, 3:4, 9:16, 9:21 |
| guidance_scale | float (1-20) | No | 3.5 | CFG scale |
| output_format | jpeg/png | No | jpeg | Format |
| safety_tolerance | "1"-"6" | No | "2" | Content filter level |
| enhance_prompt | bool | No | false | Auto-enhance prompt |
| seed | int | No | random | Seed |

```bash
# Text-to-image (no image_url)
curl -X POST "https://fal.run/fal-ai/flux-pro/kontext" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A red fox sitting in a snowy forest, photorealistic",
    "aspect_ratio": "16:9"
  }'

# Image editing (with image_url)
curl -X POST "https://fal.run/fal-ai/flux-pro/kontext" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Change the background to a tropical beach at sunset",
    "image_url": "https://example.com/photo.jpg"
  }'
```

---

### 6. Recraft V4 — Professional Design

**Model ID:** `fal-ai/recraft/v4/text-to-image`

Designed for professional design and marketing. Excellent text rendering, brand consistency, long text support.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Text prompt (max 10,000 chars) |
| image_size | string/object | No | square_hd | Size preset or custom |
| colors | array | No | [] | Array of RGB color objects `{"r":255,"g":0,"b":0}` |
| background_color | object | No | — | RGB background color |
| enable_safety_checker | bool | No | true | Safety filter |

**Also available:** `fal-ai/recraft/v4/pro/text-to-image` (pro tier), `fal-ai/recraft/v4/text-to-vector` and `fal-ai/recraft/v4/pro/text-to-vector` (SVG vector output)

```bash
curl -X POST "https://fal.run/fal-ai/recraft/v4/text-to-image" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A minimalist logo for a coffee shop called BREW, clean typography, flat design on white background",
    "image_size": "square_hd",
    "colors": [{"r": 139, "g": 90, "b": 43}]
  }'
```

---

### 7. Nano Banana Pro — Gemini-Powered (Fastest)

**Model ID:** `fal-ai/nano-banana-pro`

Google Gemini image model via fal. Fastest generation (~3-5 seconds), up to 4K resolution, supports web search grounding.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Text prompt (3-50,000 chars) |
| resolution | "1K"/"2K"/"4K" | No | "1K" | Output resolution |
| aspect_ratio | string | No | "1:1" | auto, 21:9, 16:9, 3:2, 4:3, 5:4, 1:1, 4:5, 3:4, 2:3, 9:16 |
| num_images | int (1-4) | No | 1 | Number of images |
| output_format | jpeg/png/webp | No | png | Format |
| enable_web_search | bool | No | false | Use live web data |
| safety_tolerance | "1"-"6" | No | "4" | Content filter |
| limit_generations | bool | No | false | Force single image per prompt |
| seed | int | No | random | Seed |

**Also available:** `fal-ai/nano-banana-2` (newer v2), `fal-ai/nano-banana-pro/edit` and `fal-ai/nano-banana-2/edit` (image editing)

```bash
curl -X POST "https://fal.run/fal-ai/nano-banana-pro" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A photorealistic macro shot of morning dew on a spider web, golden hour lighting",
    "resolution": "2K",
    "aspect_ratio": "16:9",
    "output_format": "png"
  }'
```

---

### 8. Seedream V5 Lite — ByteDance

**Model ID:** `fal-ai/bytedance/seedream/v5/lite/text-to-image`

ByteDance's latest image model. High quality, fast inference.

**Also available:** `fal-ai/bytedance/seedream/v5/lite/edit` (editing), `fal-ai/bytedance/seedream/v4/edit` (v4 editing)

```bash
curl -X POST "https://fal.run/fal-ai/bytedance/seedream/v5/lite/text-to-image" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A serene Japanese garden with cherry blossoms and a wooden bridge over a koi pond"
  }'
```

---

### 9. Fast SDXL — Budget-Friendly Classic

**Model ID:** `fal-ai/fast-sdxl`

Stable Diffusion XL. Fast, cheap, battle-tested. Great for high-volume, lower-cost needs.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Text prompt |
| negative_prompt | string | No | — | What to avoid |
| image_size | string/object | No | square_hd | Size |
| num_images | int (1-8) | No | 1 | Number of images |
| num_inference_steps | int | No | 25 | Quality steps |
| guidance_scale | float | No | 7.5 | CFG scale |
| seed | int | No | random | Seed |
| enable_safety_checker | bool | No | true | Safety |

```bash
curl -X POST "https://fal.run/fal-ai/fast-sdxl" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A majestic dragon perched on a mountain peak, fantasy art style, dramatic lighting",
    "negative_prompt": "blurry, low quality, deformed",
    "image_size": "landscape_16_9",
    "num_inference_steps": 30,
    "guidance_scale": 7.5
  }'
```

---

### 10. FLUX LoRA — Custom Fine-Tuned Models

**Model ID:** `fal-ai/flux-lora`

Run FLUX with custom LoRA adapters for personalized styles, characters, or products.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Text prompt |
| loras | array | No | — | Array of `{"path": "url/id", "scale": 0.0-2.0}` |
| image_size | string/object | No | landscape_4_3 | Size |
| num_images | int (1-4) | No | 1 | Count |
| num_inference_steps | int | No | 28 | Steps |
| guidance_scale | float | No | 3.5 | CFG |
| seed | int | No | random | Seed |

**Also available:** `fal-ai/flux-2/lora` (FLUX.2 + LoRA), `fal-ai/flux-kontext-lora` (Kontext + LoRA)

```bash
curl -X POST "https://fal.run/fal-ai/flux-lora" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A photo of TOK person standing in a garden",
    "loras": [{"path": "https://huggingface.co/user/my-lora/resolve/main/lora.safetensors", "scale": 1.0}],
    "image_size": "portrait_4_3"
  }'
```

---

## IMAGE UTILITY MODELS

---

### 11. Topaz Upscale — Image Super-Resolution

**Model ID:** `fal-ai/topaz/upscale/image`

AI upscaling powered by Topaz. Enhance resolution of any image.

```bash
curl -X POST "https://fal.run/fal-ai/topaz/upscale/image" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"image_url": "https://example.com/low-res.jpg"}'
```

---

### 12. BRIA Background Remove

**Model ID:** `fal-ai/bria/background/remove`

Remove backgrounds from images cleanly.

```bash
curl -X POST "https://fal.run/fal-ai/bria/background/remove" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"image_url": "https://example.com/photo.jpg"}'
```

---

### 13. Lava SR — Super Resolution

**Model ID:** `fal-ai/lava-sr`

Open-source super resolution model.

```bash
curl -X POST "https://fal.run/fal-ai/lava-sr" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"image_url": "https://example.com/image.jpg"}'
```

---

## VIDEO GENERATION MODELS

**Important:** All video models should use the **queue API** (`queue.fal.run`) since generation takes 30s-5min+.

---

### 14. Veo 3 — Google's Best (Text-to-Video with Audio)

**Model ID:** `fal-ai/veo3`

Google's latest video model. Generates video WITH native audio from text prompts.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Video description (max 20,000 chars) |
| duration | "4s"/"6s"/"8s" | No | "8s" | Video length |
| aspect_ratio | "16:9"/"9:16" | No | "16:9" | Aspect ratio |
| resolution | "720p"/"1080p" | No | "720p" | Resolution |
| generate_audio | bool | No | true | Generate audio track |
| auto_fix | bool | No | true | Auto-fix prompt if content policy fails |
| safety_tolerance | "1"-"6" | No | "4" | Content filter |
| negative_prompt | string | No | — | What to avoid |
| seed | int | No | random | Seed |

```bash
curl -X POST "https://queue.fal.run/fal-ai/veo3" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A time-lapse of a flower blooming in a garden with soft ambient sounds of birds and wind",
    "duration": "8s",
    "resolution": "1080p",
    "generate_audio": true
  }'
```

---

### 15. Sora 2 — OpenAI Video

**Model ID (text-to-video):** `fal-ai/sora-2/text-to-video`
**Model ID (image-to-video):** `fal-ai/sora-2/image-to-video`
**Model ID (video remix):** `fal-ai/sora-2/video-to-video/remix`

OpenAI's video generation model.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Video description |
| aspect_ratio | string | No | — | Aspect ratio |
| resolution | string | No | — | Resolution |
| duration | int | No | — | Seconds (I2V) |
| model | string | No | — | Model variant |
| image_url | string | I2V only | — | First frame image |

**Pro variants:** `fal-ai/sora-2/text-to-video/pro`, `fal-ai/sora-2/image-to-video/pro`

```bash
# Text to video
curl -X POST "https://queue.fal.run/fal-ai/sora-2/text-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A drone shot flying over a coastal cliff at golden hour, cinematic"
  }'

# Image to video
curl -X POST "https://queue.fal.run/fal-ai/sora-2/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "The subject slowly turns and smiles at the camera",
    "image_url": "https://example.com/portrait.jpg"
  }'
```

---

### 16. Kling Video — Professional Cinematics

**Model ID (v2 text-to-video):** `fal-ai/kling-video/v2`
**Model ID (v3 pro image-to-video):** `fal-ai/kling-video/v3/pro/image-to-video`
**Model ID (o3 image-to-video):** `fal-ai/kling-video/o3/standard/image-to-video`

Professional-grade video with enhanced visual fidelity, camera control, multi-shot support.

| Param (v3 pro I2V) | Type | Required | Default | Description |
|---------------------|------|----------|---------|-------------|
| prompt | string | Yes* | — | Text prompt (*or multi_prompt) |
| start_image_url | string | No | — | First frame image |
| end_image_url | string | No | — | Last frame image |
| duration | string | No | — | Video duration |
| aspect_ratio | string | No | — | Aspect ratio |
| negative_prompt | string | No | — | What to avoid |
| cfg_scale | float | No | — | CFG guidance |
| generate_audio | bool | No | — | Generate audio (Chinese/English) |
| voice_ids | array | No | — | Voice IDs for audio |
| elements | array | No | — | Character/object reference images |
| multi_prompt | array | No | — | Multi-shot prompts |
| shot_type | string | No | — | Multi-shot type |

```bash
# Text to video (v2)
curl -X POST "https://queue.fal.run/fal-ai/kling-video/v2" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A samurai walking through a bamboo forest, cinematic slow motion"
  }'

# Image to video (v3 pro)
curl -X POST "https://queue.fal.run/fal-ai/kling-video/v3/pro/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "The character slowly looks up at the sky as wind blows through their hair",
    "start_image_url": "https://example.com/character.jpg",
    "duration": "5s"
  }'
```

---

### 17. MiniMax Hailuo — Image-to-Video

**Model ID:** `fal-ai/minimax/hailuo-02/standard/image-to-video`

Generate video from images. Strong motion and coherence.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | No | — | Motion/action description |
| image_url | string | Yes | — | Source image URL |
| end_image_url | string | No | — | End frame image |
| duration | string | No | — | Video length |
| resolution | string | No | — | Output resolution |
| prompt_optimizer | bool | No | — | Auto-optimize prompt |

```bash
curl -X POST "https://queue.fal.run/fal-ai/minimax/hailuo-02/standard/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "The person waves hello and smiles warmly",
    "image_url": "https://example.com/portrait.jpg"
  }'
```

---

### 18. LTX Video 2 19B — Open-Source Video (with Camera LoRAs)

**Model ID (I2V):** `fal-ai/ltx-2-19b/image-to-video`

Open-source video model with camera movement LoRAs and audio generation.

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | Yes | — | Video description |
| image_url | string | No | — | First frame image |
| end_image_url | string | No | — | Last frame image |
| num_frames | int | No | — | Frame count |
| fps | float | No | — | Frames per second |
| guidance_scale | float | No | — | CFG scale |
| num_inference_steps | int | No | — | Quality steps |
| camera_lora | string | No | — | Camera movement LoRA |
| camera_lora_scale | float | No | — | Camera LoRA strength |
| generate_audio | bool | No | — | Generate audio track |
| video_size | object | No | — | {width, height} |
| image_strength | float | No | — | Input image influence |
| negative_prompt | string | No | — | What to avoid |
| seed | int | No | random | Seed |

```bash
curl -X POST "https://queue.fal.run/fal-ai/ltx-2-19b/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Camera slowly dollies forward through a mystical forest",
    "image_url": "https://example.com/forest.jpg",
    "num_frames": 97,
    "fps": 24,
    "camera_lora": "dolly-forward",
    "generate_audio": true
  }'
```

---

### 19. PixVerse V5 — Image-to-Video

**Model ID:** `fal-ai/pixverse/v5/image-to-video`

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| prompt | string | No | — | Motion description |
| image_url | string | Yes | — | Source image |
| duration | string | No | — | "5s" or "8s" |
| resolution | string | No | — | Output resolution |
| style | string | No | — | Visual style |
| negative_prompt | string | No | — | What to avoid |
| seed | int | No | random | Seed |

```bash
curl -X POST "https://queue.fal.run/fal-ai/pixverse/v5/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "The flowers sway gently in the breeze",
    "image_url": "https://example.com/garden.jpg",
    "duration": "5s"
  }'
```

---

### 20. Wan V2 — Alibaba Video

**Model ID:** `fal-ai/wan/v2`

Alibaba's Wan video model. Multi-modal video generation with text-to-video, reference-to-video, and image-to-video.

```bash
curl -X POST "https://queue.fal.run/fal-ai/wan/v2" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "An astronaut floating through a colorful nebula, cosmic dust particles"
  }'
```

**Also available:** `fal-ai/wan-motion` (motion-focused), `fal-ai/wan-t2v-lora` (with LoRA)

---

### 21. Cosmos Predict 2 — NVIDIA World Model

**Model ID:** `fal-ai/cosmos-predict-2`

NVIDIA's world simulation model for physics-aware video generation.

```bash
curl -X POST "https://queue.fal.run/fal-ai/cosmos-predict-2" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A ball rolling down a hill and bouncing off rocks, realistic physics"
  }'
```

---

## VIDEO UTILITY MODELS

---

### 22. Topaz Video Upscale

**Model ID:** `fal-ai/topaz/upscale/video`

AI video upscaling powered by Topaz.

```bash
curl -X POST "https://queue.fal.run/fal-ai/topaz/upscale/video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://example.com/video.mp4"}'
```

---

### 23. Video Utilities — Reverse, Scale, Trim

**Reverse:** `fal-ai/workflow-utilities/reverse-video`
**Scale:** `fal-ai/workflow-utilities/scale-video`
**Trim:** `fal-ai/workflow-utilities/trim-video`

```bash
# Reverse a video
curl -X POST "https://fal.run/fal-ai/workflow-utilities/reverse-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://example.com/video.mp4"}'

# Scale a video
curl -X POST "https://fal.run/fal-ai/workflow-utilities/scale-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://example.com/video.mp4", "width": 1920, "height": 1080}'

# Trim a video
curl -X POST "https://fal.run/fal-ai/workflow-utilities/trim-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://example.com/video.mp4", "start": 0, "end": 5}'
```

---

### 24. Lip Sync

**Sync:** `fal-ai/sync-lipsync/v2`
**PixVerse:** `fal-ai/pixverse/lipsync`

Sync lip movements to audio in videos.

```bash
curl -X POST "https://queue.fal.run/fal-ai/sync-lipsync/v2" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/talking-head.mp4",
    "audio_url": "https://example.com/speech.mp3"
  }'
```

---

## ADDITIONAL MODELS REFERENCE

### Image Generation (additional)
| Model ID | Description |
|----------|-------------|
| `fal-ai/qwen-image` | Qwen image generation |
| `fal-ai/gemini-3` | Google Gemini 3 image |
| `fal-ai/reve/edit` | Reve image editing |
| `fal-ai/firered-image-edit` | FireRed image editing |
| `fal-ai/lucy-edit/dev` | Lucy image editing (dev) |
| `fal-ai/lucy-edit/fast` | Lucy image editing (fast) |
| `fal-ai/genfocus` | GenFocus image generation |
| `fal-ai/genfocus/all-in-focus` | All-in-focus mode |
| `fal-ai/personaplex` | Character consistency |

### Video Generation (additional)
| Model ID | Description |
|----------|-------------|
| `fal-ai/kling-video/v1/pro/ai-avatar` | Kling AI avatar video |
| `fal-ai/vidu/q3/image-to-video/turbo` | Vidu turbo I2V |
| `fal-ai/ltx-video-13b-distilled/image-to-video` | LTX 13B distilled |
| `fal-ai/lucy-5b/image-to-video` | Lucy 5B I2V |
| `fal-ai/creatify/aurora` | Creatify Aurora video |
| `fal-ai/multishot-master` | Multi-shot video |

### Avatar & Digital Twin
| Model ID | Description |
|----------|-------------|
| `fal-ai/heygen/avatar4/digital-twin` | HeyGen digital twin |
| `fal-ai/heygen/avatar4/image-to-video` | HeyGen avatar video |
| `fal-ai/heygen/v2/translate/precision` | HeyGen translation (precision) |
| `fal-ai/heygen/v2/translate/speed` | HeyGen translation (speed) |
| `fal-ai/ai-avatar/single-text` | AI avatar from text |
| `fal-ai/bytedance/omnihuman/v1` | OmniHuman avatar |

### 3D Generation
| Model ID | Description |
|----------|-------------|
| `fal-ai/meshy/v6/image-to-3d` | Image to 3D model |
| `fal-ai/meshy/v6/text-to-3d` | Text to 3D model |

### Training / Fine-Tuning
| Model ID | Description |
|----------|-------------|
| `fal-ai/flux-2-trainer-v2` | FLUX.2 LoRA trainer |
| `fal-ai/flux-lora-fast-training` | Fast FLUX LoRA training |
| `fal-ai/flux-lora-portrait-trainer` | Portrait LoRA trainer |
| `fal-ai/flux-kontext-trainer` | Kontext LoRA trainer |
| `fal-ai/flux-2-klein-4b-base-trainer` | FLUX.2 Klein 4B trainer |
| `fal-ai/flux-2-klein-9b-base-trainer` | FLUX.2 Klein 9B trainer |
| `fal-ai/wan-22-image-trainer` | Wan image LoRA trainer |
| `fal-ai/ltx-video-trainer` | LTX video LoRA trainer |
| `fal-ai/qwen-image-trainer-v2` | Qwen image LoRA trainer |
| `fal-ai/z-image-trainer` | Z-Image trainer |

---

## Model Selection Guide

### By Use Case

| Use Case | Recommended Model | Why |
|----------|-------------------|-----|
| **Fastest image** | `fal-ai/flux/schnell` | 1-4 steps, ~1s inference |
| **Best quality image** | `fal-ai/flux-2-pro` | 32B params, studio-grade |
| **Design/marketing** | `fal-ai/recraft/v4/text-to-image` | Best text rendering, brand-ready |
| **Image editing** | `fal-ai/flux-pro/kontext` | Context-aware local edits |
| **Cheapest image** | `fal-ai/fast-sdxl` | SDXL, battle-tested, low cost |
| **4K resolution** | `fal-ai/nano-banana-pro` | Up to 4K, Gemini-powered |
| **Custom style (LoRA)** | `fal-ai/flux-lora` | Bring your own LoRA |
| **Best video (with audio)** | `fal-ai/veo3` | Google Veo 3, native audio |
| **Cinematic video** | `fal-ai/kling-video/v3/pro/image-to-video` | Pro-grade, camera control |
| **OpenAI video** | `fal-ai/sora-2/text-to-video` | Sora 2 via fal |
| **Image→Video** | `fal-ai/minimax/hailuo-02/standard/image-to-video` | Strong motion coherence |
| **Open-source video** | `fal-ai/ltx-2-19b/image-to-video` | Camera LoRAs, audio |
| **Background removal** | `fal-ai/bria/background/remove` | Clean cutouts |
| **Upscale image** | `fal-ai/topaz/upscale/image` | Topaz AI upscaling |
| **Vector/SVG** | `fal-ai/recraft/v4/text-to-vector` | Native vector output |

### By Speed (Image)

1. 🏎️ `fal-ai/flux/schnell` (~1s)
2. 🏎️ `fal-ai/nano-banana-pro` (~3-5s)
3. 🚗 `fal-ai/fast-sdxl` (~2-4s)
4. 🚗 `fal-ai/flux/dev` (~5-10s)
5. 🚂 `fal-ai/flux-2-pro` (~10-15s)
6. 🚂 `fal-ai/recraft/v4/text-to-image` (~5-15s)

---

## OpenAPI Schema Discovery

Every fal model exposes its full OpenAPI schema. Use this to discover exact params for any model:

```bash
# Get full schema for any model
curl -s "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id={model_id}" | jq '.components.schemas'

# Example: get input params for Veo 3
curl -s "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=fal-ai/veo3" | jq '.components.schemas | to_entries[] | select(.key | test("Input")) | .value.properties | keys'
```

This is the source of truth for any model's parameters. Use it when a model isn't documented here or when you need exact field constraints.