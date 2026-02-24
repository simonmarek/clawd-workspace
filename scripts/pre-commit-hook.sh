#!/bin/bash
# Pre-commit hook to prevent sensitive data from being committed
# Copy this file to .git/hooks/pre-commit and make it executable

set -e

echo "🔒 Running pre-commit security checks..."

# Patterns to detect sensitive data
SENSITIVE_PATTERNS=(
    # Session tokens and cookies
    "session[_-]?token"
    "auth[_-]?token"
    "access[_-]?token"
    "refresh[_-]?token"
    "cookie[_-]?secret"
    "session[_-]?secret"
    "jwt[_-]?secret"
    
    # Browser profile data
    "chrome[_-]?profile"
    "firefox[_-]?profile"
    "safari[_-]?profile"
    "Cookies\\.sqlite"
    "Login Data"
    "Web Data"
    
    # Private keys
    "-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----"
    "-----BEGIN (RSA |DSA |EC |OPENSSH )?ENCRYPTED PRIVATE KEY-----"
    
    # API keys and secrets
    "api[_-]?key"
    "apikey"
    "secret[_-]?key"
    "private[_-]?key"
    "password"
    "passwd"
    
    # OpenClaw specific
    "OPENCLAW_SESSION"
    "GATEWAY_TOKEN"
    "DISCORD_TOKEN"
    "TELEGRAM_BOT_TOKEN"
)

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

# Check each staged file
for file in $STAGED_FILES; do
    # Skip binary files
    if file "$file" | grep -q "text"; then
        for pattern in "${SENSITIVE_PATTERNS[@]}"; do
            if git show :"$file" | grep -iE "$pattern" > /dev/null 2>&1; then
                echo ""
                echo "❌ SECURITY ALERT: Potential sensitive data detected in $file"
                echo "   Pattern matched: $pattern"
                echo ""
                echo "   This file may contain:"
                echo "   - Session tokens or cookies"
                echo "   - API keys or secrets"
                echo "   - Browser profile data"
                echo "   - Private keys"
                echo ""
                echo "   If this is a false positive, use: git commit --no-verify"
                echo "   Otherwise, remove the sensitive data before committing."
                exit 1
            fi
        done
    fi
done

echo "✅ Security checks passed"
exit 0
