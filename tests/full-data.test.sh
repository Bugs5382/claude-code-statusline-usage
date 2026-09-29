# shellcheck shell=bash
# Full payload: every usage field is shown and saved.
run_hook full.json
assert_eq 0 "$STATUS" "exit status"
assert_eq "Opus · my-project · session 24% (resets 2025-02-01 16:00) · week 41% (resets 2025-02-06 16:00)" "$OUT" "status line"

dir="$HOME/.claude/usage"
assert_file "$dir/latest.json"
assert_eq "23.5" "$(jq -r '.rate_limits.five_hour.used_percentage' "$dir/latest.json")" "latest five_hour"
assert_eq "1738857600" "$(jq -r '.rate_limits.seven_day.resets_at' "$dir/latest.json")" "latest seven_day reset"
assert_eq "number" "$(jq -r '.captured_at | type' "$dir/latest.json")" "latest captured_at"

assert_file "$dir/history.tsv"
assert_eq "captured_at	session_pct	session_resets_at	week_pct	week_resets_at" "$(head -n 1 "$dir/history.tsv")" "history header"
assert_eq "2" "$(wc -l < "$dir/history.tsv" | tr -d ' ')" "history rows"
assert_eq "23.5	1738425600	41.2	1738857600" "$(tail -n 1 "$dir/history.tsv" | cut -f 2-)" "history row"
