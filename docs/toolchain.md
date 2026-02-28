# 工具链详解

Spec 框架内置了 MCP 服务器和 Skills，增强 AI 的能力。

## 📦 MCP 服务器

MCP (Model Context Protocol) 让 AI 能与外部工具交互。

| MCP | 图标 | 包名 | 用途 | 验证命令 |
|-----|------|------|------|----------|
| **memory** | 🧠 | `@modelcontextprotocol/server-memory` | 跨会话持久化记忆 | 自动可用 |
| **sqlite** | 🗄️ | `mcp-server-sqlite` | 数据库操作与查询 | 「列出所有表」 |
| **playwright** | 🎭 | `@playwright/mcp` | 浏览器自动化、E2E 测试、截图 | 「打开 example.com 并截图」 |

### 安装 MCP

```bash
# macOS / Linux
./scripts/skills_and_mcps/install_mcp_mac_linux.sh

# Windows (PowerShell)
./scripts/skills_and_mcps/install_mcp_win.ps1
```

### 配置文件

MCP 配置在 `.cursor/mcp.json`，详细说明见 [mcp_setup.md](plan_auto/mcp_setup.md)。

---

## 🛠️ Skills

Skills 是预定义的能力模板，让 AI 按最佳实践执行任务。

### 流程类 Skills

| Skill | 图标 | 用途 | 触发方式 |
|-------|------|------|----------|
| **spec_implementation_phase** | 📋 | Spec 模式实现阶段：拆任务 → TDD → 验收 → code-review | 自动（说「继续开发」） |
| **plan_auto_initializer** | 🚀 | Plan-Auto 首轮：产出 feature list、init.sh、progress | 自动（选 Plan-Auto 模式） |
| **plan_auto_coding_session** | ⚡ | Plan-Auto 每轮：实现一个 feature → E2E 验收 | 自动（说「继续」） |

### 开发辅助 Skills

| Skill | 图标 | 用途 | 调用方式 |
|-------|------|------|----------|
| **curl_test** | 🌐 | cURL 接口测试模板 | `/curl_test` 或自动 |
| **git_operations** | 🔀 | Git 工作流（禁止自动 push） | `/git_operations` 或自动 |
| **dev_services** | 🐳 | Docker 开发服务管理（PostgreSQL/Redis/MySQL/MongoDB） | 自动检测或 `/dev_services` |

### 代码规范 Skills

| Skill | 图标 | 用途 |
|-------|------|------|
| **api_pydantic_style** | 📐 | FastAPI + Pydantic v2 统一风格 |
| **domain_naming_convention** | 📝 | 文件/目录命名规范（下划线） |

### ECC 系列 Skills

从 [everything-claude-code](https://github.com/affaan-m/everything-claude-code) 引入的最佳实践：

| Skill | 图标 | 用途 |
|-------|------|------|
| **ecc_tdd_workflow** | 🧪 | TDD 工作流，80%+ 测试覆盖 |
| **ecc_verification_loop** | ✅ | 验证闭环（build + test + lint） |
| **ecc_security_review** | 🔒 | 安全审查（OWASP Top 10） |
| **ecc_api_design** | 📡 | REST API 设计规范 |
| **ecc_backend_patterns** | ⚙️ | 后端架构模式 |
| **ecc_frontend_patterns** | 🎨 | 前端架构模式 |

---

## 🚀 Dev Services Skill

自动检测项目需要的开发服务（数据库、缓存等），一键创建 Docker 容器。

### 支持的服务

| 服务 | 图标 | 默认端口 | 特性 |
|------|------|----------|------|
| PostgreSQL | 🐘 | 5432-5499 | 随机端口、随机密码 |
| Redis | 🔴 | 6379-6399 | 无密码模式 |
| MySQL | 🐬 | 3306-3399 | 随机端口、随机密码 |
| MongoDB | 🍃 | 27017-27099 | 随机端口、随机密码 |

### 使用方法

```bash
# 检测项目需要的服务
.claude/skills/dev_services/scripts/lib/detect.sh

# 创建 PostgreSQL
.claude/skills/dev_services/scripts/services/postgres.sh create

# 管理服务
.claude/skills/dev_services/scripts/lib/manage.sh list
.claude/skills/dev_services/scripts/lib/manage.sh get postgresql
```

---

## 📁 目录结构

```
.claude/
├── rules/                    # 规则文件
│   ├── spec_trigger.md       # 何时触发需求流程
│   ├── spec_manager.md       # 归档流程
│   ├── implementation_loop.md # 自循环实现
│   ├── global_guard.md       # 全局规范
│   ├── fastapi_shield.md     # 后端规范
│   ├── frontend_architect.md # 前端规范
│   ├── ecc_security.md       # 安全规范
│   └── ecc_testing.md        # 测试规范
│
└── skills/                   # 技能目录
    ├── spec_implementation_phase/
    ├── plan_auto_initializer/
    ├── plan_auto_coding_session/
    ├── curl_test/
    ├── git_operations/
    ├── dev_services/
    ├── api_pydantic_style/
    ├── domain_naming_convention/
    └── ecc_*/
```
