---
name: domain-naming-convention
description: Unify domain and spec-related file/directory naming with underscores. Use when creating or renaming spec files, specs subdirs, or when documenting naming rules.
---

# 领域与 Spec 命名规范（下划线统一）

本规范要求：**与「领域」相关的文件名、目录名及文档中的命名描述，一律使用下划线（`_`），禁止使用中划线/连字符（`-`）**。便于与 URL 路径、日期写法（如 `2025-02-07`）区分，并统一可读性。

## 何时使用

- 在 `docs/spec/active/` 下新建或重命名 spec 文件。
- 在 `docs/spec/specs/` 下新建领域子目录。
- 在 `docs/spec/archive/` 下命名归档目录（日期部分可用 `-`，名称部分用 `_`）。
- 编写或修改规则、文档时描述「领域」「spec 文件名」的命名约定。
- 前端/后端中与 spec 或领域相关的文件名（如组件、模块）需与 spec 命名风格一致时。

## 强制约定

1. **Spec 单文件**：`{领域}_{简短描述}.md`，例如 `auth_login.md`、`spec_list_api.md`。禁止 `auth-login.md`、`spec-list-api.md`。
2. **Spec 目录**（多工件时）：`{领域}_{描述}/`，例如 `auth_login/`、`spec_list_api/`。禁止 `auth-login/`、`spec-list-api/`。
3. **Source of Truth 领域目录**：`docs/spec/specs/<领域>/` 中的 `<领域>` 使用下划线，例如 `specs/auth/`、`specs/spec_list/`。禁止 `specs/spec-list/`。
4. **归档目录**：建议 `archive/YYYY-MM-DD_{需求名}/`，日期保留 `-` 便于排序，名称部分用下划线，例如 `archive/2025-02-07_spec_list_api/`。禁止 `archive/2025-02-07-spec-list-api/`。
5. **文档与规则中的示例**：凡描述上述命名处，一律写 `领域_描述`、`auth_login`、`spec_list_api`、`specs/spec_list/` 等，不写带中划线的示例。

## 不适用本规范的情形

- 日期：`YYYY-MM-DD` 保持连字符，不改为下划线。
- 第三方或工具既定命名（如 npm 包名）可不改，除非你正在统一项目内 spec/领域相关命名。
- URL 路径中的连字符（如 `/api/spec/list`）由 API 设计决定，不强制改为下划线。

## 参考

- Spec 目录与命名规则：`.cursor/rules/spec_manager.mdc`。
- 本 Skill 与 `spec_manager.mdc` 一致；新建或修改 spec、归档、写文档时按本规范使用下划线。
