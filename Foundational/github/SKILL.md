---
name: github
description: GitHub via the `gh` CLI — repos, issues, PRs, search, Actions, releases, gists, and the API.
metadata: {"openclaw": {"emoji": "🐙", "requires": {"bins": ["gh"], "env": ["GITHUB_TOKEN"]}}}
---

# GitHub

Use `gh` for all GitHub operations. Auth is automatic via `GITHUB_TOKEN` — no login needed.

Tips:
- `--repo owner/repo` targets any repo without cloning
- `--json field1,field2 --jq '...'` for structured output
- `gh api <endpoint>` for anything not covered by built-in commands
- `gh help <command>` for usage details
