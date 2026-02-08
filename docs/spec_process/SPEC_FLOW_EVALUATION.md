# Spec 流程评估：当前设计 vs OpenSpec

## 一、当前设计摘要

| 维度 | 当前实现 |
|------|----------|
| 结构 | `docs/spec/active/`（进行中） + `docs/spec/archive/`（已结束） + `docs/spec/specs/`（Source of Truth） |
| 状态 | 单文件内文首 `status: proposal \| implementation` |
| 门禁 | spec_manager.mdc：非 Bug 变更必须先改 spec，再写代码 |
| 触发 | 修改 `docs/spec/**` 时 AI 同步实现；改代码时先检查/补 spec |
| 单需求粒度 | 一篇 .md = 一个需求，极简（接口、约定、无实现细节） |

**优点**：极简、无 CLI 依赖、完全由 Cursor rules 驱动，易上手。

---

## 二、OpenSpec 核心设计对比

### 2.1 双轨制：Source of Truth vs 变更提案

| OpenSpec | 当前 |
|----------|------|
| **Source of Truth**：`specs/` 下按领域一份「当前系统行为」的活文档，归档时把本次变更合并进去 | 已引入 `docs/spec/specs/`，归档时合并 delta |
| **变更 (changes/)**：每次改动一个文件夹，内含 proposal / design / tasks / **delta specs** | 只有「单篇需求文档」，无 proposal/design/tasks 拆分，有 delta 语义 |

### 2.2 工件链与 Delta Spec

| OpenSpec | 当前 |
|----------|------|
| proposal → specs(delta) → design → tasks → implement，且允许随时回溯修改 | 单文件混合「做什么 + 约定」，无 proposal/design/tasks 分离 |
| Delta 明确标 ADDED / MODIFIED / REMOVED，归档时按此合并到 Source of Truth | 已规定 ADDED/MODIFIED/REMOVED，归档时合并到 specs/ |

### 2.3 归档与校验

| OpenSpec | 当前 |
|----------|------|
| 归档 = 将 delta 合并进 `specs/` + 变更夹挪到 `changes/archive/` | 已规定：合并到 specs/ + 移入 archive |
| `/opsx:verify`：完整性、正确性、一致性 | 已规定归档前「实现 vs spec」校验 |

### 2.4 工作流弹性

| OpenSpec | 当前 |
|----------|------|
| 动作制：new → ff/continue → apply → verify → archive | 状态机：proposal → implementation → 校验 → 归档 |
| `/opsx:explore` 先探索再建变更；多变更并行 + bulk-archive | 已规定需求不清时先探索；多需求多文件，无 bulk 冲突约定 |

---

## 三、可优化点（按优先级）

### P0：与 Skill 强相关、易落地

1. **Source of Truth** — 已落地：`docs/spec/specs/`，归档时合并 delta。
2. **Delta 语义** — 已落地：ADDED/MODIFIED/REMOVED，归档时合并。
3. **归档前校验** — 已落地：归档前必须做「实现 vs spec」校验。

### P1：增强可执行性

4. **拆分 proposal / design / tasks（可选）** — 复杂需求可采「每需求一目录」+ 多工件。
5. **多变更并行与命名** — 已约定单 active 项 = 一逻辑变更单元，命名 `{领域}_{描述}`（下划线，见领域命名规范）。

### P2：体验与规模

6. **探索** — 已规定需求不清晰时先探索再写 spec。
7. **列表与可见性** — Spec 列表 API 可扩展为读 active + specs，便于 AI/人查看。

---

## 四、建议的规则与目录演进（最小可行）

已纳入 spec_manager.mdc：Source of Truth、Delta、归档前校验、探索。可选：复杂需求用目录+多工件。

---

## 五、文档存放与归档清理（本次补充）

### 5.1 流程类文档的存放

- **业务 spec** 仅存在于：`docs/spec/active/`、`docs/spec/archive/`、`docs/spec/specs/`。`docs/spec/` 根目录仅保留 `README.md`（目录说明）。
- **流程/评估/指引类文档**（如本评估、最佳实践、模板）放在 **`docs/spec_process/`**，不放在 `docs/spec/` 下，避免与业务需求混在一起。
- **规则**：在 spec_manager.mdc 中明确「流程与指引文档存放于 `docs/spec_process/`」；新增此类文档时一律放入该目录。

### 5.2 归档时清理

- **归档动作** 除「合并 delta → 移入 archive」外，须做**清理**：
  - 将该变更**专属**的临时文档（如仅为此变更写的 design-note、临时评估片段等）一并移入 archive 下该变更的目录，或删除；不得留在 `docs/spec/active/` 或 `docs/spec/` 根目录。
  - **常青流程文档**（如 `docs/spec_process/SPEC_FLOW_EVALUATION.md`）不随任何单次变更归档而删除，始终保留在 `docs/spec_process/`。
- **判断**：若某文档只服务于「当前正在归档的这一个变更」，则视为该变更专属，随归档移走或删；若服务于整个 spec 流程或未来所有变更，则放在 `docs/spec_process/` 且不删除。

---

## 六、新需求闭环与可优化点

### 6.1 「直接提出新需求」能否逻辑闭环？

| 环节 | 当前是否闭环 | 说明 |
|------|--------------|------|
| **入口** | ✅ | 在 `docs/spec/active/` 新增一篇 spec（或目录），`status: proposal`，即完成「提出新需求」。 |
| **实现** | ✅ | spec_manager 规定：修改 spec 时 AI 同步实现；实现时先有 spec 再写代码。 |
| **完成定义** | ⚠️ 偏弱 | 未显式规定「实现完成」的判定：如该 spec 所列接口/场景是否都有对应代码且行为一致。建议：在规则中写清「实现完成 = spec 中列出的接口/场景/约定在代码中均有对应且行为一致」；可选在 spec 或同目录 `tasks.md` 中列清单并勾选。 |
| **校验** | ✅ | 归档前必须做「实现 vs spec」校验。 |
| **归档** | ✅ | 合并 delta 到 `specs/<领域>/spec.md`，将变更移入 archive，并做归档清理（见 5.2）。 |
| **可见性** | ⚠️ 可加强 | 提出新需求前若先「列出当前 active 项」，可避免重复或冲突；归档后通过 `archive/` 或 `specs/` 可确认结果。规则可补充：提出新需求时先列出 active，再创建或修改 spec。 |

**结论**：在「提出新需求 → 实现 → 校验 → 归档」主链上可以逻辑闭环；闭环质量可再加强的两点：**实现完成定义**（含可选 tasks 清单）、**提出新需求前先看 active 列表**。

### 6.2 继续对比 OpenSpec 的可优化点

| 优化点 | OpenSpec 做法 | 当前 | 建议 |
|--------|----------------|------|------|
| **实现完成定义** | tasks.md 清单 + 勾选，verify 检查任务与需求覆盖 | 无显式「完成」定义 | 规则中明确「实现完成」定义；复杂需求可选 tasks.md 清单。 |
| **提出前看列表** | `openspec list` 看进行中变更，避免重复 | 无强制步骤 | 规定：提出新需求时先列出 `docs/spec/active/` 下现有项，再创建/修改 spec。 |
| **单次变更 ID/标识** | 变更文件夹名即标识（如 `add_dark_mode`） | 文件名即标识，使用下划线 | 保持即可；若多工件则用目录名作为变更 ID。 |
| **归档后规格可查** | 合并后 `specs/` 即当前系统 | 已支持 | 保持；可配合列表 API 暴露「当前 specs 摘要」。 |
| **多变更冲突** | bulk-archive 时检测同领域冲突、按顺序合并 | 无 | 可选：多变更同时归档时，若涉及同一 `specs/<领域>/spec.md`，按变更完成顺序或显式指定顺序合并，避免覆盖混乱。 |
| **探索后落单** | `/opsx:explore` 后根据结论 `/opsx:new` | 已规定先探索再写 spec | 保持。 |

以上均可通过补充 spec_manager.mdc 条文或 `docs/spec_process/` 下的指引实现，无需引入 CLI。
