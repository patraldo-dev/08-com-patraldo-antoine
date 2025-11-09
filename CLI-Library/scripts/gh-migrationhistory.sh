#!/bin/bash

# Configuration
ORG="patraldo-dev"
LOG_FILE="simple_repo_list.log"

# Initialize log
echo "Simple Repository List - $(date)" > "$LOG_FILE"
echo "=====================" >> "$LOG_FILE"

echo "Listing all repositories in $ORG..."

# Just list all repositories
gh repo list "$ORG" --limit 1000 --json nameWithOwner >> "$LOG_FILE"

echo "List complete. Results saved to $LOG_FILE"
