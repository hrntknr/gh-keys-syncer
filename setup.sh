#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/hrntknr/gh-keys-syncer.git"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/gh-keys-syncer}"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 * * * *}"
GH_USER="${GITHUB_USER:-}"

command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[*] Updating repo in $INSTALL_DIR"
  git -C "$INSTALL_DIR" fetch --depth=1 origin
  git -C "$INSTALL_DIR" reset --hard origin/HEAD
else
  echo "[*] Cloning repo to $INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

SYNC_SCRIPT="$INSTALL_DIR/syncer.sh"
chmod +x "$SYNC_SCRIPT"

mkdir -p "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

TMP_CRON="$(mktemp)"
crontab -l 2>/dev/null | sed '/gh-keys-syncer/d' > "$TMP_CRON" || true

if [ -n "$GH_USER" ]; then
  echo "${CRON_SCHEDULE} GITHUB_USER=${GH_USER} \"$SYNC_SCRIPT\" # gh-keys-syncer" >> "$TMP_CRON"
else
  echo "${CRON_SCHEDULE} \"$SYNC_SCRIPT\" # gh-keys-syncer" >> "$TMP_CRON"
fi

crontab "$TMP_CRON"
rm -f "$TMP_CRON"

echo "[✓] Installed successfully."
echo "    - Script: $SYNC_SCRIPT"
echo "    - Cron job: $(crontab -l | grep gh-keys-syncer)"
echo
echo "Tip: to change user and frequency, run for example:"
echo "  GITHUB_USER=octocat CRON_SCHEDULE='*/30 * * * *' ./setup.sh"
