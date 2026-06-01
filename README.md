# note-merge

> opencode skill — 让 AI agent 帮你整理笔记、深化概念、检查 vault 健康

把零散的聊天记录、论文笔记、随笔手记交给 AI，它会：检测文件的结构模式（如何提取）和参考来源（能否追踪）→ 提取知识 → 匹配 vault 中已有内容分类 → 去重 → 按照 Obsidian PARA+Zettelkasten 规范写入 vault。对于浅层概念笔记，可以读取源码和实验数据，逐层深化为高质量知识笔记。

---

## 应用场景

### 场景 1：聊天记录沉淀

> 你和 AI 讨论了一堆技术概念（MXFP4 格式、Block Rotation...），聊天记录在 `chat_export_*.md` 里。

```
整理 chat_export_0601.md
```

Agent 识别为 chat-export → 剥离对话套话 → 按话题分组 → 匹配 vault 已有内容分类 → 写入。聊天对话本身就可以作为参考，不需要额外材料。

### 场景 2：论文笔记归档

> 你读了一篇论文，写了核心方法、实验结果、与你的研究关联。

```
整理 paper_notes.md
```

Agent 识别为 research-report → 检查引用（arxiv ID、repo 路径、实验名）→ 提示你补充原文或代码 → 按 match-first 分类 → 写入 vault → 更新 _index.md MOC。

### 场景 3：概念深化（核心）

> vault 里有一个 `#status/stub` 的 `MXFP4-Format.md`，只有标题和一句话定义。

```
深入 MXFP4-Format
```

Agent 检查参考门槛 → 搜索 `source_repos` 中的源码 → 读取相关概念笔记 → 查找实验数据 → 按 5 层框架（动机→机制→设计理由→证据→系统性）重写 → 状态升级为 polished。

### 场景 4：随笔手记整理

> 随手记录了几个零散想法，没有引用任何论文或代码。

```
整理 scratch_notes.md
```

Agent 识别为 casual-note → 提取为 stub → 写入 vault → 不深化。如果用户尝试 `深入` 这类笔记，Agent 会拒绝并说明需要补充哪些参考材料。

### 场景 5：Vault 健康检查

```
检查
```

Agent 扫描全 vault → 报告断链（按影响面排序）、孤儿笔记、过期草稿、缺少 frontmatter 的笔记。

---

## 运行环境

| 层 | 依赖 |
|----|------|
| **Agent 平台** | [opencode](https://github.com/anomalyco/opencode) |
| **笔记平台** | [Obsidian](https://obsidian.md) 1.0+ |
| **配置文件** | `~/KnowledgeBase/note-merge.json`（由 `init-vault` 生成） |
| **Shell** | bash / zsh（Agent 自身使用） |

无需外部 API，无需 Python 依赖，无需数据库。所有操作在本地文件系统完成。

---

## 导入/安装

```bash
git clone https://github.com/Qesire/note-merge.git ~/.config/opencode/skills/note-merge
```

opencde 启动时自动加载。验证：在 opencode 中说 `note-merge 能做什么？`

### 初次使用

必须先初始化 vault：

```
init-vault
```

Agent 会依次询问：vault 路径、研究领域、源码仓库路径、语言偏好 → 生成 `note-merge.json` → 创建完整的 PARA 目录结构和 `.obsidian/` 配置。

---

## 使用方法

三个用户意图，无需记忆命令：

| 你想做的事 | 对 Agent 说 |
|-----------|------------|
| 把零散笔记导入 vault | `整理 <文件>` / `ingest <files>` |
| 深化一个概念笔记 | `深入 <概念名>` / `deepen <concept>` |
| 检查 vault 健康 | `检查` / `check` |

### 两个独立检查

处理每个文件时，Agent 从两个独立维度检查：

**结构检查 — 决定如何提取：**

| 检测到的模式 | 提取策略 | 例子 |
|-------------|---------|------|
| Q&A 对话 | 按话题分组，提取回答内容 | AI 聊天导出 |
| 章节标题 | 按 H2 切分 | 论文笔记、实验报告 |
| 实验数据表格 | 保留配置+结果为一个单元 | 实验输出日志 |
| 以上皆无 | 按段落分组，作为 stub/draft | 随手记、碎片想法 |

一个文件可以匹配多种模式（如 Q&A 中嵌入了实验数据），全部适用。

**参考检查 — 决定能否深化：**

| 检测到的引用 | 行为 |
|-------------|------|
| arxiv / DOI / URL | 询问用户是否拉取原文 |
| repo / 文件路径 | 询问用户是否读取代码 |
| 实验脚本名 | 询问用户是否查找实验输出 |
| 以上皆无 | 跳过拉取，该笔记后续无法深化，除非用户补充参考 |

两个检查是独立的——结构良好的文件可能没有引用，自由随笔可能引用了 arxiv。

### 分类策略：先匹配再猜测

Agent 不会盲目按关键词分类。它会先搜索 vault 中是否已有相关笔记（标题匹配 → wikilink 上下文匹配），只有在 vault 里找不到任何关联时，才用关键词推测。这确保新笔记总是被放在已有知识的相邻位置。

### 配置驱动

所有行为由 `~/KnowledgeBase/note-merge.json` 驱动：

```json
{
  "vault": "~/KnowledgeBase",
  "domains": ["quantization", "diffusion", "low-level-vision"],
  "source_repos": ["~/TinyFusion", "~/DiTQuantValidation"],
  "language": "zh-CN"
}
```

- `domains` → 生成分类关键词映射和 `2-Areas/` 目录
- `source_repos` → `深入` 时搜索源码的位置
- `language` → 文件名语言选择

---

## Skill 结构

```
note-merge/
├── SKILL.md                    # 主指令（Agent 入口）
├── README.md
├── templates/                  # 4 个核心模板
│   ├── tpl-concept.md
│   ├── tpl-concept-deepened.md
│   ├── tpl-paper-note.md
│   ├── tpl-experiment.md
│   └── tpl-project-index.md
└── references/                 # 按需加载的详细规范
    ├── merge-workflow.md       # ingest 全流程
    ├── concept-deepening.md    # 5-layer 深化框架
    ├── edge-cases.md           # 边界情况
    ├── vault-setup.md          # init-vault 流程
    └── config.schema.md        # note-merge.json 字段说明
```

---

## 预期结果

### ingest 之后

一篇聊天记录经 `整理` 后变成：

```markdown
---
tags: [type/concept, area/quantization, technique/mxfp4, status/draft]
created: 2026-06-01
source: chat_export_0601.md
---

# MXFP4 格式

## 定义
MXFP4 是 4-bit 浮点格式，采用 E2M1 mantissa + E8M0 共享 block scale...

## 来源
从聊天记录提取: chat_export_0601.md
```

### deepen 之后

同一篇笔记经 `深入` 后变成 5 层结构化笔记（动机→机制→设计理由→证据→系统性耦合），含源码 file:line 引用、实验指标数据、上下游 wikilinks。参见 `templates/tpl-concept-deepened.md`。

### check 之后

```
Vault 检查 — 2026-06-01
═══════════════════════════
  断链: 12 个 (影响 25 篇笔记)
    高优先级: [[Cayley-SGD]] — 被 8 篇笔记引用但目标不存在
    ...

  过期草稿: 3 篇 (>30 天未修改)
  孤儿笔记: 5 篇 (无人引用)
  Frontmatter 缺失: 2 篇
```

---

## License

MIT
