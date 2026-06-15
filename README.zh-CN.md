# ccs — Claude Code 会话管理工具

**[English](README.md) · 简体中文**

一个轻量、零依赖的命令行工具，用来**列出、移动、清理 Claude Code 的会话**。

---

## 目录

- [背景：Claude Code 的会话是怎么存的](#背景claude-code-的会话是怎么存的)
- [ccs 解决什么问题](#ccs-解决什么问题)
- [安装](#安装)
- [命令详解](#命令详解)
  - [`ccs list` — 列出会话（含精简版与目录过滤）](#ccs-list--列出会话含精简版与目录过滤)
  - [`ccs move` — 移动会话到其它目录](#ccs-move--移动会话到其它目录)
  - [`ccs delete` — 删除会话](#ccs-delete--删除会话)
  - [`ccs clean` — 清理无元数据会话](#ccs-clean--清理无元数据会话)
  - [`ccs prune` — 按时间清理](#ccs-prune--按时间清理)
  - [`ccs version` / `ccs help`](#ccs-version--ccs-help)
- [移动会话完整指南（重点）](#移动会话完整指南重点)
- [状态(STATUS)含义](#状态status含义)
- [工作原理](#工作原理)
- [安全说明](#安全说明)
- [许可证](#许可证)

---

## 背景：Claude Code 的会话是怎么存的

Claude Code 把每一段对话存成一个 `.jsonl` 文件，路径是：

```
~/.claude/projects/<编码后的目录名>/<会话ID>.jsonl
```

关键点：**会话归属于你启动它时所在的目录**。比如你在 `/Users/hector` 下运行
`claude`，这段对话就存到 `~/.claude/projects/-Users-hector/` 里。目录路径里所有
非字母数字字符都会被编码成 `-`。

另有一份**元数据**（会话名、状态、cwd、进程 PID）存在
`~/.claude/sessions/<PID>.json`，它是**临时的**：进程结束就可能被清掉。

`claude --resume` / `claude --continue` 恢复时，**只看你当前目录对应的那个
projects 文件夹**里有哪些 `.jsonl`。所以「能不能恢复」取决于会话文件在哪个文件夹。

## ccs 解决什么问题

- 几十段会话散落在各个早已忘记的目录下；
- 同一段对话因复制在多个文件夹里有副本；
- Claude Code **没有内置命令**删除某个会话，也没有命令把会话挪到别的目录。

`ccs` 补上这块：一个地方看全部会话、把会话搬到指定目录、删掉不想要的。

---

## 安装

```bash
git clone https://github.com/Practical-creater/ccs-session-manager.git
cd ccs-session-manager
./install.sh
```

`install.sh` 把 `ccs` 复制到 `~/.local/bin/` 并赋予可执行权限；若该目录不在 `PATH`，
安装脚本会提示你加哪一行。**唯一要求是 Python 3.6+**（只用标准库，零依赖）。

---

## 命令详解

```
ccs list [-c|--compact] [--here|<目录>]   列出会话（可精简 / 可按目录过滤）
ccs move <id|名字> <目标目录>             把会话移动到指定目录
ccs delete <id|名字>                      删除会话
ccs clean                                 删除所有「无元数据」会话
ccs prune <天数>                          删除超过 N 天未活动的会话
ccs version | -v                          版本号
ccs help    | -h                          帮助
```

会话既可用 **ID 前 4 位**指定，也可用**会话名**。

### `ccs list` — 列出会话（含精简版与目录过滤）

按最近活动倒序列出，**每个物理文件一行**（副本分别显示）。

```
  ID   NAME              DIR                          UPDATED       MSG   SIZE  STATUS
a569  english-talking   ~                            05-30 11:44   492    2MB  ● active
551f  refactor-auth     ~/Desktop/cc-project/demo    05-28 20:49    16   36KB  idle
4043  claude-proxy      ~/Downloads/model-proxy      05-26 14:36    10   19KB  saved
```

| 字段 | 说明 |
|------|------|
| **ID** | 会话 ID 前 4 位，用于在其它命令里指定 |
| **NAME** | 会话名（`/rename` 设过的；现在即使关闭也能显示，见[工作原理](#工作原理)） |
| **DIR** | 文件**真实所在目录**（`claude --resume` 能找到它的地方） |
| **MSG / SIZE** | 消息条数 / 文件大小 |
| **STATUS** | 见[状态含义](#状态status含义) |

**精简版 `-c` / `--compact`** —— 会话多时，把宽表压成一行：ID、状态符号、名字（无名则显示目录）、日期。

```
$ ccs list -c
a569 ● english-talking                          05-30 11:44
4043 · claude-proxy                             05-26 14:36
...
45 sessions   ●=active  ·=saved
```

**按目录过滤 `--here` / `<目录>`** —— 只看某个项目的会话，方便针对性处理。`--here`（或 `.`）用当前目录，也可传任意路径：

```bash
cd ~/Desktop/cc-project/demo
ccs list --here       # 只看这个目录的会话
ccs delete 1a0f       # 然后针对性删

ccs list ~/Downloads/model-proxy   # 不用 cd，直接过滤指定目录
```

可与 `-c` 叠加：`ccs list --here -c`。

### `ccs move` — 移动会话到其它目录

```bash
ccs move <id|名字> <目标目录>
```

把会话的 `.jsonl` 复制进 `<目标目录>` 对应的 project 文件夹，并删除原处文件，使其
能在 `<目标目录>` 下恢复。

```bash
ccs move english-talking ~/Desktop/chats
#   from  /Users/hector
#   to    /Users/hector/Desktop/chats
# Proceed? [y/N] y
# ✓ Moved.
# Resume it with:  cd ~/Desktop/chats && claude --resume
```

> ⚠️ **正在运行的会话无法移动。** `ccs move` 会检查目标会话的进程 PID 是否存活，
> 存活则**直接拒绝**并提示先退出。原因见[移动会话完整指南](#移动会话完整指南重点)。

会话在多个文件夹有副本时，会列出来让你选；已在目标目录的副本自动排除。

### `ccs delete` — 删除会话

```bash
ccs delete a569              # 用 ID 前 4 位
ccs delete english-talking   # 用会话名
```

删除会话（同时移除 `.jsonl` 和元数据）。多副本时逐一列出让你选删哪个（或 `[a]` 全删）。
正在运行的会话会标 `(running!)` 并警告。

### `ccs clean` — 清理无元数据会话

删除所有 **saved**（只有 `.jsonl`、没有活元数据）的会话。删除前列出清单并要求确认。

```bash
ccs clean
```

> 注意：`saved` 不等于垃圾 —— 它们**仍可恢复**。清单看清楚再确认。

### `ccs prune` — 按时间清理

删除最后活动超过 `<天数>` 天的会话。**正在运行的永远不删。**

```bash
ccs prune 30
```

### `ccs version` / `ccs help`

```bash
ccs version     # 打印版本号
ccs help        # 完整帮助
```

---

## 移动会话完整指南（重点）

### 为什么不能移动「正在运行」的会话

会话开着时，进程会持续往 `.jsonl` 追加内容。此时复制/删除/移动这个文件：删了下一回合
又被写回，复制走的是随时变旧的快照 —— 等于「坐在树枝上锯树枝」。所以移动前必须让它停。

`ccs move` 内置保护：检查会话 PID 是否存活，存活就拒绝并提示退出。

### 标准三步流程

```bash
# 1. 在该会话终端里退出
/exit
# 2. 任意普通终端执行（退出后用 ID 最稳，名字也支持）
ccs move a569 ~/Desktop/chats
# 3. 去新目录恢复
cd ~/Desktop/chats && claude --resume
```

---

## 状态(STATUS)含义

| 状态 | 含义 |
|------|------|
| `● active` | 有活进程正在运行它（PID 存活） |
| `idle` | 已关闭，但还留着元数据小档案 |
| `saved` | 只剩对话文件、没有活元数据 —— **仍然完全可以 `claude --resume` 恢复** |

`idle` 和 `saved` 都是「已关闭、可恢复」，区别仅在于那份临时元数据是否还在。元数据是
按进程（PID）临时存在的，进程一退就可能被清，所以大多数历史会话都是 `saved`。

> `claude --resume` 只列**交互式**（`entrypoint=cli`）会话；通过 Agent SDK 程序化
> 创建的会话（`sdk-cli` / `sdk-ts`）不会出现在 `--resume` 里，但 `ccs` 看得见、也能删。

---

## 工作原理

- **`list`** 同时扫描 `~/.claude/projects/**/*.jsonl`（对话本体）和
  `~/.claude/sessions/*.json`（元数据），按真实路径关联。每个物理文件一行，副本一目了然。
- **DIR 显示文件的物理位置**（`claude --resume` 真正读取的地方）。Claude 的目录编码
  （非字母数字 → `-`）是**有损的**（`cc-project` vs `cc/project` 无法区分），`ccs` 靠
  **逐段查文件系统**还原真实路径；对于**已删除**或含中文等特殊字符的目录，则**从对话
  文件里记录的真实 `cwd` 读回原名**。
- **名字在退出后依然保留**：会话名本来只存在临时元数据里，进程一退就没了。`ccs` 还会
  **从对话文件内容里读回标题**（`customTitle` / `agentName`），所以关闭的会话在列表里
  仍显示名字，也能继续用名字做 `move` / `delete`。
- **运行状态判定**靠检查记录的 PID 是否存活，比单看 `status` 字段更可靠。

---

## 安全说明

- `ccs` 只读写 **`~/.claude` 下的本地文件**，不发起任何网络请求。
- 删除 / 移动**正在运行**的会话会被拦截或警告 —— 请先退出。
- 所有破坏性操作（delete / clean / prune / move）执行前都会要求确认。

---

## 许可证

MIT，见 [LICENSE](LICENSE)。
