---
name: vibecode-integration-github
description: >
  GitHub integration via the gh CLI and REST/GraphQL API.
  Consult this skill:
  1. When the user asks to manage repositories, issues, or pull requests
  2. When the user needs to check CI/CD status, releases, or Actions workflows
  3. When the user wants to search code, create gists, or manage GitHub settings
  4. When the user mentions repos, PRs, issues, commits, or GitHub
metadata: {"openclaw": {"emoji": "🐙", "requires": {"env": ["GITHUB_TOKEN"]}}}
---

# GitHub Integration

Full GitHub access via `gh` CLI (preferred) and REST/GraphQL APIs.

**Auth**: `GITHUB_TOKEN` env var from Nango (User OAuth).

## Setup (run once per session)

```bash
# Authenticate gh CLI with the token
echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null
gh auth status
```

After this, all `gh` commands work without additional auth.

## Issues

```bash
# List issues
gh issue list --repo owner/repo --state open --limit 20

# Create issue
gh issue create --repo owner/repo --title "Bug: login fails" --body "Steps to reproduce..." --label bug

# View issue
gh issue view 42 --repo owner/repo

# Close issue
gh issue close 42 --repo owner/repo

# Search issues across repos
gh search issues "login error" --owner myorg --state open --limit 10

# Add comment
gh issue comment 42 --repo owner/repo --body "Fixed in #45"
```

## Pull requests

```bash
# List PRs
gh pr list --repo owner/repo --state open

# Create PR
gh pr create --repo owner/repo --title "Fix login bug" --body "Closes #42" --base main --head fix/login

# View PR (with diff stats)
gh pr view 45 --repo owner/repo

# Review PR
gh pr review 45 --repo owner/repo --approve --body "LGTM"

# Merge PR
gh pr merge 45 --repo owner/repo --squash --delete-branch

# Check PR CI status
gh pr checks 45 --repo owner/repo

# List PR files changed
gh pr diff 45 --repo owner/repo --stat
```

## Repositories

```bash
# List repos
gh repo list myorg --limit 20

# View repo info
gh repo view owner/repo

# Clone repo
gh repo clone owner/repo

# Create repo
gh repo create myorg/new-repo --private --description "Project description"

# Search repos
gh search repos "machine learning" --language python --sort stars --limit 10
```

## Actions & CI

```bash
# List workflow runs
gh run list --repo owner/repo --limit 10

# View specific run
gh run view RUN_ID --repo owner/repo

# View run logs
gh run view RUN_ID --repo owner/repo --log

# Re-run failed workflow
gh run rerun RUN_ID --repo owner/repo

# List workflows
gh workflow list --repo owner/repo

# Trigger workflow dispatch
gh workflow run deploy.yml --repo owner/repo --ref main -f environment=production
```

## Releases & tags

```bash
# List releases
gh release list --repo owner/repo --limit 10

# Create release
gh release create v1.0.0 --repo owner/repo --title "v1.0.0" --notes "Release notes" --target main

# Download release assets
gh release download v1.0.0 --repo owner/repo --pattern "*.tar.gz"
```

## Gists

```bash
# Create gist
gh gist create file.py --desc "Utility script" --public

# List gists
gh gist list --limit 10

# View gist
gh gist view GIST_ID
```

## Code search

```bash
# Search code
gh search code "TODO fixme" --repo owner/repo --limit 20

# Search across org
gh search code "api_key" --owner myorg --language python
```

## REST API (for anything gh doesn't cover)

```bash
# Generic API call
gh api repos/owner/repo/commits --jq '.[0].sha'

# With pagination
gh api repos/owner/repo/issues --paginate --jq '.[].title'

# POST request
gh api repos/owner/repo/issues -f title="New issue" -f body="Description"

# GraphQL
gh api graphql -f query='{ viewer { login repositories(first: 5) { nodes { name stargazerCount } } } }'
```

## Tips

- **`--repo owner/repo`** targets any repo without cloning. Omit if inside a cloned repo.
- **`--json field1,field2 --jq '...'`** for structured output on most commands.
- **`gh api`** covers any GitHub API endpoint not wrapped by a built-in command.
- **`gh help <command>`** for usage details on any command.
- **The user may say "repo" or "PR"** without mentioning GitHub — infer from context.
- **Rate limit**: 5,000 requests/hour for authenticated users. Check with `gh api rate_limit`.

---

*Based on [gh CLI manual](https://cli.github.com/manual/), [steipete/github skill](https://clawhub.ai/steipete/github), and [GitHub REST API docs](https://docs.github.com/en/rest).*
