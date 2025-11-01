#!/bin/bash

# Configuration
ORIGINAL_ORGS=("pinchepoutine" "pinchepoutinedev" "cpidms" "pinchepoutinedigital" "patraldo" "patrouch-com" "mypod-dev" "Urban-Inversion" "patrouch-dev" "cheftech-dev" "bigdaddydotdev" "ambientx-dev" "patraldo-dev" "patrouch-ca" "Mexican-Bold")
LOG_FILE="original_orgs_activity.log"
TODAY=$(date +%Y-%m-%d)

# Initialize log
echo "Original Organizations Activity Check - $(date)" > "$LOG_FILE"
echo "=================================" >> "$LOG_FILE"

echo "Checking for recent activity in original organizations..."

for org in "${ORIGINAL_ORGS[@]}"; do
    echo "Checking organization: $org" | tee -a "$LOG_FILE"
    
    # Get repositories in this organization
    repos=$(gh repo list "$org" --limit 1000 --json nameWithOwner,updatedAt 2>/dev/null)
    
    if [ -n "$repos" ]; then
        echo "$repos" | while read -r repo_line; do
            # Extract repository details
            repo_name=$(echo "$repo_line" | sed 's/.*"nameWithOwner":"\([^"]*\)".*/\1/')
            updated_at=$(echo "$repo_line" | sed 's/.*"updatedAt":"\([^"]*\)".*/\1/')
            
            if [ -n "$repo_name" ] && [ -n "$updated_at" ]; then
                # Check if updated today
                if [[ "$updated_at" == *"$TODAY"* ]]; then
                    echo "  Repository: $repo_name" | tee -a "$LOG_FILE"
                    echo "  Updated today: $updated_at" | tee -a "$LOG_FILE"
                    
                    # Check for transfer events
                    events=$(gh api "repos/$repo_name/events" 2>/dev/null)
                    if echo "$events" | grep -q '"type":"TransferredEvent"'; then
                        transfer_date=$(echo "$events" | grep -A10 '"type":"TransferredEvent"' | grep '"created_at"' | head -1 | sed 's/.*"created_at":"\([^"]*\)".*/\1/')
                        echo "  ✅ Transfer event found: $transfer_date" | tee -a "$LOG_FILE"
                    fi
                fi
            fi
        done
    else
        echo "  No repositories found or access denied" | tee -a "$LOG_FILE"
    fi
    
    echo "  ---" | tee -a "$LOG_FILE"
done

echo "Check complete. Results saved to $LOG_FILE"
