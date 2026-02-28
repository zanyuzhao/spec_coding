# MCP 数据库配置验证

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
3. 如果返回正确的表结构，则 MCP 配置成功

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

## 配置文件位置

- MCP 配置: `.cursor/mcp.json`
- 环境变量模板: `.env.example`
- 初始化脚本: `data/init_db.sql`
- SQLite 数据库: `data/dev.db` (自动创建，已在 .gitignore)

## 前置依赖

已安装 `uv` 和 `uvx`:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
```

## 安全注意事项

1. **不要提交敏感信息**: `.env` 和 `*.db` 文件已在 `.gitignore` 中
2. **生产环境**: 使用强密码和受限权限的数据库用户
3. **连接字符串**: 避免在代码中硬编码，使用环境变量

## 故障排除

### SQLite MCP 不工作
```bash
# 验证 uvx 可用
uvx --version

# 手动测试 SQLite MCP
uvx mcp-server-sqlite --help
```

### MCP 配置未加载
1. 确保配置文件路径正确 (`.cursor/mcp.json`)
2. 重启 Cursor/Claude Code
3. 检查 Cursor 设置中 MCP 是否启用

## 参考链接

- [MCP SQLite Server - PyPI](https://pypi.org/project/mcp-server-sqlite/)
- [MCP Official Servers - GitHub](https://github.com/modelcontextprotocol/servers)
