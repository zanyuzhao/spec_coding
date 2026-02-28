---
name: git_operations
description: Git 操作封装。提供标准化的 Git 工作流模板，包括新需求开分支、commit 规范、禁止自动 push（只能由人类执行）。
---

# Git 操作 Skill

提供标准化的 Git 工作流模板，确保有层次的 git 管理和自动化流程。

## 核心原则

⚠️ **重要规则**：
1. **新需求必须开新分支** - 禁止直接在 main 分支开发
2. **禁止自动 push** - 只能执行 commit，push 必须由人类手动执行
3. **有层次的分支管理** - 功能分支 → 合并到 main

## 何时使用

- 开始新需求开发
- 提交代码变更
- 创建和管理分支
- 查看 Git 状态和历史

## 分支管理

### 分支命名规范

```
<type>/<issue-id>-<short-description>

类型：
- feature/  新功能
- fix/      Bug 修复
- refactor/ 重构
- docs/     文档更新
- chore/    杂项（配置、依赖等）

示例：
- feature/F001-sqlite-mcp
- fix/login-validation
- refactor/api-response-format
- docs/readme-update
```

### 创建新分支（新需求必须）

```bash
# 从 main 创建新分支
git checkout main
git pull origin main  # 先同步远程（如果需要）
git checkout -b feature/F001-sqlite-mcp

# 或者从当前分支创建
git checkout -b feature/new-feature
```

### 分支操作

```bash
# 查看所有分支
git branch -a

# 切换分支
git checkout feature/F001-sqlite-mcp

# 删除已合并的本地分支
git branch -d feature/old-feature

# 查看当前分支状态
git status
```

## Commit 规范

### Commit 消息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型（type）

| 类型 | 说明 | 示例 |
|------|------|------|
| feat | 新功能 | feat(api): add user login endpoint |
| fix | Bug 修复 | fix(auth): resolve token expiry issue |
| refactor | 重构 | refactor(db): optimize query performance |
| docs | 文档 | docs(readme): update installation guide |
| style | 格式 | style(lint): fix code formatting |
| test | 测试 | test(api): add unit tests for auth |
| chore | 杂项 | chore(deps): update dependencies |

### Commit 模板

```bash
# 基本格式
git commit -m "feat(scope): brief description"

# 带详细说明
git commit -m "feat(api): add user login endpoint" -m "Implement JWT-based authentication with refresh token support"

# 带关联 Issue
git commit -m "feat(api): add user login endpoint" -m "Closes #123"

# 完整格式（使用 HEREDOC）
git commit -m "$(cat <<'EOF'
feat(api): add user login endpoint

- Implement JWT-based authentication
- Add refresh token support
- Add login validation

Closes #123

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

## 标准工作流

### 新需求工作流

```bash
# 1. 确保在 main 分支
git checkout main

# 2. 创建新分支（必须）
git checkout -b feature/F001-feature-name

# 3. 开发过程中的提交
git add <files>
git commit -m "feat(scope): description"

# 4. 查看状态
git status
git log --oneline -5

# ⚠️ 5. push 由人类手动执行
# git push -u origin feature/F001-feature-name
```

### 修复 Bug 工作流

```bash
# 1. 从 main 创建修复分支
git checkout main
git checkout -b fix/bug-description

# 2. 修复并提交
git add <files>
git commit -m "fix(scope): resolve bug description"

# ⚠️ 3. push 由人类手动执行
# git push -u origin fix/bug-description
```

### 查看变更

```bash
# 查看当前状态
git status

# 查看未暂存的变更
git diff

# 查看已暂存的变更
git diff --cached

# 查看最近提交
git log --oneline -10

# 查看文件变更历史
git log --follow --oneline <file>

# 查看某次提交的详情
git show <commit-hash>
```

### 撤销操作

```bash
# 撤销工作区修改（未 add）
git restore <file>

# 撤销暂存（已 add，未 commit）
git restore --staged <file>

# 修改最近一次提交消息
git commit --amend -m "new message"

# ⚠️ 危险：撤销提交（保留修改）
git reset --soft HEAD~1

# ⚠️ 危险：撤销提交（丢弃修改）
git reset --hard HEAD~1
```

## 常用命令速查

### 日常操作

```bash
# 查看状态
git status

# 添加文件
git add <file>           # 添加单个文件
git add <dir>/           # 添加目录
git add -p               # 交互式添加

# 提交
git commit -m "message"
git commit --amend       # 修改最近提交

# 查看历史
git log --oneline -10
git log --graph --oneline --all
```

### 分支操作

```bash
# 创建并切换
git checkout -b <branch>

# 合并分支
git checkout main
git merge <branch>

# 查看分支
git branch -a

# 删除分支
git branch -d <branch>
```

### 远程操作（仅查看，不自动执行）

```bash
# 查看远程仓库
git remote -v

# 查看远程分支
git branch -r

# 查看与远程的差异
git fetch origin
git log HEAD..origin/main --oneline

# ⚠️ push 由人类手动执行
# git push origin <branch>
```

## 禁止操作

以下操作 **禁止 AI 自动执行**，必须由人类手动确认：

| 操作 | 原因 |
|------|------|
| `git push` | 影响远程仓库，需人工确认 |
| `git push --force` | 危险操作，可能覆盖他人提交 |
| `git reset --hard` | 丢弃未提交的修改 |
| `git clean -fd` | 删除未跟踪的文件 |
| `git rebase` | 重写历史，需谨慎 |

## 与 Harnesses 流程集成

在 Harnesses 模式下，每轮完成一个 feature 后：

```bash
# 1. 查看变更
git status
git diff

# 2. 添加变更
git add <changed-files>

# 3. 提交（AI 可执行）
git commit -m "feat(harnesses): F001 - feature description"

# 4. 更新 progress 文件（如果需要）
# ...

# ⚠️ 5. push 由人类决定是否执行
```

## 项目特定配置

本项目（spec_coding）的 Git 配置：

- 主分支：`main`
- 提交签名：Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
- 提交前检查：确保 lint 和 test 通过
