---
name: harnesses_coding_session
description: Harnesses 模式每轮执行：选一个未完成 feature → init+基线 E2E → 实现 → verify → 标 passes → 更新 progress 并提交。
---

# Harnesses 编码 Session（每轮）

当用户在 **Harnesses** 模式下说「继续」「下一轮」「接着做」，或新 session 检测到已有 `feature_list.json` 与 `claude-progress.txt` 时，执行本 Skill。每轮**只做一条** feature，通过验证后才标记完成并交接。

## 触发条件

- 用户已选择 **B / Harnesses** 模式，且 **harnesses_initializer** 已执行过（存在 feature list 与 progress 文件）。

## 执行步骤（每轮闭环）

### 1. Plan（选一个 feature）

- 读取 **`feature_list.json`** 与 **`claude-progress.txt`**（或项目约定路径）。
- 在 `passes === false` 的条目中，按优先级或依赖选**一个** feature 作为本轮目标。
- 若全部已 `passes === true`，则回复：所有 feature 已完成；可请人类验收或归档。

### 2. 环境与基线

- 执行 **`init.sh`**（或等价），确保开发环境/服务已启动。
- 跑一次**基础 E2E 或冒烟测试**，确认当前应用处于可运行状态。若失败，先修到通过再开始本 feature，避免在坏基础上叠加改动。

### 3. 实现

- **仅**实现本轮选中的那一条 feature。
- 建议按 **TDD**：先写/补该 feature 的测试或 E2E 步骤，再实现代码，通过后再重构。
- 实现时遵守项目既有规范（如 `global_guard.mdc`、`api_pydantic_style`）。

### 4. Verify

- 运行 **build + 单元/集成测试 + 本 feature 的 E2E 验证**（若有浏览器/Puppeteer 等 MCP 或脚本，用其验证该条 steps）。
- **只有**本 feature 的验收全部通过后，才可将该条在 `feature_list.json` 中设为 **`passes: true`**。禁止未通过就标记完成。
- 与 ECC `/verify` 一致：build、test、E2E。

### 5. 失败时

- 若 build 失败或测试/E2E 失败，先修复（等同 ECC `/build-fix`），再重新执行步骤 4，直到通过。

### 6. 交接

- 写 **git commit**：清晰描述本轮完成的 feature（如 `feat(harnesses): implement <description>`）。
- 更新 **`claude-progress.txt`**：记录本轮完成的 feature、关键文件、已知注意点，便于下一轮或新 session 接上。

### 7. Code review（可选）

- 每完成 1 个 feature 或每 N 个 feature，可做一次代码审查（与 ECC `/code-review` 一致）；若做，在 progress 中略记。

### 8. 下一轮

- 若仍有 `passes === false` 的 feature，回复：本轮已完成 [feature 描述]；说「继续」或「下一轮」将进行下一条。若全部完成，回复：所有 feature 已完成，请验收。

## 与 Effective harnesses 文章一致

- 每轮只做**一个** feature，避免一次做太多导致 context 耗尽或半成品。
- 通过 **feature list + progress + git** 交接，新 session 可快速接上。
- 仅在实际通过 E2E/验收后才改 `passes`，避免过早宣布完成。
