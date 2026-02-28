# Dev Services Skill 设计文档

## 概述

**名称**: `dev_services`

**用途**: 开发依赖服务自动化管理器 —— 当开发需要数据库/缓存等外部服务时，自动通过 Docker 创建、配置好，并自动注入到项目配置中。

**核心理念**:
- **智能检测**：Claude 自动检测代码需要什么服务
- **智能决策**：已有服务时询问复用，无服务时自动创建
- **服务隔离**：每个项目独立的服务容器，互不干扰
- **安全默认**：随机密码、仅本地端口、命名空间隔离

---

## 自动检测机制

### 检测触发点

| 触发点 | 检测逻辑 | 示例 |
|--------|----------|------|
| **导入语句** | 扫描 Python/TS import | `import psycopg2`, `from sqlalchemy import` |
| **配置文件** | 扫描 .env 模式 | `DATABASE_URL=postgres://...` |
| **依赖文件** | 扫描 requirements.txt | `psycopg2`, `redis` |
| **代码模式** | 扫描关键词 | `create_engine`, `Redis(`, `MongoClient` |

### 检测规则

```yaml
postgres:
  python:
    imports: ["import psycopg2", "from sqlalchemy import", "from asyncpg import"]
    patterns: ["create_engine", "AsyncEngine", "postgresql://"]
    packages: ["psycopg2", "sqlalchemy", "asyncpg"]
  typescript:
    imports: ["import { Pool } from 'pg'", "import { PrismaClient }"]
    patterns: ["postgresql://"]
  env_patterns: ["DATABASE_URL=postgres", "POSTGRES_"]

redis:
  python:
    imports: ["import redis", "from redis import", "import aioredis"]
    patterns: ["Redis(", "aioredis.from_url"]
    packages: ["redis", "aioredis"]
  typescript:
    imports: ["import Redis from 'ioredis'", "import { createClient } from 'redis'"]
    patterns: ["redis://"]
  env_patterns: ["REDIS_URL=", "REDIS_HOST="]

mongodb:
  python:
    imports: ["import pymongo", "from motor.motor_asyncio import"]
    patterns: ["MongoClient", "mongodb://"]
    packages: ["pymongo", "motor"]
  env_patterns: ["MONGODB_URI=", "MONGO_URL="]

mysql:
  python:
    imports: ["import pymysql", "import mysql.connector"]
    patterns: ["mysql://", "MySQLdb"]
    packages: ["pymysql", "mysql-connector-python"]
  env_patterns: ["MYSQL_", "DATABASE_URL=mysql"]
```

---

## 智能决策逻辑

### 决策树

```
检测到需要服务 X
    │
    ├─ 本地已有 dev_*_X 服务？
    │   │
    │   ├─ 无 → 【自动创建】 → 返回连接信息
    │   │
    │   └─ 有 → 有几个？
    │       │
    │       ├─ 1 个 running → 【询问】「检测到已有服务，是否复用？」
    │       │                   ├─ 是 → 返回连接信息
    │       │                   └─ 否 → 创建新实例
    │       │
    │       ├─ 1 个 stopped → 【询问】「检测到已停止的服务，是否启动？」
    │       │                    ├─ 是 → 启动并返回连接
    │       │                    └─ 否 → 创建新实例
    │       │
    │       └─ 多个 → 【询问】「检测到多个服务，选择使用哪个？」
    │                    └─ 选择后返回连接
    │
    └─ 开发者主动请求 → 【直接创建】
```

### 决策规则表

| 场景 | 本地服务状态 | 操作 | 是否询问 |
|------|-------------|------|----------|
| 自动检测 | 无 | 自动创建 | ❌ |
| 自动检测 | 1 个 running | 询问复用 | ✅ |
| 自动检测 | 1 个 stopped | 询问启动 | ✅ |
| 自动检测 | 多个 | 列出选择 | ✅ |
| 开发者主动请求 | 任意 | 直接创建 | ❌ |

### 询问模板

**已有服务（running）**:
```
🔄 检测到已有 PostgreSQL 服务:
- 名称: postgres_a1f2b3
- 数据库: spec_coding
- 运行时间: 2小时

是否复用此服务？
[A] 复用（推荐）  [B] 创建新实例
```

**已有服务（stopped）**:
```
⏸️ 检测到已停止的 Redis 服务:
- 名称: redis_b2c3d4
- 上次运行: 2天前

[A] 启动并复用（推荐）  [B] 创建新实例
```

**多个服务**:
```
🔍 检测到多个 PostgreSQL 服务:

| # | 名称 | 状态 | 数据库 | 运行时间 |
|---|------|------|--------|----------|
| A | postgres_a1f2b3 | running | spec_coding | 2h |
| B | postgres_c3d4e5 | running | test_db | 30m |

选择使用哪个？[A/B] 或 [C] 创建新实例
```

---

## 支持的服务列表

### 第一期（核心服务）

| 服务 | 容器镜像 | 默认端口 | 数据持久化 |
|------|----------|----------|------------|
| **postgres** | `postgres:15-alpine` | 随机 | ✅ volume |
| **mysql** | `mysql:8` | 随机 | ✅ volume |
| **redis** | `redis:7-alpine` | 随机 | ❌ 内存 |
| **mongodb** | `mongo:7` | 随机 | ✅ volume |

### 第二期（扩展服务，可选）

| 服务 | 容器镜像 | 默认端口 | 用途 |
|------|----------|----------|------|
| **elasticsearch** | `elasticsearch:8` | 随机 | 搜索引擎 |
| **rabbitmq** | `rabbitmq:3-management` | 随机 | 消息队列 |
| **minio** | `minio/minio` | 随机 | 对象存储 |
| **kafka** | `bitnami/kafka` | 随机 | 事件流 |

---

## 命名约定

```
容器名称:   dev_{project_name}_{service_type}_{instance_id}
网络名称:   dev_{project_name}_network
卷名称:     dev_{project_name}_{service_type}_data
配置文件:   .dev_services/{service_type}.env
```

**示例**:
```
容器:   dev_spec_coding_postgres_a1f2b3
网络:   dev_spec_coding_network
卷:     dev_spec_coding_postgres_data
配置:   .dev_services/postgres.env
```

---

## 配置文件格式

### .dev_services/{service}.env

```bash
# PostgreSQL - 自动生成于 2026-02-28T12:00:00
DEV_POSTGRES_HOST=127.0.0.1
DEV_POSTGRES_PORT=54321
DEV_POSTGRES_USER=dev_user_a1f2b3
DEV_POSTGRES_PASSWORD=xK9mN2pL5qR8sT
DEV_POSTGRES_DB=spec_coding

# 连接字符串（可直接复制使用）
DATABASE_URL=postgresql://dev_user_a1f2b3:xK9mN2pL5qR8sT@127.0.0.1:54321/spec_coding
```

### .dev_services/state.json

```json
{
  "project_name": "spec_coding",
  "services": {
    "postgres_a1f2b3": {
      "type": "postgres",
      "container_id": "abc123...",
      "created_at": "2026-02-28T12:00:00Z",
      "status": "running",
      "port": 54321,
      "credentials": {
        "user": "dev_user_a1f2b3",
        "password": "xK9mN2pL5qR8sT",
        "database": "spec_coding"
      }
    }
  }
}
```

---

## Skill 工具定义

### 0. detect_services（内部工具 - 自动调用）

**用途**: 检测代码/配置需要的服务

**触发时机**:
- 开始实现需要外部服务的功能时
- 代码中导入相关依赖时
- 配置文件引用服务时

**参数**:
```typescript
{
  scope: "current_file" | "project" | "directory",
  hint?: "postgres" | "redis" | "mysql" | "mongodb"  // 可选，指定检测类型
}
```

**返回**:
```typescript
{
  detected: [
    {
      type: "postgres",
      source: "backend/app/db.py",
      evidence: "from sqlalchemy import create_engine",
      confidence: 0.9
    },
    {
      type: "redis",
      source: "requirements.txt",
      evidence: "redis==5.0.0",
      confidence: 1.0
    }
  ]
}
```

**使用示例**:
```
Claude 内部调用:
→ detect_services(scope="project")
← { detected: [{ type: "postgres", ... }] }

→ 如果 detected 不为空，调用 resolve_service
```

### 0.1. resolve_service（内部工具 - 智能决策）

**用途**: 智能决策服务来源

**参数**:
```typescript
{
  service_type: "postgres" | "redis" | "mysql" | "mongodb",
  auto_create_if_missing?: boolean  // 默认 true
}
```

**返回**:
```typescript
{
  action: "use_existing" | "start_stopped" | "create_new",
  service?: {
    name: "postgres_a1f2b3",
    connection: { ... }
  },
  ask_user?: {
    question: "检测到已有服务，是否复用？",
    options: ["复用", "创建新实例"]
  }
}
```

**决策流程**:
```python
def resolve_service(service_type):
    existing = list_services(type=service_type)

    if not existing:
        # 无服务 → 自动创建
        return create_service(service_type)

    if len(existing) == 1:
        svc = existing[0]
        if svc.status == "running":
            # 有运行中的服务 → 询问复用
            return ask_user("是否复用？", options=["复用", "创建新实例"])
        else:
            # 有停止的服务 → 询问启动
            return ask_user("是否启动？", options=["启动", "创建新实例"])

    # 多个服务 → 列出选择
    return ask_user("选择服务？", options=existing + ["创建新实例"])
```

---

### 1. create_service

**用途**: 创建开发服务

**参数**:
```typescript
{
  service_type: "postgres" | "mysql" | "redis" | "mongodb" | ...,
  name?: string,  // 可选，默认为 service_type
  version?: string,  // 可选，默认使用推荐版本
  persist?: boolean,  // 可选，是否持久化数据，默认 true
  env?: Record<string, string>  // 可选，额外环境变量
}
```

**返回**:
```typescript
{
  success: true,
  service: {
    name: "postgres_a1f2b3",
    type: "postgres",
    container_id: "abc123...",
    connection: {
      host: "127.0.0.1",
      port: 54321,
      user: "dev_user_a1f2b3",
      password: "xK9mN2pL5qR8sT",
      database: "spec_coding",
      url: "postgresql://..."
    },
    env_file: ".dev_services/postgres.env"
  }
}
```

**使用示例**:
```
用户: 我需要 PostgreSQL 数据库
Claude: [调用 create_service(postgres)]
       ✅ PostgreSQL 已创建！
       - 连接字符串已写入 .dev_services/postgres.env
       - 你可以在代码中使用 DATABASE_URL 环境变量
```

### 2. list_services

**用途**: 列出当前项目的所有开发服务

**参数**: 无

**返回**:
```typescript
{
  services: [
    {
      name: "postgres_a1f2b3",
      type: "postgres",
      status: "running",
      port: 54321,
      uptime: "2h 30m"
    },
    {
      name: "redis_b2c3d4",
      type: "redis",
      status: "running",
      port: 63791,
      uptime: "1h 15m"
    }
  ]
}
```

### 3. get_connection

**用途**: 获取服务的连接信息

**参数**:
```typescript
{
  service_name: string  // 服务名称或类型
}
```

**返回**: 连接信息（包含密码）

### 4. stop_service

**用途**: 停止服务（保留数据）

**参数**:
```typescript
{
  service_name: string,
  remove_data?: boolean  // 是否删除数据，默认 false，需要人类确认
}
```

**安全限制**:
- `remove_data: true` 需要人类明确确认
- 确认提示：「⚠️ 这将删除所有数据，无法恢复。确认删除？」

### 5. start_service

**用途**: 启动已停止的服务

**参数**:
```typescript
{
  service_name: string
}
```

### 6. logs_service

**用途**: 查看服务日志

**参数**:
```typescript
{
  service_name: string,
  follow?: boolean,  // 是否持续跟踪，默认 false
  tail?: number  // 显示最后 N 行，默认 100
}
```

---

## 安全限制规则

### 自动允许（无需确认）

| 操作 | 条件 |
|------|------|
| `create_service` | 服务名称以 `dev_{project}_` 开头 |
| `list_services` | 仅列出当前项目的服务 |
| `get_connection` | 仅当前项目的服务 |
| `logs_service` | 仅当前项目的服务 |
| `stop_service` | `remove_data: false` |
| `start_service` | 仅当前项目的服务 |

### 需要人类确认

| 操作 | 确认提示 |
|------|----------|
| `stop_service(remove_data: true)` | 「⚠️ 这将永久删除所有数据，无法恢复。确认删除？」 |
| `create_service` 端口冲突时 | 「端口 XXXX 已被占用，是否使用随机端口？」 |
| 创建超过 3 个同类型服务 | 「已存在 3 个 PostgreSQL 实例，确认创建更多？」 |

### 禁止操作

| 操作 | 原因 |
|------|------|
| 操作非当前项目的容器 | 安全隔离 |
| `docker system prune` | 可能影响其他项目 |
| 暴露到公网 IP | 仅允许 127.0.0.1 |
| 使用特权容器 | 安全风险 |

---

## 底层实现

### 脚本结构

```
.claude/skills/dev_services/
├── SKILL.md              # Skill 定义（Claude 读取）
└── scripts/
    ├── dev-services.sh    # 统一入口脚本（所有操作）
    └── services/
        ├── postgres.sh     # PostgreSQL 服务模板
        ├── mysql.sh        # MySQL 服务模板
        ├── redis.sh        # Redis 服务模板
        └── mongodb.sh      # MongoDB 服务模板
```

### dev-services.sh 核心逻辑

```bash
#!/bin/bash
# dev-services.sh - 开发服务统一管理脚本
#
# 用法:
#   dev-services.sh create postgres
#   dev-services.sh create redis --name my-cache
#   dev-services.sh list
#   dev-services.sh connect postgres_xxx
#   dev-services.sh stop postgres_xxx [--delete-data]
#   dev-services.sh start postgres_xxx
#   dev-services.sh logs postgres_xxx [--follow]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROJECT_NAME=$(basename "$PROJECT_ROOT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'")
CONFIG_DIR="$PROJECT_ROOT/.dev_services"

# 颜色输出
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 生成随机字符串
random_string() {
    openssl rand -hex 12
}

# 获取随机端口
get_random_port() {
    python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()"
}

# 加载服务模板
load_service_template() {
    local service_type=$1
    local template_file="$SCRIPT_DIR/services/${service_type}.sh"
    if [[ ! -f "$template_file" ]]; then
        log_error "Unsupported service type: $service_type"
        exit 1
    fi
    source "$template_file"
}

# 创建服务
create_service() {
    local service_type=$1
    local service_name=$2

    load_service_template "$service_type"

    # 检查是否已存在
    local existing=$(docker ps -q -f "name=dev_${PROJECT_NAME}_${service_type}")
    if [[ -n "$existing" ]]; then
        log_warn "Service already exists: dev_${PROJECT_NAME}_${service_type}"
        return 1
    fi

    # 生成实例 ID 和配置
    local instance_id=$(random_string)
    local container_name="dev_${PROJECT_NAME}_${service_name}_${instance_id}"
    local port=$(get_random_port)
    local password=$(random_string)
    local user="dev_user_${instance_id}"
    local database="${PROJECT_NAME}"

    # 创建网络（如果不存在）
    docker network create "dev_${PROJECT_NAME}_network" 2>/dev/null || true

    # 创建容器
    docker run -d \
        --name "$container_name" \
        --network "dev_${PROJECT_NAME}_network" \
        -p "127.0.0.1:${port}:${SERVICE_PORT}" \
        ${SERVICE_VOLUME:+-v "$SERVICE_VOLUME"} \
        ${SERVICE_ENV[@]} \
        "$SERVICE_IMAGE"

    # 写入配置文件
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/${service_type}.env" << EOF
# ${service_type^^} - Auto-generated
DEV_${service_type^^}_HOST=127.0.0.1
DEV_${service_type^^}_PORT=$port
DEV_${service_type^^}_USER=$user
DEV_${service_type^^}_PASSWORD=$password
DEV_${service_type^^}_DB=$database

# Connection URL
$SERVICE_CONNECTION_URL
EOF

    log_info "✅ $service_type created: $container_name"
    log_info "   Port: $port"
    log_info "   Config: $CONFIG_DIR/${service_type}.env"
}

# 列出服务
list_services() {
    docker ps -a --filter "name=dev_${PROJECT_NAME}_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# 其他命令类似实现...
```

### 服务模板示例（postgres.sh）

```bash
# PostgreSQL 服务配置
SERVICE_IMAGE="postgres:15-alpine"
SERVICE_PORT="5432"
SERVICE_VOLUME="dev_${PROJECT_NAME}_postgres_data:/var/lib/postgresql/data"
SERVICE_ENV=(
    -e "POSTGRES_USER=dev_user_${instance_id}"
    -e "POSTGRES_PASSWORD=${password}"
    -e "POSTGRES_DB=${database}"
)
SERVICE_CONNECTION_URL="postgresql://${user}:${password}@127.0.0.1:${port}/${database}"
```

---

## 与现有工具链的集成

### 与 .env.example 的关系

创建服务后，自动追加到 `.env.example`:

```bash
# === Dev Services (自动生成) ===
# PostgreSQL
DEV_POSTGRES_HOST=127.0.0.1
DEV_POSTGRES_PORT=54321
...
```

### 与 init.sh 的关系

扩展 `init.sh` 支持开发服务:

```bash
# 启动开发服务
./docs/harnesses/init.sh --with-services postgres,redis
```

### 与 SQLite MCP 的关系

- SQLite MCP: 用于本地开发数据库（无需 Docker）
- Dev Services: 用于生产级数据库（PostgreSQL、MySQL 等）

两者共存，按需选择。

---

## 使用流程示例

### 场景 1: 新项目需要 PostgreSQL

```
用户: 我需要在项目中添加用户认证，需要 PostgreSQL

Claude:
1. [检测项目类型] 这是一个 FastAPI 项目
2. [调用 create_service(postgres)]
3. ✅ PostgreSQL 已创建！

连接信息:
- Host: 127.0.0.1:54321
- Database: spec_coding
- User: dev_user_a1f2b3
- Password: xK9mN2pL5qR8sT

配置已写入:
- .dev_services/postgres.env
- 请在 .env 中添加: source .dev_services/postgres.env

现在开始实现用户认证功能...
```

### 场景 2: 需要缓存

```
用户: 这个接口需要加缓存，帮我创建 Redis

Claude: [调用 create_service(redis)]
✅ Redis 已创建！

连接信息:
- Host: 127.0.0.1:63791
- 无密码（Redis 默认）

配置已写入 .dev_services/redis.env

现在开始添加缓存逻辑...
```

### 场景 3: 查看服务状态

```
用户: 看看当前有哪些开发服务

Claude: [调用 list_services()]

当前项目的开发服务:

| 服务 | 状态 | 端口 | 运行时间 |
|------|------|------|----------|
| postgres_a1f2b3 | running | 54321 | 2h 30m |
| redis_b2c3d4 | running | 63791 | 1h 15m |
```

---

## 实现优先级

### P0（必须实现）

1. `create_service` - 核心功能
2. `list_services` - 状态查看
3. `get_connection` - 获取连接信息

### P1（重要）

4. `stop_service` - 停止服务
5. `start_service` - 重启服务
6. `logs_service` - 日志查看

### P2（可选）

7. 支持更多服务类型（Elasticsearch、RabbitMQ 等）
8. 服务健康检查
9. 自动迁移（从 SQLite 到 PostgreSQL）

---

## 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| Docker 未安装 | 无法使用 | 首次使用时检测并提示安装 |
| 端口冲突 | 创建失败 | 使用随机端口 + 重试机制 |
| 数据丢失 | 丢失开发数据 | 默认持久化 + 明确确认删除 |
| 资源占用 | 内存/磁盘不足 | 提供停止不活跃服务的命令 |
| 密码泄露 | 安全风险 | 仅本地端口 + .gitignore 忽略配置 |

---

## 总结

| 维度 | 说明 |
|------|------|
| **价值** | 显著提升开发体验，「需要数据库」→「自动创建并配置好」 |
| **复杂度** | 中等（~500 行脚本） |
| **上下文占用** | 低（~400 tokens） |
| **依赖** | Docker CLI |
| **风险** | 低（本地隔离 + 安全默认） |
| **与现有工具关系** | 增量添加，不影响现有流程 |

---

## 下一步

确认设计后，可选择：

1. **直接实现**：按 Harnesses 流程开始实现
2. **调整设计**：修改某些细节后再实现
3. **暂缓实现**：保存设计文档，稍后实现

请告诉我你的决定。
