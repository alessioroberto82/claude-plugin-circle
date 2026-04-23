#!/bin/bash
# Circle — Dependency Update Script
# Updates all Circle ecosystem components in one shot.
#
# Usage: bash update-deps.sh
#
# Components managed:
#   - Claude plugins (marketplace + installed)
#   - npm global packages (bmad-mcp)
#   (iOS/Swift deps — including Cupertino — moved to companion plugin circle-ios in v2.0.0)
#   - circle plugin (git pull if remote exists)

set -euo pipefail

echo "=== Circle Dependencies Update ==="
echo ""

# 1. Plugin marketplace — update indexes
echo "→ Updating marketplace indexes..."
claude plugin marketplace update claude-plugins-official 2>/dev/null || echo "  ⚠ claude-plugins-official: update failed (may not be registered)"
claude plugin marketplace update thedotmack 2>/dev/null || echo "  ⚠ thedotmack: update failed"
echo ""

# 2. Plugins — update installed ones
echo "→ Updating plugins..."
claude plugin update claude-mem@thedotmack 2>/dev/null || echo "  ⚠ claude-mem: update failed"
claude plugin update Notion@claude-plugins-official 2>/dev/null || echo "  ⚠ Notion: update failed"
# code-review, feature-dev, github auto-update (Anthropic official)
echo ""

# 3. npm globals
echo "→ Updating npm global packages..."
npm install -g bmad-mcp 2>/dev/null && echo "  bmad-mcp: updated" || echo "  ⚠ bmad-mcp: update failed (try with sudo)"
echo ""

# iOS / Swift development deps moved to the `circle-ios` companion plugin
# as of v2.0.0. Update those via: claude plugin update circle-ios@circle
# (companion plugin carries its own updater instructions in its deps-manifest.yaml).

# 4. circle plugin (if it has a remote)
CIRCLE_DIR="${CIRCLE_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"}"
if [ -d "$CIRCLE_DIR/.git" ]; then
    REMOTE=$(cd "$CIRCLE_DIR" && git remote -v 2>/dev/null | head -1)
    if [ -n "$REMOTE" ]; then
        echo "→ Updating circle plugin..."
        (cd "$CIRCLE_DIR" && git pull)
    else
        echo "→ circle: local only (no remote configured)"
    fi
else
    echo "→ circle: not a git repository"
fi

echo ""
echo "=== Update complete ==="
