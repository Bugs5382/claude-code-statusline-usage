# shellcheck shell=bash
# Reset times default to %Y-%m-%d %H:%M and CLAUDE_USAGE_DATE_FORMAT overrides
# that for both. full.json's resets_at fixtures are 2025-02-01 16:00 and
# 2025-02-06 16:00 in UTC (the process TZ, set by run.sh). A format that fails
# validation falls back to the default, and the script still exits 0.
default="Opus · my-project · session 24% (resets 2025-02-01 16:00) · week 41% (resets 2025-02-06 16:00)"

run_hook full.json
assert_eq 0 "$STATUS" "default: exit status"
assert_eq "$default" "$OUT" "default: status line"

run_hook full.json CLAUDE_USAGE_DATE_FORMAT=
assert_eq 0 "$STATUS" "empty: exit status"
assert_eq "$default" "$OUT" "empty: status line"

run_hook full.json 'CLAUDE_USAGE_DATE_FORMAT=%a %-I:%M%p'
assert_eq 0 "$STATUS" "old look: exit status"
assert_eq "Opus · my-project · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)" "$OUT" "old look: status line"

run_hook full.json 'CLAUDE_USAGE_DATE_FORMAT=%d/%m %H:%M %%'
assert_eq 0 "$STATUS" "literal percent: exit status"
assert_eq "Opus · my-project · session 24% (resets 01/02 16:00 %) · week 41% (resets 06/02 16:00 %)" "$OUT" "literal percent: status line"

# Each of these is rejected: no conversion at all, only a literal percent, a
# conversion outside the set both date flavours share, a dangling percent, a
# flag with no conversion, a control character, and an overlong string.
long="$(printf '%%Y%.0s' $(seq 1 40))"
for bad in 'YYYY-MM-DD' '%%' '%Q' '%Y-%m-%' '%-' "$(printf '%%Y\n%%m')" "$(printf '%%Y\t%%m')" "$long"; do
  run_hook full.json "CLAUDE_USAGE_DATE_FORMAT=$bad"
  assert_eq 0 "$STATUS" "bad [$bad]: exit status"
  assert_eq "$default" "$OUT" "bad [$bad]: status line"
done

# The format and the zone override combine: the zone moves the time, the
# format decides how it reads.
run_hook full.json CLAUDE_STATUSLINE_TZ=America/New_York
assert_eq "Opus · my-project · session 24% (resets 2025-02-01 11:00) · week 41% (resets 2025-02-06 11:00)" "$OUT" "zone, default format: status line"

run_hook full.json CLAUDE_STATUSLINE_TZ=America/New_York 'CLAUDE_USAGE_DATE_FORMAT=%a %b %e %-I:%M%p %Z'
assert_eq 0 "$STATUS" "zone and format: exit status"
assert_eq "Opus · my-project · session 24% (resets Sat Feb  1 11:00AM EST) · week 41% (resets Thu Feb  6 11:00AM EST)" "$OUT" "zone and format: status line"

run_hook full.json CLAUDE_STATUSLINE_TZ=America/New_York CLAUDE_USAGE_DATE_FORMAT=%Q
assert_eq "Opus · my-project · session 24% (resets 2025-02-01 11:00) · week 41% (resets 2025-02-06 11:00)" "$OUT" "zone, bad format: status line"

# Display only: the files on disk keep epoch seconds whatever the format.
dir="$HOME/.claude/usage"
rm -rf "$dir"
run_hook full.json 'CLAUDE_USAGE_DATE_FORMAT=%a %-I:%M%p'
assert_eq "1738425600" "$(jq -r '.rate_limits.five_hour.resets_at' "$dir/latest.json")" "latest.json keeps epoch"
assert_eq "1738425600" "$(tail -n 1 "$dir/history.tsv" | cut -f 3)" "history.tsv keeps epoch"
