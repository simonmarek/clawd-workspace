#!/bin/bash
# gateway-security-check.sh - Weekly gateway security verification
# Run via cron: 0 2 * * 0 /Users/simonmarek/.openclaw/workspace/scripts/gateway-security-check.sh

set -e

WORKSPACE="/Users/simonmarek/.openclaw/workspace"
REPORT_FILE="$WORKSPACE/logs/gateway-security-$(date +%Y%m%d).md"

mkdir -p "$WORKSPACE/logs"

echo "=== Gateway Security Check $(date) ===" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Check if gateway config exists
CONFIG_PATH="$HOME/.openclaw/config.json"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "ℹ️ No gateway config found at $CONFIG_PATH - skipping" >> "$REPORT_FILE"
    exit 0
fi

echo "## Gateway Configuration Review" >> "$REPORT_FILE"

# Check localhost binding (critical)
if grep -q '"host".*"127.0.0.1\|"localhost"' "$CONFIG_PATH" 2>/dev/null; then
    echo "✅ Gateway bound to localhost only" >> "$REPORT_FILE"
else
    echo "🚨 WARNING: Gateway may be exposed to network" >> "$REPORT_FILE"
    echo "   Verify 'host' is set to '127.0.0.1' or 'localhost'" >> "$REPORT_FILE"
fi

# Check authentication enabled
if grep -q '"auth".*true' "$CONFIG_PATH" 2>/dev/null || grep -q '"apiKey"' "$CONFIG_PATH" 2>/dev/null; then
    echo "✅ Authentication appears enabled" >> "$REPORT_FILE"
else
    echo "⚠️ WARNING: Authentication may be disabled" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "Check completed at $(date)" >> "$REPORT_FILE"
