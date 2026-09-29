# shellcheck shell=bash
# The folder part shows unless it is turned off with CLAUDE_STATUSLINE_FOLDER=0.
usage=" · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)"

run_hook full.json
assert_eq 0 "$STATUS" "default: exit status"
assert_eq "Opus · my-project$usage" "$OUT" "default: status line"

run_hook full.json CLAUDE_STATUSLINE_FOLDER=1
assert_eq "Opus · my-project$usage" "$OUT" "set to 1: status line"

run_hook full.json CLAUDE_STATUSLINE_FOLDER=0
assert_eq 0 "$STATUS" "hidden: exit status"
assert_eq "Opus$usage" "$OUT" "hidden: status line"

cp "$FIXTURES/config-login.json" "$HOME/.claude.json"
run_hook full.json CLAUDE_STATUSLINE_FOLDER=0 CLAUDE_STATUSLINE_LOGIN=1
assert_eq "Opus (user@example.com)$usage" "$OUT" "hidden with login: status line"
