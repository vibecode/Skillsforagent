---
name: csv-report
description: >
  Generate reports, summaries, and visualizations from CSV data. Use this skill
  whenever a user provides a CSV file and wants a report, analysis, summary,
  dashboard, chart, or data visualization. Also use when the user asks to pivot,
  aggregate, or break down CSV data, or says things like "analyze this spreadsheet,"
  "chart these numbers," "what are the trends in this data," or "create a report
  from this file." Handles any CSV — sales data, survey results, financial records,
  logs, inventory, or other tabular data.
metadata:
  openclaw:
    emoji: "📊"
---

# CSV Report Generator

Turn any CSV file into a clean, insightful report with summary statistics, pivoted data tables, and charts.

## How It Works

This skill follows a three-phase process: **Understand → Analyze → Present**. Each phase builds on the last. Don't skip ahead — understanding the data first prevents wasted work and wrong charts.

## Phase 1: Understand the Data

Before writing any analysis code, get oriented.

1. **Read the CSV** using Python/pandas:
   ```python
   import pandas as pd
   df = pd.read_csv("path/to/file.csv")
   ```

2. **Profile the data** — run this first to understand what you're working with:
   - `df.shape` — how many rows and columns
   - `df.dtypes` — what types pandas inferred
   - `df.head(10)` — first few rows to see the actual data
   - `df.describe(include='all')` — summary statistics
   - `df.isnull().sum()` — missing values per column

3. **Classify columns** into three buckets:
   - **Dimensions** — categorical columns good for grouping (names, categories, regions, statuses)
   - **Measures** — numeric columns good for aggregation (revenue, count, amount, score)
   - **Time** — date/datetime columns good for trend analysis

   This classification drives everything downstream. If the user specified what to analyze, use that. Otherwise, infer the most interesting dimensions and measures from the data profile.

4. **Clean the data** if needed:
   - Strip whitespace from headers: `df.columns = df.columns.str.strip()`
   - Parse dates: `df['date_col'] = pd.to_datetime(df['date_col'], errors='coerce')`
   - Handle missing values: note them in the report rather than silently dropping rows
   - Normalize inconsistent categories (e.g., "NY" vs "New York" — mention this if found)

## Phase 2: Analyze

Build the analytical core of the report. The goal is to surface the most useful insights, not to run every possible aggregation.

### Choosing what to analyze

If the user asked for something specific ("break down sales by region"), do exactly that. If the request is open-ended ("generate a report from this CSV"), pick the 2-4 most informative analyses based on the data profile:

- **If there's a time column + a measure**: trend over time (line chart)
- **If there's a categorical dimension + a measure**: breakdown by category (bar chart)
- **If there are two measures**: correlation or scatter plot
- **If there's a high-cardinality dimension**: top-N analysis (top 10 products, etc.)
- **If there are proportions or parts of a whole**: composition (pie/stacked bar)

### Pivot tables

Use pandas pivot tables for aggregations. They're the workhorse of this skill:

```python
pivot = df.pivot_table(
    values='revenue',        # measure column
    index='region',          # row grouping
    columns='quarter',       # column grouping (optional)
    aggfunc='sum',           # aggregation: sum, mean, count, etc.
    margins=True             # add totals row/column
)
```

When building pivot tables:
- Always include `margins=True` for totals — readers expect them
- Round floats to 2 decimal places for readability
- Sort by the most meaningful column (usually the total or the latest period)
- If a pivot table has more than 15 rows, show the top 10 and summarize the rest as "Other"

### Summary statistics

Calculate the headline numbers that belong at the top of the report:
- Total/sum of the primary measure
- Count of records
- Average, median, min, max of key measures
- Time range covered (if dates exist)
- Number of unique values in key dimensions

## Phase 3: Present

### Charts

Create charts using matplotlib. Good defaults make the difference between a chart people read and one they skip.

```python
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# Set a clean style
plt.style.use('seaborn-v0_8-whitegrid')

fig, ax = plt.subplots(figsize=(10, 6))
# ... build the chart ...

ax.set_title('Revenue by Region', fontsize=14, fontweight='bold', pad=15)
ax.set_xlabel('Region', fontsize=11)
ax.set_ylabel('Revenue ($)', fontsize=11)

# Format large numbers readably
ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda x, _: f'${x:,.0f}'))

plt.tight_layout()
plt.savefig('chart_name.png', dpi=150, bbox_inches='tight')
plt.close()
```

**Chart rules** (these exist because the defaults are ugly and confusing):
- Always include a title, axis labels, and units
- Use `tight_layout()` and `bbox_inches='tight'` — cut-off labels are the #1 chart complaint
- Format numbers for humans: use commas, dollar signs, percentage signs as appropriate
- Rotate x-axis labels at 45° if they overlap
- Use color meaningfully: a single-series bar chart doesn't need a rainbow
- Limit to 2-3 charts per report — more charts ≠ more insight
- Save as PNG at 150 DPI — good balance of quality and file size

**Chart type selection:**
| Data pattern | Chart type |
|---|---|
| Trend over time | Line chart |
| Category comparison | Horizontal bar chart |
| Parts of a whole | Pie chart (≤6 slices) or stacked bar |
| Distribution | Histogram |
| Two variables | Scatter plot |

### Report Structure

Write the report in Markdown. Use this template:

```markdown
# [Report Title]

**Data source:** [filename] | **Records:** [count] | **Period:** [date range if applicable]

## Key Findings

- [Top 3-5 bullet points with the most important insights]
- [Include actual numbers — "Revenue grew 23% from Q1 to Q4" not "Revenue grew"]

## Summary

[2-3 sentence overview of what the data shows]

| Metric | Value |
|--------|-------|
| Total Records | X |
| [Key Measure] Total | $X |
| [Key Measure] Average | $X |

## [Analysis Section 1 — e.g., "Revenue by Region"]

[Brief context sentence]

![Chart](chart_name.png)

| [Dimension] | [Measure] | % of Total |
|-------------|-----------|------------|
| ... | ... | ... |

## [Analysis Section 2 — e.g., "Monthly Trend"]

[Brief context sentence]

![Chart](chart_name_2.png)

[Key observations about the trend]

## Notes

- [Data quality issues, if any]
- [Assumptions made]
- [Caveats about the analysis]
```

**Report writing guidance:**
- Lead with insights, not methodology. "Sales peaked in Q3 at $2.1M" beats "I used pandas to calculate quarterly totals."
- Every chart needs a text callout explaining what to notice — don't make the reader interpret alone
- Include a "Notes" section for caveats: missing data, assumptions, data quality issues
- Tables should be sorted meaningfully (by value descending, or chronologically)
- Include percentage-of-total columns where they add context

### Output Files

Save these files to the output directory:
1. `report.md` — the full Markdown report
2. `*.png` — chart image files (referenced in the report)
3. `summary.csv` — the pivoted/aggregated data as a CSV (useful for downstream work)

## Handling Ambiguity

If the user's request is vague (e.g., "make a report from this"), don't ask a bunch of clarifying questions — just generate the best report you can from the data profile. You can always refine in a follow-up. A good-enough report now beats a perfect report after 5 rounds of questions.

If the CSV has 20+ columns, focus on the 3-5 most interesting relationships rather than trying to cover everything. Mention the other columns exist in the Notes section.

## Common Pitfalls

- **Don't display raw DataFrames as output.** Always format as Markdown tables or save as CSV.
- **Don't ignore dates.** If there's a date column, there's almost certainly a time-based trend worth showing.
- **Don't forget to close plots.** Always call `plt.close()` after saving — open figures leak memory.
- **Don't use pie charts for more than 6 categories.** They become unreadable. Use a bar chart instead.
- **Don't produce a 20-page report.** 2-4 focused analyses are better than 10 shallow ones. If the user wants more depth, they'll ask.
