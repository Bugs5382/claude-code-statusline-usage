# claude-code-statusline-usage 📊

> ⏱️ A status line for the Claude CLI that shows your plan usage and saves it for scripts to read.

The Claude CLI hands its `statusLine` command a JSON payload on every update, including how much of
your plan's usage windows you have spent. This script turns that into one short line under the
prompt, and writes the same numbers to disk. 🗂️ **Scripts, agents and people can then plan work
around the limits** from live figures instead of guesses.

## ✨ Highlights

- 👀 **Usage at a glance:** model, folder, session window and weekly window, each with its reset time.
- 💾 **Saved for later:** `latest.json` on every update, plus a throttled `history.tsv` log.
- 🛟 **Never breaks the prompt:** a missing or odd field is left out, and the script always exits 0.
- 🍎 **macOS and Linux:** works with both BSD and GNU `date`.
- 🔒 **Local only:** reads stdin and nothing else, and never touches the network.
- 🪶 **One dependency:** `jq`. Without it the line still shows, and says `jq` is missing.

## 📦 Install

```bash
git clone https://github.com/Bugs5382/claude-code-statusline-usage.git
cd claude-code-statusline-usage
bash install.sh
```

`install.sh` copies `statusline.sh` to `~/.claude/statusline.sh` and prints the settings snippet.
It does not edit `settings.json`. If a different `~/.claude/statusline.sh` is already there, it is
kept as `statusline.sh.bak.<timestamp>`. Run it again to update.

Then add this to `~/.claude/settings.json`, merged with what is already there:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## 🚀 Usage

The line shows up under the prompt on the next update:

```text
Opus · my-project · session 24% (resets Sat 4:00PM) · week 41% (resets Thu 4:00PM)
```

The usage parts need `rate_limits` in the payload, which **the Claude CLI only sends on Claude.ai
Pro and Max plans, and only after the first reply**. Until then, or on other plans, you get the
model and folder alone (`Opus · my-project`) and nothing is written to disk.

Reset times are shown in your local time zone. Each window is optional. A window without a `resets_at` shows its percentage without the reset
time. The fields read are the ones in the
[status line docs](https://code.claude.com/docs/en/statusline.md):

| Shown as | Payload field |
|---|---|
| model | `model.display_name` |
| folder | last part of `workspace.current_dir` (or `cwd`) |
| session | `rate_limits.five_hour.used_percentage`, `.resets_at` |
| week | `rate_limits.seven_day.used_percentage`, `.resets_at` |

The session window is sent as `rate_limits.five_hour`, but the script assumes no length for it or
for the weekly window. `resets_at` says when each one ends.

## 🗂️ Output files

Both files go to `~/.claude/usage/` (see Configuration). They are written only when the payload
carries usage.

`latest.json` is rewritten on every update, through a temp file and a rename, so a reader never
sees half a file. `captured_at` is the Unix time of the update, and `rate_limits` is copied as the
CLI sent it, including any window this script does not display:

```json
{"captured_at":1738420000,"rate_limits":{"five_hour":{"used_percentage":23.5,"resets_at":1738425600},"seven_day":{"used_percentage":41.2,"resets_at":1738857600}}}
```

`history.tsv` gets one tab-separated row per interval (five minutes by default), with a header
row. The throttle reads the time from the last row, so there is no extra state file. An empty cell
means the payload did not carry that value:

```text
captured_at	session_pct	session_resets_at	week_pct	week_resets_at
1738420000	23.5	1738425600	41.2	1738857600
1738420300	24.1	1738425600	41.4	1738857600
```

Reset times are kept so the real window lengths can be measured from the data: each change in
`session_resets_at` or `week_resets_at` marks the start of a new window.

A quick read from a script:

```bash
jq -r '.rate_limits.five_hour.used_percentage // empty' ~/.claude/usage/latest.json
```

## ⚙️ Configuration

Set these in the environment the CLI runs the command in, for example in the `command` itself
(`"command": "CLAUDE_USAGE_LOG_EVERY=60 ~/.claude/statusline.sh"`).

| Variable | Default | What it does |
|---|---|---|
| `CLAUDE_USAGE_DIR` | `~/.claude/usage` | Folder for `latest.json` and `history.tsv` |
| `CLAUDE_USAGE_LOG_EVERY` | `300` | Minimum seconds between `history.tsv` rows; `0` logs every update |

A value for `CLAUDE_USAGE_LOG_EVERY` that is not a whole number falls back to `300`. If the folder
cannot be created, the line still prints and the files are skipped.

## 🧰 Requirements

- `bash` 3.2 or later (the one macOS ships is fine)
- `jq` (`brew install jq`, `apt install jq`)
- macOS or Linux

## 📄 License

MIT. See [LICENSE](LICENSE).
