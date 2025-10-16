#!/bin/bash
set -euo pipefail

AK="$HOME/.ssh/authorized_keys"
GH_USER="${GITHUB_USER:-$(whoami)}"

mkdir -p "$HOME/.ssh"
touch "$AK"
chmod 600 "$AK"

KEYS="$(curl -fsSL "https://github.com/${GH_USER}.keys" || true)"

if grep -q '^# begin gh-keys-syncer' "$AK"; then
  awk -v keys="$KEYS" '
    BEGIN {
      n = split(keys, arr, "\n")
      inside = 0
    }
    /^# begin gh-keys-syncer/ {
      print
      for (i = 1; i <= n; i++) if (arr[i] != "") print arr[i]
      inside = 1
      next
    }
    inside && /^# end gh-keys-syncer/ {
      inside = 0
      print
      next
    }
    !inside { print }
  ' "$AK" > "$AK.tmp" && mv "$AK.tmp" "$AK"
else
  {
    cat "$AK"
    echo "# begin gh-keys-syncer"
    echo "$KEYS"
    echo "# end gh-keys-syncer"
  } > "$AK.tmp" && mv "$AK.tmp" "$AK"
fi
