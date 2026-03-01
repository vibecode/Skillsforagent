---
name: quickchart
description: >
  Foundational skill for the QuickChart.io API — server-side chart and QR code image generation
  via HTTP. No auth required for free tier. Use this skill when: (1) generating chart images
  (bar, line, pie, doughnut, radar, scatter, bubble, gauge, sparkline, etc.), (2) creating QR
  code images from text or URLs, (3) rendering data visualizations as PNG/SVG/WebP/PDF for
  embedding in emails, messages, or documents, (4) building Chart.js configs and rendering them
  as static images, (5) creating short URLs for charts, (6) generating progress bars or
  sparklines for dashboards. Includes a wrapper script for quick use. No API key needed for
  basic usage (500 charts/month free). This is the base QuickChart skill — specialized skills
  may reference it for data visualization workflows.
metadata: {"openclaw": {"emoji": "📊"}}
---

# QuickChart

Server-side chart and QR code image generation. Pass a Chart.js config → get back a PNG. No auth, no install, pure HTTP.

## How It Works

QuickChart renders [Chart.js](https://www.chartjs.org/) configurations as static images via a REST API. Send a Chart.js config object, get back a PNG/SVG/WebP/PDF image.

- **Base URL:** `https://quickchart.io`
- **Auth:** None required (free tier: 500/month, 1 req/sec). Set `QUICKCHART_API_KEY` for paid plans.
- **Self-hosted:** Open source at https://github.com/typpo/quickchart (unlimited, no auth)

## Wrapper Script

The fastest way to generate charts. Handles POST requests, JSON construction, and error handling.

```bash
SCRIPT="<skill_path>/scripts/quickchart.sh"
```

### Charts — Quick Reference

```bash
# Simple bar chart
bash $SCRIPT chart --labels "Jan,Feb,Mar,Apr" --data "10,20,30,25" --title "Monthly Sales" --out sales.png

# Line chart with two datasets
bash $SCRIPT chart --type line \
  --labels "Q1,Q2,Q3,Q4" \
  --data "100,150,130,170" --label1 "Revenue" \
  --data2 "80,90,110,95" --label2 "Costs" \
  --title "Revenue vs Costs" --out revenue.png

# Pie chart
bash $SCRIPT chart --type pie --labels "Chrome,Firefox,Safari,Edge" --data "65,15,12,8" --out browsers.png

# Doughnut chart
bash $SCRIPT chart --type doughnut --labels "Yes,No,Maybe" --data "55,30,15" --out survey.png

# Radar chart
bash $SCRIPT chart --type radar --labels "Speed,Power,Range,Safety,Comfort" --data "8,6,9,7,8" --out stats.png

# Sparkline (minimal, no axes)
bash $SCRIPT chart --type sparkline --data "5,10,8,15,12,20,18" --width 200 --height 50 --out spark.png

# Custom dimensions, retina, SVG output
bash $SCRIPT chart --labels "A,B,C" --data "1,2,3" --width 800 --height 600 --dpr 1 --format svg --out chart.svg

# Chart.js v4
bash $SCRIPT chart --labels "Mon,Tue,Wed" --data "5,10,15" --version 4 --out modern.png

# Full Chart.js config (advanced)
bash $SCRIPT chart --config '{"type":"bar","data":{"labels":["A","B"],"datasets":[{"label":"X","data":[10,20],"backgroundColor":["#ff6384","#36a2eb"]}]},"options":{"plugins":{"datalabels":{"display":true,"color":"#fff"}}}}' --out custom.png

# Get URL instead of downloading
bash $SCRIPT chart --labels "A,B,C" --data "1,2,3" --url-only
```

### QR Codes

```bash
# Basic QR code
bash $SCRIPT qr --text "https://example.com" --out example_qr.png

# Styled QR code
bash $SCRIPT qr --text "Hello World" --size 400 --dark "2563eb" --light "f0f9ff" --ec-level H --out styled.png

# QR with center logo
bash $SCRIPT qr --text "https://mysite.com" --center-image "https://example.com/logo.png" --center-ratio 0.25 --out branded.png

# QR with caption
bash $SCRIPT qr --text "WIFI:T:WPA;S:MyNetwork;P:password123;;" --caption "Scan for WiFi" --out wifi.png

# SVG format
bash $SCRIPT qr --text "data" --format svg --out code.svg

# URL only
bash $SCRIPT qr --text "https://example.com" --url-only
```

### Short URLs

```bash
# Create a shareable short URL for a chart
bash $SCRIPT short --config '{"type":"bar","data":{"labels":["A","B"],"datasets":[{"label":"X","data":[1,2]}]}}'
# Returns: https://quickchart.io/chart/render/<id>
```

## Direct API Usage

When you need more control than the wrapper provides:

### POST (Recommended)

```bash
curl -X POST https://quickchart.io/chart \
  -H 'Content-Type: application/json' \
  -d '{
    "chart": {"type":"bar","data":{"labels":["A","B","C"],"datasets":[{"label":"Sales","data":[10,20,30]}]}},
    "width": 600,
    "height": 400,
    "backgroundColor": "white",
    "devicePixelRatio": 2,
    "format": "png",
    "version": "2"
  }' -o chart.png
```

### GET (Simple cases)

```
https://quickchart.io/chart?w=600&h=400&bkg=white&c={type:'bar',data:{labels:['A','B','C'],datasets:[{label:'Sales',data:[10,20,30]}]}}
```

URL-encode the `c` parameter for special characters. Max URL length ~16,000 chars.

## Chart Types

| Type | `type` value | Best for |
|------|-------------|----------|
| Bar | `bar` | Comparing categories |
| Horizontal Bar | `horizontalBar` | Long category labels |
| Line | `line` | Trends over time |
| Pie | `pie` | Proportions (few slices) |
| Doughnut | `doughnut` | Proportions with center label |
| Radar | `radar` | Multi-axis comparisons |
| Polar Area | `polarArea` | Like pie but by radius |
| Scatter | `scatter` | Correlation between variables |
| Bubble | `bubble` | Three-variable scatter |
| Sparkline | `sparkline` | Inline trend indicators |
| Progress Bar | `progressBar` | Completion percentage |
| Radial Gauge | `radialGauge` | Single KPI display |
| Speedometer | `gauge` | Value within ranges |
| Box Plot | `boxplot` | Distribution statistics |
| Violin | `violin` | Distribution shape |
| Sankey | `sankey` | Flow/process visualization |
| Funnel | `funnel` | Conversion funnels (v3+) |

## Built-in Plugins

These are available without configuration:

- **datalabels** — Display values on data points. Use `options.plugins.datalabels`.
- **annotation** — Draw reference lines, boxes, labels. Use `options.annotation.annotations`.
- **doughnutlabel** — Text in center of doughnut charts. Use `options.plugins.doughnutlabel`.

## Key Parameters

| Parameter | Default | Notes |
|-----------|---------|-------|
| `width` | 500 | Pixels |
| `height` | 300 | Pixels |
| `devicePixelRatio` | 2 | Set to 1 for exact pixel dimensions |
| `backgroundColor` | transparent | Color name, hex, rgb |
| `version` | "2" | "2", "3", or "4" for Chart.js version |
| `format` | "png" | png, webp, jpg, svg, pdf |

> **DPR note:** Default DPR is 2, so a 500×300 chart produces a 1000×600 image. Set `--dpr 1` (or `"devicePixelRatio": 1`) for exact pixel match.

## Common Patterns

### Dashboard sparklines
```bash
for metric in "cpu:45,52,48,60,55" "mem:70,72,68,75,80" "disk:30,31,32,33,35"; do
  name="${metric%%:*}"; data="${metric#*:}"
  bash $SCRIPT chart --type sparkline --data "$data" --width 200 --height 50 --dpr 1 --out "${name}_spark.png"
done
```

### Chart with annotation line
```bash
bash $SCRIPT chart --config '{
  "type":"bar",
  "data":{"labels":["Mon","Tue","Wed","Thu","Fri"],"datasets":[{"label":"Sales","data":[12,19,8,15,22]}]},
  "options":{"annotation":{"annotations":[{"type":"line","mode":"horizontal","scaleID":"y-axis-0","value":15,"borderColor":"red","borderWidth":2,"label":{"enabled":true,"content":"Target"}}]}}
}' --out annotated.png
```

## Error Handling

- **400 Bad Request** — Invalid chart config. Error rendered in the image + `X-quickchart-error` header.
- **URL too long** — Use POST instead of GET.
- **Rate limited** — Free tier: 1 req/sec, 500/month. Add delay between calls or use API key.

## References

- [references/api-reference.md](references/api-reference.md) — Full parameter tables, all chart types, plugin details, rate limits
- [QuickChart Gallery](https://quickchart.io/gallery/) — Browse editable chart examples
- [Chart.js Docs (v2)](https://www.chartjs.org/docs/2.9.4/) — Config reference for Chart.js v2
- [Chart.js Docs (v4)](https://www.chartjs.org/docs/latest/) — Config reference for Chart.js v4
