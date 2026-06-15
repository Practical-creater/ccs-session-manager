# Changelog

All notable changes to `ccs` are documented here. Versions follow
[semantic versioning](https://semver.org/).

## 1.4.0

- **Recover session names from the conversation file.** A session's name lives
  in its live metadata, which is removed when the process exits. `ccs` now also
  reads the title (`customTitle` / `agentName`) from the `.jsonl` itself, so a
  closed session keeps its name in `list` and can still be targeted by name in
  `move` / `delete`.
- Renamed the `orphaned` status to **`saved`** (less alarming, accurate: the
  conversation is saved on disk and still fully resumable). Updated `clean`
  wording to make clear those sessions are resumable.

## 1.3.0

- **`ccs list --here`** (or `.`) limits the list to the current directory.
  Pass any `<dir>` path to filter by an arbitrary directory. Combines with `-c`.

## 1.2.1

- Fixed garbled directory display: deleted folders with non-ASCII names no
  longer render as `~/Desktop/////////////`. Directory paths are reconstructed
  from the filesystem, and the true name (even of a deleted or CJK-named
  directory) is recovered from the `cwd` recorded inside the conversation file.

## 1.2.0

- **`ccs list -c` / `--compact`** — a slim one-line-per-session view.

## 1.1.0

- **`ccs move <id|name> <dir>`** — relocate a session so it resumes from another
  directory. Refuses to move a running session (checks PID liveness).
- Added detailed Chinese documentation (`README.zh-CN.md`).

## 1.0.0

- Initial release: `list`, `delete`, `clean`, `prune`. Joins conversation files
  with live metadata; shows duplicate copies of a session across folders.
