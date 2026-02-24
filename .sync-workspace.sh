#!/bin/bash
# Daily workspace sync script
# Commits all changes, tags with timestamp, pushes to remote
# Detects merge conflicts and notifies instead of forcing resolution

set -e

WORKSPACE_DIR="/Users/simonmarek/.openclaw/workspace"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
TAG_NAME="sync-${TIMESTAMP}"
LOG_FILE="/tmp/openclaw-sync-${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

cd "$WORKSPACE_DIR"

log "🦞 Starting workspace sync at $(date)"
log ""

# Check if we're in a git repo
if [ ! -d ".git" ]; then
    log "${RED}❌ Error: Not a git repository${NC}"
    exit 1
fi

# Fetch latest from remote to detect conflicts early
log "📥 Fetching latest changes from remote..."
if ! git fetch origin main 2>&1 | tee -a "$LOG_FILE"; then
    log "${RED}❌ Failed to fetch from remote${NC}"
    exit 1
fi

# Check for merge conflicts before committing
log "🔍 Checking for potential conflicts..."
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main 2>/dev/null || echo "")

if [ -n "$REMOTE_COMMIT" ] && [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    # Check if local is behind remote
    if git merge-base --is-ancestor HEAD origin/main; then
        log "${YELLOW}⚠️  Local is behind remote. Attempting to merge...${NC}"
        
        # Try to merge
        if ! git merge origin/main --no-edit 2>&1 | tee -a "$LOG_FILE"; then
            log ""
            log "${RED}❌ MERGE CONFLICT DETECTED${NC}"
            log ""
            log "The workspace sync cannot proceed automatically because there are"
            log "conflicts between local changes and remote changes."
            log ""
            log "Files with conflicts:"
            git diff --name-only --diff-filter=U | tee -a "$LOG_FILE"
            log ""
            log "Please resolve conflicts manually:"
            log "  1. cd $WORKSPACE_DIR"
            log "  2. Resolve conflicts in the files listed above"
            log "  3. git add ."
            log "  4. git commit -m 'Resolved merge conflicts'"
            log "  5. git push"
            log ""
            log "Or, to discard local changes and use remote:"
            log "  git reset --hard origin/main"
            log ""
            
            # Send notification (this will be picked up by OpenClaw)
            echo "MERGE_CONFLICT: Workspace sync failed due to merge conflicts. Check $LOG_FILE for details."
            exit 1
        fi
        
        log "${GREEN}✅ Successfully merged remote changes${NC}"
    fi
fi

# Check if there are any changes to commit
if git diff --quiet HEAD && git diff --cached --quiet HEAD; then
    log "${GREEN}✓ No changes to commit${NC}"
    log "🦞 Sync complete at $(date) - nothing to push"
    exit 0
fi

# Stage all changes
log "📦 Staging changes..."
git add -A

# Commit with timestamp
log "💾 Committing changes..."
COMMIT_MSG="Auto-sync: ${TIMESTAMP}"
if ! git commit -m "$COMMIT_MSG" 2>&1 | tee -a "$LOG_FILE"; then
    log "${RED}❌ Failed to commit changes${NC}"
    exit 1
fi

log "${GREEN}✅ Committed: $COMMIT_MSG${NC}"

# Tag with timestamp
log "🏷️  Creating tag: $TAG_NAME"
if ! git tag -a "$TAG_NAME" -m "Workspace sync at ${TIMESTAMP}" 2>&1 | tee -a "$LOG_FILE"; then
    log "${YELLOW}⚠️  Warning: Failed to create tag${NC}"
fi

# Push commit and tags
log "🚀 Pushing to remote..."
if ! git push origin main 2>&1 | tee -a "$LOG_FILE"; then
    log "${RED}❌ Failed to push to remote${NC}"
    exit 1
fi

if ! git push origin "$TAG_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    log "${YELLOW}⚠️  Warning: Failed to push tag${NC}"
fi

log ""
log "${GREEN}✅ Sync complete!${NC}"
log "   Commit: $COMMIT_MSG"
log "   Tag: $TAG_NAME"
log "   Time: $(date)"
log ""
log "🦞 Workspace synced to https://github.com/simonmarek/openclaw-workspace"

exit 0
