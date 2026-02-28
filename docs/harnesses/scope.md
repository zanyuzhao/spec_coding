# 工具链与自动化建设 - 高层目标与范围

## 目标

为 spec_coding 项目建设完整的自动化工具链，包括：
- MCP 服务器集成（数据库操作、网页自动化测试）
- Claude Code Skills 封装（cURL 接口测试、Git 操作）
- Harnesses 流程完善与验证

## 核心能力

### 1. MCP 服务器
- **Postgres/Database MCP**: 数据库连接、查询、schema 检查能力
- **Playwright MCP**: 网页自动化操作、E2E 测试、截图验证

### 2. Claude Code Skills
- **curl_test**: cURL 接口测试 skill，封装常用 HTTP 请求模式
- **git_operations**: Git 操作 skill，新需求开分支、自动化 commit（不 push）

### 3. Harnesses 流程验证
- 验证 init.sh 可正常启动服务
- 验证 feature list 结构合理
- 验证 progress 文件可正常更新

## 范围边界

- **包含**: MCP 配置、Skill 编写、流程验证脚本
- **不包含**: 具体业务功能实现、生产部署配置

## 预期产出

1. `.claude/mcp.json` 或 `.cursor/mcp.json` 更新（添加 Postgres、Playwright MCP）
2. `.claude/skills/curl_test/SKILL.md`
3. `.claude/skills/git_operations/SKILL.md`
4. 验证脚本与文档
