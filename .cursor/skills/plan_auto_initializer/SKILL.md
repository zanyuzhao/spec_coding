---
name: plan_auto_initializer
description: Plan-Auto 模式首轮：根据用户目标产出 feature list、init.sh、progress 文件与初始提交，为后续「每轮一个 feature」打基础。
---

# Plan-Auto 首轮（Initializer）

当用户选择 **Plan-Auto** 且当前项目**尚未**具备 feature list、init.sh、claude-progress 等交接工件时，执行本 Skill。产出「基本文档」与交接结构，具体实现细节更多交给后续 Coding Session 的 AI。

## 触发条件

- 用户已选择 **B / Plan-Auto** 模式。
- 项目根目录或约定位置**不存在** `feature_list.json`（或等价）及 `claude-progress.txt`（或等价）。

## 执行步骤

### 1. 高层目标与范围（基本文档）

- 根据用户的本轮需求描述，写一份**简短**高层目标/范围说明（几句话或一页内）：
  - 要做什么、为谁、核心能力有哪些。
  - 不要求详细接口设计；细节可在后续每 feature 实现时由 AI 决定。

### 2. Feature list（JSON）

- 创建 **`feature_list.json`**（或项目约定的路径，如 `docs/plan_auto/feature_list.json`）：
  - 将高层目标拆成多条**可执行、可验收**的 feature。
  - 每条结构建议：
    - `category`: 如 `"functional"`；
    - `description`: 一句话描述；
    - `steps`: 数组，验收步骤（如「打开页面」「点击 X」「验证 Y」）；
    - `passes`: 布尔，初始一律 `false`。
  - 禁止在后续 Session 中删除或改写 steps/description，只允许修改 `passes` 为 `true` 当且仅当该条已通过 E2E/验收。

### 3. init.sh

- 创建 **`init.sh`**（或项目约定名）：
  - 能**启动应用/开发环境**（如启动 backend 与 frontend、或 docker-compose up）。
  - 可选：跑一次**最基础的 E2E 或冒烟测试**，确保「当前代码能跑起来」。
  - 后续每轮 Coding Session 会先执行此脚本再做新 feature。

### 4. Progress 文件

- 创建 **`claude-progress.txt`**（或 `docs/plan_auto/claude-progress.txt`）：
  - 用于记录每轮完成情况、最近修改、已知问题等，便于下一轮或新 session 快速接上。
  - 首轮可写：初始化完成、feature 总数、init.sh 用法。

### 5. 初始提交

- 将上述文件加入版本控制并做**初始提交**（若仓库已有代码，可只提交新增的 feature_list.json、init.sh、claude-progress.txt 及范围说明）。
  - 提交信息清晰，如 `chore(plan-auto): add feature list, init.sh, progress file`。

### 6. 说明下一轮

- 回复用户：Plan-Auto 已初始化；接下来每轮只需说「继续」或「下一轮」，将执行 **`plan_auto_coding_session`**：每次选一个未完成 feature，实现并 E2E 验收通过后标为 passes，更新 progress 并提交。

## 核心理念

- **Plan**：先产出清晰的 feature list 计划，避免 AI 过早宣布完成或一次做太多。
- **Auto**：init.sh + progress 作为交接工件，下一轮 AI 无需猜测环境与进度，自动增量实现。
- 基本文档（范围说明）保留，但不强制详细设计，尊重「交给 AI 作出结果」的自动化思路。
