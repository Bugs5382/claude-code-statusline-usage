#!/usr/bin/env bash
# Plain-bash test runner. Each *.test.sh file runs in its own subshell with a
# throwaway HOME, so a test can never read or write the real ~/.claude.
#
#   bash tests/run.sh               # every test file
#   bash tests/run.sh tests/x.test.sh
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TESTS_DIR/.." && pwd)"
FIXTURES="$TESTS_DIR/fixtures"
HOOK="$ROOT/statusline.sh"
INSTALLER="$ROOT/install.sh"
REAL_DATE="$(command -v date)"
export ROOT FIXTURES HOOK INSTALLER REAL_DATE

# Fixed zone and locale so reset times render the same on every machine.
export TZ=UTC LC_ALL=C
unset CLAUDE_USAGE_DIR CLAUDE_USAGE_LOG_EVERY CLAUDE_STATUSLINE_LOGIN CLAUDE_STATUSLINE_FOLDER CLAUDE_CONFIG_DIR CLAUDE_STATUSLINE_TZ

failures=0

fail() {
  printf '    FAIL: %s\n' "$*"
  failures=$((failures + 1))
}

assert_eq() { # <expected> <actual> <label>
  [ "$1" = "$2" ] || fail "$3: expected [$1], got [$2]"
}

assert_contains() { # <haystack> <needle> <label>
  case "$1" in *"$2"*) ;; *) fail "$3: [$2] not found in [$1]" ;; esac
}

assert_not_contains() { # <haystack> <needle> <label>
  case "$1" in *"$2"*) fail "$3: [$2] should not be in [$1]" ;; esac
}

assert_file() { [ -f "$1" ] || fail "missing file: $1"; }
assert_no_path() { [ ! -e "$1" ] || fail "should not exist: $1"; }

# run_hook <fixture-or-"-"> [env assignments...]
# Feeds a fixture (or stdin when "-") to the hook. Sets OUT and STATUS, which
# the sourced test files read.
# shellcheck disable=SC2034
run_hook() {
  local input="$1"; shift
  if [ "$input" = - ]; then
    OUT="$(env "$@" bash "$HOOK" 2>/dev/null)"
  else
    OUT="$(env "$@" bash "$HOOK" < "$FIXTURES/$input" 2>/dev/null)"
  fi
  STATUS=$?
}

# A bin folder holding only the named tools, for tests that hide a command.
make_bin() { # <dir> <tool>...
  local dir="$1" tool p; shift
  mkdir -p "$dir"
  for tool in "$@"; do
    p="$(command -v "$tool")" && ln -sf "$p" "$dir/$tool"
  done
}

files=()
for arg in "$@"; do
  files+=("$(cd "$(dirname "$arg")" && pwd)/$(basename "$arg")")
done
[ "${#files[@]}" -gt 0 ] || files=("$TESTS_DIR"/*.test.sh)

total_failures=0
for t in "${files[@]}"; do
  printf '%s\n' "$(basename "$t")"
  (
    TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/statusline-usage.XXXXXX")"
    export HOME="$TEST_HOME"
    trap 'rm -rf "$TEST_HOME"' EXIT
    cd "$TEST_HOME" || exit 1
    # shellcheck source=/dev/null
    . "$t"
    exit "$failures"
  )
  rc=$?
  if [ "$rc" -eq 0 ]; then echo "  ok"; else echo "  $rc failure(s)"; total_failures=$((total_failures + rc)); fi
done

if [ "$total_failures" -gt 0 ]; then
  echo "FAILED: $total_failures assertion(s)"
  exit 1
fi
echo "all tests passed"
