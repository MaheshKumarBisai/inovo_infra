#!/bin/bash
# sync-secrets.sh
# Automates uploading secrets from local .env.deployment directly to GitHub Actions.
# Usage: ./sync-secrets.sh [GITHUB_USERNAME]

set -e

GITHUB_USER=${1:-"MaheshKumarBisai"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="$SCRIPT_DIR/.env.deployment"

echo "=========================================================="
echo "  Inovo Infrastructure - GitHub Secrets Sync"
echo "  Target GitHub Account: $GITHUB_USER"
echo "=========================================================="

# 1. Check GitHub CLI installation
if ! command -v gh &> /dev/null; then
  echo "❌ Error: GitHub CLI ('gh') is not installed."
  echo "👉 Install with: brew install gh"
  echo "👉 Then authenticate: gh auth login"
  exit 1
fi

# 2. Check GitHub CLI authentication
if ! gh auth status &> /dev/null; then
  echo "❌ Error: Not logged in to GitHub CLI."
  echo "👉 Run: gh auth login"
  exit 1
fi

# 3. Check secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
  echo "❌ Error: .env.deployment file not found at: $SECRETS_FILE"
  echo "👉 Create it by copying the template:"
  echo "   cp $SCRIPT_DIR/.env.deployment.example $SECRETS_FILE"
  echo "   (fill in your real AWS keys, DB password, and ACM ARN)"
  exit 1
fi

# Repositories to sync
REPOS=(
  "inovo_infra"
  "invento_Backend"
  "Invento_Frontend"
  "Invento_gateway"
)

echo "🚀 Syncing secrets from .env.deployment to GitHub..."
echo ""

for REPO in "${REPOS[@]}"; do
  echo "📦 Updating secrets for: $GITHUB_USER/$REPO"
  
  if gh secret set -f "$SECRETS_FILE" --repo "$GITHUB_USER/$REPO"; then
    echo "   ✅ Successfully synced secrets to $REPO"
  else
    echo "   ⚠️ Warning: Could not sync to $REPO. (Make sure repo exists under $GITHUB_USER)"
  fi
  echo ""
done

echo "=========================================================="
echo "🎉 Secrets sync completed!"
echo "Now when you push to main, GitHub Actions has the exact"
echo "secrets needed to run Terraform Validate, Plan & Apply."
echo "=========================================================="
