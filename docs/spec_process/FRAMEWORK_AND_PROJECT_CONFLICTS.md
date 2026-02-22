# 框架与项目：开发中可能遇到的冲突与对策

本文档梳理「用本框架做模板开发其他项目」或「在同一仓库中同时维护框架与业务」时，可能出现的**与 Skills 路径类似**的冲突，以及建议的**预防与解决方式**。便于提前规避或快速排查。

---

## 一、Skills 路径约定

- **约定**：项目技能放在 `.cursor/skills/` 下，按子目录或命名区分（如 `api_pydantic_style`、`domain_naming_convention` 与项目专属子目录）。多项目或同仓多技能时注意命名不冲突。详见 README 与 [cursor_skills_and_mcp.md](../cursor_skills_and_mcp.md)。

---

## 二、MCP 与配置中的「项目路径」硬编码

### 2.1 MCP filesystem 路径

- **问题**：`mcp.json` 里 filesystem 的 `args` 若写死为当前仓库路径（如 `d:\code\spec_coding`），复制到其他项目或换机器后，MCP 仍指向旧目录，导致 Agent 读写错项目。
- **对策**：
  - 示例与文档中**不要写死绝对路径**，改为占位符（如 `C:\path\to\your\project\root`）并说明：「请替换为当前项目根目录的绝对路径」。
  - 使用本框架新开项目时，在用户级 `mcp.json` 中把 filesystem 的路径改为**新项目根目录**。
- **本仓库已做**：在 [cursor_skills_and_mcp.md](../cursor_skills_and_mcp.md) 的 mcp.json 示例中使用占位符并加说明。

### 2.2 环境变量与端口

- **问题**：前端 `NEXT_PUBLIC_API_URL` 默认连 `http://127.0.0.1:8000`；若本机同时跑多个基于本框架的项目且都用 8000，会端口冲突。
- **对策**：不同项目使用不同端口（如 8001、8002），并在各自项目里设置对应的 `NEXT_PUBLIC_API_URL`。文档中已说明可通过该变量覆盖。

---

## 三、Rules：框架规则 vs 项目规则

- **问题**：`.cursor/rules/` 下既有框架规则（spec_trigger、spec_manager、global_guard、fastapi_shield、frontend_architect），后续可能加项目专属规则。若命名或职责不清，易误删/误改框架规则，或不知道哪些可改。
- **对策**：
  - **框架规则**（建议保留、仅按需微调）：`spec_trigger.mdc`、`spec_manager.mdc`、`global_guard.mdc`、`fastapi_shield.mdc`、`frontend_architect.mdc`。它们约定 Spec 流程、全局约束与后端/前端规范。
  - **项目规则**：可新增 `.cursor/rules/` 下其他 `.mdc` 文件，命名建议与业务相关（如 `billing_rules.mdc`），避免与上述文件名混淆。
  - 若修改框架规则，注意保持与 `docs/spec_process/` 下流程文档一致。
- **目录**：Cursor 对 rules 的加载方式以官方为准；当前不强制将框架规则迁入子目录，仅通过**命名与文档**区分框架规则与项目规则。

---

## 四、目录结构假定（backend / frontend / app）

- **问题**：规则中 `globs: backend/**`、`globs: frontend/**` 以及 Skill/规则内引用的 `backend/app/core/response.py`、`app/api/` 等，均假定仓库有 `backend/`、`frontend/`，且后端包名为 `app`。若新项目改为 `server/`、`web/` 或包名改为 `myapp`，规则与技能中的路径会失效或误导。
- **对策**：
  - 使用本框架时，尽量保持 `backend/`、`frontend/` 及后端包名 `app`；若必须改名，需同步修改：
    - `.cursor/rules/` 中对应规则的 `globs`（如改为 `server/**`）；
    - `.cursor/skills/api_pydantic_style/SKILL.md` 等中写死的 `backend/app/`、`app/core/` 等路径。
  - 文档中已说明技术栈可替换，但目录与包名变更需人工同步规则与技能。

---

## 五、Spec 流程相关

### 5.1 多需求同领域归档顺序

- **问题**：多个 active 项均涉及同一 `specs/<领域>/spec.md` 时，若同时归档或顺序不清，合并 delta 可能互相覆盖或顺序错乱。
- **对策**：归档时若存在多个 active 涉及同一领域，按**完成顺序**或**用户指定顺序**依次合并到该 `specs/<领域>/spec.md`；必要时与用户确认顺序。已在 `spec_manager.mdc` 中补充约定。

### 5.2 需求取消 / 废弃

- **问题**：某需求已录在 active 但决定不做了，若没有统一做法，可能一直留在 active 或被人误删，不利于管理。
- **对策**：可选择其一：
  - 将该 active 移入 `docs/spec/archive/`，目录名加后缀 `_cancelled`（如 `archive/2025-02-20_xxx_cancelled`），或在 spec 文首标 `status: cancelled` 并简短注明原因；
  - 或直接删除该 active 文件/目录（若不需要留痕）。已在 `spec_manager.mdc` 中补充说明。

### 5.3 归档依赖人工说「归档」

- **问题**：归档仅在用户明确说「归档」「开发完成」等时执行；用户若忘记说，active 会堆积。
- **对策**：README 与流程说明中已强调「开发完成后请主动说归档」；可在日常习惯或团队约定中固定「需求验收后即说归档」。

### 5.4 active 可见性

- **问题**：提出新需求时若不知道当前已有哪些 active，容易重复建 spec 或与进行中需求冲突。
- **对策**：提出新需求前，先让 AI 列出 `docs/spec/active/` 下现有项；规则中已规定「先列出现有 active 再创建或修改 spec」。在 `docs/spec/active/README.md` 中可再次提示。

---

## 六、用户级 vs 项目级资源

| 资源           | 用户级（多项目共用）     | 项目级（本仓）                         |
|----------------|--------------------------|----------------------------------------|
| **Skills**     | `~/.cursor/skills/`      | `.cursor/skills/`（项目技能） |
| **Rules**      | 一般不放在用户级         | `.cursor/rules/`                       |
| **MCP 配置**   | `~/.cursor/mcp.json`     | 通常用用户级；filesystem 路径按项目设  |
| **docs/spec**  | 无                       | `docs/spec/`（active、archive、specs） |

克隆本框架到新仓库时：项目级内容会一并克隆；MCP 的 filesystem 路径需在新项目中改为新仓库路径；用户级 Skills 若已按推荐安装，无需每项目再配。

---

## 七、小结

与「Skills 路径」同类的开发中问题主要集中在：**路径或配置写死、框架与项目边界不清、流程依赖人工步骤**。通过「占位符 + 说明、框架/项目命名与文档约定、spec_manager 与 README 的补充约定」即可在不大改结构的前提下降低冲突与误用。若后续 Cursor 支持 rules/skills 子目录或工作区级 MCP，可再考虑将框架规则/技能进一步收拢到子目录。
