#!/usr/bin/env bash
set -euo pipefail

# Configuration — update REPO to match your published repo
REPO="DEFRA/copilot-plugin-publisher"
ASSET_NAME="copilot-plugin.zip"

echo "Downloading latest Copilot plugin release from $REPO..."

# Fetch the download URL for the latest release asset
DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" \
  | jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | .browser_download_url")

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  echo "ERROR: Could not find $ASSET_NAME in the latest release of $REPO"
  exit 1
fi

curl -sL "$DOWNLOAD_URL" -o "$ASSET_NAME"

# Unzip into the current directory (creates/overwrites .github/agents/ and .github/skills/)
echo "Extracting to .github/..."
unzip -o "$ASSET_NAME" -d .
rm "$ASSET_NAME"

echo ""
echo "Done. Files installed:"
find .github/agents -name "*.md" | sort
find .github/skills -name "*.md" | sort
echo ""
echo "IMPORTANT: Ensure your VS Code settings include:"
echo '  "chat.customAgentInSubagent.enabled": true'
echo '  "chat.useAgentSkills": true'
