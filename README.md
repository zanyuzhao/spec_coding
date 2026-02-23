# Spec 全栈开发框架

## 项目由来与意义

本项目的设计借鉴了 **OpenSpec** 的开发模式，针对 **Vibe Coding**（与 AI 对话式编程）中常见的问题做了专门优化：

- **需求理解幻觉**：纯对话容易产生「你以为 AI 懂了、AI 以为你要的是别的」的偏差，导致实现与预期不符。
- **任务与需求文档模糊**：没有成文的需求时，AI 容易在长对话中遗忘或曲解早期约定，幻觉被不断放大。
- **传统 Spec 的上下文挤占**：若把整份大 spec 塞进对话，会挤占 Cursor 的上下文窗口，影响后续实现与检索效率。
- **流程及文档汉化**： 避免中文开发者需要处理大量应为流程和需求文档

本框架将 **Spec 流程以 Cursor Rules + Skills 的方式集成**：需求落在轻量的 `docs/spec` 文档中，**何时走 Spec、如何归档**由规则与技能驱动，AI 按「先录需求再实现」执行，无需你背诵流程。这样既保留了「需求成文、可追溯、可归档」的好处，又避免了「大文档占满上下文」的问题。同时项目内提供 **API 风格、领域命名、测试最佳实践** 等多项 Skill 与检查清单，便于 AI 与人类协同时保持风格一致、减少返工。

简单了解项目后，即可在 Cursor 中实现 **Spec 驱动 + AI 提效** 的最佳实践，适合作为团队或个人在 Cursor 中进行规范开发的起点。

---

## 快速理解：项目架构与 Spec 流程

### 项目基本架构（逻辑关系）

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                     Cursor  IDE / 你                      │
                    └───────────────────────────┬───────────────────────────────┘
                                                │
            ┌───────────────────────────────────┼───────────────────────────────────┐
            ▼                                   ▼                                   ▼
   ┌─────────────────┐               ┌─────────────────┐               ┌─────────────────┐
   │ .cursor/rules/  │               │ .cursor/skills/ │               │   docs/spec/    │
   │ 何时走 Spec、   │               │ API 风格、      │               │ 需求写在这里    │
   │ 如何归档、      │◄──────────────│ 命名规范、      │──────────────►│ active / archive│
   │ 后端/前端规范   │  按需触发      │ 测试最佳实践等  │  读写、归档    │ / specs(真相源)  │
   └────────┬────────┘               └─────────────────┘               └────────┬────────┘
            │                                                                   │
            │ 驱动实现、校验、归档                                                │ 实现需与 spec 一致
            ▼                                                                   ▼
   ┌─────────────────────────────────────────────────────────────────────────────────┐
   │  backend/ (FastAPI + Pydantic)     │     frontend/ (Next.js + shadcn/ui)        │
   └─────────────────────────────────────────────────────────────────────────────────┘
```

- **规则 (rules)**：决定「新功能/改需求」时自动走 Spec、归档时做校验与合并；后端/前端各有代码规范。
- **技能 (skills)**：在改 API、命名、写测试时提供统一约定；框架技能在 `.cursor/skills/`（如 `api_pydantic_style`、`domain_naming_convention`），项目专属技能可放同级其他子目录。
- **docs/spec**：`active/` 进行中需求，`archive/` 已归档，`specs/` 为当前系统的「单一事实来源」，归档时把 delta 合并进去。

### Spec 工作流程

**两阶段流程**：提新需求时 AI 只产出**需求说明 + 设计文档**并**停止**，待你确认或修改文档后说「继续开发」再实现；开发完成后你说「归档」则执行归档。

```
  你：「加一个 xxx 功能」 / 「把 xxx 改成 yyy」
                    │
                    ▼
  ┌─────────────────────────────────────┐
  │ spec_trigger 识别为「新功能/改需求」 │
  └─────────────────┬───────────────────┘
                    │
                    ▼
  ┌─────────────────────────────────────┐
  │ 在 docs/spec/active/ 产出需求说明    │  ← 先出文档，不写代码
  │ 与设计文档，然后停止                 │
  └─────────────────┬───────────────────┘
                    │
                    ▼
  你：查看/修改文档后说「继续开发」「按文档开发」
                    │
                    ▼
  ┌─────────────────────────────────────┐
  │ 按 spec 与设计实现 backend/frontend │  ← 开发清单与验收
  └─────────────────┬───────────────────┘
                    │
  你：「归档」/「开发完成」
                    │
                    ▼
  ┌─────────────────────────────────────┐
  │ 归档检查列表：校验 → 合并 delta       │
  │ → 移入 archive，清理临时文档         │
  └─────────────────────────────────────┘
```

修 Bug、提问、纯讨论设计**不会**触发上述流程，直接按你的问题响应。

**注意：** 新需求时 AI 不会在未获你确认前自动写代码；确认文档后说「继续开发」再实现。开发完成后要**主动说「归档」或「开发完成」**才会执行归档，否则 `docs/spec/active/` 会越积越多。

---

## 目录结构

- `backend/` — FastAPI，Pydantic v2，统一响应，依赖注入
- `frontend/` — Next.js 14 + shadcn/ui，响应式，Loading/Error 完备
- `docs/spec/active/` — 进行中的需求（提案或实现中）
- `docs/spec/archive/` — 已归档需求（仅历史）
- `docs/spec/specs/` — **Source of Truth**，按领域一份「当前系统」规格
- `docs/spec_process/` — 流程说明、开发/归档检查清单、测试最佳实践等
- `.cursor/rules/` — 五条**框架规则**（spec_trigger、spec_manager、global_guard、fastapi_shield、frontend_architect），建议保留；项目专属规则可新增其他 `.mdc` 文件。
- `.cursor/skills/` — 项目技能：API 与 Pydantic 风格、领域命名规范等
- `spec_cli/` — **可安装 CLI**：在任意项目根执行 `spec-coding init` 即可接入本框架，无需复制整仓。详见 [spec_cli/README.md](spec_cli/README.md) 与 [docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md](docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md)。

更多「框架 vs 项目」可能冲突及对策见 [docs/spec_process/FRAMEWORK_AND_PROJECT_CONFLICTS.md](docs/spec_process/FRAMEWORK_AND_PROJECT_CONFLICTS.md)。

### 新项目 / 老项目如何接入（推荐：可安装方式）

若希望**新项目**直接在项目根写业务（无多余 `backend/` 嵌套）、或**老项目**直接接入 Spec 流程，可不用「复制本仓再在 backend 里开发」：

1. **安装 CLI**：在仓库根执行 `pip install -e .`，或 `cd spec_cli && pip install -e .`
2. **在目标项目根目录执行**：`spec-coding init`（若后端/前端目录名或包名不同，可加 `--backend-dir`、`--frontend-dir`、`--app-package`）。

接入后，该目录下会有 `docs/spec/`、`docs/spec_process/`、`.cursor/rules/`、`.cursor/skills/`，业务代码结构由你自定（可仍用 `backend/`、`frontend/`，也可用 `server/`、`web/` 等）。详见 [docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md](docs/spec_process/INSTALLABLE_SPEC_FRAMEWORK.md)。

# 技术栈
项目以python后端和Next.js 14 + shadcn/ui前端技术栈为例，项目中和推荐安装脚本中的skill也是针对这两个技术栈的
如果使用其他技术栈，只需要让ai帮忙替换掉对应技术栈的skill即可


**后端 Lint / 类型检查**（可选）：`pip install -r requirements_dev.txt` 后执行 `ruff check .`、`ruff format --check .`、`pyright`。

前端默认请求 `http://127.0.0.1:8000`，可通过 `NEXT_PUBLIC_API_URL` 覆盖。

## 如何用 Spec 驱动开发

- **会触发 Spec 流程（仅文档阶段）**：新功能、修改既有功能/行为（例如「加一个登录」「把列表改成支持分页」）→ AI 产出需求说明与设计文档到 `docs/spec/active/` 后**停止**，等你确认或修改文档；你说「继续开发」「按文档开发」后再实现。
- **不触发**：修 Bug、提问解释、设计/流程讨论、纯重构或修 lint。

规则说明：`spec_trigger.mdc`（始终生效）根据你的意图决定是否走 Spec；只有当你明确说「归档」「开发完成」等时才会执行归档；`spec_manager.mdc` 定义归档六步与 spec 规则；`fastapi_shield` / `frontend_architect` 在改对应代码时生效。

**Cursor Skills 与 MCP 推荐安装**：推荐清单见 [docs/cursor_skills_and_mcp.md](docs/cursor_skills_and_mcp.md)。一键安装脚本见 `scripts/skills_and_mcps/`，详见其内 [README.md](scripts/skills_and_mcps/README.md)。
