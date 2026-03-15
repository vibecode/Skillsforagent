# Requirements Analysis: CSV Report Skill

## User Request
> "I've been doing this same workflow every time someone asks me to generate a report from a CSV — reading the file, pivoting the data, making a chart. Can we turn this into a reusable skill so any agent on our platform can do it?"

## Identified Workflow Steps
1. **Read a CSV file** — parse the file, understand its schema (columns, types, row count)
2. **Pivot/aggregate the data** — group by dimensions, compute metrics (sum, avg, count, etc.)
3. **Generate a chart** — visualize the pivoted data as a chart (bar, line, pie, etc.)
4. **Produce a report** — combine the summary statistics, pivot table, and chart into a deliverable

## Implicit Requirements
- The skill should work with **any CSV**, not just a specific schema
- The agent needs to **infer** appropriate pivot dimensions and metrics from the data
- Chart type should be chosen intelligently based on data shape
- Output should be shareable (HTML file, image, or both)
- Should handle common CSV issues: missing values, mixed types, encoding

## Constraints & Decisions
- **Runtime environment**: Linux container with Node.js available; Python likely available or installable
- **Charting library**: Need something that works headlessly — options include:
  - Python: matplotlib, plotly (generates HTML), seaborn
  - Node: chart.js via canvas, or generate HTML with embedded chart.js
- **Data processing**: pandas (Python) is the gold standard for pivot tables
- **Output format**: HTML report with embedded chart is most portable

## Skill Scope
The skill should handle:
- Single CSV → summary report with pivot table and chart
- User can optionally specify: pivot columns, metric columns, aggregation, chart type
- If not specified, the agent should auto-detect reasonable defaults

## Out of Scope (v1)
- Multi-file joins
- Real-time/streaming data
- Database connections
- Interactive dashboards
