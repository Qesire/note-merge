# note-merge

> opencode skill — AI agent 可执行的 Obsidian 笔记清洗、分类、合并与深化指令集

对 opencode AI agent 的指令集，让它知道当用户丢来零散笔记时，如何清洗→分类→去重→格式化→放入 Obsidian vault（基于 PARA+Zettelkasten），以及如何把空壳概念笔记逐层深化为高质量知识笔记。

---

## 目录

- [应用场景](#应用场景)
- [运行环境](#运行环境)
- [导入/安装](#导入安装)
- [使用方法](#使用方法)
- [Skill 结构](#skill-结构)
- [预期结果](#预期结果)
- [与传统笔记工具的区别](#与传统笔记工具的区别)

---

## 应用场景

这个 skill 解决的是**非结构化笔记→结构化 Obsidian vault**的最后一公里。具体场景：

### 场景 1：聊天记录沉淀

> 你和 AI 讨论了一堆技术概念（MXFP4 格式、Block Rotation、SmoothQuant...），聊天记录在 `chat_export_*.md` 里。

**对 opencode 说：** `merge chat_export_0601.md`

Agent 会：剥离对话套话 → 提取实质知识单元 → 分类到 Quantization/领域 → 去重 → 加上 frontmatter 和 wikilinks → 写入 vault 里对应的目录。

### 场景 2：论文阅读归档

> 你读了一篇论文，逐字摘录了核心方法、实验结果、与你的关联。

**对 opencode 说：** `import paper_notes_raw.md`

Agent 会：识别内容类型（论文笔记）→ 分配标签 `#type/paper` → 补充 arxiv/authors 字段 → 放入 `3-Resources/Papers/<topic>/` → 更新论文 _index.md。

### 场景 3：概念深化（核心功能）

> vault 里有一个 `#status/stub` 的 `MXFP4-Format.md`，只写了标题和一句话定义。你想知道这个概念的完整机理。

**对 opencode 说：** `deepen MXFP4-Format`

Agent 会：读取引用的源码（`mxfp4.py`, `quant_layer.py`）→ 读取相关概念笔记 → 查找实验输出 → 按 5 层深度框架（动机→机制→设计理由→证据→系统性耦合）重写笔记 → 补充 wikilinks → 状态升级为 `polished`。

### 场景 4：批量标准化

> vault 里积压了 30 篇 draft 笔记，frontmatter 不一致，标签缺失，wikilinks 断裂。

**对 opencode 说：** `batch format 2-Areas/Quantization/`

Agent 会：逐篇检查 → 补充 frontmatter → 修复 wikilinks → 断点续传 → 输出处理报告。

### 场景 5：创建新 vault

> 第一次用 Obsidian，想从零建一个 PARA+Zettelkasten 知识库。

**对 opencode 说：** `init-vault`

Agent 会：创建完整目录结构 + `.obsidian/` 配置 + 注入 10 个模板 + _MOCs 占位 → 你可以直接用 Obsidian 打开。

---

## 运行环境

| 层 | 依赖 | 说明 |
|----|------|------|
| **Agent 平台** | [opencode](https://github.com/anomalyco/opencode) | skill 的运行载体；AI agent 负责读取指令文件并执行 |
| **笔记平台** | [Obsidian](https://obsidian.md) 1.0+ | vault 的目标/源平台；所有约定（wikilinks、frontmatter、MOC）均为 Obsidian 原生 |
| **Shell 环境** | bash 4.0+ / zsh | `scripts/` 目录中的 7 个工具脚本依赖 |
| **Python（可选）** | Python 3.9+ | 仅 `dedup-semantic.py` 需要；`pip install sentence-transformers` 可选，无此依赖时会降级到 Jaccard 文本相似度 |
| **文件系统** | 任意 Linux/macOS/WSL | 默认 vault 路径 `~/KnowledgeBase/` |

**无外部 API 依赖**，不需要联网，不需要数据库。所有操作在本地文件和 git 中完成。

### 快速验证环境

```bash
# skill 自身不需要安装任何东西，但可以验证脚本环境
cd ~/.config/opencode/skills/note-merge
bash scripts/validate-frontmatter.sh ~/KnowledgeBase   # 检查 vault 中的 frontmatter
python3 scripts/dedup-semantic.py --help 2>/dev/null || echo "Python 语义去重不可用（正常，可选）"
```

---

## 导入/安装

### 方法 1：git clone（推荐）

```bash
mkdir -p ~/.config/opencode/skills
git clone https://github.com/Qesire/note-merge.git ~/.config/opencode/skills/note-merge
```

openocde 在下次启动时会自动发现 `SKILL.md` 并加载此 skill。

### 方法 2：openocde 内置导入（如果支持）

```
opencode skill import Qesire/note-merge
```

### 验证安装

在 opencode 会话中输入：

```
note-merge 能做什么？
```

如果 agent 回复了 skill 的行动列表（merge / clean / import / deepen / ...），说明加载成功。

### 前置条件

skill 需要 Obsidian vault 存在于 `~/KnowledgeBase/`。如果还没有：

```
init-vault
```

Agent 会自动创建完整的 PARA+Zettelkasten 结构。

---

## 使用方法

skill 通过 opencode 对话触发。所有交互都是自然语言，不需要记忆命令。

### 触发词

Agent 会在以下关键词出现时自动加载此 skill：

| 类型 | 触发词 |
|------|--------|
| 中文 | 整理笔记, 清洗笔记, 合并笔记, 导入笔记, 深化笔记, 深挖, 随笔, 零散笔记, 聊天记录, 初始化vault |
| English | clean notes, merge notes, import notes, deepen notes, chat export, scratch notes, fleeting notes, vault setup, init vault |

### 常用命令速查

```
# 笔记导入
merge chat_export_0519.md              # 多文件全流程导入
clean chat_export_0519.md              # 仅清洗聊天导出（不写入 vault）
import paper_notes.md                  # 单文件快速导入
classify *.md                          # 预分类（dry-run，不写入）

# 概念深化（核心）
deepen MXFP4-Format                    # 单概念深化 → 5 层分析
batch deepen 2-Areas/Quantization/     # 批量深化目录内所有 stub/draft

# Vault 健康
audit                                  # 全量健康扫描（断链、孤儿笔记、过期草稿...）
link-check                             # 验证所有 [[wikilinks]]
track scan                             # 记录 vault 健康快照
track report                           # 查看最近健康报告

# 修复操作
format Block-Rotation                  # 单篇格式化（补充 frontmatter）
batch format 2-Areas/Quantization/     # 批量格式化
batch re-index                         # 重新生成所有 _index.md MOC

# Vault 管理
init-vault                             # 创建新 vault（默认 ~/KnowledgeBase/）
resolve                                # 交互式处理去重冲突
```

### 典型工作流

```
第 1 步: init-vault                              # 创建 vault（仅首次）
第 2 步: merge 聊天记录 / 论文笔记 / 实验日志       # 导入原始材料
第 3 步: audit                                   # 检查 vault 健康
第 4 步: deepen <概念>                            # 深化重要的 stub
第 5 步: batch deepen <领域>                      # 批量深化
第 6 步: track scan && track report               # 记录进展
```

### 进阶：多文件聊天导出

```bash
# 假设有多个聊天导出文件
merge chat_export_0519.md chat_export_0521.md chat_export_0525.md
```

Agent 会：做清单（INVENTORY）→ 逐文件提取 → 跨文件去重 → 统一分类 → 生成 7 条笔记 → 输出合并报告。

---

## Skill 结构

```
note-merge/
├── SKILL.md                          # 主指令文件（agent 入口）
├── templates/                        # 10 个 Obsidian 笔记模板
│   ├── tpl-concept.md                #   初始概念笔记
│   ├── tpl-concept-deepened.md       #   5-layer 深化版概念笔记
│   ├── tpl-paper-note.md             #   论文笔记
│   ├── tpl-experiment.md             #   实验记录
│   ├── tpl-project-index.md          #   项目 MOC
│   ├── tpl-area-index.md             #   领域 MOC
│   ├── tpl-daily.md                  #   日记
│   ├── tpl-codebase.md               #   代码地图
│   ├── tpl-stub.md                   #   占位笔记
│   └── tpl-chat-extract.md           #   聊天导出中间格式
├── references/                       # 详细执行规范（agent 按需加载）
│   ├── merge-workflow.md             #   7-phase 合并流程 + 分类决策树
│   ├── concept-deepening.md          #   5-layer 深化框架 + 质量门
│   ├── batch-operations.md           #   批处理 + checkpoints + track 指标
│   ├── conflict-resolution.md        #   去重冲突决策矩阵
│   ├── vault-setup.md                #   Obsidian vault 初始化
│   └── edge-cases.md                 #   边界情况处理协议
└── scripts/                          # 独立可执行工具（bash + python）
    ├── init-vault.sh                 #   创建 Obsidian vault
    ├── validate-frontmatter.sh       #   检查 frontmatter 完整性
    ├── find-broken-links.sh          #   查找断链 [[wikilinks]]
    ├── check-moc-coverage.sh         #   检查 MOC 覆盖
    ├── scan-stale-drafts.sh          #   发现过期草稿
    ├── tag-inventory.sh              #   标签使用统计
    ├── migrate-status.sh             #   批量状态迁移
    └── dedup-semantic.py             #   语义去重（可选 sentence-transformers）
```

---

## 预期结果

### 导入后的笔记格式

**一篇导入完成的论文笔记：**

```markdown
---
tags: [type/paper, area/quantization, technique/ptq, status/toread]
arxiv: 2405.xxxxx
authors: Wu, et al.
year: 2024
topic: quantization
created: 2026-06-01
source: chat_export_0519.md
---

# PTQ4DiT

## 一句话总结
Block-wise reconstruction for DiT PTQ with timestep-aware calibration.

## 核心方法
- Timestep shuffling in calibration
- Block-level reconstruction with MSE loss

## 与我的研究关联
- 关联项目: [[../../1-Projects/PTQ4DiT/_index|PTQ4DiT]]
- 关联概念: [[Block-Reconstruction]], [[Timestep-Dependent-Activations]]
```

### Deepen 后的完成笔记（5 层）

一篇 stub（3 行）经 `deepen` 后变为结构化笔记：

**Before（stub）：**
```markdown
---
tags: [type/concept, area/quantization, status/stub]
---
# MXFP4 格式
## 定义
一种 4-bit 浮点量化格式。
```

**After（polished，~150-300 行）：**
```markdown
---
tags: [type/concept, area/quantization, technique/mxfp4, status/polished]
created: 2026-05-15
deepened: 2026-06-01
---

# MXFP4 格式

## 1. 动机
Activation quantization in DiT models reveals per-channel variance up to σ=3.4
in QKV projections. Without block-shared scaling, outlier channels dominate
MSE. MXFP4 solves this by using a block-shared E8M0 exponent...

## 2. 机制
源码: mxfp4.py:128 `class MXFP4Quantizer`
Pseudo-code: [5+ steps]
| 公式 | 代码位置 |
|------|---------|
| Ŵ = S × q(W/S) | mxfp4.py:156 forward() |

## 3. 设计理由
Hadamard rotation vs random rotation: Hadamard preserves norm isometry
(proved in QuaRot Lemma 1) while random loses this property.
Block_size=32: matches hardware warp size, verified in mxfp4.py:89.

## 4. 必要性验证
Experiment: tiny_learned_mxfp4_experiment.py
| Method | MSE |
|--------|-----|
| RTN (baseline) | 0.0081 |
| MXFP4 w/ Block Hadamard | 0.0042 |
→ 48% MSE reduction.

## 5. 系统性耦合
上游: [[Block-Rotation]] (Hadamard transform feeds into quantizer)
      [[E8M0 Format]] (shared exponent format used by MXFP4)
下游: [[DiTQuant-Validation]] (project validates MXFP4 on TinyDiT)
      [[PTQ4DiT]] (uses MXFP4 as quantizer backend)
```

### Vault 健康报告

`track report` 输出：

```
Vault Health Report — 2026-06-01 14:00
═══════════════════════════════════════
  Total Notes: 93
    Draft: 14  Stub: 0  Polished: 16  ToRead: 28  Active: 7

  Health Issues:
    Broken Links:      12 ⚠
    MOC Coverage:      78.5% ⚠
    Stale Drafts:       0 ✅
    Missing Frontmatter: 0 ✅

  Top Priority: Fix 12 broken links in Quantization/
```

---

## 与传统笔记工具的区别

| | note-merge skill | Obsidian 插件 | 传统笔记脚本 |
|---|---|---|---|
| **谁来执行** | AI agent（理解内容后自动决策） | 用户手动操作 | 用户手动运行 |
| **分类方式** | 内容语义理解 → 自动判断 PARA 位置 | 用户手动拖拽 | 正则/文件名匹配 |
| **去重** | 语义相似度 + 冲突决策矩阵 | 无 | 文件名比较 |
| **深化** | 读源码 + 读论文 + 5 层分析框架 | 无 | 无 |
| **边界处理** | 7 种边界情况协议 | 无 | 静默失败 |
| **错误恢复** | 断点续传 + dry-run 预览 | 无 | 无 |

**本质区别**：这不是一个"工具"——这是一份给 AI 的 SOP（标准操作流程），告诉 AI 在处理笔记时每一步该做什么、不该做什么、遇到边界情况如何处理。

---

## License

MIT
