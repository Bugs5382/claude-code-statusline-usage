# shellcheck shell=bash
# Reset times, with the default format or an override, render the same with
# BSD date (macOS, `date -r <epoch>`) and GNU date (Linux, `date -d @<epoch>`).
# Each stub accepts only its own flavour and hands the call to the real date in
# whatever form the host understands.
native() { # <epoch> <format>
  if "$REAL_DATE" -d @0 +%s >/dev/null 2>&1; then
    "$REAL_DATE" -d "@$1" "$2"
  else
    "$REAL_DATE" -r "$1" "$2"
  fi
}

make_stub() { # <dir> <gnu|bsd>
  mkdir -p "$1"
  cat > "$1/date" <<STUB
#!/usr/bin/env bash
$(declare -f native)
REAL_DATE="$REAL_DATE"
flavour=$2
case "\$1" in
  --version) [ "\$flavour" = gnu ] || { echo "date: illegal option -- -" >&2; exit 1; }
      echo "date (GNU coreutils) stub" ;;
  -r) [ "\$flavour" = bsd ] || { echo "date: \$2: No such file or directory" >&2; exit 1; }
      native "\$2" "\$3" ;;
  -d) [ "\$flavour" = gnu ] || { echo "date: illegal option -- d" >&2; exit 1; }
      native "\${2#@}" "\$3" ;;
  *)  exec "\$REAL_DATE" "\$@" ;;
esac
STUB
  chmod +x "$1/date"
}

for flavour in gnu bsd; do
  make_stub "$HOME/$flavour" "$flavour"
  run_hook full.json PATH="$HOME/$flavour:$PATH" CLAUDE_USAGE_DIR="$HOME/$flavour-usage"
  assert_eq 0 "$STATUS" "$flavour: exit status"
  assert_eq "Opus · my-project · session 24% (resets 2025-02-01 16:00) · week 41% (resets 2025-02-06 16:00)" "$OUT" "$flavour: status line"

  run_hook full.json PATH="$HOME/$flavour:$PATH" CLAUDE_USAGE_DIR="$HOME/$flavour-usage" 'CLAUDE_USAGE_DATE_FORMAT=%a %-I:%M%p'
  assert_eq 0 "$STATUS" "$flavour, format: exit status"
  assert_eq "Opus · my-project · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)" "$OUT" "$flavour, format: status line"

  run_hook full.json PATH="$HOME/$flavour:$PATH" CLAUDE_USAGE_DIR="$HOME/$flavour-usage" CLAUDE_USAGE_DATE_FORMAT=%Q
  assert_eq 0 "$STATUS" "$flavour, bad format: exit status"
  assert_eq "Opus · my-project · session 24% (resets 2025-02-01 16:00) · week 41% (resets 2025-02-06 16:00)" "$OUT" "$flavour, bad format: status line"

  run_hook full.json PATH="$HOME/$flavour:$PATH" CLAUDE_USAGE_DIR="$HOME/$flavour-usage" CLAUDE_STATUSLINE_TZ=America/New_York 'CLAUDE_USAGE_DATE_FORMAT=%F %H:%M %Z'
  assert_eq 0 "$STATUS" "$flavour, zone and format: exit status"
  assert_eq "Opus · my-project · session 24% (resets 2025-02-01 11:00 EST) · week 41% (resets 2025-02-06 11:00 EST)" "$OUT" "$flavour, zone and format: status line"
done

# A date that understands neither form drops the reset text, not the line.
mkdir -p "$HOME/broken"
# shellcheck disable=SC2016 # the stub's own $1 and $@ stay literal
printf '#!/usr/bin/env bash\ncase "$1" in -r|-d|--version) exit 1 ;; esac\nexec "%s" "$@"\n' "$REAL_DATE" > "$HOME/broken/date"
chmod +x "$HOME/broken/date"
run_hook full.json PATH="$HOME/broken:$PATH" CLAUDE_USAGE_DIR="$HOME/broken-usage"
assert_eq 0 "$STATUS" "no epoch support: exit status"
assert_eq "Opus · my-project · session 24% · week 41%" "$OUT" "no epoch support: status line"
