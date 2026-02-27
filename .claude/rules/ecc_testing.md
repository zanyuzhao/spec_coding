# ECC Testing（测试要求）

适用：backend/**/*.py、frontend/**/*.{ts,tsx}、**/test*.py、**/*.test.*

## 最低测试覆盖率：80%

以下类型均需覆盖：
1. **单元测试**：函数、工具、组件
2. **集成测试**：API 端点、数据库操作
3. **E2E 测试**：关键用户流程（按语言/框架选用）

## TDD 流程（强制）

1. 先写测试（RED）
2. 跑测试，应失败
3. 最小实现（GREEN）
4. 跑测试，应通过
5. 重构（IMPROVE）
6. 验证覆盖率 ≥ 80%

## 测试失败时

1. 检查测试隔离与 mock
2. 优先修实现，除非确认测试写错

与 spec_implementation_phase、ecc_tdd_workflow Skill 配合使用。
