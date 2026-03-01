# QuickChart API Reference

Full parameter reference for all QuickChart.io endpoints. Consult when you need exact parameter names, accepted values, or response formats.

## Table of Contents

1. [Chart Endpoint](#chart-endpoint)
2. [QR Code Endpoint](#qr-code-endpoint)
3. [Short URL Endpoint](#short-url-endpoint)
4. [Templates](#templates)
5. [Chart Types](#chart-types)
6. [Plugins](#plugins)

---

## Chart Endpoint

### GET `https://quickchart.io/chart`

| Parameter | Alias | Type | Default | Description |
|-----------|-------|------|---------|-------------|
| `chart` | `c` | string (JS/JSON) | *required* | Chart.js configuration object |
| `width` | `w` | integer | 500 | Image width in pixels |
| `height` | `h` | integer | 300 | Image height in pixels |
| `devicePixelRatio` | — | integer | 2 | Pixel ratio (1 = exact size, 2 = retina) |
| `backgroundColor` | `bkg` | string | transparent | RGB, hex, HSL, or color name |
| `version` | `v` | string | "2.9.4" | Chart.js version: "2", "3", "4" |
| `format` | `f` | string | "png" | Output: png, webp, jpg, svg, pdf, base64 |
| `encoding` | — | string | "url" | "url" or "base64" (for chart param encoding) |

**URL length limit:** ~16,000 chars. Use POST for larger charts.

**Example GET:**
```
https://quickchart.io/chart?w=600&h=400&bkg=white&c={type:'bar',data:{labels:['A','B','C'],datasets:[{label:'Sales',data:[10,20,30]}]}}
```

### POST `https://quickchart.io/chart`

Send JSON body with same parameters. Returns binary image.

```json
{
  "chart": {"type": "bar", "data": {"labels": ["A","B"], "datasets": [{"label": "X", "data": [1,2]}]}},
  "width": 600,
  "height": 400,
  "devicePixelRatio": 2,
  "backgroundColor": "white",
  "format": "png",
  "version": "2",
  "key": "optional-api-key"
}
```

**Note:** To include JavaScript functions (e.g. formatters), send `chart` as a **string**, not a JSON object.

### Response

- **Success:** Binary image (Content-Type matches format)
- **Error (400):** Error message rendered in the image. Also in `X-quickchart-error` header.

---

## QR Code Endpoint

### GET `https://quickchart.io/qr`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | string | *required* | QR content (URL-encode!) |
| `size` | integer | 150 | Width/height in pixels |
| `margin` | integer | 4 | Whitespace in modules |
| `dark` | hex string | 000000 | Dark cell color |
| `light` | hex string | ffffff | Light cell color (use `0000` for transparent) |
| `ecLevel` | string | M | Error correction: L, M, Q, H |
| `format` | string | png | Output: png, svg |
| `centerImageUrl` | string | — | URL of center overlay image (URL-encode!) |
| `centerImageSizeRatio` | float | 0.3 | Center image size (0.0–1.0) |
| `centerImageWidth` | integer | — | Center image width in pixels |
| `centerImageHeight` | integer | — | Center image height in pixels |
| `caption` | string | — | Text below QR code |
| `captionFontFamily` | string | sans-serif | Caption font family |
| `captionFontSize` | integer | 10 | Caption font size in pixels |
| `captionFontColor` | string | black | Caption text color |

**Example:**
```
https://quickchart.io/qr?text=https%3A%2F%2Fexample.com&size=300&dark=333333&ecLevel=H
```

---

## Short URL Endpoint

### POST `https://quickchart.io/chart/create`

Same JSON body as the chart POST endpoint. Returns a short URL.

**Response:**
```json
{
  "success": true,
  "url": "https://quickchart.io/chart/render/9a560ba4-ab71-4d1e-89ea-ce4741e9d232"
}
```

**Expiration:** 3 days (free), 6 months (paid).

---

## Templates

Any short URL can be used as a template. Override values via query parameters:

| Parameter | Description |
|-----------|-------------|
| `title` | Chart title |
| `labels` | Comma-separated X-axis labels |
| `data1`, `data2`, ..., `dataN` | Comma-separated dataset values |
| `label1`, `label2`, ..., `labelN` | Dataset labels |
| `backgroundColor1`, ..., `backgroundColorN` | Dataset background colors |
| `borderColor1`, ..., `borderColorN` | Dataset border colors |

**Example:**
```
https://quickchart.io/chart/render/zf-abc-123?title=Q1+Sales&labels=Jan,Feb,Mar&data1=100,200,300
```

---

## Chart Types

All Chart.js v2/v3/v4 chart types are supported, plus these extras:

| Type | Config `type` | Notes |
|------|---------------|-------|
| Bar | `bar` | Vertical bars |
| Horizontal Bar | `horizontalBar` | v2 only; v4 uses `bar` + `indexAxis:'y'` |
| Line | `line` | Use `fill:false` for no area fill |
| Pie | `pie` | |
| Doughnut | `doughnut` | Supports `doughnutlabel` plugin |
| Radar | `radar` | |
| Polar Area | `polarArea` | |
| Scatter | `scatter` | Data as `{x, y}` objects |
| Bubble | `bubble` | Data as `{x, y, r}` objects |
| Radial Gauge | `radialGauge` | Single-value gauge ([chartjs-radial-gauge](https://github.com/nicolarobine/chartjs-radial-gauge)) |
| Speedometer | `gauge` | Multi-range gauge ([chartjs-gauge](https://github.com/nicolarobine/chartjs-gauge)) |
| Box Plot | `boxplot` | Requires array-of-arrays data |
| Violin | `violin` | Like box plot with density distribution |
| Sparkline | `sparkline` | Minimal line chart, no axes |
| Progress Bar | `progressBar` | Horizontal fill bar, single value |
| Sankey | `sankey` | Flow diagram; data as `{from, to, flow}` |
| Funnel | `funnel` | v3+ only |
| Candlestick | `candlestick` | v3+ financial |
| OHLC | `ohlc` | v3+ financial |

---

## Plugins

QuickChart includes these Chart.js plugins (no installation needed):

| Plugin | Purpose |
|--------|---------|
| `chartjs-plugin-datalabels` | Labels on data points (auto-included) |
| `chartjs-plugin-annotation` | Lines, boxes, labels on chart area |
| `chartjs-plugin-doughnutlabel` | Center text in doughnut charts |
| `chartjs-chart-box-and-violin-plot` | Box plots and violin charts |
| `chartjs-chart-radial-gauge` | Radial gauge charts |
| `chartjs-chart-financial` | Candlestick/OHLC (v3+) |
| `chartjs-chart-funnel` | Funnel charts (v3+) |
| `chartjs-chart-sankey` | Sankey/flow diagrams |

### Using datalabels

```json
{
  "type": "bar",
  "data": {...},
  "options": {
    "plugins": {
      "datalabels": {
        "display": true,
        "color": "#000",
        "anchor": "end",
        "align": "top"
      }
    }
  }
}
```

### Using annotation

```json
{
  "options": {
    "annotation": {
      "annotations": [{
        "type": "line",
        "mode": "horizontal",
        "scaleID": "y-axis-0",
        "value": 50,
        "borderColor": "red",
        "borderWidth": 2,
        "label": {"enabled": true, "content": "Threshold"}
      }]
    }
  }
}
```

---

## Rate Limits

| Tier | Rate | Monthly Limit | Auth |
|------|------|---------------|------|
| Free | 1 req/sec | 500 charts/month | None required |
| Community | 10 req/sec | 1,000/month | API key |
| Professional | 120 req/sec | Unlimited | API key |

Self-hosted (open source): unlimited. See https://github.com/typpo/quickchart
