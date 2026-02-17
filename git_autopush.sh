#!/bin/bash

# Check if a commit message is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 \"Your commit message\""
  exit 1
fi

COMMIT_MESSAGE="$1"

# Get current branch name
CURRENT_BRANCH=$(git branch --show-current)

# Pull latest changes first (handles Cloudflare auto-commits)
echo "Pulling latest changes from $CURRENT_BRANCH..."
git pull origin "$CURRENT_BRANCH" --rebase

# Add all changes (excluding generated files)
git add . ':!scripts/generated-routes.json' ':!.svelte-kit/'

# Commit if there are changes
if git diff --staged --quiet; then
  echo "No changes to commit"
else
  git commit -m "$COMMIT_MESSAGE"
fi

# Push to current branch
echo "Pushing to origin/$CURRENT_BRANCH..."
git push origin "$CURRENT_BRANCH"

echo "Changes added, committed, and pushed to $CURRENT_BRANCH successfully!"

