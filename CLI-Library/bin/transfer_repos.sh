#!/bin/bash

# Configuration
TARGET_ORG="patraldo-dev"             # Target organization (CHANGE THIS)
PREFIX="migrated-"                  # Prefix for renamed repos (optional)
LOG_FILE="transfer.log"             # Log file for tracking
DELAY=5                             # Seconds between transfers (avoid rate limits)
ORGS_FILE="orgs.txt"               # File containing list of source orgs

# Initialize log
echo "Starting repository transfer at $(date)" > "$LOG_FILE"

# Get current username
USERNAME=$(gh api user --jq '.login')
echo "Authenticated as: $USERNAME" | tee -a "$LOG_FILE"

# Check GitHub CLI authentication scopes
echo "Checking GitHub CLI authentication scopes..." | tee -a "$LOG_FILE"

# Get the full scope string properly
SCOPES_LINE=$(gh auth status --show-token 2>&1 | grep "Token scopes:")
SCOPES=$(echo "$SCOPES_LINE" | sed "s/.*Token scopes: //; s/'//g")
echo "Current scopes: $SCOPES" | tee -a "$LOG_FILE"

# Check if required scopes are present
if [[ ! "$SCOPES" =~ "admin:org" ]] || [[ ! "$SCOPES" =~ "repo" ]]; then
    echo "❌ ERROR: Missing required scopes. Need 'admin:org' and 'repo'" | tee -a "$LOG_FILE"
    echo "Run: gh auth login --scopes 'admin:org,repo'" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Authentication and scopes verified successfully" | tee -a "$LOG_FILE"

# Read source organizations from file
if [ ! -f "$ORGS_FILE" ]; then
    echo "❌ ERROR: Organizations file not found: $ORGS_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Read organizations from file, excluding the target org and empty lines
SOURCE_ORGS=()
while IFS= read -r org; do
    # Skip empty lines and the target organization
    if [[ -n "$org" && "$org" != "$TARGET_ORG" ]]; then
        SOURCE_ORGS+=("$org")
    fi
done < "$ORGS_FILE"

if [ ${#SOURCE_ORGS[@]} -eq 0 ]; then
    echo "❌ ERROR: No source organizations found in $ORGS_FILE (after excluding target: $TARGET_ORG)" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Found ${#SOURCE_ORGS[@]} source organizations to process:" | tee -a "$LOG_FILE"
for org in "${SOURCE_ORGS[@]}"; do
    echo "  - $org" | tee -a "$LOG_FILE"
done

# Verify ownership of target organization
echo "Verifying target organization ownership..." | tee -a "$LOG_FILE"
TARGET_ROLE=$(gh api "orgs/$TARGET_ORG/memberships/$USERNAME" --jq '.role' 2>/dev/null)
if [ "$TARGET_ROLE" != "admin" ]; then
    echo "❌ ERROR: You must be an OWNER of $TARGET_ORG to receive repositories." | tee -a "$LOG_FILE"
    echo "Your current role: $TARGET_ROLE" | tee -a "$LOG_FILE"
    exit 1
fi
echo "✅ Confirmed: Owner of $TARGET_ORG" | tee -a "$LOG_FILE"

# Loop through each source organization
for SOURCE_ORG in "${SOURCE_ORGS[@]}"; do
    echo "Processing organization: $SOURCE_ORG" | tee -a "$LOG_FILE"

    # Get all repositories in the source org
    REPOS=$(gh repo list "$SOURCE_ORG" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')

    if [ -z "$REPOS" ]; then
        echo "No repositories found in $SOURCE_ORG" | tee -a "$LOG_FILE"
        continue
    fi

    # Transfer each repository
    for REPO in $REPOS; do
        REPO_NAME=$(basename "$REPO")
        NEW_NAME="${PREFIX}${REPO_NAME}"  # Rename to avoid conflicts

        echo "Transferring $REPO to $TARGET_ORG as $NEW_NAME" | tee -a "$LOG_FILE"

        # Transfer via GitHub API
        RESPONSE=$(gh api --method POST \
            -H "Accept: application/vnd.github.v3+json" \
            "/repos/$REPO/transfer" \
            -f new_owner="$TARGET_ORG" \
            -f name="$NEW_NAME" 2>&1)

        if [ $? -eq 0 ]; then
            echo "✅ Success: $REPO -> $TARGET_ORG/$NEW_NAME" | tee -a "$LOG_FILE"
        else
            echo "❌ Failed: $REPO. Error: $RESPONSE" | tee -a "$LOG_FILE"

            # Additional debugging for common errors
            if [[ "$RESPONSE" == *"Must have admin rights to Repository"* ]]; then
                echo "→ This suggests you don't have admin access to $REPO" | tee -a "$LOG_FILE"
                echo "→ Check repository settings or try manual transfer" | tee -a "$LOG_FILE"
            fi
        fi

        sleep $DELAY  # Avoid rate limits
    done
done

echo "Transfer completed at $(date)" | tee -a "$LOG_FILE"
