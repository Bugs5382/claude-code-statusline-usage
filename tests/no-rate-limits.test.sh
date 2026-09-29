# shellcheck shell=bash
# Before the first reply, or on a plan without limits, there is no usage to
# show and nothing is written.
run_hook no-rate-limits.json
assert_eq 0 "$STATUS" "exit status"
assert_eq "Opus · my-project" "$OUT" "status line"
assert_no_path "$HOME/.claude/usage"
