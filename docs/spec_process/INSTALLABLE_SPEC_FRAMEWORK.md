# Spec 框架可安装化

本文档说明如何将本仓库的「Spec 流程 + Cursor 规则 + 技能」作为**可安装的脚手架**使用，从而：

- **新项目**：在任意空目录或已有项目根目录执行一条命令即可注入 Spec 框架，无需复制整仓再把业务写在 `backend/` 下。
- **老项目**：在任何现有仓库根目录执行初始化，即可接入 Spec 流程与规则，不强制改现有目录名。
- **降低理解成本**：项目结构由你自己定（如 `server/`、`web/`、包名 `myapp`），框架通过可选参数写入对应路径的规则与文档。

---

## 一、当前问题

- 每次开新项目都要**复制本仓库**，然后在 `backend/` 里写业务 → 新项目被包在「框架仓」里，多一层目录，且老项目无法复用。
- 规则与技能里写死了 `backend/`、`frontend/`、`app`，若你希望用 `server/`、`web/` 或包名 `myapp`，需手动改多处。

可安装化后：**任意目录**都可成为「Spec 驱动」的项目根，目录名与包名可配置。

---

## 二、使用方式

### 2.1 安装

从本仓库安装（开发/未发 PyPI 时）：

```bash
cd /path/to/spec_coding
pip install -e .
```

将来可发到 PyPI 后：

```bash
pip install spec-coding
```

### 2.2 在新项目根目录接入框架（推荐）

在**你的项目根目录**下执行：

```bash
cd /path/to/your_project
spec-coding init
```

会创建/写入：

- `docs/spec/`（active、archive、specs、README）
- `docs/spec_process/`（流程说明、检查清单、最佳实践等）
- `.cursor/rules/`（spec_trigger、spec_manager、global_guard、fastapi_shield、frontend_architect）
- `.cursor/skills/`（api_pydantic_style、domain_naming_convention，可选）
- `.claude/rules/`（与 Cursor 规则等价的 Claude Code 规则，含 spec 触发、归档、自循环实现等）
- `CLAUDE.md`（项目根，Claude Code 的项目说明与使用方式）

**不会**创建 `backend/`、`frontend/`，你的业务代码结构自己定；规则中的路径会使用默认 `backend`、`frontend`、`app`，若与你实际不符，见 2.4。**Cursor 与 Claude Code 均可使用**：同一套 spec 流程，init 后两种环境均可按「先出文档 → 确认 → 继续开发 → 归档」使用。

### 2.3 自定义目录与包名

若你的后端目录叫 `server/`、前端叫 `web/`、Python 包名为 `myapp`：

```bash
spec-coding init --backend-dir server --frontend-dir web --app-package myapp
```

生成的 `.cursor/rules/` 与 `.cursor/skills/` 中的路径和 glob 会使用你传入的值，无需事后手改。

### 2.4 可选：只初始化 Spec 文档与流程（无 Cursor 规则/技能）

若你只想用 `docs/spec` 的目录与流程，不用 Cursor 规则/技能：

```bash
spec-coding init --docs-only
```

只创建 `docs/spec/` 与 `docs/spec_process/`。

### 2.5 可选：带后端/前端的完整脚手架

若希望像「复制本仓」一样得到一份带 FastAPI + Next.js 的起步项目：

```bash
spec-coding create my_app --with-starter
```

会在当前目录下创建 `my_app/`，其中包含 Spec 框架 + `backend/` + `frontend/` 的模板代码，等同于当前仓库的简化版。适合「从零开新全栈项目」且想沿用本仓库技术栈时使用。

---

## 三、与「复制整仓」的对比

| 方式           | 新项目结构           | 老项目接入     | 目录/包名定制     |
|----------------|----------------------|----------------|-------------------|
| 复制整仓       | 业务在 `xxx/backend/` 下，多一层 | 不便           | 需手改规则与技能  |
| `spec-coding init` | 业务即项目根，无多余层级 | 任意目录可接入 | `--backend-dir` 等 |

---

## 四、npx 方式（可选）

若团队无 Python 环境或习惯用 npx，可提供等价能力：

- **方案 A**：发布一个 npm 包 `create-spec-coding-app`，执行 `npx create-spec-coding-app@latest my_project` 时，从 GitHub release 下载模板 zip，解压到 `my_project/`（内容与 `spec-coding init` + 可选 starter 一致）。
- **方案 B**：在仓库中保留一个 `scripts/init.js`，用 Node 实现「复制模板 + 占位符替换」，通过 `npx spec-coding-init` 或文档中的 `node scripts/init.js` 调用。

当前以 **pip 安装 + `spec-coding init`** 为主；npx 可作为后续扩展。

---

## 五、单一来源（仓库中只有一份）

**仓库里只保留一份**：规则、技能与流程文档仅存在于仓库根的 `.cursor/` 与 `docs/`。`spec_cli` 下的 `templates/` 已加入 `.gitignore`，不纳入版本控制；在 `pip install -e .` 或打 sdist/wheel 时由 `build_templates` 从仓库根生成（并写入占位符）。

- 修改规则/技能/流程时只改仓库根 `.cursor` 与 `docs`，无需也不应改 `spec_cli/templates/`。
- 安装（`pip install -e .`）与首次运行 `spec-coding init` 时会自动生成 `templates/`，无需手跑脚本。

## 六、模板与占位符

CLI 内置模板中对路径使用占位符，在 `init` 时替换为实际值：

- `{{BACKEND_DIR}}` → 默认 `backend`，可用 `--backend-dir` 覆盖
- `{{FRONTEND_DIR}}` → 默认 `frontend`，可用 `--frontend-dir` 覆盖
- `{{APP_PACKAGE}}` → 默认 `app`（Python 包名），可用 `--app-package` 覆盖

规则与技能中凡涉及「后端目录」「前端目录」「后端包名」的地方都会替换，保证与项目实际结构一致。详见 [FRAMEWORK_AND_PROJECT_CONFLICTS.md](./FRAMEWORK_AND_PROJECT_CONFLICTS.md) 中的「目录结构假定」与对策。

---

## 七、小结

- **推荐用法**：新项目在空目录或已有项目根执行 `spec-coding init`（按需加 `--backend-dir` 等），业务代码与 Spec 文档同层，无多余嵌套。
- **老项目**：在现有仓库根执行 `spec-coding init` 并传入与实际一致的目录/包名，即可接入 Spec 流程与 Cursor 规则。
- **可选**：`spec-coding create my_app --with-starter` 提供「框架 + 后端 + 前端」一站式脚手架；npx 方案可后续补充。
