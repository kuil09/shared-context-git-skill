# Shared Context Git Skill

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

一个为多个AI智能体提供标准化工作流的技能，通过Git托管的远程仓库共享项目上下文。智能体读取和更新由Markdown文件组成的共享记忆，并将Git历史用作审查轨迹。

## 主要功能

- 使用标准文档模板初始化共享上下文仓库
- 在读写前安全同步本地克隆
- 记录稳定事实、活跃上下文、决策、未解决问题和交接内容
- 支持基于分支的上下文更新，可作为diff进行审查
- 当本地状态过时、脏或分叉时安全停止

## 仓库结构

```
├── SKILL.md                    # 技能定义和核心规则
├── agents/
│   ├── openai.yaml             # OpenAI智能体集成配置
│   ├── claude.yaml             # Claude Code智能体集成配置
│   └── codex.yaml              # OpenAI Codex智能体集成配置
├── scripts/                    # 自动化Bash脚本
│   ├── bootstrap_repo.sh       # 从模板创建初始文档
│   ├── check_divergence.sh     # 报告上下文分支的分叉和过期分支
│   ├── cleanup_branches.sh     # 删除旧的已合并context/*分支
│   ├── sync_context.sh         # 获取远程变更并快进
│   ├── prepare_branch.sh       # 创建上下文分支
│   ├── validate_context.sh     # 验证文档结构
│   └── summarize_context.sh    # 输出状态摘要和压缩提示
├── tests/                      # 基于BATS的回归测试
│   ├── *.bats                  # 每个脚本的行为测试
│   ├── test_helper.bash        # 共享测试辅助程序
│   ├── run_tests.sh            # 完整测试运行器
│   └── lib/bats-core/          # 以Git子模块管理的BATS运行器
├── assets/
│   └── templates/              # 文档起始模板
│       ├── CONTEXT.md           # 共享状态文档
│       ├── HANDOFF.md           # 交接笔记（可选）
│       └── POLICY.md            # 协作策略（可选）
└── references/                 # 详细参考文档
    ├── schema.md               # 文档结构规范
    ├── update-rules.md         # 更新规则
    ├── git-workflows.md        # Git工作流模式
    ├── conflict-policy.md      # 冲突处理策略
    └── handoff-guidelines.md   # 交接指南
```

## 文档组成

### 必需文档

| 文档 | 说明 |
|------|------|
| `CONTEXT.md` | 汇总当前项目状态的核心文档，包含概述、稳定事实、活跃上下文、决策和未解决问题等部分。 |

### 可选文档

| 文档 | 说明 |
|------|------|
| `HANDOFF.md` | 给下一个智能体的交接笔记。 |
| `POLICY.md` | 团队协作策略和指南。 |

## 核心规则

1. **先读后写**：先获取或同步，再读取`CONTEXT.md`，然后再编辑。
2. **将共享记忆保存在仓库中**，而不仅仅在会话本地笔记中。
3. **优先使用基于分支的更新**：应避免直接推送到默认分支，若需直接推送须有明确理由。
4. **永不自动解决冲突**：若仓库脏或分支已分叉，停止并进行协调。
5. **区分事实和推断**：已验证的事实放在稳定部分；不确定性在未解决问题中保持可见。
6. **在提交消息中记录变更历史**：使用结构化提交消息（Trigger/Applied/Unresolved），而非单独的文件。

## 使用方法

### 工作流

```bash
# 1. 若仓库不存在则初始化
scripts/bootstrap_repo.sh

# 2. 在本地克隆中同步
scripts/sync_context.sh

# 3. 读取CONTEXT.md，以及HANDOFF.md（如有）

# 4. 若需共享更新则创建分支
scripts/prepare_branch.sh --actor <name> --slug <topic>

# 5. 更新Markdown文件

# 6. 验证文档结构
scripts/validate_context.sh

# 7. 检查diff并汇总当前状态
scripts/summarize_context.sh

# 8. 仅在变更有意义且准确时提交并推送
```

### 脚本指南

| 脚本 | 说明 |
|------|------|
| `bootstrap_repo.sh` | 从模板创建初始文档集。 |
| `check_divergence.sh` | 报告`context/*`分支与基础分支的分叉情况，并标记过期分支。 |
| `cleanup_branches.sh` | 从本地和可选的`origin`上删除已合并的旧`context/*`分支。 |
| `sync_context.sh` | 获取远程变更，并在安全时快进基础分支。 |
| `prepare_branch.sh` | 创建或切换到名为`context/<actor>/<YYYY-MM-DD>-<slug>`的分支。 |
| `validate_context.sh` | 检查必需文件和标题。 |
| `summarize_context.sh` | 输出紧凑的状态摘要和压缩提示。 |

## 测试

```bash
git submodule update --init --recursive
./tests/run_tests.sh
```

- 测试使用BATS验证`scripts/`下工作流脚本的正常和错误路径。
- `tests/run_tests.sh`使用捆绑的`tests/lib/bats-core`子模块运行完整的`.bats`测试套件。

## 协作模式

- **仅本地草稿**：同步、读取、本地编辑、验证后不提交即停止。
- **提交到分支并推送**：创建上下文分支，更新文档，验证，提交，推送。
- **PR提案**：在此完成Git工作，然后将PR创建交给此技能之外的特定提供商工具。

## 参考文档

- [schema.md](references/schema.md) — 文档结构规范
- [update-rules.md](references/update-rules.md) — 更新规则
- [git-workflows.md](references/git-workflows.md) — Git工作流模式
- [conflict-policy.md](references/conflict-policy.md) — 冲突处理策略
- [handoff-guidelines.md](references/handoff-guidelines.md) — 交接指南

## 智能体配置

`agents/`目录中包含适用于各智能体框架的配置文件。

| 配置文件 | 智能体 | 默认执行者名称 | 分支前缀 |
|---------|--------|--------------|---------|
| `agents/openai.yaml` | OpenAI Agents | `openai` | `context/openai` |
| `agents/claude.yaml` | Claude Code | `claude` | `context/claude` |
| `agents/codex.yaml` | OpenAI Codex | `codex` | `context/codex` |

每个配置包含技能参考路径（`skill_paths`）、默认参数（`parameters`）和工作流提示（`workflow_hints`）。

### OpenAI Agents用法

```bash
# 配置文件路径: agents/openai.yaml
# 分支创建示例:
scripts/prepare_branch.sh --actor openai --slug my-topic
```

### Claude Code用法

```bash
# 配置文件路径: agents/claude.yaml
# 分支创建示例:
scripts/prepare_branch.sh --actor claude --slug my-topic
```

### Codex用法

```bash
# 配置文件路径: agents/codex.yaml
# 分支创建示例:
scripts/prepare_branch.sh --actor codex --slug my-topic
```

## 系统要求

- Git CLI
- Bash shell
- 标准Unix工具（grep、awk等）

无外部包或库依赖。
