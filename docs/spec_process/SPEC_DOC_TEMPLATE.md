# 需求说明与设计文档模板

新需求触发时，在 `docs/spec/active/` 下产出**需求说明**与**设计文档**后即停止，待用户确认或修改文档后再继续开发。推荐写在同一份 spec 中，用下列结构（可按需求裁剪）。

---

## 裁剪指南

根据需求复杂度选择合适的模板：

| 复杂度 | 定义 | 必填章节 |
|--------|------|----------|
| **简单** | 加字段、改文案、单端点小改动 | 需求简述 + 字段对照表 |
| **中等** | 新增 1-3 个端点 + 基础 UI | 需求简述 + API 契约 + 数据模型 |
| **复杂** | 多端点 + 前后端联动 + 状态管理 | 完整模板 |

**裁剪原则**：
- 简单变更不要用完整模板，增加不必要开销
- 中等变更至少要有 API 契约，确保前后端对齐
- 复杂变更必须用完整模板，并考虑拆分多个 spec

---

## 文件头

```markdown
status: proposal
```

文档阶段用 `proposal`；用户确认并说「继续开发」后，可改为 `implementation`。

---

## 一、需求说明

- **需求简述**：一两句话说明做什么、为谁、解决什么问题。
- **背景/目标**（可选）：为什么做、业务或技术背景。
- **用户故事或场景**（可选）：例如「作为 xxx，我希望…，以便…」或关键使用场景。
- **验收标准**（文字）：完成的定义，如「接口返回分页数据」「前端列表支持排序」。可执行验收命令放在「设计」的「验收」段。

---

## 二、设计

### 2.1 API 契约（必填）

**端点列表**：以表格形式列出所有接口。

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| GET | /api/items | 获取列表 | 可选 |
| POST | /api/items | 创建项 | 必需 |

**请求/响应格式**：每个端点详细说明。

```
GET /api/items?page=1&size=20&status=active

Query 参数：
  - page: int, 默认 1, 页码
  - size: int, 默认 20, 每页数量
  - status: str, 可选, 筛选状态

响应 200：
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "size": 20,
    "pages": 5
  }
}

错误响应：
{
  "code": 400,
  "message": "Invalid parameter: page must be positive",
  "data": null
}
```

**分页格式**（统一约定）：
```json
{
  "items": [],      // 数据数组
  "total": 100,     // 总条数
  "page": 1,        // 当前页（从 1 开始）
  "size": 20,       // 每页条数
  "pages": 5        // 总页数
}
```

### 2.2 数据模型（必填）

**数据库表结构**：

```sql
-- 示例：items 表
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**前后端类型对应表**：

| 字段名 | 数据库类型 | 后端类型 (Pydantic) | 前端类型 (TS) | 必填 | 说明 |
|--------|-----------|-------------------|--------------|------|------|
| id | SERIAL | int | number | 是 | 主键 |
| name | VARCHAR(255) | str | string | 是 | 名称 |
| status | VARCHAR(50) | str | string | 否 | 状态，默认 active |
| created_at | TIMESTAMP | datetime | string (ISO) | 是 | 创建时间 |
| updated_at | TIMESTAMP | datetime | string (ISO) | 是 | 更新时间 |

### 2.3 前后端方案

- **后端改动点**：新增/修改的路由、服务、模型文件路径。
- **前端改动点**：新增/修改的页面、组件、API 调用文件路径。
- **调用关系**：前端如何调用后端接口，数据流向。

### 2.4 任务拆分（可选）

编号列表，如：
1. 后端：新增 GET /api/xxx
2. 后端：新增 Pydantic 模型
3. 前端：列表页与请求
4. 验收：跑 pytest 与 build

### 2.5 验收（必填）

列出可执行命令，实现完成后用于自测；失败则改代码再跑直到通过。

- 后端：`cd backend && pytest tests/test_xxx.py -v`
- 前端：`cd frontend && npm run build`
- E2E（可选）：`cd frontend && npm run test:e2e`

---

## 示例（完整）

```markdown
status: proposal

# 需求说明
- **需求简述**：订单列表支持分页与按状态筛选。
- **验收标准**：接口支持 page/size/status 参数并返回分页结构；前端展示分页控件与筛选。

# 设计

## API 契约

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| GET | /api/orders | 获取订单列表 | 可选 |

### GET /api/orders

Query 参数：
  - page: int, 默认 1
  - size: int, 默认 20
  - status: str, 可选, 值：pending/paid/cancelled

响应 200：
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [{ "id": 1, "status": "paid", ... }],
    "total": 100,
    "page": 1,
    "size": 20,
    "pages": 5
  }
}

## 数据模型

| 字段名 | 数据库类型 | 后端类型 | 前端类型 | 必填 |
|--------|-----------|---------|---------|------|
| id | SERIAL | int | number | 是 |
| status | VARCHAR(50) | str | string | 是 |

## 任务拆分
1. 后端：新增 Pydantic 模型 OrderResponse
2. 后端：新增 GET /api/orders 路由
3. 前端：订单列表页与分页 UI
4. 验收：见下

## 验收
- 后端：`cd backend && pytest tests/test_orders.py -v`
- 前端：`cd frontend && npm run build`
```

用户确认文档后说「继续开发」，再按此 spec 与设计进行实现。
