# Spec 全栈开发框架

基于 `.cursor/rules/*.mdc` 的 Spec 驱动开发：需求在 `docs/spec`，规则在 `.cursor/rules/`。

## 结构

- `backend/` — FastAPI，Pydantic v2，统一响应，依赖注入
- `frontend/` — Next.js 14 + shadcn/ui，响应式，Loading/Error 完备
- `docs/spec/active/` — 活跃需求（提案/实现）
- `docs/spec/archive/` — 已归档
- `.cursor/rules/` — 五个 .mdc 规则（spec_trigger、spec_manager、fastapi_shield、frontend_architect、global_guard）

## 本地运行

```bash
# 后端
cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload

# 前端（另开终端）
cd frontend && npm i && npm run dev
```

**后端 Lint / 类型检查**（可选）：`pip install -r requirements_dev.txt` 后执行 `ruff check .`、`ruff format --check .`、`pyright`。

前端默认请求 `http://127.0.0.1:8000`，可通过 `NEXT_PUBLIC_API_URL` 覆盖。

## 如何用 Spec 驱动开发

**无需记流程**：你只要说「加一个 xxx 功能」或「把 xxx 改成 yyy」，AI 会**自动**走 Spec 流程（先录需求到 `docs/spec/active/`，再实现）。修 Bug、提问、讨论设计不会触发，直接响应。

- **会触发**：新功能、修改既有功能/行为。
- **不触发**：修 Bug、提问解释、设计/流程讨论、纯重构/修 lint。

规则说明：`spec_trigger.mdc`（始终生效）根据意图决定是否走 spec；归档仅响应用户明确说的「归档」「开发完成」等；`spec_manager.mdc` 定义归档六步与 spec 规则；`fastapi_shield` / `frontend_architect` 在改对应代码时生效。

**Cursor Skills 与 MCP**：推荐清单见 [docs/cursor_skills_and_mcp.md](docs/cursor_skills_and_mcp.md)。一键安装：运行 `scripts/install_skills_win.ps1` 与 `scripts/install_mcp_win.ps1`（Windows）或 `scripts/install_skills_mac_linux.sh`、`scripts/install_mcp_mac_linux.sh`（Mac/Linux），详见 [scripts/README.md](scripts/README.md)。
