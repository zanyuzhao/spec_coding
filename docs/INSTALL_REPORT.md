# 流程与工具安装报告

本文档罗列根据「Spec / Harnesses 双模式 + ECC 工具增强」设计所实现的流程、安装的组件及成功/失败状态。环境默认：**Ubuntu**。

**Cursor 与 Claude Code 能力一致**：流程（spec_trigger、Spec/Harnesses 分流）、规则（.cursor/rules 与 .claude/rules）、技能（.cursor/skills 与 .claude/skills）已对齐；本仓以 .cursor 为编辑主环境，.claude 为同步副本，供 Claude Code 使用。通过 `spec-coding init` 安装到其他项目时，会同时写入 .cursor 与 .claude 的 rules 与 skills。

---

## 一、流程实现状态

| 项目 | 状态 | 说明 |
|------|------|------|
| 新/改需求未指定模式时给出 A(Spec) / B(Harnesses) 选项 | ✅ 成功 | 已写入 `.cursor/rules/spec_trigger.mdc` |
| Bug / 测试 / 提问 / 设计讨论不走流程 | ✅ 成功 | 保持原 spec_trigger 逻辑 |
| Spec 模式：先文档 → 确认 → 继续开发走 spec_implementation_phase | ✅ 成功 | spec_trigger 与 Skill `spec_implementation_phase` 联动 |
| Harnesses 模式：首轮 initializer、后续 coding session | ✅ 成功 | Skills `harnesses_initializer`、`harnesses_coding_session` 已创建 |
| ECC 的 plan/verify/tdd/code-review 内嵌到流程 | ✅ 成功 | 由上述 Skills 描述，无需人类单独敲命令 |

---

## 二、系统环境（Ubuntu）

| 工具 | 路径/版本 | 状态 |
|------|-----------|------|
| Node.js | 已安装，v20.20.0 | ✅ 成功 |
| npm | 已安装，10.8.2 | ✅ 成功 |
| Git | 已安装，2.43.0 | ✅ 成功 |
| Python 3 | 已安装，3.12.3 | ✅ 成功 |
| pnpm | 未检测到 | ⚠️ 可选（需则 `npm i -g pnpm`） |

---

## 三、本仓库新增/修改的规则与 Skills

### 3.1 规则（.cursor/rules/）

| 文件 | 状态 | 说明 |
|------|------|------|
| spec_trigger.mdc | ✅ 已修改 | 增加「新/改需求 → 未指定模式则给出 Spec/Harnesses 选项」；Harnesses 首轮与后续轮指向对应 Skill；继续开发仅 Spec 模式并走 spec_implementation_phase |
| ecc_testing.mdc | ✅ 已添加 | ECC testing：80% 覆盖率、TDD 红绿重构，globs 匹配 backend/frontend 与测试文件 |
| ecc_security.mdc | ✅ 已添加 | ECC security：提交前安全与秘密管理，globs 匹配 backend/frontend 与 .env 相关 |
| 其他（global_guard、spec_manager、fastapi_shield、frontend_architect） | 未改动 | 保持原样 |

### 3.2 本仓库自定义 Skills（.cursor/skills/）

| Skill | 路径 | 状态 | 说明 |
|-------|------|------|------|
| spec_implementation_phase | .cursor/skills/spec_implementation_phase/SKILL.md | ✅ 成功 | Spec 实现阶段：plan → TDD → verify → code-review，闭环 |
| harnesses_initializer | .cursor/skills/harnesses_initializer/SKILL.md | ✅ 成功 | Harnesses 首轮：feature list、init.sh、progress、初始提交 |
| harnesses_coding_session | .cursor/skills/harnesses_coding_session/SKILL.md | ✅ 成功 | Harnesses 每轮：选一 feature → init+E2E → 实现 → verify → 标 passes → progress+commit |
| api_pydantic_style | .cursor/skills/api_pydantic_style/SKILL.md | 原有 | API 与 Pydantic 风格 |
| domain_naming_convention | .cursor/skills/domain_naming_convention/SKILL.md | 原有 | 领域与 spec 命名 |

---

## 四、从 ECC 安装的 Skills

来源：`https://github.com/affaan-m/everything-claude-code`（已 clone 至 /tmp/ecc_repo 并复制到本项目）。

| Skill | 本项目路径 | 状态 | 说明 |
|-------|------------|------|------|
| verification-loop | .cursor/skills/ecc_verification_loop/ | ✅ 成功 | Build / typecheck / lint / test / security / diff 验证环 |
| tdd-workflow | .cursor/skills/ecc_tdd_workflow/ | ✅ 成功 | TDD 红绿重构与 80% 覆盖率要求 |
| backend-patterns | .cursor/skills/ecc_backend_patterns/ | ✅ 成功 | 后端 API、数据库、缓存等模式 |
| api-design | .cursor/skills/ecc_api_design/ | ✅ 成功 | REST API 设计、分页、错误响应 |
| frontend-patterns | .cursor/skills/ecc_frontend_patterns/ | ✅ 成功 | React、Next.js 等前端模式 |
| security-review | .cursor/skills/ecc_security_review/ | ✅ 成功 | 安全审查清单 |

以上在「继续开发」或 Harnesses 轮次中会由 `spec_implementation_phase` / `harnesses_coding_session` 的步骤引用（如 verify 阶段对应 verification-loop，实现方式对应 tdd-workflow）。

---

## 五、ECC Rules（已精简并并入项目规则）

| 项目 | 路径 | 状态 | 说明 |
|------|------|------|------|
| ECC testing | .cursor/rules/ecc_testing.mdc | ✅ 已启用 | 80% 覆盖率、TDD，与 spec_implementation_phase 配合 |
| ECC security | .cursor/rules/ecc_security.mdc | ✅ 已启用 | 提交前安全与秘密管理，与 fastapi_shield 配合 |
| docs/ecc_rules/ | docs/ecc_rules/README.md | 已清理 | 其余 ECC 规则已删除，仅保留 README 说明来源与合并位置 |

---

## 六、MCP

| 项目 | 路径/配置 | 状态 | 说明 |
|------|------------|------|------|
| MCP 配置 | .cursor/mcp.json | ✅ 已配置 | 仅保留 **memory**（跨会话记忆）；**filesystem 已移除**（Cursor/Claude 内置文件能力已够用，无需 MCP 占上下文） |
| memory 服务器 | npx @modelcontextprotocol/server-memory | ✅ 已启用 | 首次运行会拉包；若不需要跨会话记忆可删掉此项以省上下文 |
| Puppeteer/Playwright（E2E） | 未配置 | ⚠️ 可选 | Harnesses 做浏览器 E2E 时可自行在 mcp.json 中添加 |

---

## 七、ECC Hooks

| 项目 | 状态 | 说明 |
|------|------|------|
| ECC hooks（sessionStart/sessionEnd/afterFileEdit 等） | ❌ 未安装 | 依赖 ECC 仓库中 `scripts/hooks/*.js` 及 `.cursor/hooks.json`；若需安装，请从 everything-claude-code 克隆后复制 `hooks/`、`scripts/hooks/` 到本项目并配置 Cursor 支持的 hooks 格式 |

---

## 八、汇总表：成功 / 失败

| 类别 | 成功 | 失败/未安装 |
|------|------|-------------|
| 流程与规则 | spec_trigger 更新、Spec/Harnesses 分流、继续开发与 Skill 联动 | — |
| 本仓库 Skills | spec_implementation_phase, harnesses_initializer, harnesses_coding_session | — |
| ECC Skills | ecc_verification_loop, ecc_tdd_workflow, ecc_backend_patterns, ecc_api_design, ecc_frontend_patterns, ecc_security_review | — |
| ECC Rules | ecc_testing.mdc、ecc_security.mdc 已并入 .cursor/rules | docs/ecc_rules/ 其余已清理，仅留 README |
| 系统工具 | node, npm, git, python3 | pnpm 未检测（可选） |
| MCP | .cursor/mcp.json 仅保留 memory | filesystem 已删除（用内置能力）；Puppeteer 等可选自加 |
| ECC Hooks | — | 未安装（需从 ECC 手动复制并配置） |

---

## 九、使用前请确认

1. **MCP**：若不需要跨会话记忆，可删掉 `mcp.json` 中 memory 或整文件以省上下文。
2. **Harnesses 模式**：首轮会生成 `feature_list.json`、`init.sh`、`claude-progress.txt`；路径可与 Skill 内约定一致或在本项目内自定（如 `docs/harnesses/`）。
3. **Spec 模式**：与原有流程一致；「继续开发」后由 AI 按 `spec_implementation_phase` 执行 plan → TDD → verify → code-review；测试与安全由 `ecc_testing.mdc`、`ecc_security.mdc` 约束。

安装与实现日期：2025-02-27。
