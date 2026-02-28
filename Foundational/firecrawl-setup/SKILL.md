---
name: firecrawl-setup
description: >
  Install and configure the Firecrawl CLI and its official skill for AI agents. Use this
  skill when: (1) setting up Firecrawl for the first time, (2) installing the firecrawl-cli
  npm package, (3) authenticating Firecrawl with an API key, (4) deploying the official
  Firecrawl skill to detected AI coding agents, (5) troubleshooting Firecrawl installation
  or auth issues. This is a bootstrap/setup skill — once installed, the official Firecrawl
  skill (from firecrawl/cli) handles all scraping, searching, crawling, and browser automation.
metadata: {"openclaw": {"emoji": "🔥", "requires": {"env": ["FIRECRAWL_API_KEY"]}, "primaryEnv": "FIRECRAWL_API_KEY"}}
---

# Firecrawl Setup

Bootstrap skill that installs the Firecrawl CLI and the **official Firecrawl skill** for all detected AI coding agents. After setup, the official skill handles all web scraping, searching, crawling, and browser automation.

> **⚠️ IMPORTANT: This skill only handles SETUP. You MUST complete ALL steps below — especially step 3 (installing the official skill). Do NOT skip it. The official Firecrawl skill (`firecrawl/cli`) contains the actual CLI reference, workflow patterns, and usage instructions you need for scraping, searching, crawling, and browser automation. Without it, you're flying blind.**

## What Gets Installed

1. **`firecrawl-cli`** — npm package providing the `firecrawl` command
2. **Official Firecrawl skill** — from `firecrawl/cli` via the `skills` registry, with full CLI reference, workflow patterns, security guidelines, and installation rules. **This is NOT optional — install it.**

## Quick Setup

### One-Liner (Recommended)

```bash
bash scripts/setup.sh
```

This runs all steps automatically: install CLI → authenticate → install official skill for all agents.

### One-Liner Alternative (Interactive, Opens Browser for Auth)

```bash
npx -y firecrawl-cli@latest init --browser --all
```

### Manual Steps

**All 4 steps are required. Do not skip step 3.**

```bash
# 1. Install CLI globally
npm install -g firecrawl-cli@latest

# 2. Authenticate (pick one)
export FIRECRAWL_API_KEY="fc-YOUR-API-KEY"           # env var (recommended for agents)
firecrawl login --api-key "fc-YOUR-API-KEY"           # store in CLI config
firecrawl login --browser                             # browser OAuth

# 3. ⚠️ REQUIRED: Install official Firecrawl skill for all agents
#    This installs the REAL usage skill with CLI reference, workflows, and security rules.
#    Without this, you only have the CLI binary but no skill guidance for using it properly.
npx -y skills add firecrawl/cli --all

# 4. Verify
firecrawl --status
```

Expected output when ready:

```
  🔥 firecrawl cli v1.x.x

  ● Authenticated via FIRECRAWL_API_KEY
  Concurrency: 0/100 jobs (parallel scrape limit)
  Credits: 500,000 remaining
```

## Authentication

The CLI reads `FIRECRAWL_API_KEY` env var automatically — no login step needed if the var is set.

| Method | Command | Notes |
|--------|---------|-------|
| Env var | `export FIRECRAWL_API_KEY=fc-...` | Best for agents, no interactive step |
| CLI login | `firecrawl login --api-key fc-...` | Stores in `~/.config/firecrawl/` |
| Browser OAuth | `firecrawl login --browser` | Opens browser, interactive |
| Self-hosted | `firecrawl --api-url http://localhost:3002` | No API key needed |

Check config: `firecrawl view-config`
Check status: `firecrawl --status`
Clear credentials: `firecrawl logout`

## Troubleshooting

### `firecrawl: command not found`

```bash
# Ensure npm global bin is in PATH
export PATH="$(npm bin -g):$PATH"
# Or use npx
npx firecrawl-cli --version
# Reinstall
npm install -g firecrawl-cli@latest
```

### Authentication failures

```bash
# Check current auth status
firecrawl --status
# Re-authenticate
firecrawl login --api-key "$FIRECRAWL_API_KEY"
# Or clear and retry
firecrawl logout
export FIRECRAWL_API_KEY="fc-YOUR-KEY"
firecrawl --status
```

### Skill not detected by agent

After installing the skill, restart your agent or editor for skill discovery to kick in.

```bash
# Verify skill is installed
npx -y skills list
# Reinstall if needed
npx -y skills add firecrawl/cli --all
```

## After Setup

> **Setup is NOT complete until the official Firecrawl skill is installed.** If you only installed the CLI and authenticated but skipped `npx -y skills add firecrawl/cli --all`, go back and run it now. The official skill contains the workflow patterns, command reference, and security guidelines you need.

Once installed, the **official Firecrawl skill** provides complete instructions for:

- **Scraping** — `firecrawl https://url --only-main-content`
- **Searching** — `firecrawl search "query" --scrape --limit 10`
- **Mapping** — `firecrawl map https://url --search "keyword"`
- **Crawling** — `firecrawl crawl https://url --wait --progress`
- **Agent** — `firecrawl agent "extract data" --wait`
- **Browser** — `firecrawl browser "open https://url"` → `"snapshot"` → `"click @ref"` → `"scrape"`

This setup skill's job is done once `firecrawl --status` shows authenticated. The official skill takes over from there.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `FIRECRAWL_API_KEY` | API key (required) |
| `FIRECRAWL_API_URL` | Custom API URL for self-hosted (optional) |
| `FIRECRAWL_NO_TELEMETRY=1` | Disable anonymous telemetry (optional) |
