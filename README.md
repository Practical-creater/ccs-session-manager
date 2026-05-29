# ccs — Claude Code session manager

**[English](README.md) · [简体中文](README.zh-CN.md)**

A tiny, dependency-free CLI to **list, move, and clean up Claude Code sessions**.

Claude Code stores every conversation as a `.jsonl` file under
`~/.claude/projects/<encoded-cwd>/`, keyed by the directory it was launched from.
Over time these pile up — dozens of unnamed sessions across folders you've long
forgotten, including stray copies of the same conversation. Claude Code has no
built-in command to delete one, or to move one to another directory. `ccs` is
that command.

```
  ID   NAME                   DIR                              UPDATED      MSG   SIZE  STATUS
──────────────────────────────────────────────────────────────────────────────────────────
a569  english-talking        ~                                05-30 02:35  201  745KB  ● active
551f  refactor-auth          ~/Desktop/cc-project/cc-0525     05-28 20:49   16   36KB  idle
4043  (unnamed)              ~/Desktop/cc-project/demo        05-26 14:36   10   19KB  orphaned
```

## Install

```bash
git clone https://github.com/Practical-creater/ccs-session-manager.git
cd ccs-session-manager
./install.sh
```

`install.sh` copies the `ccs` script to `~/.local/bin/` and makes it executable.
If that directory isn't on your `PATH`, the installer tells you the one line to
add to your shell config. The only requirement is **Python 3.6+** (standard
library only — no pip, no dependencies).

Or just drop the single `ccs` file anywhere on your `PATH` yourself.

## Usage

```bash
ccs list                      # list all sessions, newest first
ccs move <id|name> <dir>      # move a session so it resumes from <dir>
ccs delete <id|name>          # delete a session (4-char ID prefix or name)
ccs clean                     # delete all orphaned sessions (file, no metadata)
ccs prune <days>              # delete sessions inactive for more than <days> days
ccs help                      # full help
ccs version                   # print version
```

### Examples

```bash
ccs delete a569                            # delete by the first 4 chars of the ID
ccs delete english-talking                 # delete by session name
ccs move a569 ~/Desktop/chats              # relocate a session to another folder
ccs prune 30                               # remove everything untouched for 30+ days
```

When a session exists in **multiple folders** (e.g. after you've copied one),
`ccs delete` and `ccs move` list every copy and let you choose:

```
Found 2 copies of this session — pick which to delete:
  [1] a569  english-talking    ~ (running!)
  [2] a569  (unnamed)          ~/Desktop/cc-project/chats
  [a] all    [q] cancel
```

## Moving a session

`ccs move <id|name> <dir>` relocates a session's conversation file into the
Claude project folder for `<dir>`, so you can resume it from there:

```bash
ccs move english-talking ~/Desktop/chats
cd ~/Desktop/chats && claude --resume          # pick it from the list
```

> **A running session can't be moved.** While a session is open in a terminal,
> the live process keeps rewriting its file — so any copy or delete is undone on
> the next keystroke. `ccs move` detects this and refuses, telling you to exit
> first. The correct order is always: **exit the session → `ccs move` → resume
> in the new directory.**

## How it works

- **`list`** scans `~/.claude/projects/**/*.jsonl` (the conversations) and
  `~/.claude/sessions/*.json` (the live metadata: name, status, cwd, pid) and
  joins them. Each physical file is one row, so duplicate copies are visible.
- The **directory shown is the file's real location on disk** — where
  `claude --resume` will actually find it. Because Claude encodes a path into a
  folder name by replacing every non-alphanumeric character with `-` (losing the
  distinction between a separator and a literal `-` in names like `cc-project`),
  `ccs` reconstructs the true path by checking the filesystem token-by-token.
- **Status:** `● active` = a live process is running it · `idle` = closed but
  known · `orphaned` = a conversation file with no metadata (typical leftover).
  "Running" is determined by checking whether the recorded PID is still alive.

## Notes

- `ccs` only ever reads and deletes **local files under `~/.claude`**. It makes
  no network calls.
- Deleting or moving a **running** session is blocked/flagged — exit it first.

## License

MIT — see [LICENSE](LICENSE).
