---
name: dev_services
description: 开发依赖服务自动化管理器：自动检测服务需求、智能决策、创建和管理 Docker 服务（PostgreSQL、Redis、MySQL、MongoDB 等）
---

# Dev Services Skill

自动检测项目对开发服务的需求（数据库、缓存等），智能决策是创建新服务还是复用现有服务，并提供统一的管理接口。

## 核心能力

### 1. 服务检测 (detect_service_needs)

自动分析项目代码，检测需要的服务：

**检测维度：**
- 代码导入语句：`import psycopg2`, `from redis import`, `mysql.connector`
- 配置文件：`.env`, `config.yml`, `settings.py` 中的连接字符串
- 依赖文件：`requirements.txt`, `package.json` 中的数据库驱动

**使用：**
```bash
# 检测当前项目需要的服务
./scripts/lib/detect.sh
# 输出: postgresql redis
```

### 2. 智能决策 (resolve_service)

当检测到服务需求时，智能决策：

**决策树：**
1. 检查是否已有同名服务在运行 → 复用
2. 检查是否有可复用的兼容服务 → 询问复用
3. 都没有 → 创建新服务

**使用：**
```bash
# 决策服务创建
./scripts/lib/resolve.sh postgresql
# 输出决策结果和建议
```

### 3. 服务模板

支持的服务类型：

| 服务 | 脚本 | 默认端口范围 | 特性 |
|------|------|-------------|------|
| PostgreSQL | `scripts/services/postgres.sh` | 5432-5499 | 随机端口、随机密码 |
| Redis | `scripts/services/redis.sh` | 6379-6399 | 无密码模式 |
| MySQL | `scripts/services/mysql.sh` | 3306-3399 | 随机端口、随机密码 |
| MongoDB | `scripts/services/mongodb.sh` | 27017-27099 | 随机端口、随机密码 |

**创建服务：**
```bash
# 创建 PostgreSQL
./scripts/services/postgres.sh create
# 输出连接信息，写入 .dev-services/

# 创建 Redis
./scripts/services/redis.sh create
```

### 4. 服务管理

统一的服务管理接口：

```bash
# 列出所有开发服务
./scripts/lib/manage.sh list

# 获取服务连接信息
./scripts/lib/manage.sh get postgresql

# 启动/停止服务
./scripts/lib/manage.sh start postgresql
./scripts/lib/manage.sh stop postgresql

# 查看日志
./scripts/lib/manage.sh logs postgresql
```

## 配置文件

服务创建后，配置信息写入 `.dev-services/` 目录：

```
.dev-services/
├── postgresql.env      # PostgreSQL 连接信息
├── redis.env           # Redis 连接信息
└── services.json       # 所有服务元数据
```

**环境变量格式：**
```bash
# postgresql.env
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=devuser
POSTGRES_PASSWORD=random_password
POSTGRES_DB=devdb
DATABASE_URL=postgresql://devuser:random_password@127.0.0.1:5432/devdb
```

## 工作流集成

### 在开发会话开始时

```bash
# 1. 检测服务需求
./scripts/lib/detect.sh

# 2. 对每个需要的服务
./scripts/lib/resolve.sh <service_name>

# 3. 按决策结果创建或复用服务
```

### Claude 自动化调用

当检测到代码需要数据库/缓存时：

1. **自动检测**：分析代码发现 `import psycopg2`
2. **智能决策**：检查是否有现成的 PostgreSQL
3. **创建/复用**：按决策创建新服务或复用现有
4. **注入配置**：将连接信息写入 `.env` 或提示用户

## 使用示例

### 场景：新项目需要 PostgreSQL

```bash
# Claude 检测到代码需要 PostgreSQL
# 自动执行：

# 1. 检查现有服务
docker ps --filter "name=dev-postgres"

# 2. 没有则创建
./scripts/services/postgres.sh create

# 3. 输出配置
echo "已创建 PostgreSQL 服务"
echo "DATABASE_URL=postgresql://..." > .env
```

### 场景：需要 Redis 缓存

```bash
# 检测到 Redis 依赖
./scripts/lib/resolve.sh redis

# 如果已有 dev-redis，输出复用信息
# 如果没有，创建新服务
./scripts/services/redis.sh create
```

## 目录结构

```
.claude/skills/dev_services/
├── SKILL.md                    # 本文档
├── scripts/
│   ├── lib/
│   │   ├── detect.sh          # 服务检测逻辑
│   │   ├── resolve.sh         # 智能决策逻辑
│   │   └── manage.sh          # 服务管理接口
│   └── services/
│       ├── postgres.sh        # PostgreSQL 模板
│       ├── redis.sh           # Redis 模板
│       ├── mysql.sh           # MySQL 模板
│       └── mongodb.sh         # MongoDB 模板
```

## 快速开始

```bash
# 1. 检测项目需要的服务
.claude/skills/dev_services/scripts/lib/detect.sh

# 2. 智能决策（查看建议）
.claude/skills/dev_services/scripts/lib/resolve.sh postgresql

# 3. 创建服务
.claude/skills/dev_services/scripts/services/postgres.sh create

# 4. 管理服务
.claude/skills/dev_services/scripts/lib/manage.sh list
.claude/skills/dev_services/scripts/lib/manage.sh get postgresql
```

## 前置条件

- Docker 已安装并运行
- `docker` 命令可用
- 端口范围未被占用（5432-5499, 6379-6399, 3306-3399, 27017-27099）

## 注意事项

1. **数据持久化**：服务数据存储在 Docker volume 中，删除容器不会丢失数据
2. **端口冲突**：自动检测并使用下一个可用端口
3. **密码安全**：自动生成随机密码，存储在 `.dev-services/` 中
4. **清理**：使用 `docker rm` 删除容器，volume 数据仍保留

## 实现状态

- [x] DS001: Skill 目录结构和 SKILL.md
- [x] DS002: 服务检测逻辑 (detect_service_needs)
- [x] DS003: PostgreSQL 服务模板
- [x] DS004: Redis 服务模板
- [x] DS005: MySQL 服务模板
- [x] DS006: MongoDB 服务模板
- [x] DS007: 服务管理功能
- [x] DS008: 智能决策逻辑 (resolve_service)
- [x] DS009: 集成测试
