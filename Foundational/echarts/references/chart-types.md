# ECharts — Chart Type Reference

Detailed configs for chart types beyond the basics in SKILL.md.

## Stacked Bar

```json
{
  "xAxis": { "type": "category", "data": ["Q1", "Q2", "Q3", "Q4"] },
  "yAxis": { "type": "value" },
  "legend": { "bottom": 0 },
  "series": [
    { "name": "Product A", "type": "bar", "stack": "total", "data": [320, 302, 301, 334] },
    { "name": "Product B", "type": "bar", "stack": "total", "data": [120, 132, 101, 134] },
    { "name": "Product C", "type": "bar", "stack": "total", "data": [220, 182, 191, 234] }
  ]
}
```

All series with the same `"stack"` value are stacked. Omit `stack` for grouped (side-by-side).

## Horizontal Bar

Swap the axes:

```json
{
  "yAxis": { "type": "category", "data": ["Python", "JS", "Go", "Rust"] },
  "xAxis": { "type": "value" },
  "series": [{ "type": "bar", "data": [85, 72, 45, 38] }]
}
```

## Area Chart

```json
{
  "xAxis": { "type": "category", "data": ["Mon", "Tue", "Wed", "Thu", "Fri"] },
  "yAxis": { "type": "value" },
  "series": [{
    "type": "line",
    "data": [820, 932, 901, 934, 1290],
    "areaStyle": {
      "color": { "type": "linear", "x": 0, "y": 0, "x2": 0, "y2": 1,
        "colorStops": [{"offset": 0, "color": "rgba(84,112,198,0.5)"}, {"offset": 1, "color": "rgba(84,112,198,0.05)"}]
      }
    },
    "smooth": true
  }]
}
```

## Stacked Area

```json
{
  "xAxis": { "type": "category", "data": ["Mon", "Tue", "Wed", "Thu", "Fri"] },
  "yAxis": { "type": "value" },
  "series": [
    { "name": "Email", "type": "line", "stack": "total", "areaStyle": {}, "data": [120, 132, 101, 134, 90] },
    { "name": "Search", "type": "line", "stack": "total", "areaStyle": {}, "data": [220, 182, 191, 234, 290] },
    { "name": "Direct", "type": "line", "stack": "total", "areaStyle": {}, "data": [150, 232, 201, 154, 190] }
  ]
}
```

## Radar Chart

No axes needed. Define `radar.indicator` for dimensions:

```json
{
  "radar": {
    "indicator": [
      { "name": "Speed", "max": 100 },
      { "name": "Power", "max": 100 },
      { "name": "Defense", "max": 100 },
      { "name": "Range", "max": 100 },
      { "name": "Stamina", "max": 100 }
    ]
  },
  "series": [{
    "type": "radar",
    "data": [
      { "value": [80, 90, 60, 70, 85], "name": "Player A" },
      { "value": [60, 70, 80, 95, 65], "name": "Player B" }
    ]
  }]
}
```

## Heatmap

Requires `visualMap` for color mapping:

```json
{
  "xAxis": { "type": "category", "data": ["Mon", "Tue", "Wed", "Thu", "Fri"] },
  "yAxis": { "type": "category", "data": ["Morning", "Afternoon", "Evening"] },
  "visualMap": { "min": 0, "max": 100, "calculable": true, "orient": "horizontal", "left": "center", "bottom": 0 },
  "series": [{
    "type": "heatmap",
    "data": [[0,0,10],[0,1,50],[0,2,80],[1,0,30],[1,1,60],[1,2,90],[2,0,20],[2,1,70],[2,2,40],[3,0,60],[3,1,40],[3,2,55],[4,0,90],[4,1,30],[4,2,20]],
    "label": { "show": true }
  }]
}
```

Data format: `[xIndex, yIndex, value]`.

## Treemap

Hierarchical data with nested `children`:

```json
{
  "series": [{
    "type": "treemap",
    "data": [
      { "name": "Engineering", "value": 45, "children": [
        { "name": "Frontend", "value": 20 },
        { "name": "Backend", "value": 15 },
        { "name": "Infra", "value": 10 }
      ]},
      { "name": "Design", "value": 25 },
      { "name": "Marketing", "value": 30 }
    ]
  }]
}
```

## Sunburst

Like treemap but radial:

```json
{
  "series": [{
    "type": "sunburst",
    "radius": ["15%", "80%"],
    "data": [
      { "name": "Web", "children": [
        { "name": "React", "value": 40 },
        { "name": "Vue", "value": 30 },
        { "name": "Angular", "value": 15 }
      ]},
      { "name": "Mobile", "children": [
        { "name": "iOS", "value": 25 },
        { "name": "Android", "value": 35 }
      ]}
    ],
    "label": { "rotate": "radial" }
  }]
}
```

## Funnel

```json
{
  "series": [{
    "type": "funnel",
    "data": [
      { "value": 100, "name": "Visitors" },
      { "value": 80, "name": "Signups" },
      { "value": 60, "name": "Trials" },
      { "value": 40, "name": "Paid" },
      { "value": 20, "name": "Enterprise" }
    ],
    "label": { "formatter": "{b}: {c}" }
  }]
}
```

## Sankey

Flow between nodes:

```json
{
  "series": [{
    "type": "sankey",
    "data": [
      { "name": "Organic" }, { "name": "Paid" }, { "name": "Landing" },
      { "name": "Signup" }, { "name": "Purchase" }
    ],
    "links": [
      { "source": "Organic", "target": "Landing", "value": 500 },
      { "source": "Paid", "target": "Landing", "value": 300 },
      { "source": "Landing", "target": "Signup", "value": 600 },
      { "source": "Signup", "target": "Purchase", "value": 200 }
    ],
    "emphasis": { "focus": "adjacency" }
  }]
}
```

## Boxplot

```json
{
  "xAxis": { "type": "category", "data": ["Group A", "Group B", "Group C"] },
  "yAxis": { "type": "value" },
  "series": [{
    "type": "boxplot",
    "data": [
      [655, 850, 940, 980, 1175],
      [672, 780, 840, 930, 1100],
      [780, 840, 855, 880, 940]
    ]
  }]
}
```

Data format: `[min, Q1, median, Q3, max]`.

## Financial Chart — Full Pattern

Candlestick with moving average overlay + volume bar subplot:

```json
{
  "backgroundColor": "#1a1a2e",
  "title": { "text": "SYMBOL", "left": "center", "textStyle": { "color": "#e0e0e0", "fontSize": 16 } },
  "grid": [
    { "left": "8%", "right": "4%", "top": "10%", "height": "55%" },
    { "left": "8%", "right": "4%", "top": "70%", "height": "18%" }
  ],
  "xAxis": [
    { "type": "category", "data": "DATES_ARRAY", "axisLine": { "lineStyle": { "color": "#444" } },
      "axisLabel": { "color": "#aaa" }, "gridIndex": 0 },
    { "type": "category", "data": "DATES_ARRAY", "axisLabel": { "show": false }, "gridIndex": 1 }
  ],
  "yAxis": [
    { "scale": true, "splitLine": { "lineStyle": { "color": "#333" } },
      "axisLabel": { "color": "#aaa" }, "gridIndex": 0 },
    { "scale": true, "splitLine": { "show": false }, "axisLabel": { "show": false }, "gridIndex": 1 }
  ],
  "series": [
    {
      "name": "Price",
      "type": "candlestick",
      "data": "OHLC_ARRAY (each: [open, close, low, high])",
      "itemStyle": {
        "color": "#26a69a",
        "color0": "#ef5350",
        "borderColor": "#26a69a",
        "borderColor0": "#ef5350"
      },
      "xAxisIndex": 0, "yAxisIndex": 0
    },
    {
      "name": "MA20",
      "type": "line",
      "data": "MOVING_AVG_ARRAY",
      "smooth": true,
      "lineStyle": { "color": "#ffab40", "width": 1.5 },
      "symbol": "none",
      "xAxisIndex": 0, "yAxisIndex": 0
    },
    {
      "name": "Volume",
      "type": "bar",
      "data": "VOLUME_ARRAY",
      "xAxisIndex": 1, "yAxisIndex": 1,
      "itemStyle": { "color": "rgba(38,166,154,0.4)" }
    }
  ]
}
```

**Candlestick colors:** `color` = bullish (close > open), `color0` = bearish (close < open).

**Volume coloring by direction:** To color volume bars red/green by price direction, make each volume data point an object:
```json
{ "value": 35000, "itemStyle": { "color": "rgba(239,83,80,0.5)" } }
```

## Mixed Chart Types

Combine bar + line on the same axes:

```json
{
  "xAxis": { "type": "category", "data": ["Jan", "Feb", "Mar", "Apr"] },
  "yAxis": [
    { "type": "value", "name": "Revenue" },
    { "type": "value", "name": "Growth %", "axisLabel": { "formatter": "{value}%" } }
  ],
  "series": [
    { "name": "Revenue", "type": "bar", "data": [120, 150, 180, 210] },
    { "name": "Growth", "type": "line", "yAxisIndex": 1, "data": [12, 25, 20, 17], "smooth": true }
  ]
}
```

## Tooltip

Add tooltips (useful if chart will be rendered as SVG and embedded in HTML):

```json
{ "tooltip": { "trigger": "axis" } }
```

For pie/funnel: `{ "tooltip": { "trigger": "item" } }`.

## Visual Styling Patterns

### Dark Theme Manual

```json
{
  "backgroundColor": "#1a1a2e",
  "textStyle": { "color": "#e0e0e0" },
  "xAxis": { "axisLine": { "lineStyle": { "color": "#444" } }, "axisLabel": { "color": "#aaa" } },
  "yAxis": { "splitLine": { "lineStyle": { "color": "#333" } }, "axisLabel": { "color": "#aaa" } }
}
```

### Custom Color Palette

```json
{ "color": ["#5470c6", "#91cc75", "#fac858", "#ee6666", "#73c0de", "#3ba272", "#fc8452", "#9a60b4", "#ea7ccc"] }
```

### Rich Label Formatting

```json
{
  "label": {
    "show": true,
    "formatter": "{name|{b}}\n{value|{c}}",
    "rich": {
      "name": { "fontSize": 12, "color": "#666" },
      "value": { "fontSize": 16, "fontWeight": "bold", "color": "#333" }
    }
  }
}
```

## ECharts 6.0 New Chart Types

Version 6.0 added several new types (may require importing extensions):

- **chord** — visualize relationships and flow between categories (circular layout)
- **beeswarm** — expand overlapping scatter points into honeycomb patterns
- **violin** — distribution shape visualization (via custom series extension)
- **scatter jittering** — add random offset to overlapping scatter points

These are available in ECharts 6.0+. The core types listed in SKILL.md work in all versions 5.x+.
