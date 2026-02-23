# Spec 全栈开发框架（Claude Code）

本仓库使用 **Spec 驱动开发**：需求写在 `docs/spec/`，流程与检查清单在 `docs/spec_process/`。与 Claude 交流用**中文**；代码与标识符用**英文**。

## 项目结构

- **backend/** — FastAPI + Pydantic v2，统一 `ApiResponse`，依赖注入
- **frontend/** — Next.js 14 + shadcn/ui，响应式，Loading/Error 完备
- **docs/spec/active/** — 进行中的需求（先录需求再写代码）
- **docs/spec/archive/** — 已归档需求（仅历史）
- **docs/spec/specs/** — Source of Truth，按领域一份「当前系统」规格；归档时把 active 的 delta 合并到此
- **docs/spec_process/** — 流程说明、开发清单、归档检查列表、测试最佳实践

## 何时走 Spec

- **触发（仅文档阶段）**：新功能、修改既有功能/行为（如「加一个登录」「订单列表要分页」）→ 在 `docs/spec/active/` 下产出**需求说明 + 设计文档**，然后**停止**，等用户确认或修改文档；**不**在未确认前自动写代码。
- **继续开发**：用户查看/修改文档后说「继续开发」「按文档开发」「开始实现」→ 再按该 spec 与设计实现 backend/frontend 并跑验收。
- **不触发**：修 Bug、提问解释、设计讨论、纯重构（未改对外行为）→ 直接响应，不写 spec。

## 实现与验收（含自循环）

- 实现时按 `docs/spec_process/CHECKLISTS.md` 的「开发清单列表」逐项核对。
- **自循环实现**：当你说「按某 spec 实现并做到验收通过」时，Claude 会按 `.claude/rules/implementation_loop.md` 执行：分析需求 → 拆分任务 → 逐项开发 → 跑验收命令 → 失败则修到过，直到产出测试后的成品。详见下文「在 Claude 中如何用」。

### active spec 建议结构（需求说明 + 设计，便于确认后自循环）

新需求时先产出**需求说明**与**设计**（见 `docs/spec_process/SPEC_DOC_TEMPLATE.md`），结构建议包含：

- **需求说明**：需求简述、背景/目标（可选）、用户故事或场景（可选）、验收标准（文字）。
- **设计**：接口与数据模型、前后端方案、任务拆分（可选）、**验收**（必写，可执行命令）。

验收段示例：`cd backend && pytest ...`、`cd frontend && npm run build`。用户确认文档并说「继续开发」后，Claude 再按此实现并执行验收命令，失败则修到过。

## 归档（仅当用户明确说「归档」「开发完成」等时执行）

1. 确定要归档的 active 项
2. 归档前校验：实现与 spec 一致
3. 完善接口/使用文档（可选）
4. 按 ADDED/MODIFIED/REMOVED 合并到 `docs/spec/specs/<领域>/spec.md`
5. 将该项从 active 移入 archive（建议路径 `archive/YYYY-MM-DD_需求名/`）
6. 归档清理：该变更专属的临时文档移入 archive 或删除

执行时必须按 `docs/spec_process/CHECKLISTS.md` 的「归档检查列表」逐项完成。

## 常用命令

- 后端：`cd backend && pytest`、`cd backend && ruff check .`、`cd backend && pyright`
- 前端：`cd frontend && npm run build`、`cd frontend && npm run lint`
- 前端默认请求 `http://127.0.0.1:8000`，可通过 `NEXT_PUBLIC_API_URL` 覆盖

## 在 Claude 中如何用

**阶段一：提需求 → 只出文档，然后停**

1. 说新功能或改需求，例如：「加一个订单列表分页」。
2. Claude 会在 `docs/spec/active/` 下生成**需求说明 + 设计文档**（见 `docs/spec_process/SPEC_DOC_TEMPLATE.md`），然后**停止**，请你查看或修改文档，不会自动写代码。

**阶段二：确认文档后 → 继续开发（可自循环到验收通过）**

3. 你确认或修改文档后说：「继续开发」「按文档开发」「开始实现」等。
4. Claude 会按该 spec 与设计：拆任务 → 逐项实现 → 跑验收命令 → 失败则修到过，直到通过或需你决策（详见 `.claude/rules/implementation_loop.md`）。
5. 完成后若需归档，再说「归档」或「开发完成」。

---

## 规则与约定

- 自循环实现流程：`.claude/rules/implementation_loop.md`。
- Spec 触发、归档、Delta 语义：`spec_trigger.md`、`spec_manager.md`。
- 全局与后端/前端代码规范：`global_guard.md`、`fastapi_shield.md`、`frontend_architect.md`。
- 领域与 spec 命名（下划线）：`domain_naming_convention.md`。
- API 与 Pydantic 风格：`api_pydantic_style.md`。
