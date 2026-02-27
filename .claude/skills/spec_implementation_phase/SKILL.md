---
name: spec_implementation_phase
description: Spec 模式下的实现阶段：按设计文档拆任务 → TDD 实现 → verify 验收 → code-review，闭环执行，无需人类单独敲 /plan、/verify 等命令。
---

# Spec 实现阶段（内嵌 ECC 式 plan / TDD / verify / code-review）

当用户已确认 `docs/spec/active/` 下某需求的文档并说「继续开发」「按文档开发」等时，**必须按本 Skill 的顺序执行**，形成闭环。本 Skill 将 ECC 的 plan、tdd、verify、code-review 用法内嵌到流程中，无需人类再输入 `/plan`、`/verify` 等命令。

## 触发条件

- 当前需求走的是 **Spec 模式**（用户曾选择 A / Spec）。
- 用户已确认需求说明与设计文档，并说出「继续开发」「按文档开发」「开始实现」等。

## 执行步骤（顺序执行，不可跳过）

### 1. Plan（任务拆分）

- 读取该需求在 `docs/spec/active/` 下的**设计文档**（含任务拆分、验收命令）。
- 若设计文档中已有「任务拆分」节，直接采用；若无，则根据接口与前后端方案**拆成可执行任务列表**（编号列表，如：1. 后端新增 GET /api/xxx；2. 前端列表页；3. 验收）。
- 在回复或同目录 `tasks.md` 中列出任务，便于逐项勾选。**不要**用一句话需求重新「猜」计划，必须以设计文档为准。

### 2. 实现（TDD）

- 按任务列表**逐项**实现。
- 每项或每层采用 **TDD**：先写测试或用例（红）→ 最小实现通过（绿）→ 必要时重构（重构）。与 ECC `/tdd` 一致。
- 实现时遵守 `docs/spec_process/CHECKLISTS.md` 开发清单；涉及 API 时使用项目 Skill `api_pydantic_style`。

### 3. Verify（验证环）

- 实现告一段落或全部完成后，必须执行**验证环**：
  - 运行**设计文档「验收」段**中列出的所有命令（如 `cd backend && pytest ...`、`cd frontend && npm run build`）。
  - 加上：backend 的 build/lint/typecheck（如 `ruff check`、`pyright`）、frontend 的 `npm run build` / `npm run lint`。
- 与 ECC `/verify` 等价：build + test + lint/typecheck + 设计文档验收命令。

### 4. 失败时（build-fix）

- 若 verify 中任一步失败（build 失败、测试失败、lint 报错），**不得**宣布完成。
- 先按失败信息修复（修构建、修测试、修 lint），再**重新执行步骤 3**，直到全部通过。与 ECC `/build-fix` 逻辑一致。

### 5. Code review

- 在认为「实现完成」并准备请人类验收或归档前，必须做**一次代码审查**：
  - 检查：与 spec 一致、边界与错误处理、无遗漏接口、代码质量与规范、安全与依赖。
  - 与 ECC `/code-review` 检查项一致。若发现问题，修改后回到步骤 3 再 verify。

### 6. 交付

- 通过 review 后，向人类汇报：实现已完成，已通过验收与 code review；请验收。若人类说「归档」或「开发完成」，则执行 `spec_manager.mdc` 中的归档流程。

## 与 ECC 的对应

| 步骤 | ECC 等价 | 说明 |
|------|----------|------|
| 1 Plan | `/plan` | 输入为设计文档，输出为任务列表。 |
| 2 实现 | `/tdd` | TDD 红绿重构。 |
| 3 Verify | `/verify` | 设计文档验收命令 + build + lint。 |
| 4 失败 | `/build-fix` | 修到通过再重新 verify。 |
| 5 Code review | `/code-review` | 质量、安全、与 spec 一致。 |

本 Skill 确保 Spec 模式下「继续开发」一次触发即可走完全流程，无需人类记忆或输入多条命令。
