#!/bin/bash

# Get your username
USERNAME=$(gh api user --jq '.login')

# Get all organizations you're a member of, excluding the target organization
TARGET_ORG="patraldo-dev"
ORGS=$(gh api user/orgs --jq '.[].login' | grep -v "^$TARGET_ORG$")

echo "Organizations to be deleted:"
echo "$ORGS"
echo

# Confirm before proceeding
read -p "Are you sure you want to delete these organizations? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# For each organization
for org in $ORGS; do
    echo "Processing organization: $org"
    
    # Check if the organization has any repositories
    REPOS=$(gh repo list "$org" --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')
    
    if [ -n "$REPOS" ]; then
        echo "⚠️  Organization $org still has repositories:"
        echo "$REPOS"
        echo "Skipping deletion. Please transfer or delete these repositories first."
        echo
        continue
    fi
    
    # Delete the organization
    echo "Deleting organization: $org"
    RESPONSE=$(gh api --method DELETE -H "Accept: application/vnd.github.v3+json" "/orgs/$org" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully deleted $org"
    else
        echo "❌ Failed to delete $org: $RESPONSE"
    fi
    echo
done

echo "Operation completed."
