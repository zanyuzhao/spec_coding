# MCP 服务器配置文档

本文档记录 spec_coding 项目配置的所有 MCP 服务器。

## 已配置的 MCP 服务器

### SQLite（已配置 ✅）

- **包**: `mcp-server-sqlite` (PyPI 官方包)
- **版本**: 2025.4.25
- **数据库路径**: `data/dev.db`
- **特点**: 无需额外安装数据库服务，开箱即用

**可用工具**:
- `read_query` - 执行 SELECT 查询
- `write_query` - 执行 INSERT/UPDATE/DELETE
- `create_table` - 创建表
- `list_tables` - 列出所有表
- `describe-table` - 查看表结构
- `append_insight` - 添加业务洞察

**验证步骤**:
1. 重启 Cursor/Claude Code 以加载新 MCP 配置
2. 在对话中询问 Claude：
   - "列出 SQLite 数据库中的所有表"
   - "查询 specs 表的内容"

---

### Playwright（已配置 ✅）

- **包**: `@playwright/mcp@latest` (Microsoft 官方)
- **版本**: 0.0.68+
- **用途**: 浏览器自动化、E2E 测试、网页截图

**可用工具**:
- `browser_navigate` - 导航到指定 URL
- `browser_click` - 点击元素
- `browser_type` - 输入文本
- `browser_screenshot` - 截取屏幕截图
- `browser_evaluate` - 执行 JavaScript
- `browser_wait_for` - 等待元素/条件
- `browser_close` - 关闭浏览器

**验证步骤**:
1. 重启 Cursor/Claude Code
2. 在对话中询问 Claude：
   - "使用 Playwright 打开 https://example.com 并截图"
   - "访问 http://127.0.0.1:3000 并检查页面标题"

**高级配置选项**:
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "-y", "@playwright/mcp@latest",
        "--browser", "chrome",
        "--caps", "vision,pdf"
      ]
    }
  }
}
```

**常用命令行选项**:
- `--browser <browser>` - 指定浏览器 (chrome, firefox, webkit, msedge)
- `--caps <caps>` - 启用额外能力 (vision, pdf, devtools)
- `--cdp-endpoint <endpoint>` - 连接到现有 Chrome DevTools 端点
- `--headless` - 无头模式（默认）

---

### PostgreSQL（可选，需手动配置）

官方 Postgres MCP 服务器目前需要从源码安装。如需使用：

**方式一：Docker**
```json
{
  "mcpServers": {
    "postgres": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "mcp-test:/mcp",
        "mcp/postgres"
      ]
    }
  }
}
```

**方式二：从源码安装**
```bash
# 克隆官方仓库
git clone https://github.com/modelcontextprotocol/servers.git mcp-servers

# 配置 mcp.json
{
  "mcpServers": {
    "postgres": {
      "command": "uv",
      "args": [
        "--directory", "/path/to/mcp-servers/src/postgres",
        "run", "mcp-server-postgres",
        "--db-url", "postgresql://user:pass@localhost/db"
      ]
    }
  }
}
```

**启动 PostgreSQL（Docker 方式）**:
```bash
docker run -d \
  --name spec_coding_postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=spec_coding \
  -p 5432:5432 \
  postgres:15
```

---

## 配置文件位置

| 文件 | 路径 | 说明 |
|------|------|------|
| MCP 配置 | `.cursor/mcp.json` | Cursor MCP 服务器配置 |
| 环境变量模板 | `.env.example` | 环境变量示例 |
| 数据库初始化 | `data/init_db.sql` | SQLite 表结构 |
| SQLite 数据库 | `data/dev.db` | 开发数据库（已在 .gitignore）|

---

## 前置依赖

### uv/uvx（用于 SQLite MCP）
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
```

### Node.js/npx（用于 Playwright MCP）
```bash
# 确保 Node.js 18+ 已安装
node --version
npm --version
```

---

## 安全注意事项

1. **不要提交敏感信息**: `.env` 和 `*.db` 文件已在 `.gitignore` 中
2. **生产环境**: 使用强密码和受限权限的数据库用户
3. **连接字符串**: 避免在代码中硬编码，使用环境变量
4. **浏览器自动化**: 仅访问可信网站，避免在登录状态下执行不可信操作

---

## 故障排除

### SQLite MCP 不工作
```bash
# 验证 uvx 可用
uvx --version

# 手动测试 SQLite MCP
uvx mcp-server-sqlite --help
```

### Playwright MCP 不工作
```bash
# 验证 npx 可用
npx --version

# 手动测试 Playwright MCP
npx -y @playwright/mcp@latest --help

# 安装浏览器（首次使用）
npx playwright install chromium
```

### MCP 配置未加载
1. 确保配置文件路径正确 (`.cursor/mcp.json`)
2. 重启 Cursor/Claude Code
3. 检查 Cursor 设置中 MCP 是否启用

---

## 参考链接

- [MCP SQLite Server - PyPI](https://pypi.org/project/mcp-server-sqlite/)
- [Playwright MCP - npm](https://www.npmjs.com/package/@playwright/mcp)
- [MCP Official Servers - GitHub](https://github.com/modelcontextprotocol/servers)
- [Playwright Documentation](https://playwright.dev)
