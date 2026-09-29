# shellcheck shell=bash
# CLAUDE_STATUSLINE_TZ only changes the zone the reset-time date calls use.
# full.json's resets_at fixtures render Sat 4:00PM / Thu 4:00PM under UTC
# (the process TZ, set by run.sh) and Sat 11:00AM / Thu 11:00AM under
# America/New_York.

run_hook full.json CLAUDE_STATUSLINE_TZ=America/New_York
assert_eq 0 "$STATUS" "override: exit status"
assert_eq "Opus · my-project · session 24% (resets Sat 11:00AM) · week 41% (resets Thu 11:00AM)" "$OUT" "override: status line"

run_hook full.json CLAUDE_STATUSLINE_TZ=UTC
assert_eq 0 "$STATUS" "equal to TZ: exit status"
assert_eq "Opus · my-project · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)" "$OUT" "equal to TZ: status line"

run_hook full.json
assert_eq 0 "$STATUS" "unset: exit status"
assert_eq "Opus · my-project · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)" "$OUT" "unset: status line"

run_hook full.json CLAUDE_STATUSLINE_TZ=Not/AZone
assert_eq 0 "$STATUS" "invalid: exit status"
assert_eq "Opus · my-project · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)" "$OUT" "invalid: status line"
