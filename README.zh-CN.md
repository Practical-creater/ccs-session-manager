# ccs — Claude Code 会话管理工具

**[English](README.md) · 简体中文**

一个轻量、零依赖的命令行工具，用来**列出、移动、清理 Claude Code 的会话**。

---

## 目录

- [背景：Claude Code 的会话是怎么存的](#背景claude-code-的会话是怎么存的)
- [ccs 解决什么问题](#ccs-解决什么问题)
- [安装](#安装)
- [命令详解](#命令详解)
  - [`ccs list` — 列出所有会话](#ccs-list--列出所有会话)
  - [`ccs move` — 移动会话到其它目录](#ccs-move--移动会话到其它目录)
  - [`ccs delete` — 删除会话](#ccs-delete--删除会话)
  - [`ccs clean` — 清理孤儿会话](#ccs-clean--清理孤儿会话)
  - [`ccs prune` — 按时间清理](#ccs-prune--按时间清理)
  - [`ccs version` / `ccs help`](#ccs-version--ccs-help)
- [移动会话完整指南（重点）](#移动会话完整指南重点)
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
`claude`，这段对话就存到 `~/.claude/projects/-Users-hector/` 里。目录路径里的
`/` 会被编码成 `-`（实际上所有非字母数字字符都会变成 `-`）。

另外还有一份元数据（会话名、状态、cwd、进程 PID）存在：

```
~/.claude/sessions/<PID>.json
```

`claude --resume` / `claude --continue` 在恢复时，**只看你当前所在目录对应的那个
projects 文件夹**里有哪些 `.jsonl`。这就是为什么「同一段对话能不能恢复」取决于它
所在的文件夹。

## ccs 解决什么问题

用久了你会发现：

- 几十段会话散落在各个早已忘记的目录下，大量是 `(unnamed)`；
- 同一段对话因为复制，在多个文件夹里有副本；
- Claude Code **没有内置命令**来删除某个会话，也没有命令把会话挪到别的目录。

`ccs` 就是补上这块：一个地方看全部会话、把会话搬到指定目录、删掉不想要的。

---

## 安装

```bash
git clone https://github.com/Practical-creater/ccs-session-manager.git
cd ccs-session-manager
./install.sh
```

`install.sh` 会把 `ccs` 脚本复制到 `~/.local/bin/` 并赋予可执行权限。如果该目录
不在你的 `PATH` 里，安装脚本会提示你往 shell 配置里加哪一行。

**唯一要求是 Python 3.6+**（只用标准库，无需 pip，零依赖）。

你也可以直接把单个 `ccs` 文件丢到 `PATH` 上的任意目录里手动安装。

---

## 命令详解

```
ccs list                    列出所有会话
ccs move <id|name> <目录>   把会话移动到指定目录，使其可在该目录恢复
ccs delete <id|name>        删除会话
ccs clean                   删除所有孤儿会话
ccs prune <天数>            删除超过 N 天未活动的会话
ccs version | -v            打印版本
ccs help    | -h            打印帮助
```

会话既可以用 **ID 前 4 位**指定，也可以用**会话名**指定。

### `ccs list` — 列出所有会话

按最近活动时间倒序列出全部会话。**每个物理文件一行**，所以同一会话在不同文件夹
的副本会分别显示，便于区分。

```
  ID   NAME                   DIR                              UPDATED      MSG   SIZE  STATUS
──────────────────────────────────────────────────────────────────────────────────────────
a569  english-talking        ~                                05-30 02:35  201  745KB  ● active
551f  refactor-auth          ~/Desktop/cc-project/cc-0525     05-28 20:49   16   36KB  idle
4043  (unnamed)              ~/Desktop/cc-project/demo        05-26 14:36   10   19KB  orphaned
```

字段含义：

| 字段 | 说明 |
|------|------|
| **ID** | 会话 ID 的前 4 位，用于在其它命令里指定该会话 |
| **NAME** | 会话名（用 `/rename` 设置过的才有，否则显示 `(unnamed)`） |
| **DIR** | 该文件**真实所在的目录**——也就是 `claude --resume` 能找到它的地方 |
| **UPDATED** | 最后活动时间 |
| **MSG** | 用户 / 助手消息条数 |
| **SIZE** | 文件大小 |
| **STATUS** | `● active` 正在运行 · `idle` 已关闭但有记录 · `orphaned` 只有对话文件、无元数据 |

### `ccs move` — 移动会话到其它目录

```bash
ccs move <id|name> <目标目录>
```

把会话的 `.jsonl` 文件复制进 `<目标目录>` 对应的 Claude project 文件夹，并删除
原处的文件，使这段对话从此可以在 `<目标目录>` 下恢复。

```bash
ccs move english-talking ~/Desktop/chats
#   from  /Users/hector
#   to    /Users/hector/Desktop/chats
# Proceed? [y/N] y
# ✓ Moved.
# Resume it with:  cd ~/Desktop/chats && claude --resume
```

> ⚠️ **正在运行的会话无法移动。** `ccs move` 会检测目标会话是否有存活进程占用，
> 若有则**直接拒绝**并提示你先退出。原因见下方[完整指南](#移动会话完整指南重点)。

如果该会话在多个文件夹有副本，`ccs move` 会列出来让你选要移动哪一个；已经在目标
目录里的副本会被自动排除。

### `ccs delete` — 删除会话

```bash
ccs delete a569              # 用 ID 前 4 位
ccs delete english-talking   # 用会话名
```

删除会话，同时移除它的 `.jsonl` 和元数据文件。若该会话在多个文件夹有副本，会逐一
列出让你选择删哪一个（或 `[a]` 全删）：

```
Found 2 copies of this session — pick which to delete:
  [1] a569  english-talking    ~ (running!)
  [2] a569  (unnamed)          ~/Desktop/cc-project/chats
  [a] all    [q] cancel
```

正在运行的会话会标记 `(running!)` 并警告——删了也会被活进程重新写回，应先退出。

### `ccs clean` — 清理孤儿会话

删除所有 **orphaned** 会话（只有 `.jsonl`、没有对应元数据的文件，通常是切换工作
目录后的遗留）。删除前会列出清单并要求确认。

```bash
ccs clean
```

### `ccs prune` — 按时间清理

删除最后活动时间超过 `<天数>` 天的会话。**正在运行的会话永远不会被删。**

```bash
ccs prune 30    # 删除 30 天前的会话
```

### `ccs version` / `ccs help`

```bash
ccs version     # 打印版本号
ccs help        # 打印完整帮助
```

---

## 移动会话完整指南（重点）

这是最容易踩坑的地方，单独讲清楚。

### 为什么不能移动「正在运行」的会话

一个会话在终端里开着的时候，**它的进程会持续往 `.jsonl` 文件里追加内容**。
所以如果你在它还活着的时候去复制 / 删除 / 移动这个文件：

- 你删掉它，下一回合（你一发消息、模型一回复）它立刻又被写回来；
- 你复制走的是一个随时会变旧的快照。

这就像「坐在树枝上锯这根树枝」。所以**移动一个会话，必须先让它停下来。**

`ccs move` 内置了这道保护：它会检查该会话记录的进程 PID 是否还存活，存活就拒绝
移动并提示你先退出。

### 标准三步流程

以「把当前正在用的会话搬到 `~/Desktop/chats`」为例：

```bash
# 第 1 步：在该会话的终端里退出
/exit

# 第 2 步：在任意普通终端执行
ccs move english-talking ~/Desktop/chats

# 第 3 步：去新目录恢复
cd ~/Desktop/chats && claude --resume
```

退出后进程结束，文件定稿，`ccs move` 就能干净地搬走并删除原处文件。之后回到原来
的目录再 `claude --resume`，列表里已经没有它了。

### 手动等价操作

`ccs move` 本质上就是帮你自动完成下面这套（含安全检查）：

```bash
SID=<会话ID>
P="$HOME/.claude/projects"
cp "$P/<源目录编码>/$SID.jsonl" "$P/<目标目录编码>/$SID.jsonl"
rm "$P/<源目录编码>/$SID.jsonl"
```

其中目录编码 = 把绝对路径里所有非字母数字字符换成 `-`。例如
`/Users/hector/Desktop/chats` → `-Users-hector-Desktop-chats`。

---

## 工作原理

- **`list`** 同时扫描 `~/.claude/projects/**/*.jsonl`（对话本体）和
  `~/.claude/sessions/*.json`（元数据：名字、状态、cwd、PID），按真实路径把两者
  关联起来。每个物理文件算一行，所以副本一目了然。
- **DIR 列显示的是文件的物理位置**（即 `claude --resume` 实际会读取的地方），
  而不是对话内容里记录的原始 cwd——一旦会话被复制过，这两者就不一样了。
- 由于 Claude 的目录编码（非字母数字 → `-`）是**有损的**（`cc-project` 和
  `cc/project` 编码后无法区分），`ccs` 通过**逐段查文件系统**来还原真实路径：
  对每一段，看 `/` 拼接还是 `-` 拼接的路径在磁盘上真实存在，从而消除歧义。
  对于已被删除、磁盘上不存在的目录，退回到朴素的 `/` 还原。
- **运行状态判定**：通过检查元数据里记录的 PID 是否还存活来判断会话是否正在运行，
  比单纯看 `status` 字段更可靠（已崩溃但元数据残留的情况也能识别）。

---

## 安全说明

- `ccs` 只读写 **`~/.claude` 下的本地文件**，不发起任何网络请求。
- 删除 / 移动**正在运行**的会话会被拦截或警告——请先退出该会话。
- 所有破坏性操作（delete / clean / prune / move）执行前都会要求确认。

---

## 许可证

MIT，见 [LICENSE](LICENSE)。
