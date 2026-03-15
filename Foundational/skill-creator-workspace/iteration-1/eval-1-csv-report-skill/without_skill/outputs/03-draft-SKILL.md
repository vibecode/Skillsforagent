# CSV Report Skill

Generate summary reports from CSV files — data profiling, pivot tables, and charts — all automated.

## When to Use This Skill

Use this skill when:
- A user asks you to analyze, summarize, or report on a CSV file
- A user wants a chart or visualization from tabular data
- A user says "generate a report" and provides (or references) a CSV
- You need to pivot, aggregate, or summarize CSV data

## Prerequisites

Run setup once per environment (the script is idempotent):

```bash
bash "$(dirname "$0")/scripts/setup.sh"
```

This installs Python dependencies: `pandas`, `matplotlib`, `jinja2`.

## Workflow

### Step 1: Profile the CSV

Run the analyzer to understand the data before making decisions:

```bash
python3 "$(dirname "$0")/scripts/analyze_csv.py" --file <path-to-csv>
```

Returns JSON to stdout:
```json
{
  "row_count": 1500,
  "columns": [
    {"name": "date", "dtype": "datetime", "nunique": 365, "nulls": 0, "sample": ["2024-01-01", "2024-01-02"]},
    {"name": "region", "dtype": "string", "nunique": 4, "nulls": 0, "sample": ["North", "South", "East", "West"]},
    {"name": "product", "dtype": "string", "nunique": 12, "nulls": 3, "sample": ["Widget A", "Widget B"]},
    {"name": "revenue", "dtype": "float64", "nunique": 1350, "nulls": 0, "sample": [1234.56, 789.01]},
    {"name": "units_sold", "dtype": "int64", "nunique": 200, "nulls": 0, "sample": [42, 17]}
  ],
  "summary_stats": { ... }
}
```

### Step 2: Decide What to Pivot

**This is where YOU reason.** Based on the profile, decide:

- **Group-by columns (dimensions):** Choose low-cardinality string/categorical columns (nunique < 20 is a good threshold). These become the rows/axes of the pivot.
- **Value columns (metrics):** Choose numeric columns (int/float). These get aggregated.
- **Aggregation function:** `sum` for revenue/counts, `mean` for rates/averages, `count` for frequencies.
- **Chart type:** `bar` for comparisons, `line` for time series, `pie` for proportions (≤6 categories).

**Heuristics:**
- If a datetime column exists and user mentions "trend" or "over time" → use it as the x-axis, chart type = `line`
- If there are 2+ categorical columns → pivot one as rows, one as column groups
- If user doesn't specify, pick the most interesting dimension (lowest cardinality > 1) and the first numeric column
- Always tell the user what you chose and why

### Step 3: Generate the Report

```bash
python3 "$(dirname "$0")/scripts/report_csv.py" \
  --file <path-to-csv> \
  --group-by <col1> [<col2>] \
  --metrics <col1> [<col2>] \
  --agg <sum|mean|count|median> \
  --chart-type <bar|line|pie|heatmap> \
  --title "Report Title" \
  --output <output-dir>
```

This produces:
- `report.html` — self-contained HTML report with embedded chart, pivot table, and summary stats
- `chart.png` — standalone chart image
- `pivot.csv` — the pivot table as CSV (for further use)

### Step 4: Deliver to User

1. Share the HTML report (upload to cloud storage or serve via public files if available)
2. Show the chart image inline if the platform supports it
3. Summarize key findings in your message — don't just dump a file, **interpret the data**

## Parameters Reference

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--file` | Yes | Path to the input CSV file |
| `--group-by` | Yes | Column(s) to group by (space-separated) |
| `--metrics` | Yes | Numeric column(s) to aggregate (space-separated) |
| `--agg` | No | Aggregation function. Default: `sum` |
| `--chart-type` | No | Chart type. Default: auto-detected |
| `--title` | No | Report title. Default: derived from filename |
| `--output` | No | Output directory. Default: `./csv-report-output` |
| `--top-n` | No | Only show top N rows in pivot. Default: all |
| `--sort-by` | No | Sort pivot by this metric. Default: first metric desc |

## Error Handling

- **File not found:** Tell the user and ask for the correct path.
- **No numeric columns:** You can still do frequency counts — use `--agg count` with any column as metric.
- **Too many categories (nunique > 50):** Warn the user the chart will be cluttered. Suggest `--top-n 10` or binning.
- **Encoding issues:** Try `--encoding latin1` or `--encoding utf-8-sig` if default fails.
- **Empty CSV / malformed:** Report the error clearly; don't retry blindly.

## Examples

### "Show me sales by region"
```bash
python3 scripts/analyze_csv.py --file sales.csv
# → sees 'region' (4 unique), 'revenue' (numeric)
python3 scripts/report_csv.py --file sales.csv --group-by region --metrics revenue --agg sum --chart-type bar --title "Sales by Region"
```

### "How have monthly signups trended?"
```bash
python3 scripts/analyze_csv.py --file signups.csv
# → sees 'signup_date' (datetime), 'user_id' (high cardinality)
# Agent decides: group by month, count user_id
python3 scripts/report_csv.py --file signups.csv --group-by signup_date --metrics user_id --agg count --chart-type line --title "Monthly Signup Trend"
```

### "Give me a summary of this data" (no specific ask)
```bash
python3 scripts/analyze_csv.py --file data.csv
# Agent picks the most interesting dimension + metric combo
# Agent generates report and explains what it found
```
