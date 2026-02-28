# Spec 全栈开发框架

> 让 AI 理解你的需求，而不是猜测你的需求

解决 **Vibe Coding** 的三大痛点：
- 🎯 **需求偏差** — AI 实现的和你想的不一样
- 📝 **文档混乱** — 需求散落在对话里，无法追溯
- 🔄 **约定遗忘** — 长对话后 AI 忘记之前的约定

## 30 秒上手

```bash
# 安装
pip install -e .

# 在你的项目根目录执行
spec-coding init
```

搞定！现在你的项目已接入 Spec 框架。

## 它能帮你做什么

### ✅ 需求先成文，再实现

```
你: 加一个用户登录功能
AI: 好的，我先写需求说明和设计文档...
    [产出 docs/spec/active/login/spec.md]
    请确认文档后再说「继续开发」
你: 看了，没问题，继续开发
AI: [按文档实现代码] → [跑验收测试] → [全部通过]
```

### ✅ 两种模式，按需选择

| 模式 | 适合场景 | 特点 |
|------|---------|------|
| **Spec** | 精细控制、维护老代码 | 先文档 → 确认 → 实现 |
| **Plan-Auto** | 快速产出、新功能验证 | 先计划 → 自动增量实现 |

### ✅ 自动化质量保障

- 📋 **任务拆分** — AI 自动拆分任务，逐项实现
- ✅ **验收闭环** — 代码写完自动跑测试，不过就修
- 🔒 **安全检查** — 提交前自动检查安全问题
- 📦 **80% 测试覆盖** — 强制 TDD，保证质量

### ✅ 需求可追溯、可归档

```
docs/spec/
├── active/      ← 进行中的需求
├── archive/     ← 已完成的历史
└── specs/       ← 系统规格（Source of Truth）
```

归档时自动合并到 Source of Truth，长期维护不迷路。

## 设计思路

本框架借鉴了两方面的精华：

1. **OpenSpec** — 需求成文、Delta 合并、Source of Truth
2. **Effective Agents** — Feature list 驱动、增量实现、E2E 验收

核心理念：**先想清楚，再动手写代码**。

---

# 详细文档

## 两种模式详解

### Spec 模式：精细控制

适合：需要精确控制、维护老代码、接口要可追溯

```
1. 你说需求 → AI 产出需求说明 + 设计文档 → 停止
2. 你看文档 → 确认或修改
3. 你说「继续开发」→ AI 按文档实现 → 跑验收 → 通过
4. 你说「归档」→ AI 合并到 Source of Truth
```

### Plan-Auto 模式：快速产出

适合：快速验证想法、人类少介入、AI 多轮产出

```
1. 首轮：AI 产出 feature list（计划）→ 你确认
2. 后续：每说一次「继续」，AI 实现一个 feature → E2E 验收 → 通过标 ✅
3. 全部完成 → 归档
```

## 什么时候走流程？

| 场景 | 是否走流程 |
|------|-----------|
| 新功能 | ✅ 走 |
| 修改既有功能 | ✅ 走 |
| 修 Bug | ❌ 直接改 |
| 提问/讨论 | ❌ 直接回答 |
| 纯重构 | ❌ 直接改 |

## 目录结构

```
your-project/
├── docs/
│   ├── spec/
│   │   ├── active/      ← 进行中的需求
│   │   ├── archive/     ← 已归档需求
│   │   └── specs/       ← Source of Truth
│   ├── spec_process/    ← 流程文档
│   └── plan_auto/       ← Plan-Auto 脚本
├── .claude/             ← Claude Code 规则和技能
├── .cursor/             ← Cursor 规则和技能
└── CLAUDE.md            ← 项目说明（给 AI 看的）
```

## 常用命令

```bash
# 归档检查
./scripts/archive.sh --check

# 启动开发环境
./docs/plan_auto/init.sh

# 验证流程
./docs/plan_auto/verify_plan_auto.sh
```

## 技术栈

本框架以 **FastAPI + Next.js** 为例，但流程与规则可复用于任何技术栈。

## 扩展阅读

- [工具链详解](docs/toolchain.md) — MCP 服务器、Skills 列表
- [流程文档](docs/spec_process/) — 开发清单、归档检查、测试最佳实践
- [MCP 配置](docs/plan_auto/mcp_setup.md) — 如何配置 MCP 服务器
