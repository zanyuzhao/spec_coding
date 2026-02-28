#!/bin/bash
# resolve.sh - 智能决策逻辑
#
# 用法:
#   ./scripts/lib/resolve.sh <service>
#   ./scripts/lib/resolve.sh postgresql
#
# 输出决策结果和建议

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
DEV_SERVICES_DIR="$PROJECT_ROOT/.dev-services"
SERVICES_DIR="$SCRIPT_DIR/../services"

# ========================================
# 颜色和输出
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ========================================
# 服务配置
# ========================================
declare -A CONTAINER_PREFIXES=(
    ["postgresql"]="dev-postgres"
    ["postgres"]="dev-postgres"
    ["redis"]="dev-redis"
    ["mysql"]="dev-mysql"
    ["mongodb"]="dev-mongodb"
    ["mongo"]="dev-mongodb"
)

declare -A SERVICE_SCRIPTS=(
    ["postgresql"]="$SERVICES_DIR/postgres.sh"
    ["postgres"]="$SERVICES_DIR/postgres.sh"
    ["redis"]="$SERVICES_DIR/redis.sh"
    ["mysql"]="$SERVICES_DIR/mysql.sh"
    ["mongodb"]="$SERVICES_DIR/mongodb.sh"
    ["mongo"]="$SERVICES_DIR/mongodb.sh"
)

# ========================================
# 检查服务是否存在
# ========================================

check_service_exists() {
    local service=$1
    local prefix="${CONTAINER_PREFIXES[$service]}"

    if [[ -z "$prefix" ]]; then
        return 1
    fi

    # 检查运行中的容器
    if docker ps --filter "name=^${prefix}" --format "{{.Names}}" | head -1 | grep -q .; then
        return 0
    fi

    # 检查已停止的容器
    if docker ps -a --filter "name=^${prefix}" --format "{{.Names}}" | head -1 | grep -q .; then
        return 0
    fi

    return 1
}

# ========================================
# 检查服务是否运行
# ========================================

check_service_running() {
    local service=$1
    local prefix="${CONTAINER_PREFIXES[$service]}"

    if docker ps --filter "name=^${prefix}" --format "{{.Names}}" | head -1 | grep -q .; then
        return 0
    fi

    return 1
}

# ========================================
# 获取现有服务信息
# ========================================

get_existing_services() {
    local service=$1
    local prefix="${CONTAINER_PREFIXES[$service]}"

    docker ps -a --filter "name=^${prefix}" --format "{{.Names}}\t{{.Status}}"
}

# ========================================
# 决策逻辑
# ========================================

resolve_service() {
    local service=$1

    # 规范化服务名
    local normalized_service="$service"
    case "$service" in
        postgres) normalized_service="postgresql" ;;
        mongo) normalized_service="mongodb" ;;
    esac

    echo -e "${CYAN}=== 智能决策: $normalized_service ===${NC}"
    echo ""

    # 检查服务脚本是否存在
    local script="${SERVICE_SCRIPTS[$normalized_service]}"
    if [[ -z "$script" ]] || [[ ! -f "$script" ]]; then
        echo -e "${RED}✗ 不支持的服务类型: $service${NC}"
        echo ""
        echo "支持的服务: postgresql, redis, mysql, mongodb"
        return 1
    fi

    # 决策树
    echo -e "${BOLD}决策流程:${NC}"
    echo ""

    # 1. 检查是否有运行中的服务
    if check_service_running "$normalized_service"; then
        echo -e "1. ${GREEN}✓${NC} 检测到运行中的服务"

        local containers=$(docker ps --filter "name=^${CONTAINER_PREFIXES[$normalized_service]}" --format "{{.Names}}")
        echo ""
        echo -e "${GREEN}>>> 决策: 复用现有服务${NC}"
        echo ""
        echo "运行中的容器:"
        for container in $containers; do
            local status=$(docker inspect --format '{{.State.Status}}' "$container")
            local ports=$(docker port "$container" 2>/dev/null | head -1)
            echo "  🟢 $container ($status)"
            echo "      $ports"
        done

        echo ""
        echo -e "${BOLD}建议操作:${NC}"
        echo "  直接使用现有服务，无需创建新实例"
        echo ""
        echo "查看连接信息:"
        echo "  $script status"

        return 0
    fi

    # 2. 检查是否有已停止的服务
    if check_service_exists "$normalized_service"; then
        echo -e "1. ${YELLOW}!${NC} 检测到已停止的服务"
        echo -e "2. ${GREEN}✓${NC} 可以启动现有服务"

        local containers=$(docker ps -a --filter "name=^${CONTAINER_PREFIXES[$normalized_service]}" --format "{{.Names}}")
        echo ""
        echo -e "${YELLOW}>>> 决策: 启动现有服务${NC}"
        echo ""
        echo "已停止的容器:"
        for container in $containers; do
            local status=$(docker inspect --format '{{.State.Status}}' "$container")
            echo "  🔴 $container ($status)"
        done

        echo ""
        echo -e "${BOLD}建议操作:${NC}"
        echo "  启动现有服务:"
        echo "  $script start"

        return 0
    fi

    # 3. 没有现有服务，需要创建
    echo -e "1. ${YELLOW}○${NC} 没有检测到现有服务"
    echo ""
    echo -e "${CYAN}>>> 决策: 创建新服务${NC}"
    echo ""
    echo -e "${BOLD}建议操作:${NC}"
    echo "  创建新的 $normalized_service 服务:"
    echo "  $script create"
    echo ""
    echo "创建后将自动:"
    echo "  - 分配随机端口"
    echo "  - 生成随机密码"
    echo "  - 写入配置到 .dev-services/"
}

# ========================================
# 自动执行决策
# ========================================

auto_resolve() {
    local service=$1

    # 规范化服务名
    local normalized_service="$service"
    case "$service" in
        postgres) normalized_service="postgresql" ;;
        mongo) normalized_service="mongodb" ;;
    esac

    local script="${SERVICE_SCRIPTS[$normalized_service]}"
    if [[ -z "$script" ]] || [[ ! -f "$script" ]]; then
        echo "不支持的服务类型: $service"
        return 1
    fi

    # 如果运行中，返回成功
    if check_service_running "$normalized_service"; then
        log_info "服务已在运行中"
        return 0
    fi

    # 如果存在但停止，启动它
    if check_service_exists "$normalized_service"; then
        log_info "启动现有服务..."
        "$script" start
        return $?
    fi

    # 创建新服务
    log_info "创建新服务..."
    "$script" create
    return $?
}

# ========================================
# 主入口
# ========================================

main() {
    local service=${1:-}
    local auto=${2:-}

    if [[ -z "$service" ]]; then
        echo "用法: $0 <service> [--auto]"
        echo ""
        echo "服务类型: postgresql, redis, mysql, mongodb"
        echo ""
        echo "选项:"
        echo "  --auto   自动执行决策（启动或创建）"
        exit 1
    fi

    # 确保 Docker 可用
    if ! docker info &>/dev/null; then
        echo -e "${RED}[ERROR] Docker is not running${NC}"
        exit 1
    fi

    if [[ "$auto" == "--auto" ]]; then
        auto_resolve "$service"
    else
        resolve_service "$service"
    fi
}

main "$@"
