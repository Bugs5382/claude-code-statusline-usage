# shellcheck shell=bash
# latest.json is rewritten on every run; history.tsv gets at most one row per
# interval, measured from the last row already in the file.
dir="$HOME/.claude/usage"
rows() { wc -l < "$1" | tr -d ' '; }

run_hook full.json
run_hook full.json
assert_eq 2 "$(rows "$dir/history.tsv")" "default interval: second run is not logged"

printf '%s\n' '{"stale":true}' > "$dir/latest.json"
run_hook full.json
assert_eq "null" "$(jq -r '.stale' "$dir/latest.json")" "latest.json is rewritten every run"

# A last row older than the interval lets the next run log again.
old=$(( $(date +%s) - 301 ))
printf 'captured_at\tsession_pct\tsession_resets_at\tweek_pct\tweek_resets_at\n%s\t1\t2\t3\t4\n' "$old" > "$dir/history.tsv"
run_hook full.json
assert_eq 3 "$(rows "$dir/history.tsv")" "old last row: run is logged"

custom="$HOME/elsewhere"
run_hook full.json CLAUDE_USAGE_DIR="$custom" CLAUDE_USAGE_LOG_EVERY=0
run_hook full.json CLAUDE_USAGE_DIR="$custom" CLAUDE_USAGE_LOG_EVERY=0
assert_file "$custom/latest.json"
assert_eq 3 "$(rows "$custom/history.tsv")" "interval 0: every run is logged"

bad="$HOME/bad-interval"
run_hook full.json CLAUDE_USAGE_DIR="$bad" CLAUDE_USAGE_LOG_EVERY=soon
run_hook full.json CLAUDE_USAGE_DIR="$bad" CLAUDE_USAGE_LOG_EVERY=soon
assert_eq 2 "$(rows "$bad/history.tsv")" "invalid interval falls back to the default"

# An unwritable folder costs the saved files, never the status line.
touch "$HOME/blocked"
run_hook full.json CLAUDE_USAGE_DIR="$HOME/blocked/usage"
assert_eq 0 "$STATUS" "unwritable dir: exit status"
assert_contains "$OUT" "session 24%" "unwritable dir: status line"
