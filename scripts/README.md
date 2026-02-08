# Cursor Skills 与 MCP 安装脚本

本目录提供一键安装推荐 **Skills** 和 **MCP** 的脚本，安装到**用户级**目录（所有项目共用），无需手动复制文件。

## 前置要求

- **Skills 安装**：需要已安装 [Git](https://git-scm.com/)
- **MCP 安装**：无额外要求（脚本会写入 `mcp.json`）
- **MCP 验证**：需要 Node.js / npx（用于确认 MCP 命令可执行）

## 脚本说明

| 脚本 | 作用 |
|------|------|
| `install_skills_win.ps1` / `install_skills_mac_linux.sh` | 将推荐 Skills 从 GitHub 克隆并复制到用户级 `~/.cursor/skills/`（Windows：`%USERPROFILE%\.cursor\skills\`） |
| `install_mcp_win.ps1` / `install_mcp_mac_linux.sh` | 将推荐 MCP（shadcn、filesystem、fetch）**合并**到用户级 `~/.cursor/mcp.json`，不覆盖已有配置 |
| `verify_mcp_win.ps1` / `verify_mcp_mac_linux.sh` | 快速检查 MCP 相关命令是否能被 npx 执行（可选，用于排错） |

## 使用方法

### Windows（PowerShell）

在项目根目录或 `scripts/` 目录下执行：

```powershell
# 安装推荐 Skills（用户级）
.\scripts\install_skills_win.ps1

# 安装 / 合并推荐 MCP 配置（用户级）
.\scripts\install_mcp_win.ps1

# 可选：验证 MCP 命令是否可用
.\scripts\verify_mcp_win.ps1
```

若在项目根执行，可写为：`.\scripts\install_skills_win.ps1`；若已 `cd scripts`，则：`.\install_skills_win.ps1`。

### Mac / Linux（Bash）

```bash
# 安装推荐 Skills（用户级）
bash scripts/install_skills_mac_linux.sh
# 或：chmod +x scripts/install_skills_mac_linux.sh && ./scripts/install_skills_mac_linux.sh

# 安装 / 合并推荐 MCP 配置（用户级）
bash scripts/install_mcp_mac_linux.sh

# 可选：验证 MCP 命令是否可用
bash scripts/verify_mcp_mac_linux.sh
```

合并 MCP 时，若系统中有 `jq` 或 `python3`，脚本会只**新增**推荐的 MCP 条目，不覆盖你已有的其他 MCP 配置。

## MCP 是否需要每次开机手动运行？

**不需要。**  
MCP 是由 **Cursor 在需要时自动启动**的：当你使用到某个 MCP 时，Cursor 会根据 `mcp.json` 里的 `command` 和 `args` 拉起对应进程。因此：

- 不需要开机自启脚本；
- 不需要常驻“运行 MCP”的脚本。

`verify_mcp_win.ps1` / `verify_mcp_mac_linux.sh` 仅用于检查本机能否成功执行这些 MCP 命令（例如 npx 是否可用、网络是否正常），方便排查问题。

## 安装的 Skills 来源

| 仓库 | 说明 |
|------|------|
| agentworks/secure-skills | 低风险代码审查、研究等 |
| daniel-scrivner/cursor-skills | PRD、任务拆解、PR 流程 |
| dadbodgeoff/drift | 代码库模式检测，辅助风格一致 |
| vercel-labs/agent-skills | 前端/全栈相关技能 |

安装后重启 Cursor，或在 Agent 对话中输入 `/` 即可看到新 Skills。

## 安装的 MCP

| MCP | 作用 |
|-----|------|
| shadcn | 浏览/安装 shadcn 组件，与项目 `components.json` 一致 |
| filesystem | 限定到**当前项目根目录**的文件读写（脚本会根据执行位置推断项目根） |
| fetch | 拉取网页/文档为 Markdown，便于查 API 与文档 |

安装后重启 Cursor 即可使用；首次调用某 MCP 时 Cursor 会按需启动对应进程。

## 更多说明

详见 [docs/cursor_skills_and_mcp.md](../docs/cursor_skills_and_mcp.md)。
