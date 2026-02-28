# 编辑器兼容性说明

本框架支持 **Claude Code** 和 **Cursor** 两种 AI 编程工具，规则和技能保持一致。

## 目录对应关系

| 用途 | Claude Code | Cursor |
|------|-------------|--------|
| 规则文件 | `.claude/rules/*.md` | `.cursor/rules/*.mdc` |
| 技能目录 | `.claude/skills/*/` | `.cursor/skills/*/` |
| MCP 配置 | 不适用 | `.cursor/mcp.json` |
| 项目说明 | `CLAUDE.md` | `.cursorrules`（可选） |

## 文件格式差异

| 文件类型 | Claude Code | Cursor |
|----------|-------------|--------|
| 规则文件 | `.md` (Markdown) | `.mdc` (Cursor 规则格式) |
| 技能文件 | `SKILL.md` | `SKILL.md`（相同） |

## 特有配置

### Claude Code 特有
- `.claude/settings.local.json` — 本地设置
- `CLAUDE.md` — 项目说明（AI 自动读取）

### Cursor 特有
- `.cursor/mcp.json` — MCP 服务器配置
- `.cursorrules` — 项目规则（可选，本框架未使用）

## 同步策略

修改规则或技能时，需要同时更新两个目录：

```bash
# 同步规则文件（.md → .mdc）
cp .claude/rules/xxx.md .cursor/rules/xxx.mdc

# 同步技能目录
cp -r .claude/skills/xxx .cursor/skills/
```

## 当前同步状态

✅ **Rules** — 8 个规则文件已同步
- ecc_security
- ecc_testing
- fastapi_shield
- frontend_architect
- global_guard
- implementation_loop
- spec_manager
- spec_trigger

✅ **Skills** — 14 个技能目录已同步
- api_pydantic_style
- curl_test
- dev_services
- domain_naming_convention
- ecc_api_design
- ecc_backend_patterns
- ecc_frontend_patterns
- ecc_security_review
- ecc_tdd_workflow
- ecc_verification_loop
- git_operations
- plan_auto_coding_session
- plan_auto_initializer
- spec_implementation_phase
