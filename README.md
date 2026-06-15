# ccs — Claude Code session manager

**[English](README.md) · [简体中文](README.zh-CN.md)**

A tiny, dependency-free CLI to **list, move, and clean up Claude Code sessions**.

Claude Code stores every conversation as a `.jsonl` file under
`~/.claude/projects/<encoded-cwd>/`, keyed by the directory it was launched from.
Over time these pile up — dozens of sessions across folders you've long
forgotten, including stray copies of the same conversation. Claude Code has no
built-in command to delete one, or to move one to another directory. `ccs` is
that command.

```
  ID   NAME              DIR                          UPDATED       MSG   SIZE  STATUS
a569  english-talking   ~                            05-30 11:44   492    2MB  ● active
551f  refactor-auth     ~/Desktop/cc-project/demo    05-28 20:49    16   36KB  idle
4043  claude-proxy      ~/Downloads/model-proxy      05-26 14:36    10   19KB  saved
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
ccs list [-c|--compact] [--here|<dir>]   # list sessions (optionally compact / filtered)
ccs move <id|name> <dir>                 # move a session so it resumes from <dir>
ccs delete <id|name>                     # delete a session (4-char ID prefix or name)
ccs clean                                # delete all "saved" sessions (no metadata sidecar)
ccs prune <days>                         # delete sessions inactive for more than <days> days
ccs help                                 # full help
ccs version                              # print version
```

### Examples

```bash
ccs list -c                                # slim one-line-per-session view
ccs list --here                            # only sessions for the current directory
ccs list ~/Desktop/cc-project/demo         # only sessions for that directory
ccs delete a569                            # delete by the first 4 chars of the ID
ccs delete english-talking                 # delete by session name
ccs move a569 ~/Desktop/chats              # relocate a session to another folder
ccs prune 30                               # remove everything untouched for 30+ days
```

### Compact view (`-c`)

When you have many sessions, `-c` drops the wide columns down to one tight line
each — ID, a status glyph, the name (or directory if unnamed), and the date:

```
$ ccs list -c
a569 ● english-talking                          05-30 11:44
4043 · claude-proxy                             05-26 14:36
...
45 sessions   ●=active  ·=saved
```

### Filter by directory (`--here` / `<dir>`)

To work on just one project's sessions — e.g. to clean them up — limit the list
to a directory. `--here` (or `.`) uses your current directory; or pass any path:

```bash
cd ~/Desktop/cc-project/demo
ccs list --here        # the 6 sessions that live here
ccs delete 1a0f        # then delete the one you want
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
> the next keystroke. `ccs move` detects this (by checking the recorded PID) and
> refuses, telling you to exit first. The correct order is always: **exit the
> session → `ccs move` → resume in the new directory.**

When a session exists in **multiple folders** (e.g. after copying), `ccs delete`
and `ccs move` list every copy and let you choose which one.

## How it works

- **`list`** scans `~/.claude/projects/**/*.jsonl` (the conversations) and
  `~/.claude/sessions/*.json` (the live metadata: name, status, cwd, pid) and
  joins them. Each physical file is one row, so duplicate copies are visible.
- The **directory shown is the file's real location on disk** — where
  `claude --resume` will actually find it. Claude encodes a path into a folder
  name by replacing every non-alphanumeric character with `-`, which is lossy
  (it can't tell a separator from a literal `-` in names like `cc-project`).
  `ccs` reconstructs the true path by walking the filesystem, and recovers even
  a **deleted** or non-ASCII directory name by reading the real `cwd` stored
  inside the conversation file.
- **Names survive exit.** A session's name lives in its live metadata, which is
  removed when the process ends. `ccs` also reads the title from the
  conversation file itself, so a closed session keeps its name in the list and
  can still be targeted by name in `move` / `delete`.
- **Status:**
  - `● active` — a live process is running it (the PID is alive)
  - `idle` — closed, still has a metadata sidecar
  - `saved` — only the conversation file remains; **still fully resumable**

## Notes

- `ccs` only ever reads and deletes **local files under `~/.claude`**. It makes
  no network calls.
- Deleting or moving a **running** session is blocked/flagged — exit it first.
- `claude --resume` lists only interactive (`cli`) sessions; sessions created
  programmatically through the Agent SDK (`entrypoint=sdk-*`) won't appear there
  but are still visible to `ccs` and removable with `ccs delete`.

## License

MIT — see [LICENSE](LICENSE).
