#!/bin/bash
# security-checks.sh - Automated security monitoring for OpenClaw workspace
# Run via cron: 0 3 * * * /Users/simonmarek/.openclaw/workspace/scripts/security-checks.sh

set -e

WORKSPACE="/Users/simonmarek/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/security-$(date +%Y%m%d).log"
REPORT_FILE="$WORKSPACE/logs/security-report-$(date +%Y%m%d).md"
ALERT_THRESHOLD=500  # MB

mkdir -p "$WORKSPACE/logs"
mkdir -p "$WORKSPACE/security/incidents"

echo "=== Security Check $(date) ===" | tee -a "$LOG_FILE"

# 1. Repo Size Check (Data Leak Detection)
echo "[CHECK] Repository size..." | tee -a "$LOG_FILE"
REPO_SIZE_MB=$(du -sm "$WORKSPACE" | cut -f1)
if [ "$REPO_SIZE_MB" -gt "$ALERT_THRESHOLD" ]; then
    echo "⚠️ ALERT: Repository size ${REPO_SIZE_MB}MB exceeds threshold (${ALERT_THRESHOLD}MB)" | tee -a "$REPORT_FILE"
    echo "   Possible data leak or binary blob accumulation" | tee -a "$REPORT_FILE"
fi

# 2. Scan for hardcoded credentials in code
echo "[CHECK] Hardcoded credentials..." | tee -a "$LOG_FILE"
SUSPICIOUS=$(find "$WORKSPACE" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.sh" -o -name "*.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | xargs grep -l -i "api_key\|apikey\|password\|secret\|token\|bearer" 2>/dev/null || true)
if [ -n "$SUSPICIOUS" ]; then
    echo "⚠️ WARNING: Files containing potential credential patterns:" | tee -a "$REPORT_FILE"
    echo "$SUSPICIOUS" | tee -a "$REPORT_FILE"
fi

# 3. Check .env files aren't committed
echo "[CHECK] .env file protection..." | tee -a "$LOG_FILE"
if git -C "$WORKSPACE" ls-files 2>/dev/null | grep -q "\.env"; then
    echo "🚨 CRITICAL: .env files found in git index!" | tee -a "$REPORT_FILE"
fi

# 4. Check for large/unexpected files
echo "[CHECK] Large files (>10MB)..." | tee -a "$LOG_FILE"
find "$WORKSPACE" -type f -size +10M -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | while read -r file; do
    echo "⚠️ Large file detected: $file ($(du -h "$file" | cut -f1))" | tee -a "$REPORT_FILE"
done

# 5. Memory file scan for injection patterns
echo "[CHECK] Memory files for suspicious patterns..." | tee -a "$LOG_FILE"
if [ -d "$WORKSPACE/memory" ]; then
    INJECTION_SIGNS=$(find "$WORKSPACE/memory" -type f -name "*.md" 2>/dev/null | xargs grep -l -i "system prompt\|ignore previous instruction\|you are now\|disregard" 2>/dev/null || true)
    if [ -n "$INJECTION_SIGNS" ]; then
        echo "🚨 ALERT: Potential prompt injection signs in:" | tee -a "$REPORT_FILE"
        echo "$INJECTION_SIGNS" | tee -a "$REPORT_FILE"
    fi
fi

# Generate summary
if [ -f "$REPORT_FILE" ]; then
    echo "" | tee -a "$REPORT_FILE"
    echo "---" | tee -a "$REPORT_FILE"
    echo "Review needed. Check full log at: $LOG_FILE" | tee -a "$REPORT_FILE"
else
    echo "✅ All security checks passed" | tee -a "$REPORT_FILE"
fi

echo "Security check complete. Report: $REPORT_FILE"
