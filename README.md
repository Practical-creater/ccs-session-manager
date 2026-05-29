# ccs — Claude Code session manager

A tiny, dependency-free CLI to **list, inspect, and clean up Claude Code sessions**.

Claude Code stores every conversation as a `.jsonl` file under
`~/.claude/projects/<encoded-cwd>/`, keyed by the directory it was launched from.
Over time these pile up — dozens of unnamed sessions across folders you've long
forgotten, including stray copies of the same conversation. Claude Code has no
built-in command to delete one. `ccs` is that command.

```
  ID   NAME                   DIR                              UPDATED      MSG   SIZE  STATUS
──────────────────────────────────────────────────────────────────────────────────────────
a569  english-talking        ~                                05-30 02:35  201  745KB  ● active
551f  refactor-auth          ~/Desktop/cc-project/cc-0525     05-28 20:49   16   36KB  idle
4043  (unnamed)              ~/Desktop/cc-project/demo        05-26 14:36   10   19KB  orphaned
```

## Install

```bash
git clone https://github.com/<you>/ccs.git
cd ccs
./install.sh
```

`install.sh` copies the `ccs` script to `~/.local/bin/` and makes it executable.
If that directory isn't on your `PATH`, the installer tells you the one line to
add to your shell config. The only requirement is **Python 3.6+** (standard
library only — no pip, no dependencies).

Or just drop the single `ccs` file anywhere on your `PATH` yourself.

## Usage

```bash
ccs list                 # list all sessions, newest first
ccs delete <id|name>     # delete a session (4-char ID prefix or name)
ccs clean                # delete all orphaned sessions (file, no metadata)
ccs prune <days>         # delete sessions inactive for more than <days> days
ccs help                 # full help
ccs version              # print version
```

### Examples

```bash
ccs delete a569              # delete by the first 4 chars of the ID
ccs delete english-talking   # delete by session name
ccs prune 30                 # remove everything untouched for 30+ days
```

When a session exists in **multiple folders** (e.g. after you've copied one),
`ccs delete` lists every copy and lets you choose which to remove — or `[a]ll`:

```
Found 2 copies of this session — pick which to delete:
  [1] a569  english-talking    ~ (running!)
  [2] a569  (unnamed)          ~/Desktop/cc-project/chats
  [a] all    [q] cancel
```

## How it works

- **`list`** scans `~/.claude/projects/**/*.jsonl` (the conversations) and
  `~/.claude/sessions/*.json` (the live metadata: name, status, cwd) and joins
  them. Each physical file is one row, so duplicate copies are visible.
- The **directory shown is the file's real location on disk** — where
  `claude --resume` will actually find it. Because Claude encodes a path into a
  folder name by turning `/` into `-` (losing the distinction between a
  separator and a literal `-` in names like `cc-project`), `ccs` reconstructs
  the true path by checking the filesystem token-by-token.
- **Status:** `● active` = a process is running it · `idle` = closed but known ·
  `orphaned` = a conversation file with no metadata (typical leftover).

## Notes

- **Don't delete a running session** — the live process will just rewrite the
  file. `ccs` flags active sessions with `(running!)`; exit them first.
- **Moving a session** to another directory isn't a `ccs` command, but it's
  easy: copy its `.jsonl` into the target directory's `projects` folder, then
  run `claude --continue` (or `--resume`) there.
- `ccs` only ever reads and deletes **local files under `~/.claude`**. It makes
  no network calls.

## License

MIT — see [LICENSE](LICENSE).
