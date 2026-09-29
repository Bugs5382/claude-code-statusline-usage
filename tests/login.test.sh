# shellcheck shell=bash
# The signed-in login is read from the CLI config only when asked for, and any
# problem with that file just leaves it out.
rest=" · my-project · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)"

cp "$FIXTURES/config-login.json" "$HOME/.claude.json"
run_hook full.json CLAUDE_STATUSLINE_LOGIN=1
assert_eq 0 "$STATUS" "enabled: exit status"
assert_eq "Opus (user@example.com)$rest" "$OUT" "enabled: status line"

run_hook full.json
assert_eq "Opus$rest" "$OUT" "unset: status line"

run_hook full.json CLAUDE_STATUSLINE_LOGIN=0
assert_eq "Opus$rest" "$OUT" "disabled: status line"

rm -f "$HOME/.claude.json"
mkdir -p "$HOME/cfg"
cp "$FIXTURES/config-login.json" "$HOME/cfg/.claude.json"
run_hook full.json CLAUDE_STATUSLINE_LOGIN=1 CLAUDE_CONFIG_DIR="$HOME/cfg"
assert_eq "Opus (user@example.com)$rest" "$OUT" "CLAUDE_CONFIG_DIR: status line"

run_hook full.json CLAUDE_STATUSLINE_LOGIN=1
assert_eq 0 "$STATUS" "missing file: exit status"
assert_eq "Opus$rest" "$OUT" "missing file: status line"

cp "$FIXTURES/config-no-login.json" "$HOME/.claude.json"
run_hook full.json CLAUDE_STATUSLINE_LOGIN=1
assert_eq 0 "$STATUS" "missing field: exit status"
assert_eq "Opus$rest" "$OUT" "missing field: status line"

cp "$FIXTURES/config-bad-login.json" "$HOME/.claude.json"
run_hook full.json CLAUDE_STATUSLINE_LOGIN=1
assert_eq 0 "$STATUS" "non-string field: exit status"
assert_eq "Opus$rest" "$OUT" "non-string field: status line"

cp "$FIXTURES/truncated.json" "$HOME/.claude.json"
run_hook full.json CLAUDE_STATUSLINE_LOGIN=1
assert_eq 0 "$STATUS" "bad JSON: exit status"
assert_eq "Opus$rest" "$OUT" "bad JSON: status line"

# root reads a mode-000 file anyway, so the check only means something as a user.
if [ "$(id -u)" -ne 0 ]; then
  cp "$FIXTURES/config-login.json" "$HOME/.claude.json"
  chmod 000 "$HOME/.claude.json"
  run_hook full.json CLAUDE_STATUSLINE_LOGIN=1
  assert_eq 0 "$STATUS" "unreadable file: exit status"
  assert_eq "Opus$rest" "$OUT" "unreadable file: status line"
  chmod 600 "$HOME/.claude.json"
fi
