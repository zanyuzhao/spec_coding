---
name: curl_test
description: cURL 接口测试封装。提供标准化的 HTTP 请求模板、认证头配置、响应断言模式，用于 API 接口测试和调试。
---

# cURL 接口测试 Skill

提供标准化的 cURL 命令模板，用于 API 接口测试、调试和验证。

## 何时使用

- 测试后端 API 接口
- 验证 API 响应格式
- 调试认证问题
- 检查 HTTP 状态码和响应头
- 执行冒烟测试

## 基础模板

### GET 请求

```bash
# 基本 GET 请求
curl -s -X GET "http://127.0.0.1:8000/api/v1/endpoint" | jq

# 带查询参数
curl -s -X GET "http://127.0.0.1:8000/api/v1/endpoint?key=value&limit=10" | jq

# 带请求头
curl -s -X GET "http://127.0.0.1:8000/api/v1/endpoint" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <token>" | jq
```

### POST 请求

```bash
# JSON body
curl -s -X POST "http://127.0.0.1:8000/api/v1/endpoint" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"key": "value", "number": 123}' | jq

# 带认证
curl -s -X POST "http://127.0.0.1:8000/api/v1/endpoint" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"name": "test", "status": "active"}' | jq
```

### PUT 请求

```bash
curl -s -X PUT "http://127.0.0.1:8000/api/v1/endpoint/123" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"name": "updated", "status": "inactive"}' | jq
```

### DELETE 请求

```bash
curl -s -X DELETE "http://127.0.0.1:8000/api/v1/endpoint/123" \
  -H "Authorization: Bearer <token>" | jq
```

## 响应检查模式

### 检查状态码

```bash
# 获取状态码
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "http://127.0.0.1:8000/api/v1/endpoint")

# 断言状态码
if [ "$HTTP_CODE" -eq 200 ]; then
  echo "✅ 状态码正确: $HTTP_CODE"
else
  echo "❌ 状态码错误: 期望 200，实际 $HTTP_CODE"
fi
```

### 检查响应体

```bash
# 检查响应包含特定字段
RESPONSE=$(curl -s -X GET "http://127.0.0.1:8000/api/v1/endpoint")

# 使用 jq 检查字段存在
echo "$RESPONSE" | jq -e '.success == true' > /dev/null && echo "✅ success=true" || echo "❌ success 检查失败"

# 检查 data 数组长度
DATA_COUNT=$(echo "$RESPONSE" | jq '.data | length')
echo "数据条数: $DATA_COUNT"
```

### 完整测试函数

```bash
# API 测试函数
test_api() {
  local method=$1
  local endpoint=$2
  local expected_code=$3
  local body=$4

  local url="http://127.0.0.1:8000${endpoint}"
  local args=(-s -X "$method" -H "Content-Type: application/json" -H "Accept: application/json")

  if [ -n "$body" ]; then
    args+=(-d "$body")
  fi

  local response
  response=$(curl "${args[@]}" -w "\n%{http_code}" "$url")

  local http_code
  http_code=$(echo "$response" | tail -n 1)
  local body_response
  body_response=$(echo "$response" | sed '$d')

  if [ "$http_code" -eq "$expected_code" ]; then
    echo "✅ $method $endpoint - 状态码: $http_code"
    echo "$body_response" | jq
  else
    echo "❌ $method $endpoint - 期望: $expected_code, 实际: $http_code"
    echo "$body_response" | jq
    return 1
  fi
}

# 使用示例
# test_api "GET" "/api/v1/specs" 200
# test_api "POST" "/api/v1/specs" 201 '{"name":"test"}'
```

## 本项目 API 端点

基于 backend/app/api/routes.py：

```bash
# 列出所有 specs
curl -s -X GET "http://127.0.0.1:8000/api/spec/list" | jq

# 健康检查（如果有的话）
curl -s -X GET "http://127.0.0.1:8000/docs" -o /dev/null -w "状态码: %{http_code}\n"
```

## 常用选项说明

| 选项 | 说明 |
|------|------|
| `-s` | 静默模式，不显示进度 |
| `-X <method>` | 指定 HTTP 方法 |
| `-H "Header: Value"` | 添加请求头 |
| `-d '<json>'` | 添加 JSON 请求体 |
| `-o /dev/null` | 丢弃响应体 |
| `-w "%{http_code}"` | 输出 HTTP 状态码 |
| `| jq` | 格式化 JSON 输出 |

## 认证模式

### Bearer Token

```bash
curl -s -X GET "http://127.0.0.1:8000/api/protected" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Basic Auth

```bash
curl -s -X GET "http://127.0.0.1:8000/api/protected" \
  -u "username:password"
```

### API Key

```bash
curl -s -X GET "http://127.0.0.1:8000/api/protected" \
  -H "X-API-Key: your-api-key"
```

## 错误处理

```bash
# 超时设置
curl -s --max-time 10 -X GET "http://127.0.0.1:8000/api/endpoint" | jq

# 重试
curl -s --retry 3 --retry-delay 2 -X GET "http://127.0.0.1:8000/api/endpoint" | jq

# 显示错误详情
curl -s -X GET "http://127.0.0.1:8000/api/endpoint" -w "\n状态码: %{http_code}\n耗时: %{time_total}s\n"
```

## 与本项目集成

本项目使用统一的 `ApiResponse[T]` 格式，响应结构为：

```json
{
  "success": true,
  "data": { ... },
  "message": null
}
```

或错误时：

```json
{
  "success": false,
  "data": null,
  "message": "错误描述"
}
```

测试时应验证 `success` 字段和 HTTP 状态码一致。
