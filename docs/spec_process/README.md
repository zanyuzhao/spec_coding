# Spec 流程与指引文档

本目录存放**与 spec 流程本身相关**的文档，而非具体业务需求。

- **需求说明与设计文档模板**：[SPEC_DOC_TEMPLATE.md](./SPEC_DOC_TEMPLATE.md) — 新需求时产出文档的结构；产出后停止，待用户确认再说「继续开发」。
- **开发清单与归档检查列表**：[CHECKLISTS.md](./CHECKLISTS.md) — 实现与归档时逐项核对。
- **测试最佳实践**：[testing_best_practices.md](./testing_best_practices.md) — 测试策略、工具及可选性设计指南。
- **框架与项目冲突**：[FRAMEWORK_AND_PROJECT_CONFLICTS.md](./FRAMEWORK_AND_PROJECT_CONFLICTS.md) — 开发中可能遇到的路径/规则/配置冲突及对策。
- **不存放**：具体需求 spec（业务 spec 仅存在于 `docs/spec/active/`、`docs/spec/archive/`、`docs/spec/specs/`）。

**约定**：此类文档为常青文档，不随单次需求归档而删除。若某次变更是「改进 spec 流程」且产生了仅服务于该次变更的临时文档，归档时应将临时文档移入该变更在 archive 下的目录，或删除，不得留在 `docs/spec/` 或本目录造成混淆。
