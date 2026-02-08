status: implementation

# Spec 列表 API

- **接口**: `GET /api/spec/list`
- **返回**: `{ ok, data: [ { id, title, status } ], error? }`
- **约定**: 仅返回 status 为 proposal 或 implementation 的项。
