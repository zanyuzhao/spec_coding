# Spec 目录

本目录**仅存业务需求**，不含流程与指引文档。

- **active/**：进行中的变更（提案或实现中），极简业务描述。
- **archive/**：已结束的变更，仅历史记录。
- **specs/**：Source of Truth，按领域一份「当前系统」规格；归档时从 active 合并 delta 到此。

**流程/指引类文档**（开发清单、归档检查、最佳实践等）放在 **`docs/spec_process/`**，不放在本目录下。

## 状态机

```
提案 (proposal) → 实现 (implementation) → 校验 → 归档（合并到 specs/，移入 archive，并做归档清理）
```

**强制规则**：非 Bug 的功能/接口/UI 变更，必须先在此目录新增或修改 spec，再写代码。归档前需做「实现 vs spec」校验；归档时将 delta 合并进 `specs/<领域>/spec.md`，并将该变更专属的临时文档一并移入 archive 或删除。流程与清单见 [docs/spec_process/README.md](../spec_process/README.md)。
