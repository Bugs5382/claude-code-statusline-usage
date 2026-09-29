# shellcheck shell=bash
# Any missing or odd field is dropped, never an error.
run_hook - < /dev/null
assert_eq 0 "$STATUS" "empty stdin: exit status"
assert_eq "Claude" "$OUT" "empty stdin: status line"

run_hook truncated.json
assert_eq 0 "$STATUS" "invalid JSON: exit status"
assert_eq "Claude" "$OUT" "invalid JSON: status line"

run_hook week-only.json
assert_eq 0 "$STATUS" "week only: exit status"
assert_eq "Opus · my-project · week 41% (resets Thu 4:00PM)" "$OUT" "week only: status line"
assert_eq "	41.2	1738857600" "$(tail -n 1 "$HOME/.claude/usage/history.tsv" | cut -f 3-)" "week only: history row"

rm -rf "$HOME/.claude"
run_hook no-resets.json
assert_eq 0 "$STATUS" "no resets_at: exit status"
assert_eq "Opus · session 24%" "$OUT" "no resets_at: status line"

rm -rf "$HOME/.claude"
run_hook bad-values.json
assert_eq 0 "$STATUS" "non-numeric values: exit status"
assert_eq "Opus · my-project" "$OUT" "non-numeric values: status line"
assert_no_path "$HOME/.claude/usage"
