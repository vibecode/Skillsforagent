# Skill Design Notes: csv-report

## Skill Name
`csv-report`

## Description
Generate summary reports from CSV files — including data profiling, pivot tables, and charts. Handles schema detection, aggregation, and visualization automatically.

## Architecture Decision: Python
- **pandas** for data manipulation (read_csv, pivot_table, describe)
- **matplotlib** for chart generation (save as PNG)
- **jinja2** for HTML report templating
- All are standard, well-supported, installable via pip

Why not Node? pandas is dramatically better for pivot tables and data wrangling. The agent runs shell commands anyway, so Python scripts are fine.

## Skill Structure
```
csv-report/
├── SKILL.md              # Instructions for the agent
├── scripts/
│   ├── requirements.txt  # Python dependencies
│   ├── setup.sh          # One-time setup script
│   ├── analyze_csv.py    # Schema detection & profiling
│   ├── pivot_csv.py      # Pivot table generation
│   ├── chart_csv.py      # Chart generation
│   └── report_csv.py     # Full report pipeline (combines above)
└── templates/
    └── report.html       # Jinja2 HTML report template
```

## Agent Workflow (as described in SKILL.md)
1. Agent receives user request with a CSV file path
2. Agent runs `analyze_csv.py` to profile the data → gets JSON schema + stats
3. Agent decides pivot dimensions and metrics (using its reasoning + user hints)
4. Agent runs `report_csv.py` with chosen parameters → gets HTML report + chart PNG
5. Agent shares the output with the user

## Key Design Choices
- **Scripts return JSON to stdout** so the agent can parse results and reason about them
- **SKILL.md tells the agent HOW to think**, not just what commands to run
- **Auto-detection heuristics**: numeric columns → metrics, low-cardinality strings → dimensions
- **The agent remains in the loop** — it decides what to pivot, the scripts execute
