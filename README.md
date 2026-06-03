# note-merge

> opencode skill — 让 AI agent 把原始笔记整理进 Obsidian vault，深化可追溯的概念笔记，并检查 vault 健康。

`note-merge` 面向已经存在的源材料：聊天记录、论文笔记、实验记录、随笔手记、研究报告。它不会凭空创建知识，而是先读取本地配置 `note-merge.json`，再对输入文件做三个独立判断：结构检查决定如何提取，推理脉络检查决定保留哪些思考过程，参考检查决定是否具备后续深化所需的可追溯来源。整理完成后，内容会按 Obsidian PARA+Zettelkasten 习惯写入 vault，并尽量与已有笔记、wikilink、MOC 保持一致。

**数据安全：** 绝不会覆盖或删除原始源文件。每次 `整理` 会先把源文件复制到 vault 内的 `3-Resources/Sources/` 作为不可变快照，再从中提取衍生笔记。Agent 会保留原始问题、推理过程、失败尝试和约束上下文，不做有损压缩。

**领域无关：** 核心逻辑（结构检查、推理脉络保留、参考检查、分类匹配、去重、健康检查）不绑定任何学科。`深入` 使用通用的 5 层分析框架（动机→机制→设计理由→必要性验证→系统性耦合），适用于工程技术、自然科学、人文社科、商业策略等任何有可追溯来源的知识领域。

---

## 应用场景

### 场景 1：聊天记录沉淀

> 你和 AI 讨论了一堆技术概念，例如 Concept-A、Method-B、Workflow-C，聊天记录在 `chat_export_*.md` 里。

```
整理 chat_export_0601.md
```

Agent 会把文件识别为 Q&A/对话结构。它会先复制原始文件到 `3-Resources/Sources/` 作为不可变快照，再按话题合并相邻问答。提取时会**保留**：用户问题与动机、约束条件、推理脉络、失败尝试、不确定点、决策理由、技术内容、代码块和引用。**仅去掉**纯粹的问候语、机械性复述和与研究无关的对话噪声。聊天记录可以作为 `source:`，但如果其中没有论文、代码、实验等可追溯参考，生成的笔记只能作为 draft/stub，不能直接深化为 polished。

### 场景 2：论文笔记归档

> 你读了一篇论文，写了核心方法、实验结果、与你的研究关联，并记录了 arXiv、DOI、URL 或 PDF 名称。

```
整理 paper_notes.md
```

Agent 会按章节结构或段落簇提取知识单元，独立检查 arXiv/DOI/URL/PDF 等引用。如果检测到可追溯来源，会询问是否拉取原文或元数据；如果你拒绝，引用仍会被记录到 `## 来源`。分类时先匹配 vault 中已有标题和上下文，再用关键词回退到 PARA 目录。

### 场景 3：概念深化

> vault 里有一个 `#status/stub` 或 `#status/draft` 的概念笔记，内容只有标题、定义和少量上下文。

```
深入 <概念名>
```

Agent 会先检查该笔记当前是否有可追溯来源：`source:`、代码路径、实验脚本/日志、`## 来源`、或指向已有 polished 笔记的 wikilink。满足门槛后，才会读取 `source_repos` 中的相关源码、实验输出和相邻概念笔记，按 5 层框架重写：动机、机制、设计理由、必要性验证、系统性耦合。每层都有具体的通过门槛（如：机制需≥5步描述+≥1处来源定位，设计理由需≥2个具名替代方案，证据需≥1个具名来源+具体数据，系统性耦合需≥2条上游+≥2条下游 wikilink 并解释关系）。任何层证据不足时，不会标记为 polished，而是保留 draft 并写明缺失项。

### 场景 4：随笔手记整理

> 你随手记了几个想法，没有引用论文、代码或实验，只是想先收进知识库。

```
整理 scratch_notes.md
```

Agent 会按自由文本处理，尽量按段落主题切成独立笔记或合并成少量 draft/stub。它不会扩写、不会补全缺失事实，也不会把没有参考来源的随笔直接深化。如果之后执行 `深入`，会要求你补充至少一项可追溯材料。

### 场景 5：Vault 健康检查

```
检查
```

Agent 会扫描 vault，按优先级报告断链、stub 笔记、孤儿笔记、超过 30 天未修改的 draft、超过 60 天未阅读的 toread 论文、frontmatter 缺失、状态标签不一致，以及 `note-merge.json` 中 vault/domain/source_repo 的配置问题。默认只报告，不自动修复；需要修复时要明确说 `fix it` 或类似指令。支持限定范围：`检查 2-Areas/Ecology/` 只检查该子目录。

---

## 运行环境

| 层 | 依赖 |
|----|------|
| **Agent 平台** | [opencode](https://opencode.ai/) |
| **笔记平台** | [Obsidian](https://obsidian.md) 1.0+ |
| **配置文件** | `<vault>/note-merge.json`，默认 `~/KnowledgeBase/note-merge.json` |
| **Shell** | bash / zsh（由 opencode 调用本地文件和 Git 工具） |

无需数据库，也没有独立的 Python/Node 运行时依赖。需要网络的动作只发生在你同意拉取 URL、论文元数据或远程内容时。

---

## 导入/安装

```bash
git clone https://github.com/Qesire/note-merge.git ~/.config/opencode/skills/note-merge
```

安装或更新 skill 后，重启 opencode 才会加载新的 `SKILL.md` 和参考文件。验证方式：在 opencode 中询问 `note-merge 能做什么？`，或直接说 `整理 <文件>`、`深入 <概念>`、`检查 vault`。

### 初次使用

首次使用前需要初始化或准备一个 vault 配置：

```
init-vault
```

Agent 会依次询问 vault 路径、研究领域、源码仓库路径、主要语言，然后创建 PARA 目录骨架、`.obsidian/` 基础配置、`_MOCs/`、`_templates/`，并写入 `note-merge.json`。如果你已经有 vault，也可以提供现有路径；配置文件仍是之后所有动作的入口。

---

## 使用方法

核心使用方式是五个用户意图，外加一次性的初始化：

| 你想做的事 | 对 Agent 说 |
|-----------|------------|
| 初始化 vault 和配置 | `init-vault` / `初始化 vault` |
| 把零散笔记导入 vault | `整理 <文件>` / `ingest <files>` |
| 深化一个概念笔记 | `深入 <概念名>` / `deepen <concept>` |
| 批量深化所有 stub | `deepen --all-stubs` |
| 深化指定领域 stub | `deepen --area <domain>` |
| 检查 vault 健康 | `检查` / `check` |
| 检查指定子目录 | `check 2-Areas/Ecology/` |
| 归档已完结笔记/项目 | `归档 <笔记或目录>` / `archive <note>` |

### 三个独立检查

处理每个源文件时，Agent 都会从三个维度独立检查。它们不是互斥分类，一个文件可以同时是 Q&A、带章节、含实验表格，也可以结构清晰但没有参考来源。

**结构检查 — 决定如何提取：**

| 检测到的模式 | 信号 | 提取策略 |
|-------------|------|---------|
| Q&A 对话 | `**User**:` / `**Assistant**:`、时间戳、轮次切换 | 按问答边界和话题分组，保留问题、约束、推理脉络、失败尝试和回答；仅去掉纯问候和机械复述 |
| 章节标题 | `##` 标题，尤其是方法、结果、实验、分析、Method、Results | 按 H2 切分，每节作为候选单元，过短且同题的相邻节合并；保留引用和限定条件 |
| 实验数据 | 数值指标表、YAML/JSON 配置、对照组 vs 实验组 | 保留配置和结果为同一个实验记录 |
| 代码块 | fenced code block | 概念示例保留在正文；可复用独立脚本才放入 `3-Resources/Code-Tools/` |
| 以上皆无 | 自由散文、碎片想法 | 按段落主题聚类，保留原始思考顺序，保持 draft/stub，不强行扩写 |

**推理脉络保留 — 确保思考过程不被丢弃：**

提取时，Agent 会显式扫描以下信号并保留在衍生笔记中，不作为"填充内容"剔除：

| 信号 | 保留为 |
|------|--------|
| 用户问题、为何提出 | `## 原始问题` |
| 约束条件、假设、偏好 | `## 约束与上下文` |
| 假设、不确定性、TODO | `## 未确定点` |
| 失败尝试、否定结果 | `## 失败尝试` |
| 推理步骤、trade-off、决策理由 | `## 推理脉络` |
| 纠正、反转、矛盾 | `## 待确认` |

不确定是否可丢弃时，一律保留。

**参考检查 — 决定能否追溯和深化：**

| 检测到的引用 | 行为 |
|-------------|------|
| arXiv / DOI / URL / PDF | 询问是否拉取原文或元数据；否则记录到 `## 来源` |
| repo / 文件路径 / `file:line` | 询问是否读取相关代码 |
| 实验脚本名 / 日志 / `results.json` | 询问是否查找实验脚本和输出 |
| 指向已有 polished 笔记的 wikilink | 可作为概念深化的上下文来源 |
| 以上皆无 | 只整理为 draft/stub；后续 `深入` 会被阻止，直到补充参考 |

### 分类策略：先匹配再猜测

Agent 不会只靠关键词分类。它会按以下顺序处理：

1. 精确标题匹配：vault 中已有同名 `.md` 时，合并或去重到该笔记所在目录。
2. 上下文匹配：读取 wikilink、项目名、论文名，搜索 vault 中相邻笔记。
3. 关键词回退：用 `note-merge.json` 的 `domains[]` 和通用关键词映射到 PARA 目录。
4. 歧义处理：多个候选时询问用户；完全无法判断时放入 `0-Inbox/fleeting/` 并报告。

### 配置驱动

所有动作都会先读取 `note-merge.json`。默认位置是 `~/KnowledgeBase/note-merge.json`，实际 vault 路径由其中的 `vault` 字段决定。

```json
{
  "vault": "~/KnowledgeBase",
  "domains": ["<domain-1>", "<domain-2>", "<domain-3>"],
  "source_repos": ["~/<repo-1>", "~/<repo-2>"],
  "language": "zh-CN"
}
```

- `vault`：Obsidian vault 路径。
- `domains`：创建 `2-Areas/<Domain>/`，生成 `#area/...` 标签，并参与分类关键词映射。目录名规则：每词首字母大写、保留连字符、中文原样保留（如 `ecology` → `Ecology/`，`urban-planning` → `Urban-Planning/`，`机器学习` → `机器学习/`）。
- `source_repos`：`深入` 时搜索源码实现、实验脚本和输出的位置。
- `language`：控制文件名和章节语言，支持 `zh-CN`、`en`、`mixed`。

### 数据安全保证

所有 `整理` 动作遵循三层无损保障：

| 层级 | 内容 | 不可变性 |
|------|------|---------|
| **Raw Source** | 原始文件完整副本，存放于 `3-Resources/Sources/YYYY-MM-DD/` | 只读快照，永不修改 |
| **Extracted Notes** | 从原始文件提取的概念/论文/实验笔记 | 衍生品，保留推理脉络和上下文 |
| **Deepened Notes** | 基于可追溯来源的 5 层重写分析 | 重写版本，保留原始 draft 不被覆盖 |

具体规则：

- **绝不覆盖**：提取前将源文件复制进 vault 作为快照；同名快照追加数字后缀，不覆盖。如果 vault 已有同名笔记，只提供"追加 / 创建版本副本 / 跳过"，无"覆盖/替换"选项。批量整理多文件时，可一次性确认所有去重决策，或输入 `all-append` / `all-skip` 快速处理。
- **保留推理脉络**：用户问题、约束条件、假设、不确定性、失败尝试、trade-off、决策理由、纠正和反例**不被视为填充内容**。这些会保留在 `## 原始问题`、`## 约束与上下文`、`## 推理脉络`、`## 未确定点`、`## 失败尝试`、`## 待确认` 等章节中。不确定是否可丢弃时，一律保留。
- **矛盾不抹消**：多个来源对同一概念的矛盾表述会被标记为 `## 待确认`，同时列出双方主张和出处，不做单方面取舍。
- **衍生笔记标注**：每篇从 ingest 生成的笔记必须在 frontmatter 中同时记录 `source:`（原始文件名）和 `source_snapshot:`（vault 内快照路径），确保可追溯到原始材料。同时记录 `created:` 和 `modified:` 日期。
- **操作日志**：每次 `整理` 会在 `_MOCs/` 下生成 `ingest-log-YYYY-MM-DD.md`（`#type/log`），列出所有创建/合并/跳过的笔记路径，方便回滚。归档操作会在原位置留下 `#type/redirect` 重定向笔记。

---

## Skill 结构

```
note-merge/
├── SKILL.md                    # 主指令（Agent 入口，精简版）
├── README.md                   # 项目说明
├── templates/                  # 创建 vault/笔记时使用的模板
│   ├── tpl-concept.md
│   ├── tpl-concept-deepened.md
│   ├── tpl-paper-note.md
│   ├── tpl-experiment.md
│   └── tpl-project-index.md
└── references/                 # 按动作加载的详细规范
    ├── merge-workflow.md       # ingest 全流程
    ├── concept-deepening.md    # 5-layer 深化框架和质量门槛
    ├── vault-check.md          # check / archive 命令规范
    ├── edge-cases.md           # 边界情况和异常处理
    ├── vault-setup.md          # init-vault 流程和目录骨架
    └── config.schema.md        # note-merge.json 字段说明
```

---

## 预期结果

### ingest 之后

一段聊天记录或自由笔记经 `整理` 后，会变成带 frontmatter、来源、快照路径和推理脉络的 draft/stub：

```markdown
---
tags: [type/concept, area/<domain>, technique/<technique>, status/draft]
created: 2026-06-01
modified: 2026-06-01
source: chat_export_0601.md
source_snapshot: 3-Resources/Sources/2026-06-01/chat_export_0601.md
---

# 概念名称

## 原始问题
用户询问该概念的细节、为何采用特定设计，
以及与替代方案在实际场景中的差异。

## 定义
对该概念的一句话描述。

## 机制要点
- 属性1描述
- 属性2描述
- 属性3描述

## 未确定点
- 与替代方案在特定场景下的对比待完成
- 某设计选择的最优方案尚未确定

## 来源
- 原始文件：chat_export_0601.md
- 原始快照：[[3-Resources/Sources/2026-06-01/chat_export_0601.md]]
```

### deepen 之后

同一篇笔记经 `深入` 后，只有在参考门槛和 5 层质量门槛都通过时，才会升级为 `status/polished`，并在 frontmatter 中记录 `deepened: <date>`。完成版应包含：

- 动机：具体问题、约束、去掉该机制会怎样退化。
- 机制：来源定位（`file:line` / 页码 / 章节）、步骤描述（≥5步）、形式描述到具体实现的映射。
- 设计理由：至少两个具名替代方案和具体 trade-off。
- 必要性验证：具名证据来源，以及至少一个具体数据或文献引用。
- 系统性耦合：≥2条上游 + ≥2条下游 wikilink，每条附带关系说明。

如果任一层证据不足，Agent 会保留 `status/draft`，添加 `## 深化待办`，并说明缺少哪些论文、代码或实验数据。

### check 之后

```
Vault 检查 — 2026-06-01
════════════════════════════
高优先级
- 断链: [[<missing-concept>]] 被 8 篇笔记引用，但目标不存在
- 配置问题: source_repos 中 ~/<old-repo> 不存在，已跳过

中优先级
- Stub 笔记: 12 篇，可考虑 deepen
- 过期 draft: 3 篇，超过 30 天未修改
- 积压 toread: 4 篇，超过 60 天未阅读

低优先级
- 孤儿笔记: 5 篇，没有 incoming wikilink
- Frontmatter 缺失: 2 篇，缺少 tags/created/modified
- 状态不一致: 2 篇

建议:
- 3 篇 stub 有可追溯来源，可批量 deepen: deepen --all-stubs
- 1-Projects/<old-project> 已 90 天无更新，考虑归档: archive 1-Projects/<old-project>
```

---

## License

MIT
