# Cursor Skills 与 MCP 推荐清单

本文档列出与本框架（FastAPI + Pydantic + Next.js + Spec 驱动）风格一致、可复用的 **Skills** 与 **MCP 服务器** 推荐，便于统一代码风格、数据处理与对外交互格式。

---

## 一、已具备的 Cursor 能力

- **Rules**（`.cursor/rules/*.mdc`）：`spec_trigger`、`spec_manager`、`fastapi_shield`、`frontend_architect`、`global_guard`
- **Skills 目录**：用户级 `~/.cursor/skills/`；项目级 `.cursor/skills/`（本仓库可放项目专属 skill）
- **MCP**：通过 Cursor 设置添加，或用户级 `%USERPROFILE%\.cursor\mcp.json`（Windows）

---

## 二、推荐 Skills（按用途）

### 2.1 你已安装的用户级 Skills（`~/.cursor/skills-cursor/` 为 Cursor 内置，勿改）

- `create-rule` — 创建/维护 Cursor 规则
- `create-skill` — 创建新 Skill
- `update-cursor-settings` — 修改 Cursor/VSCode 设置（如 format on save、缩进）
- `migrate-to-skills` — 将动态规则、斜杠命令迁移为 Skill

以上在 Agent 对话中输入 `/` 可看到并调用。

### 2.2 建议新增的用户级或项目级 Skills

| 用途 | 建议 | 安装方式 |
|------|------|----------|
| **Pydantic / API 一致性** | 使用本项目自带的 **项目 Skill** | 已放在 `.cursor/skills/api_pydantic_style/`，自动加载 |
| **领域 / Spec 命名规范** | spec 与领域相关文件名、目录名统一使用**下划线** | 已放在 `.cursor/skills/domain_naming_convention/`，自动加载 |
| **代码规范 / Lint** | 本仓库 backend 使用 **ruff + pyright** | 见下方「后端 Lint 与类型检查」 |
| **规则与规范** | 需要新规则时用 `/create-rule` | 在 Agent 里输入 `/create-rule` 按提示操作 |
| **新 Skill** | 需要新 Skill 时用 `/create-skill` | 在 Agent 里输入 `/create-skill` 按提示操作 |

从 GitHub 安装远程 Skill：**Cursor 设置 → Rules → Add Rule → Remote Rule (Github)**，填入仓库 URL。

---

## 三、推荐 MCP 服务器（与风格、数据、对外交互相关）

以下多为官方目录中已验证的服务器，安装方式二选一：

1. **通过 Cursor 设置**：设置 → MCP → 添加对应服务器（部分提供「Add to Cursor」一键安装）。
2. **通过 `mcp.json`**：编辑 `%USERPROFILE%\.cursor\mcp.json`（Windows）或 `~/.cursor\mcp.json`（Mac/Linux），在顶层对象中追加如下 `"服务器名": { ... }` 配置。

### 3.1 与「风格一致、文档与组件」强相关

| MCP | 作用 | 安装要点 |
|-----|------|----------|
| **shadcn/ui** | 浏览、搜索、安装 shadcn 组件，与现有 `components.json` 一致 | `npx shadcn@latest mcp`；[官方 Add to Cursor](https://cursor.com/docs/context/mcp/directory) 搜 "shadcn" |
| **Context7** | 最新代码/文档上下文，保持实现与文档一致 | 云端 MCP，需在目录中点击 Add to Cursor |
| **Ref** | 高效文档搜索，便于查 API/框架约定 | 云端，目录中添加 |

### 3.2 与「数据处理、对外 API」相关

| MCP | 作用 | 安装要点 |
|-----|------|----------|
| **Postman** | 调用、测试 API，校验请求/响应格式（与 `ApiResponse[T]` 一致） | 需 Postman API Key；目录中 Add to Cursor |
| **Supabase** | 若后续用 Postgres，可查 schema、跑查询 | 需 Supabase 项目；目录中 Add to Cursor |
| **GitHub** | 读 PR/Issue、仓库规范，保持协作与提交风格一致 | Docker 或 token；目录中 Add to Cursor |

### 3.3 与「代码质量、安全」相关

| MCP | 作用 | 安装要点 |
|-----|------|----------|
| **Semgrep** | 安全/质量规则扫描，配合 CI 或本地 | `semgrep mcp`；目录中 Add to Cursor |
| **Sentry** | 错误追踪，与前端/后端错误格式对接 | 需 Sentry 项目；目录中 Add to Cursor |
| **snyk** | 依赖漏洞扫描 | `npx -y snyk@latest mcp -t stdio`；需 Snyk 认证 |

### 3.4 示例：`mcp.json` 片段（可合并到你的用户配置）

仅作参考，按需启用并补全环境变量：

```json
{
  "shadcn": {
    "command": "npx",
    "args": ["shadcn@latest", "mcp"]
  },
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "C:\\path\\to\\your\\project\\root"]
  },
  "fetch": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-fetch"]
  }
}
```

- **filesystem**：限定到项目目录，便于 Agent 安全读写项目文件。**请将上面示例中的 `C:\\path\\to\\your\\project\\root` 改为你当前打开的项目根目录的绝对路径**（如 `d:\\code\\my_project`），否则 MCP 会指向错误目录；从本框架克隆新项目后务必在用户级 `mcp.json` 中修改此处。
- **fetch**：拉取 HTTP 文档/API 说明，便于对齐对外交互格式。

更多见 [Cursor MCP Directory](https://cursor.com/docs/context/mcp/directory)。

---

## 四、本仓库已做的「可安装」基础设施

### 4.1 后端 Lint 与类型检查（Ruff + Pyright）

- **Ruff**：格式与 lint（替代 Black + isort + 部分 flake8）。
- **Pyright**：静态类型检查，与 Pydantic、禁止 `Any` 的规则一致。

**安装与运行**（在 `backend/` 下）：

```bash
pip install -r requirements.txt
ruff check .
ruff format --check .
pyright
```

配置见：`backend/pyproject.toml`（含 Ruff 与 Pyright）。开发依赖：`pip install -r requirements_dev.txt`。

### 4.2 项目级 Skill：API 与 Pydantic 风格

- 路径：`.cursor/skills/api_pydantic_style/`
- 作用：在实现或修改接口时，提醒 Agent 使用 `ApiResponse[T]`、Pydantic v2 模型、类型完整、与 `app/core/response.py` 一致。与现有 `fastapi_shield.mdc` 互补。

### 4.3 项目级 Skill：领域命名规范

- 路径：`.cursor/skills/domain_naming_convention/`
- 作用：spec 与领域相关文件名、目录名一律使用**下划线**（如 `spec_list_api.md`、`specs/spec_list/`），禁止中划线。新建或重命名 spec、归档目录及编写命名约定时自动遵循。

由 Cursor 自动从 `.cursor/skills/` 发现，无需额外安装。

---

## 五、通过脚本一键安装（推荐）

本仓库提供脚本，运行即可将推荐 **Skills** 与 **MCP** 安装到用户级目录（所有项目共用）：

- **Windows（PowerShell）**：在项目根或 `scripts/` 下执行  
  `.\scripts\install_skills_win.ps1`、`.\scripts\install_mcp_win.ps1`
- **Mac/Linux**：`bash scripts/install_skills_mac_linux.sh`、`bash scripts/install_mcp_mac_linux.sh`

MCP **不需要**每次开机单独运行——Cursor 会在使用时按需启动。可选验证脚本：`.\scripts\verify_mcp_win.ps1` / `bash scripts/verify_mcp_mac_linux.sh`。

详细说明与脚本列表见 **[scripts/README.md](../scripts/README.md)**。

## 六、快速操作清单

1. **看现有 Skills**：Cursor 设置 → Rules → 查看「Agent Decides」中的 Skills。
2. **加 MCP**：设置 → MCP → 添加，或编辑 `%USERPROFILE%\.cursor\mcp.json`；或直接运行上述安装脚本。
3. **后端 lint**：在 `backend/` 执行 `ruff check .`、`ruff format --check .`、`pyright`（或使用 VS Code/Cursor 的 Ruff、Pyright 扩展）。
4. **用项目 Skill**：Agent 中可输入 `/api_pydantic_style`、`/domain_naming_convention` 显式调用，或由 Agent 在改 API、建 spec/归档时自动选用。

---

## 七、参考链接

- [Cursor – Agent Skills](https://cursor.com/docs/context/skills)
- [Cursor – MCP Directory](https://cursor.com/docs/context/mcp/directory)
- [Cursor – MCP Install Links](https://cursor.com/docs/context/mcp/install-links)
- [Agent Skills 标准](https://agentskills.io)
