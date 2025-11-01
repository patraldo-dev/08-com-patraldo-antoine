# List all repositories in your target organization
gh repo list patraldo-dev --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner' | while read -r repo; do
  echo "Checking webhooks for $repo"
  # Get webhooks for this repository
  webhooks=$(gh api "repos/$repo/hooks" --jq '.[] | {url: .config.url, events: .events}' 2>/dev/null)
  if [ -n "$webhooks" ]; then
    echo "Webhooks found:"
    echo "$webhooks"
  else
    echo "No webhooks found"
  fi
  echo "-------------------"
done
