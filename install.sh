#!/usr/bin/env bash
# Copy statusline.sh into ~/.claude and print the settings snippet that turns it
# on. settings.json is left alone on purpose: it holds other settings, and a
# merge done by a script is hard to review. Run it again to update.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/statusline.sh"
DEST_DIR="$HOME/.claude"
DEST="$DEST_DIR/statusline.sh"

[ -f "$SRC" ] || { echo "install: statusline.sh not found next to install.sh" >&2; exit 1; }
mkdir -p "$DEST_DIR"

# An earlier status line may be someone's own work, so it is kept, not replaced.
if [ -f "$DEST" ] && ! cmp -s "$SRC" "$DEST"; then
  backup="$DEST.bak.$(date +%Y%m%d%H%M%S)"
  mv "$DEST" "$backup"
  echo "Kept the earlier script as $backup"
fi

cp "$SRC" "$DEST"
chmod 755 "$DEST"
echo "Installed $DEST"

if ! command -v jq >/dev/null 2>&1; then
  echo "Warning: jq is not installed. The status line will only say so until it is." >&2
fi

cat <<'EOF'

Add this to ~/.claude/settings.json (merge it with what is already there):

{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}

Usage is saved to ~/.claude/usage (set CLAUDE_USAGE_DIR to change it).
EOF
