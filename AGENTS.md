# AGENTS.md - claude-code-statusline-usage

Guide for agents working in this repository. Pair with `CLAUDE.md` (the working agreement and
hook-enforced rules). Keep this file current when the script, its output files or its settings
change.

## What this is

A `statusLine` command for the Claude CLI (project type `claude-code`, variant `statusline`). It
reads the status-line JSON on stdin, prints one line (model, optional login, folder, session
window and weekly window usage), and saves the usage to `latest.json` and a throttled `history.tsv`.

The one thing to understand before changing it: the prompt waits on this script, so it must never
fail. Every field is optional, every error is swallowed, and the exit status is always 0.

## Using claude-code-statusline-usage

The contract other scripts rely on is the output files, documented in `README.md`:

- `latest.json`: `{"captured_at": <epoch>, "rate_limits": <as sent>}`, replaced atomically.
- `history.tsv`: the header `captured_at session_pct session_resets_at week_pct week_resets_at`
  (tab-separated), one row per interval. Adding a column is a breaking change for readers.
- The settings are `CLAUDE_USAGE_DIR`, `CLAUDE_USAGE_LOG_EVERY`, `CLAUDE_STATUSLINE_LOGIN` (`1`
  shows the login, off by default), `CLAUDE_STATUSLINE_FOLDER` (`0` hides the folder),
  `CLAUDE_STATUSLINE_TZ` (an IANA zone for the reset times only; process `TZ` when unset, empty,
  equal to `TZ`, or not a real zone) and `CLAUDE_USAGE_DATE_FORMAT` (a `date` format for both
  reset times, default `%Y-%m-%d %H:%M`; a format with a conversion outside the set BSD and GNU
  `date` share, a control character, no conversion, or more than 64 characters falls back to the
  default).
- Reset times are display only: `latest.json` and `history.tsv` keep `resets_at` as epoch seconds
  whatever the format or zone.
- Stdin is the only input unless `CLAUDE_STATUSLINE_LOGIN=1`, which also reads
  `${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json`. Keep that read behind the toggle.

Never state a window's length anywhere (docs, comments, output, test names). Call them the session
window and the weekly window; `five_hour` and `seven_day` appear only as the JSON field names.

## Layout

- `statusline.sh` - the script users install.
- `install.sh` - copies it to `~/.claude`, keeps a different earlier copy as a `.bak`, and prints
  the settings snippet. It never edits `settings.json`.
- `tests/run.sh` - the runner and its assertion helpers.
- `tests/<case>.test.sh` - one behaviour per file, sourced by the runner with a temporary `HOME`.
- `tests/fixtures/` - sample stdin payloads.

## Build, test, lint

- Lint: `shellcheck statusline.sh install.sh tests/*.sh`
- Test: `bash tests/run.sh` (or `bash tests/run.sh tests/<case>.test.sh`). Needs `jq`.
- CI runs both in one `✅ Checks` job (`.github/workflows/checks.yaml`) with a pinned shellcheck.

## Logging

The script has no logging on purpose: anything it writes to stdout lands in the status line, and
it runs on every prompt update. Keep it that way; debug with the tests instead.

## Conventions and gotchas

- See `CLAUDE.md` for the branch/commit/PR rules; they are enforced by the git hooks in
  `.claude/hooks` (run `bash .claude/hooks/install.sh` once per clone).
- Open every PR as a draft. CI skips drafts, so run the full checks locally, push once they pass,
  and mark the PR ready when the work is finished; see CLAUDE.md "CI and Actions minutes".
- Stay on bash 3.2 features, since that is what macOS ships as `/bin/bash`.
- GNU `date -r` takes a file name, not an epoch. The script detects GNU date and only gives it
  `-d @<epoch>`; the date tests stub both flavours, so keep them passing on macOS and Linux.
- The reset-time format allowlist in `valid_date_format` exists so a format prints the same text
  on both flavours. Only add a conversion to it after checking BSD and GNU `date` agree on it.
- The hook's AI-tell list blocks the CLI's two-word product name in tracked files outside
  `CLAUDE.md` and `.claude/`, so the docs say "the Claude CLI".
- Releases: no manifest and no `CHANGELOG.md`. The GitHub Release notes are the changelog, and the
  owner publishes them by hand.
