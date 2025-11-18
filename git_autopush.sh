#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 \"Your commit message\""
  exit 1
fi

COMMIT_MESSAGE="$1"
CURRENT_BRANCH=$(git branch --show-current)

git add .
git commit -m "$COMMIT_MESSAGE"
git push origin "$CURRENT_BRANCH"

echo "Changes added, committed, and pushed to branch: $CURRENT_BRANCH"

