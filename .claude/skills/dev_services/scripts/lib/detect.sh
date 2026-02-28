#!/bin/bash
# detect.sh - 服务需求检测库
#
# 用法:
#   source scripts/lib/detect.sh
#   detect_service_needs
#
# 输出: 检测到的服务列表 (空格分隔)

set -e

# ========================================
# 颜色和输出
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }

# ========================================
# 服务检测规则
# ========================================

# PostgreSQL 检测规则
detect_postgresql() {
    local found=0

    # 检测 Python 导入
    if grep -r "import psycopg" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 SQLAlchemy PostgreSQL
    if grep -r "postgresql://" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测环境变量
    if grep -r "POSTGRES_" --include=".env*" --include="*.env" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 requirements.txt
    if [[ -f "requirements.txt" ]] && grep -q "psycopg" requirements.txt 2>/dev/null; then
        found=1
    fi

    # 检测 pyproject.toml
    if [[ -f "pyproject.toml" ]] && grep -q "psycopg" pyproject.toml 2>/dev/null; then
        found=1
    fi

    return $found
}

# Redis 检测规则
detect_redis() {
    local found=0

    # 检测 Python 导入
    if grep -r "import redis" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 Redis URL
    if grep -r "redis://" --include="*.py" --include="*.env" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测环境变量
    if grep -r "REDIS_" --include=".env*" --include="*.env" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 requirements.txt
    if [[ -f "requirements.txt" ]] && grep -q "^redis" requirements.txt 2>/dev/null; then
        found=1
    fi

    # 检测 Node.js
    if [[ -f "package.json" ]] && grep -q '"redis"' package.json 2>/dev/null; then
        found=1
    fi

    return $found
}

# MySQL 检测规则
detect_mysql() {
    local found=0

    # 检测 Python 导入
    if grep -r "mysql.connector" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    if grep -r "import pymysql" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 MySQL URL
    if grep -r "mysql://" --include="*.py" --include="*.env" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 SQLAlchemy MySQL
    if grep -r "mysql+pymysql://" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测环境变量
    if grep -r "MYSQL_" --include=".env*" --include="*.env" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 requirements.txt
    if [[ -f "requirements.txt" ]] && grep -qE "mysql|pymysql" requirements.txt 2>/dev/null; then
        found=1
    fi

    return $found
}

# MongoDB 检测规则
detect_mongodb() {
    local found=0

    # 检测 Python 导入
    if grep -r "from pymongo" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    if grep -r "import pymongo" --include="*.py" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 MongoDB URL
    if grep -r "mongodb://" --include="*.py" --include="*.env" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测环境变量
    if grep -r "MONGO_" --include=".env*" --include="*.env" . 2>/dev/null | head -1 | grep -q .; then
        found=1
    fi

    # 检测 requirements.txt
    if [[ -f "requirements.txt" ]] && grep -q "pymongo" requirements.txt 2>/dev/null; then
        found=1
    fi

    # 检测 Node.js
    if [[ -f "package.json" ]] && grep -q '"mongoose"' package.json 2>/dev/null; then
        found=1
    fi

    return $found
}

# ========================================
# 主检测函数
# ========================================

detect_service_needs() {
    local services=()

    # 切换到项目根目录（如果是从 scripts/ 调用）
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/../../.." && pwd)"

    # 保存当前目录
    local original_dir="$(pwd)"

    # 切换到项目根目录进行检测
    cd "$project_root" 2>/dev/null || true

    # 检测各服务
    if detect_postgresql; then
        services+=("postgresql")
    fi

    if detect_redis; then
        services+=("redis")
    fi

    if detect_mysql; then
        services+=("mysql")
    fi

    if detect_mongodb; then
        services+=("mongodb")
    fi

    # 恢复目录
    cd "$original_dir" 2>/dev/null || true

    # 输出结果
    echo "${services[*]}"
}

# ========================================
# 详细检测（带来源信息）
# ========================================

detect_service_needs_verbose() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/../../.." && pwd)"
    local original_dir="$(pwd)"

    cd "$project_root" 2>/dev/null || true

    echo -e "${CYAN}=== 服务需求检测 ===${NC}" >&2
    echo "" >&2

    # PostgreSQL
    echo -e "${YELLOW}PostgreSQL:${NC}" >&2
    if grep -r "import psycopg" --include="*.py" . 2>/dev/null | head -1; then
        echo "  ✓ 检测到 psycopg 导入" >&2
    fi
    if grep -r "postgresql://" --include="*.py" . 2>/dev/null | head -1; then
        echo "  ✓ 检测到 PostgreSQL URL" >&2
    fi

    # Redis
    echo "" >&2
    echo -e "${YELLOW}Redis:${NC}" >&2
    if grep -r "import redis" --include="*.py" . 2>/dev/null | head -1; then
        echo "  ✓ 检测到 redis 导入" >&2
    fi

    # MySQL
    echo "" >&2
    echo -e "${YELLOW}MySQL:${NC}" >&2
    if grep -r "mysql.connector\|pymysql" --include="*.py" . 2>/dev/null | head -1; then
        echo "  ✓ 检测到 MySQL 相关导入" >&2
    fi

    # MongoDB
    echo "" >&2
    echo -e "${YELLOW}MongoDB:${NC}" >&2
    if grep -r "pymongo\|mongoose" --include="*.py" --include="*.js" . 2>/dev/null | head -1; then
        echo "  ✓ 检测到 MongoDB 相关导入" >&2
    fi

    cd "$original_dir" 2>/dev/null || true
}

# ========================================
# 直接执行时
# ========================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --verbose|-v)
            detect_service_needs_verbose
            echo ""
            echo "检测到的服务: $(detect_service_needs)"
            ;;
        *)
            detect_service_needs
            ;;
    esac
fi
