# API 与 Pydantic 风格一致

在实现或修改 **backend** 的 HTTP 接口时，必须与本项目的统一响应格式和 Pydantic 约定保持一致。

## 何时使用

- 新增或修改 `backend/app/api/` 下的路由。
- 定义或修改请求体、响应体、查询参数。

## 强制约定

1. **响应体**：所有接口统一使用 `ApiResponse[T]`，通过 `success(data)` / `fail(message)` 构造。禁止直接返回裸 `dict` 或 Pydantic 模型作为 JSON body。
2. **类型**：禁止 `Any`；路由处理函数与依赖函数必须有完整参数类型与返回类型；返回类型为 `ApiResponse[具体类型]`。
3. **请求/响应体**：使用 Pydantic v2 `BaseModel` 定义，禁止手写 dict。
4. **依赖**：可复用逻辑通过 `Depends(...)` 注入，参考 `app/core/deps.py`。

## 参考实现

- 统一响应定义：`backend/app/core/response.py`（`ApiResponse`、`success`、`fail`）。
- 路由示例：`backend/app/api/routes.py`（`response_model=ApiResponse[...]`，返回 `success(...)`）。

## 示例

```python
from app.core import ApiResponse, success
from app.core.deps import get_placeholder_dep

@router.get("/list", response_model=ApiResponse[list[SpecItem]])
def list_specs(dep: str = Depends(get_placeholder_dep)) -> ApiResponse[list[SpecItem]]:
    return success(service.list())
```

与 `fastapi_shield.md` 一致。
