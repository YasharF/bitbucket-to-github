#!/bin/bash

# === CONFIG ===
BITBUCKET_USERNAME="your bitbucket username"
BITBUCKET_APP_PASSWORD="your bit bucket app password"
GITHUB_USERNAME="your Gitub username"
GITHUB_TOKEN="your Github app token"
GITHUB_API="https://api.github.com"
BITBUCKET_API="https://api.bitbucket.org/2.0"

# === FUNCTIONS ===

# Fetch all workspaces you have access to
fetch_bitbucket_workspaces() {
  local url="$BITBUCKET_API/workspaces?pagelen=100"
  while [[ -n "$url" ]]; do
    response=$(curl -s -u "$BITBUCKET_USERNAME:$BITBUCKET_APP_PASSWORD" "$url")
    echo "$response" | jq -r '.values[].slug'
    url=$(echo "$response" | jq -r '.next // empty')
  done
}

# Fetch all repos for a given workspace
fetch_bitbucket_repos() {
  local workspace=$1
  local url="$BITBUCKET_API/repositories/$workspace?pagelen=100"
  while [[ -n "$url" ]]; do
    response=$(curl -s -u "$BITBUCKET_USERNAME:$BITBUCKET_APP_PASSWORD" "$url")
    echo "$response" | jq -r '.values[] | select(.scm=="git") | .slug'
    url=$(echo "$response" | jq -r '.next // empty')
  done
}

# Create a new private repo on GitHub
create_github_repo() {
  local repo=$1
  curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
    -d "{\"name\":\"$repo\",\"private\":true}" \
    "$GITHUB_API/user/repos" > /dev/null
}

# Clone, push, and rename default branch if needed
migrate_repo() {
  local workspace=$1
  local repo=$2
  local bitbucket_url="https://$BITBUCKET_USERNAME:$BITBUCKET_APP_PASSWORD@bitbucket.org/$workspace/$repo.git"
  local github_url="https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/$GITHUB_USERNAME/$repo.git"

  echo "🔄 Migrating $workspace/$repo → $GITHUB_USERNAME/$repo"

  git clone --mirror "$bitbucket_url"
  cd "$repo.git" || { echo "ERROR: Failed to enter repo $repo"; return; }

  create_github_repo "$repo"

  git remote set-url origin "$github_url"
  git push --mirror

  # detect default branch
  default_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')

  # if repo has a default branch and "main" doesn’t exist, rename it
  if [[ -n "$default_branch" ]]; then
    if ! git show-ref --verify --quiet refs/heads/main && \
       ! git ls-remote --exit-code origin main >/dev/null 2>&1; then
      echo "> Renaming default branch $default_branch → main"
      git push origin "refs/remotes/origin/$default_branch:refs/heads/main"
      git push origin --delete "$default_branch" 2>/dev/null || true
    else
      echo "WARN: Main branch already exists, skipping rename."
    fi
  else
    echo "ERROR: Could not detect default branch for $repo"
  fi

  cd ..
  rm -rf "$repo.git"
}

# === MAIN ===

echo "> Fetching all accessible Bitbucket workspaces..."
workspaces=$(fetch_bitbucket_workspaces)

for workspace in $workspaces; do
  echo "> Fetching repos from Bitbucket workspace: $workspace"
  repos=$(fetch_bitbucket_repos "$workspace")
  for repo in $repos; do
    migrate_repo "$workspace" "$repo"
  done
done

echo "> Migration complete."
