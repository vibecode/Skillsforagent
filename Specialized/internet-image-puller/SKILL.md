---
name: internet-image-puller
description: "Find public internet images and download them into a local directory with a source manifest. Use for query-driven image discovery, official brand-asset pulls, logos, moodboards, research boards, page-specific image extraction, and multi-page site image collection. Routes search discovery through SerpApi Google Images and page or site extraction through Firecrawl."
---

# Internet Image Puller

Pull public images into a local folder without hand-copying URLs. Use the bundled helper at `~/.chorus/skills/internet-image-puller/scripts/image_puller.py` so every run produces reproducible files and a source manifest.

## API readiness

SerpApi and Firecrawl are available through Chorus-managed proxies. Do not ask for keys unless a real authentication check fails. Never print or store credentials.

## Route selection

- Use `serp:search` for query-driven discovery.
- Use `firecrawl:scrape` for images from one supplied page.
- Use `firecrawl:site` for images across several related site pages.

Prefer official domains for logos, screenshots, product imagery, and brand assets. Use `--require-domain` for official-only search pulls.

## Match the requested asset type

Do not treat every image from an official page as relevant. For logo, icon, wordmark, or product-screenshot requests, filter candidate URLs and metadata with repeated `--include-keyword` values. Inspect every counted image when relevance is narrow.

For OpenAI logo assets, useful terms include `wordmark`, `blossom`, and `OpenAI_Sans`; other brands use different vocabulary. If a filter is too narrow, broaden it deliberately rather than substituting unrelated photography.

Use `--exclude-keyword` to remove irrelevant families. For generic brand-page pulls intended as usable creative assets, exclude tiny embedded-video thumbnails, tracking graphics, and negative guideline examples with names such as `DON-T` or `do-not-use`. Keep those only when the user requests exhaustive page extraction or brand-guideline examples.

The default 2 KB floor filters tiny noise; change it with `--min-bytes` only when small icons are intentional.

## Commands

```bash
python3 ~/.chorus/skills/internet-image-puller/scripts/image_puller.py config:show

python3 ~/.chorus/skills/internet-image-puller/scripts/image_puller.py serp:search \
  --query "OpenAI logo" --output-dir /path/to/output --limit 20 --require-domain openai.com \
  --include-keyword wordmark --include-keyword blossom

python3 ~/.chorus/skills/internet-image-puller/scripts/image_puller.py firecrawl:scrape \
  --url "https://openai.com/brand/" --output-dir /path/to/output --limit 20 \
  --exclude-keyword DON-T --exclude-keyword do-not-use

python3 ~/.chorus/skills/internet-image-puller/scripts/image_puller.py firecrawl:site \
  --url "https://openai.com" --map-search "brand codex" --include "/brand" --include "/codex" \
  --output-dir /path/to/output --page-limit 8 --images-per-page 100
```

## Workflow

1. Resolve the visual target, source preference, quantity, asset type, and output location.
2. Start with a representative pull unless the user requests everything.
3. Inspect `manifest.json` and the actual files, not just the exit code.
4. Reject irrelevant, duplicated, unofficial, tiny, prohibited-example, or corrupted results; refine and rerun until the requested count is genuinely useful.
5. For repeat runs, verify canonical URL and SHA-256 content duplicates are skipped and the manifest appends a new run.
6. Report downloaded, failed, and skipped counts plus source gaps.

## Safety and quality

Treat search results as discovery, not proof of reuse rights. Preserve source URLs for licensing and attribution checks. Do not bypass authentication, paywalls, robots controls, or anti-bot systems. Prefer original publisher sources. Do not overwrite unrelated files or delete prior pulls without approval.

Before reporting success, confirm the directory exists, the manifest is valid JSON, each counted file matches the requested asset type, at least one result opens as an image, requested domain filters were respected, counts match the manifest, duplicate reruns behave correctly, SHA-256 hashes are present, and failures are surfaced.
