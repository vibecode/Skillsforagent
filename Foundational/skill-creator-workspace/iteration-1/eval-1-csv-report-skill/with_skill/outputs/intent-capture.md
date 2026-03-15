# Intent Capture: CSV Report Skill

## Source
User described a recurring workflow they perform manually every time someone asks for a report from a CSV file.

## Workflow Steps (extracted from user description)
1. **Read the CSV file** — parse the file, understand columns and data types
2. **Pivot the data** — aggregate/group/summarize based on what the report needs
3. **Make a chart** — visualize the pivoted data as a chart (bar, line, pie, etc.)
4. **Generate a report** — combine the summary stats and chart into a deliverable

## What should this skill enable?
An agent should be able to take any CSV file and a user's request (e.g., "generate a sales report from this CSV") and produce a complete report with:
- Summary statistics
- Pivoted/aggregated data tables
- One or more charts
- A clean, readable output (Markdown report + chart images, or HTML)

## When should it trigger?
- User provides a CSV and asks for a "report," "analysis," "summary," or "dashboard"
- User says "pivot this data," "chart this CSV," "analyze this spreadsheet"
- User has a CSV and wants insights, trends, breakdowns, or visualizations

## Expected output format
- A Markdown report (with embedded chart images) or a standalone HTML report
- Chart images saved as PNG files
- Summary data tables in the report body

## Edge cases to handle
- CSV with messy headers (spaces, mixed case)
- Large CSVs (thousands of rows)
- Missing/null values
- Dates that need parsing
- User doesn't specify what to pivot by — skill should guide the agent to infer or ask
- Multiple possible chart types — skill should pick appropriate defaults

## Dependencies
- Python 3 with pandas, matplotlib (standard data science stack)
- No external API keys needed

## Test cases: Yes
Outputs are objectively verifiable (chart exists, correct aggregations, report structure).
