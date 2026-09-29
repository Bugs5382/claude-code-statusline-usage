# shellcheck shell=bash
# Without jq nothing can be parsed, but the prompt still gets a line that says
# why, and the script still exits 0.
bin="$HOME/bin"
make_bin "$bin" bash cat date mkdir mv tail cut mktemp rm
run_hook full.json PATH="$bin"
assert_eq 0 "$STATUS" "exit status"
assert_eq "Claude · jq not found" "$OUT" "status line"
assert_no_path "$HOME/.claude/usage"
