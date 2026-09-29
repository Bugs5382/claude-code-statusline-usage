#!/usr/bin/env bash
# Status line for the Claude CLI: model, folder, and plan usage for the session
# window (sent as rate_limits.five_hour) and the weekly window (rate_limits.
# seven_day). Nothing here assumes how long a window is; resets_at says when it
# ends. The figures are also saved to disk so other scripts can plan work from
# live numbers instead of estimates.
#
# The prompt waits on this script, so it never fails: anything missing or
# malformed is left out of the line, and the exit status is always 0.
# rate_limits is only sent on Pro and Max plans, and only after the first reply.
#
# Settings (environment):
#   CLAUDE_USAGE_DIR        where latest.json and history.tsv go (~/.claude/usage)
#   CLAUDE_USAGE_LOG_EVERY  minimum seconds between history.tsv rows (300)
#   CLAUDE_STATUSLINE_LOGIN   1 shows the signed-in login after the model (off)
#   CLAUDE_STATUSLINE_FOLDER  0 hides the folder (on)
#   CLAUDE_STATUSLINE_TZ      IANA zone (e.g. America/New_York) for reset times (process TZ)

set -uo pipefail

USAGE_DIR="${CLAUDE_USAGE_DIR:-$HOME/.claude/usage}"
LOG_EVERY="${CLAUDE_USAGE_LOG_EVERY:-300}"
case "$LOG_EVERY" in '' | *[!0-9]*) LOG_EVERY=300 ;; esac

payload="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  printf 'Claude · jq not found\n'
  exit 0
fi

# One jq call pulls every field. Non-numbers become empty strings so a bad value
# is dropped instead of breaking the arithmetic below. The unit separator keeps
# empty fields in place, which a tab would not (read collapses whitespace).
fields="$(printf '%s' "$payload" | jq -j '
  def num: if type == "number" then . else null end;
  def str: if type == "string" then . else "" end;
  def txt: if . == null then "" else tostring end;
  [ (.model.display_name | str),
    ((.workspace.current_dir // .cwd) | str),
    (.rate_limits.five_hour.used_percentage | num | txt),
    (.rate_limits.five_hour.used_percentage | num | if . then round else null end | txt),
    (.rate_limits.five_hour.resets_at | num | if . then floor else null end | txt),
    (.rate_limits.seven_day.used_percentage | num | txt),
    (.rate_limits.seven_day.used_percentage | num | if . then round else null end | txt),
    (.rate_limits.seven_day.resets_at | num | if . then floor else null end | txt)
  ] | join("\u001f")' 2>/dev/null)"

IFS=$'\x1f' read -r model dir s_pct s_round s_reset w_pct w_round w_reset <<EOF
$fields
EOF

# Only the reset-time date calls below take the override, and only when it
# names a zone the system actually has (checked against zoneinfo directly,
# since neither macOS nor Linux date rejects an unknown TZ the same way).
tz_override=""
tz_setting="${CLAUDE_STATUSLINE_TZ:-}"
if [ -n "$tz_setting" ] && [ "$tz_setting" != "${TZ:-}" ]; then
  case "$tz_setting" in
    /* | *..*) ;;
    *) [ -f "${TZDIR:-/usr/share/zoneinfo}/$tz_setting" ] && tz_override="$tz_setting" ;;
  esac
fi
if [ -n "$tz_override" ]; then
  tz_date() { TZ="$tz_override" date "$@"; }
else
  tz_date() { date "$@"; }
fi

# BSD date (macOS) takes the epoch with -r. GNU date reads -r as a file name
# and would print that file's time if one happened to match, so GNU is detected
# up front and only ever gets -d @epoch.
if date --version >/dev/null 2>&1; then
  when() { [ -n "$1" ] && tz_date -d "@$1" '+%a %-I:%M%p' 2>/dev/null; }
else
  when() { [ -n "$1" ] && { tz_date -r "$1" '+%a %-I:%M%p' 2>/dev/null || tz_date -d "@$1" '+%a %-I:%M%p' 2>/dev/null; }; }
fi

line="${model:-Claude}"
# The payload carries no account, so the login comes from the CLI's own config.
# It is opt-in because it is the one read beyond stdin.
if [ "${CLAUDE_STATUSLINE_LOGIN:-}" = 1 ]; then
  cfg="${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"
  if [ -r "$cfg" ]; then
    login="$(jq -j '.oauthAccount.emailAddress | strings' "$cfg" 2>/dev/null)"
    [ -n "$login" ] && line="$line ($login)"
  fi
fi
if [ "${CLAUDE_STATUSLINE_FOLDER:-}" != 0 ] && [ -n "$dir" ] && [ -n "${dir##*/}" ]; then
  line="$line · ${dir##*/}"
fi
if [ -n "$s_pct" ]; then
  line="$line · session ${s_round}%"
  if r="$(when "$s_reset")" && [ -n "$r" ]; then line="$line (resets $r)"; fi
fi
if [ -n "$w_pct" ]; then
  line="$line · week ${w_round}%"
  if r="$(when "$w_reset")" && [ -n "$r" ]; then line="$line (resets $r)"; fi
fi
printf '%s\n' "$line"

[ -n "$s_pct$w_pct" ] || exit 0
mkdir -p "$USAGE_DIR" 2>/dev/null || exit 0
now="$(date +%s)"

# Written to a temp file and renamed, so a reader never sees half a file.
tmp="$(mktemp "$USAGE_DIR/.latest.XXXXXX" 2>/dev/null)" || exit 0
if printf '%s' "$payload" | jq -c --argjson t "$now" '{captured_at: $t, rate_limits: .rate_limits}' > "$tmp" 2>/dev/null; then
  mv -f "$tmp" "$USAGE_DIR/latest.json" 2>/dev/null
fi
rm -f "$tmp" 2>/dev/null

# The throttle reads the last row's timestamp, so there is no separate state
# file to drift out of step with the history. Reset times are kept as well, so
# the real window length can be measured from the data rather than assumed.
hist="$USAGE_DIR/history.tsv"
last="$(tail -n 1 "$hist" 2>/dev/null | cut -f 1)"
case "$last" in '' | *[!0-9]*) last=0 ;; esac
if [ $((now - last)) -ge "$LOG_EVERY" ]; then
  [ -s "$hist" ] || printf 'captured_at\tsession_pct\tsession_resets_at\tweek_pct\tweek_resets_at\n' > "$hist" 2>/dev/null
  printf '%s\t%s\t%s\t%s\t%s\n' "$now" "$s_pct" "$s_reset" "$w_pct" "$w_reset" >> "$hist" 2>/dev/null
fi
exit 0
