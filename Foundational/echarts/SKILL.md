---
name: ECharts
description: >
  Foundational skill for Apache ECharts — local server-side chart rendering via Node.js.
  Generates PNG or SVG chart images from JSON configuration. No API key, no network calls,
  no rate limits. Use this skill when: (1) generating chart or graph images (bar, line, pie,
  scatter, candlestick, gauge, heatmap, treemap, radar, funnel, sankey, etc.), (2) creating
  financial charts with candlestick, volume, and moving averages, (3) rendering data
  visualizations as PNG or SVG for embedding in messages, emails, reports, or web pages,
  (4) building professional-quality charts with gradients, dark themes, and rich styling,
  (5) visualizing data from CSV, JSON, or API responses as chart images, (6) creating any
  kind of data visualization or infographic as a static image. This is the base charting
  skill — specialized skills may reference it for data visualization workflows.
metadata: {"openclaw": {"emoji": "📊", "install": "apt-get install -y libcairo2-dev libpango1.0-dev libjpeg62-turbo-dev libgif-dev librsvg2-dev 2>/dev/null; npm install --prefix {baseDir}/scripts echarts canvas", "requires": {"bins": ["node"]}}}
---

# ECharts

Local chart rendering. Write a JSON config → run the render script → get a PNG or SVG. No API keys, no network, no limits.

**Version:** 6.0.0 (latest major, released 2025)

## Render Script

```bash
RENDER="{baseDir}/scripts/render.js"
```

### Usage

```bash
# From stdin
echo '<json>' | node $RENDER --out chart.png

# From file
node $RENDER --file option.json --out chart.png

# With options
node $RENDER --file option.json --out chart.png --width 1000 --height 600 --theme dark --bg '#1a1a2e'

# SVG output (no node-canvas dependency needed for SVG)
node $RENDER --file option.json --out chart.svg
```

| Flag | Default | Description |
|------|---------|-------------|
| `--out` | `chart.png` | Output file path. Extension sets format unless `--format` given |
| `--file` | stdin | Read option JSON from file instead of stdin |
| `--width` | `800` | Image width in pixels |
| `--height` | `600` | Image height in pixels |
| `--theme` | none | Built-in theme: `dark` |
| `--bg` | none | Background color (overridden by `backgroundColor` in option) |
| `--format` | auto | `png` or `svg` (auto-detected from `--out` extension) |

Output on success: `{"ok":true,"path":"...","format":"...","width":...,"height":...,"bytes":...}`

## ECharts Option Format

Every chart is a single JSON object. The three things you always set:

```json
{
  "xAxis": { "type": "category", "data": ["Mon", "Tue", "Wed"] },
  "yAxis": { "type": "value" },
  "series": [{ "type": "bar", "data": [10, 20, 15] }]
}
```

That's a bar chart. Change `"type": "bar"` to `"line"`, `"scatter"`, etc.

### Core Properties

| Property | Purpose |
|----------|---------|
| `title` | Chart title: `{ text, subtext, left, textStyle }` |
| `xAxis` | X axis: `{ type: "category"/"value"/"time", data, name }` |
| `yAxis` | Y axis: same as xAxis |
| `series` | Array of data series (the actual chart data) |
| `legend` | Legend: `{ data: ["Series A", "Series B"] }` |
| `grid` | Chart area margins: `{ left, right, top, bottom }` |
| `backgroundColor` | Background: `"#fff"` or `"transparent"` |

### Series Types

| Type | Use For |
|------|---------|
| `bar` | Comparisons, rankings |
| `line` | Trends over time |
| `pie` | Proportions: `data: [{value: 40, name: "A"}, {value: 60, name: "B"}]` |
| `scatter` | Correlations, distributions |
| `candlestick` | Financial OHLC: `data: [[open, close, low, high], ...]` |
| `gauge` | Single metric (KPI dials) |
| `radar` | Multi-dimensional comparisons |
| `heatmap` | Density/matrix data |
| `treemap` | Hierarchical proportions |
| `sunburst` | Nested hierarchical data |
| `funnel` | Conversion funnels |
| `sankey` | Flow between categories |
| `graph` | Network/relationship diagrams |
| `boxplot` | Statistical distributions |

For pie, gauge, radar, funnel, sankey, sunburst, treemap, graph — no xAxis/yAxis needed. Just set series data.

## Common Chart Recipes

### Bar Chart with Gradient

```json
{
  "backgroundColor": "#ffffff",
  "title": { "text": "Monthly Revenue", "left": "center" },
  "xAxis": { "type": "category", "data": ["Jan", "Feb", "Mar", "Apr", "May", "Jun"] },
  "yAxis": { "type": "value", "name": "Revenue ($K)" },
  "series": [{
    "type": "bar",
    "data": [42, 58, 35, 71, 63, 89],
    "itemStyle": {
      "color": { "type": "linear", "x": 0, "y": 0, "x2": 0, "y2": 1,
        "colorStops": [{"offset": 0, "color": "#667eea"}, {"offset": 1, "color": "#764ba2"}]
      }
    }
  }]
}
```

### Multi-Series Line Chart

```json
{
  "title": { "text": "User Growth", "left": "center" },
  "legend": { "bottom": 0 },
  "xAxis": { "type": "category", "data": ["Q1", "Q2", "Q3", "Q4"] },
  "yAxis": { "type": "value" },
  "series": [
    { "name": "Signups", "type": "line", "data": [1200, 1800, 2400, 3100], "smooth": true },
    { "name": "Active", "type": "line", "data": [800, 1100, 1900, 2600], "smooth": true }
  ]
}
```

### Pie / Doughnut

```json
{
  "title": { "text": "Traffic Sources", "left": "center" },
  "series": [{
    "type": "pie",
    "radius": ["40%", "70%"],
    "data": [
      { "value": 1048, "name": "Organic" },
      { "value": 735, "name": "Direct" },
      { "value": 580, "name": "Referral" },
      { "value": 484, "name": "Social" }
    ],
    "label": { "formatter": "{b}: {d}%" }
  }]
}
```

### Financial Candlestick with Volume

```json
{
  "backgroundColor": "#1a1a2e",
  "title": { "text": "AAPL", "left": "center", "textStyle": { "color": "#e0e0e0" } },
  "grid": [
    { "left": "8%", "right": "4%", "top": "10%", "height": "55%" },
    { "left": "8%", "right": "4%", "top": "70%", "height": "18%" }
  ],
  "xAxis": [
    { "type": "category", "data": ["1/2", "1/3", "1/4", "1/5", "1/6"],
      "axisLine": { "lineStyle": { "color": "#444" } }, "gridIndex": 0 },
    { "type": "category", "data": ["1/2", "1/3", "1/4", "1/5", "1/6"],
      "axisLabel": { "show": false }, "gridIndex": 1 }
  ],
  "yAxis": [
    { "scale": true, "splitLine": { "lineStyle": { "color": "#333" } },
      "axisLabel": { "color": "#aaa" }, "gridIndex": 0 },
    { "scale": true, "splitLine": { "show": false }, "axisLabel": { "show": false }, "gridIndex": 1 }
  ],
  "series": [
    { "type": "candlestick", "data": [[180,185,178,187],[185,182,180,186],[182,190,181,191],[190,188,186,192],[188,195,187,196]],
      "itemStyle": { "color": "#26a69a", "color0": "#ef5350", "borderColor": "#26a69a", "borderColor0": "#ef5350" } },
    { "type": "bar", "data": [32000,28000,35000,41000,38000], "xAxisIndex": 1, "yAxisIndex": 1,
      "itemStyle": { "color": "rgba(38,166,154,0.4)" } }
  ]
}
```

### Gauge (KPI Dial)

```json
{
  "series": [{
    "type": "gauge",
    "data": [{ "value": 72, "name": "Completion" }],
    "detail": { "formatter": "{value}%", "fontSize": 24 },
    "axisLine": { "lineStyle": { "width": 15,
      "color": [[0.3, "#ef5350"], [0.7, "#ffab40"], [1, "#26a69a"]]
    }}
  }]
}
```

## Styling Quick Reference

### Colors

Set per-series via `itemStyle.color` or globally:
```json
{ "color": ["#5470c6", "#91cc75", "#fac858", "#ee6666", "#73c0de", "#3ba272"] }
```

### Gradients

```json
{ "type": "linear", "x": 0, "y": 0, "x2": 0, "y2": 1,
  "colorStops": [{"offset": 0, "color": "#top"}, {"offset": 1, "color": "#bottom"}] }
```

### Dark Theme

Pass `--theme dark` to the render script, or style manually with `backgroundColor` and light-colored text/axes.

### Data Labels

```json
{ "label": { "show": true, "position": "top", "formatter": "{c}" } }
```

Formatters: `{a}` = series name, `{b}` = category, `{c}` = value, `{d}` = percentage (pie only).

### Area Fill Under Line

```json
{ "type": "line", "areaStyle": { "opacity": 0.3 }, "data": [10, 20, 15] }
```

## Multi-Grid Layout

For charts with multiple panels (like candlestick + volume), use multiple `grid`, `xAxis`, and `yAxis` entries as arrays, linked by `gridIndex`, `xAxisIndex`, `yAxisIndex`.

## Output as Reusable File

The render script writes a file. That file can be:
- Sent in a chat message as an image attachment
- Embedded in HTML: `<img src="chart.png">`
- Attached to an email via the resend skill
- Uploaded via the cloud-storage skill for a CDN URL
- Included in a PDF via pandoc or puppeteer

Render once, use anywhere.

## Detailed Reference

For advanced chart type configs, multi-axis patterns, and financial chart templates: read [references/chart-types.md](references/chart-types.md).
