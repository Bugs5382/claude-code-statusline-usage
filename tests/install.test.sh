# shellcheck shell=bash
# The installer copies the script, keeps any earlier one, and prints the
# settings snippet without touching settings.json.
out="$(bash "$INSTALLER" 2>&1)"
assert_eq 0 "$?" "exit status"
assert_file "$HOME/.claude/statusline.sh"
[ -x "$HOME/.claude/statusline.sh" ] || fail "installed script is not executable"
cmp -s "$HOOK" "$HOME/.claude/statusline.sh" || fail "installed script differs from the source"
assert_contains "$out" '"statusLine"' "prints the settings snippet"
assert_contains "$out" '"command": "~/.claude/statusline.sh"' "snippet points at the script"
assert_no_path "$HOME/.claude/settings.json"

printf '#!/usr/bin/env bash\necho mine\n' > "$HOME/.claude/statusline.sh"
out="$(bash "$INSTALLER" 2>&1)"
cmp -s "$HOOK" "$HOME/.claude/statusline.sh" || fail "reinstall did not replace the script"
backups=("$HOME/.claude"/statusline.sh.bak.*)
backup="${backups[0]}"
if [ ! -f "$backup" ] || ! grep -q mine "$backup"; then fail "earlier script was not kept as a backup"; fi
assert_contains "$out" "$backup" "names the backup"

bash "$INSTALLER" > /dev/null 2>&1
backups=("$HOME/.claude"/statusline.sh.bak.*)
assert_eq 1 "${#backups[@]}" "same script: no new backup"
