# Spec 全栈开发框架

## 项目由来与借鉴

本框架面向 **Vibe Coding**（与 AI 对话式编程），针对「需求理解偏差、任务文档模糊、长对话遗忘约定」等问题，将**需求成文、可追溯、可归档**与**AI 工具链**结合。设计借鉴了以下两方面的思路，并做了统一整合：

### 1. Spec 驱动与文档结构（借鉴 OpenSpec）

- **需求成文**：新功能/改需求时先产出需求说明与设计文档，待确认后再实现，避免「你以为 AI 懂了、AI 实现的是别的」。
- **Delta 与 Source of Truth**：`docs/spec/active/` 进行中，`archive/` 已归档，`specs/` 为当前系统的单一事实来源；归档时按 ADDED/MODIFIED/REMOVED 合并，便于长期维护与老代码演进。
- **流程汉化**：规则与文档以中文为主，降低中文团队的流程与协作成本。

### 2. ECC + Effective harnesses（工具与长线自治）

- **ECC（Everything Claude Code）**：引入其**验证环、TDD、code-review、安全与 API 设计**等能力，以 **Skills** 形式接入；plan/verify/tdd/code-review 内嵌到「继续开发」与 Harnesses 轮次，无需人类单独敲命令。详见 [everything-claude-code](https://github.com/affaan-m/everything-claude-code)。
- **Effective harnesses（Anthropic 长线 Agent）**：提供 **Harnesses 模式**——首轮产出 feature list、init.sh、progress 文件，后续每轮只做一条 feature、E2E 通过才标完成，适合「人类少介入、AI 多轮产出可交付结果」的场景。详见 [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)。

本框架将 **Spec 流程以 Cursor/Claude 的 Rules + Skills 落地**：何时走 Spec、何时走 Harnesses、如何归档由规则与技能驱动；**双模式**可在一仓内并存，按需求选择「精细控制」或「快速产出」。

---

## 项目思路

- **双模式**：新需求/改需求时可选 **A) Spec 流程**（先出需求与设计文档，确认后再实现，适合精细控制与维护老代码）或 **B) Harnesses 流程**（AI 按 feature list 逐条实现并 E2E 验收，适合快速验证与少介入）。
- **Bug/测试/提问/设计讨论**不走上述流程，直接响应。
- **工具增强**：实现阶段自动走「任务拆分 → TDD → verify（验收命令 + build + lint）→ code-review」，与 ECC 的 plan/verify/tdd/code-review 对齐；测试与安全采用 ECC 的 80% 覆盖率与提交前安全检查。
- **Cursor 与 Claude Code 一致**：规则与技能在 `.cursor/` 与 `.claude/` 双份同步，同一套流程两种环境均可使用。

---

## 实现方案

### 规则与技能

- **规则 (rules)**：`spec_trigger` 决定何时走需求流程、是否给出 Spec/Harnesses 选项、继续开发时走哪条 Skill；`spec_manager` 定义归档与 Delta 合并；`global_guard`、`fastapi_shield`、`frontend_architect` 为全局与栈规范；`ecc_testing`、`ecc_security` 为测试与安全约束。
- **技能 (skills)**：  
  - **流程类**：`spec_implementation_phase`（Spec 下继续开发：plan → TDD → verify → code-review）、`harnesses_initializer`（Harnesses 首轮）、`harnesses_coding_session`（Harnesses 每轮一 feature）。  
  - **约定类**：`api_pydantic_style`、`domain_naming_convention`；以及从 ECC 引入的 verification-loop、tdd-workflow、backend/frontend-patterns、api-design、security-review 等。

### 文档与目录

- **docs/spec/**：`active/` 进行中需求，`archive/` 已归档，`specs/` 为 Source of Truth。
- **docs/spec_process/**：流程说明、开发/归档检查清单、测试最佳实践、可安装化说明。

### 可安装化

- 在任意项目根执行 `spec-coding init` 即可接入本框架（含 `docs/spec/`、`.cursor/`、`.claude/`），无需复制整仓；支持 `--backend-dir`、`--frontend-dir`、`--app-package` 与 `--docs-only`。详见 [docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md](docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md)。

---

## 使用方法

### 1. 新需求 / 改需求（必须走需求流程）

- 你：「加一个 xxx」「把 xxx 改成 yyy」等。
- **若未指定模式**：AI 会给出选项，请你选 **A) Spec 流程** 或 **B) Harnesses 流程**。
- **若已指定**：如「用 Spec 做」「走 Harnesses」则直接按该模式执行。

### 2. Spec 模式（先文档再实现）

1. AI 在 `docs/spec/active/` 产出**需求说明 + 设计文档**后**停止**，不写代码。
2. 你查看/修改文档后说「继续开发」「按文档开发」。
3. AI 执行 `spec_implementation_phase`：按设计拆任务 → TDD 实现 → verify（设计中的验收命令 + build + lint）→ code-review → 请你验收。
4. 完成后你说「归档」或「开发完成」，AI 按归档检查列表执行：校验 → 合并 delta → 移入 archive → 清理。

### 3. Harnesses 模式（AI 按 feature 增量产出）

1. **首轮**：AI 执行 `harnesses_initializer`，产出高层范围、`feature_list.json`、`init.sh`、`claude-progress.txt` 及初始提交。
2. **后续轮**：你说「继续」或「下一轮」，AI 执行 `harnesses_coding_session`：选一个未完成 feature → 跑 init + 基线 E2E → 实现 → verify（含 E2E）→ 通过则标 passes，更新 progress 并提交；循环直到全部完成。

### 4. 不触发需求流程

- 修 Bug、写测试、提问、设计讨论、纯重构（未改对外行为）→ 直接响应，不写 spec、不选模式。

### 5. 安装到其他项目

```bash
# 在仓库根安装 CLI
pip install -e .

# 在目标项目根执行（可选参数：--backend-dir, --frontend-dir, --app-package, --docs-only）
spec-coding init
```

接入后得到 `docs/spec/`、`docs/spec_process/`、`.cursor/rules/`、`.cursor/skills/`、`.claude/rules/`、`.claude/skills/`、`CLAUDE.md`，业务目录名可自定义。详见 [docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md](docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md)。

---

## 目录结构

- `backend/` — FastAPI，Pydantic v2，统一 ApiResponse，依赖注入
- `frontend/` — Next.js 14 + shadcn/ui，响应式，Loading/Error 完备
- `docs/spec/active/` — 进行中的需求
- `docs/spec/archive/` — 已归档需求（仅历史）
- `docs/spec/specs/` — **Source of Truth**，按领域一份「当前系统」规格
- `docs/spec_process/` — 流程说明、开发/归档检查清单、测试最佳实践、可安装化文档
- `.cursor/rules/` — 框架规则（spec_trigger、spec_manager、global_guard、fastapi_shield、frontend_architect、ecc_testing、ecc_security）
- `.cursor/skills/` — 流程与约定技能（spec_implementation_phase、harnesses_*、api_pydantic_style、domain_naming_convention 及 ECC 系列）
- `.claude/` — 与 Cursor 能力一致的规则与技能副本，供 Claude Code 使用
- `spec_cli/` — 可安装 CLI，`spec-coding init` 注入框架到任意项目根

更多「框架 vs 项目」冲突及对策见 [docs/spec_process/FRAMEWORK_AND_PROJECT_CONFLICTS.md](docs/spec_process/FRAMEWORK_AND_PROJECT_CONFLICTS.md)。流程与工具安装清单见 [docs/INSTALL_REPORT.md](docs/INSTALL_REPORT.md)。

---

## 技术栈与扩展

- 本仓以 **Python（FastAPI）+ Next.js 14 + shadcn/ui** 为例；规则与技能中的路径、示例针对该栈。
- 使用其他技术栈时，可保留 Spec/Harnesses 流程与规则，由 AI 协助替换或增补对应栈的 skills（如 ECC 的 Python/TypeScript 规则与技能）。
- **Cursor Skills 与 MCP**：推荐清单见 [docs/cursor_skills_and_mcp.md](docs/cursor_skills_and_mcp.md)；可选安装脚本见 `scripts/skills_and_mcps/`。

**后端 Lint / 类型检查**（可选）：`pip install -r requirements_dev.txt` 后执行 `ruff check .`、`ruff format --check .`、`pyright`。前端默认请求 `http://127.0.0.1:8000`，可通过 `NEXT_PUBLIC_API_URL` 覆盖。
