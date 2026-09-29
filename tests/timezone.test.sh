# shellcheck shell=bash
# CLAUDE_STATUSLINE_TZ only changes the zone the reset-time date calls use.
# full.json's resets_at fixtures render 2025-02-01 16:00 / 2025-02-06 16:00 under UTC
# (the process TZ, set by run.sh) and 2025-02-01 11:00 / 2025-02-06 11:00 under
# America/New_York.

run_hook full.json CLAUDE_STATUSLINE_TZ=America/New_York
assert_eq 0 "$STATUS" "override: exit status"
assert_eq "Opus · my-project · session 24% (resets 2025-02-01 11:00) · week 41% (resets 2025-02-06 11:00)" "$OUT" "override: status line"

run_hook full.json CLAUDE_STATUSLINE_TZ=UTC
assert_eq 0 "$STATUS" "equal to TZ: exit status"
assert_eq "Opus · my-project · session 24% (resets 2025-02-01 16:00) · week 41% (resets 2025-02-06 16:00)" "$OUT" "equal to TZ: status line"

run_hook full.json
assert_eq 0 "$STATUS" "unset: exit status"
assert_eq "Opus · my-project · session 24% (resets 2025-02-01 16:00) · week 41% (resets 2025-02-06 16:00)" "$OUT" "unset: status line"

run_hook full.json CLAUDE_STATUSLINE_TZ=Not/AZone
assert_eq 0 "$STATUS" "invalid: exit status"
assert_eq "Opus · my-project · session 24% (resets 2025-02-01 16:00) · week 41% (resets 2025-02-06 16:00)" "$OUT" "invalid: status line"
