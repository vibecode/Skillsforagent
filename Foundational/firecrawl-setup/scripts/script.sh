#!/usr/bin/env bash
# Firecrawl CLI + Official Skill installer
# Installs firecrawl-cli, authenticates via FIRECRAWL_API_KEY, and installs the
# official Firecrawl skill (from firecrawl/cli) for all detected AI coding agents.
set -euo pipefail

echo "🔥 Firecrawl Setup"
echo "=================="

# 1. Check Node.js
if ! command -v node &>/dev/null; then
  echo "❌ Node.js not found. Install Node.js first."
  exit 1
fi

# 2. Install firecrawl-cli globally
echo ""
echo "📦 Installing firecrawl-cli..."
if command -v firecrawl &>/dev/null; then
  CURRENT_VER=$(firecrawl --version 2>/dev/null || echo "unknown")
  echo "   Currently installed: $CURRENT_VER — upgrading to latest..."
fi
npm install -g firecrawl-cli@latest 2>&1 | tail -1
echo "   ✅ Installed: $(firecrawl --version 2>/dev/null || echo 'firecrawl-cli')"

# 3. Authenticate
echo ""
echo "🔑 Authenticating..."
if [ -n "${FIRECRAWL_API_KEY:-}" ]; then
  echo "   Using FIRECRAWL_API_KEY environment variable"
  firecrawl login --api-key "$FIRECRAWL_API_KEY" 2>/dev/null && echo "   ✅ Authenticated" || echo "   ⚠️  Login command failed, but env var will still work at runtime"
else
  echo "   ⚠️  FIRECRAWL_API_KEY not set."
  echo "   Set it:   export FIRECRAWL_API_KEY=fc-YOUR-KEY"
  echo "   Or run:   firecrawl login --browser"
fi

# 4. Install the official Firecrawl skill for all detected agents
#    This is REQUIRED — it provides the actual CLI reference, workflows, and security rules.
echo ""
echo "🎯 Installing official Firecrawl skill for all agents..."
echo "   ⚠️  This step is REQUIRED — do not skip it."
echo "   The official skill (firecrawl/cli) contains the CLI reference and workflow patterns."
npx -y skills add firecrawl/cli --all 2>&1 || echo "   ⚠️  Skill install step had issues (may already be installed)"

# 5. Verify
echo ""
echo "✅ Verifying..."
firecrawl --status 2>/dev/null || echo "   Run 'firecrawl --status' to verify manually"

echo ""
echo "🔥 Done! The official Firecrawl skill is now installed."
echo "   Restart your agent/editor for skill discovery."
echo "   Try: firecrawl https://example.com --only-main-content"
