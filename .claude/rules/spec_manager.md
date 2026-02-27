# Spec Manager

用户提出「新功能」或「修改既有功能」时，由 spec_trigger 自动触发本流程。修 Bug、提问、设计讨论等不触发。

## 状态机

- **提案 (proposal)**：需求说明与设计文档已产出，**等待用户确认**；未确认前不写代码。
- **实现 (implementation)**：用户已确认文档并说「继续开发」，开发中，代码需与本文档一致。
- **归档 (archive)**：校验通过后，将 delta 合并进 Source of Truth，再移入 `docs/spec/archive/`。

流转：提案（产出文档 → 停止等确认）→ 用户确认 → 实现 → 校验 → 归档。**不得在用户确认前从提案直接进入实现。**

## 新需求时：需求说明 + 设计文档（然后停止）

当 spec_trigger 识别为「新功能/改需求」时，只做以下两件事，然后**停止**，等用户确认或要求修改文档：

1. **需求说明文档**：在 active 下 spec 中或同目录，包含——需求简述、背景/目标、用户故事或场景、验收标准（文字描述）。可对应 spec 的「需求说明」节。
2. **设计文档**：在同一 spec 或同目录 `design.md` 中，包含——接口与数据模型、前后端方案、任务拆分（可选）、验收命令（可执行）。可对应 spec 的「设计」节及「验收」段。

推荐将需求说明与设计写在**同一份 spec** 中，用二级标题区分（见 `docs/spec_process/SPEC_DOC_TEMPLATE.md`）。完成后回复请用户查看文档，确认或修改后说「继续开发」再实现。

## 目录与 Source of Truth

- **active/**：进行中的变更（单文件或单目录均可）。
- **archive/**：已结束的变更，仅历史；不再驱动开发。
- **specs/**：Source of Truth。按领域分目录（如 `specs/auth/`、`specs/spec_list/`），每领域一份 `spec.md` 描述**当前系统**已合入的行为与约定。归档时必须把本次变更按 delta 合并进对应 `specs/<领域>/spec.md`。领域名与 spec 文件名一律使用**下划线**，见 Skill domain_naming_convention（`.claude/skills/domain_naming_convention/SKILL.md`）。

## Delta 语义（借鉴 OpenSpec）

在 active 下的 spec 中，用标题或块标明变更类型，便于归档时合并：

- **ADDED**：新增需求/接口/场景 → 归档时追加到 Source of Truth 对应小节。
- **MODIFIED**：修改现有描述 → 归档时替换 Source of Truth 中对应部分。
- **REMOVED**：删除的需求 → 归档时从 Source of Truth 中移除。

未标明的段落视为 ADDED。

## 文档存放

- **业务 spec** 仅存在于 `docs/spec/active/`、`docs/spec/archive/`、`docs/spec/specs/`。`docs/spec/` 根目录仅保留 README。
- **流程/评估/指引类文档**（流程评估、对比、模板、最佳实践）放在 **`docs/spec_process/`**，不得放在 `docs/spec/` 下或与业务 spec 混放。

## 强制规则

1. **门禁**：任何非 Bug 的功能/接口/UI/数据模型变更，必须先在此目录下新增或修改对应 spec，再写 backend/frontend 代码。
2. **格式**：文首一行 `status: proposal | implementation`；内容极简；若需可追溯合并，使用 ADDED/MODIFIED/REMOVED 标记。
3. **命名**：`{领域}_{简短描述}.md` 或目录 `{领域}_{描述}/`，如 `auth_login.md`、`spec_list_api.md`。一律使用**下划线**，禁止中划线；详见 Skill domain_naming_convention（`.claude/skills/domain_naming_convention/SKILL.md`）。
4. **实现完成定义**：该 spec 中列出的接口/场景/约定在代码中均有对应且行为一致；**开发时须按 `docs/spec_process/CHECKLISTS.md` 中的「开发清单列表」逐项核对**，可选在 spec 或同目录 `tasks.md` 中列子项并勾选。
5. **提出新需求时**：先列出 `docs/spec/active/` 下现有项，避免重复或冲突，再创建或修改 spec。
6. **归档前校验**：将某需求归档前，必须先执行一次「实现 vs spec」校验：列出该 spec 涉及的任务/接口/场景，检查 backend/frontend 是否有对应实现与行为；不一致则先改 spec 或代码再归档。
7. **归档动作**：校验通过后，(1) 按 delta 合并到 `specs/<领域>/spec.md`，(2) 将 active 中该变更移入 archive，(3) **归档清理**：将该变更专属的临时文档一并移入 archive 下该变更目录或删除，不得留在 active 或 `docs/spec/` 根目录。**归档时必须按 `docs/spec_process/CHECKLISTS.md` 中的「归档检查列表」逐项执行。**

## 归档流程（仅当用户明确说「归档」或「开发完成」等时按序执行）

执行时**必须对照 `docs/spec_process/CHECKLISTS.md` 中的「归档检查列表」逐项完成**。

1. **确定对象**：用户指定的 active 项，或当前对话涉及 / 最近在做的 active 项；若多个则列出让用户选一个。
2. **归档前校验**：列出该 spec 的接口/场景/约定，逐项检查 backend/frontend 是否有对应实现且行为一致；不一致则先改 spec 或代码再继续。
3. **完善文档**（推荐）：补充该需求对应的接口文档（如 FastAPI 路由的 docstring、请求/响应说明）与必要时使用说明。
4. **合并 delta**：按 ADDED/MODIFIED/REMOVED 将变更合并进 `specs/<领域>/spec.md`；无对应领域文件则新建。若多个 active 涉及同一 `specs/<领域>/spec.md`，按完成顺序或用户指定顺序依次合并。
5. **移入 archive**：将该项从 `docs/spec/active/` 移入 `docs/spec/archive/`（可带日期与下划线名称，如 `archive/2025-02-07_spec_list_api/`）。
6. **归档清理**：将该变更专属的临时文档移入其 archive 目录或删除，不在 active 或 spec 根目录遗留。

执行完后简要回复：已归档 [需求名]，已合并到 specs/[领域]，接口/使用文档已补充（若做了）。

## 执行

- **被 spec_trigger 触发「新功能/改需求」时**：只产出需求说明 + 设计文档到 `docs/spec/active/`，**然后停止**，请用户确认或修改文档，待用户说「继续开发」后再实现。不得在未确认前自动开始写代码。
- **用户说「继续开发」「按文档开发」等时**：确认针对的是哪一项 active，再按该 spec 与设计文档实现或修改 backend/frontend。
- **用户明确说「归档」或「开发完成」等时**：按上文「归档流程」六步执行。
- 修改 `docs/spec/**` 时：据此同步修改 backend/frontend。
- **需求取消**：若某 active 决定不做了，可将该变更移入 archive 并命名为 `archive/YYYY-MM-DD_<name>_cancelled` 或在 spec 文首标 `status: cancelled` 并简短注明原因。
