#!/bin/bash
# manage.sh - 服务管理接口
#
# 用法:
#   ./scripts/lib/manage.sh list
#   ./scripts/lib/manage.sh get <service>
#   ./scripts/lib/manage.sh start <service>
#   ./scripts/lib/manage.sh stop <service>
#   ./scripts/lib/manage.sh logs <service>

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
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ========================================
# 服务映射
# ========================================
declare -A SERVICE_SCRIPTS=(
    ["postgresql"]="$SERVICES_DIR/postgres.sh"
    ["postgres"]="$SERVICES_DIR/postgres.sh"
    ["redis"]="$SERVICES_DIR/redis.sh"
    ["mysql"]="$SERVICES_DIR/mysql.sh"
    ["mongodb"]="$SERVICES_DIR/mongodb.sh"
    ["mongo"]="$SERVICES_DIR/mongodb.sh"
)

declare -A CONTAINER_PREFIXES=(
    ["postgresql"]="dev-postgres"
    ["postgres"]="dev-postgres"
    ["redis"]="dev-redis"
    ["mysql"]="dev-mysql"
    ["mongodb"]="dev-mongodb"
    ["mongo"]="dev-mongodb"
)

# ========================================
# 列出所有服务
# ========================================

list_services() {
    echo -e "${CYAN}=== Dev Services ===${NC}"
    echo ""

    local found=0

    # 检查所有开发服务容器
    for prefix in "dev-postgres" "dev-redis" "dev-mysql" "dev-mongodb"; do
        local containers=$(docker ps -a --filter "name=^${prefix}" --format "{{.Names}}\t{{.Status}}\t{{.Ports}}")

        if [[ -n "$containers" ]]; then
            found=1
            echo -e "${BOLD}${prefix}:${NC}"
            echo "$containers" | while read name status ports; do
                local status_icon="🔴"
                if [[ "$status" == *"Up"* ]]; then
                    status_icon="🟢"
                fi
                echo "  $status_icon $name - $status"
                echo "      Ports: $ports"
            done
            echo ""
        fi
    done

    if [[ "$found" -eq 0 ]]; then
        log_info "No dev services found"
        echo ""
        echo "To create a service, run:"
        echo "  ./scripts/services/postgres.sh create"
        echo "  ./scripts/services/redis.sh create"
    fi
}

# ========================================
# 获取服务连接信息
# ========================================

get_connection() {
    local service=$1

    if [[ -z "$service" ]]; then
        log_error "Please specify a service name"
        echo "Usage: $0 get <service>"
        return 1
    fi

    # 规范化服务名
    local normalized_service="$service"
    case "$service" in
        postgres) normalized_service="postgresql" ;;
        mongo) normalized_service="mongodb" ;;
    esac

    # 查找配置文件
    local env_file=""

    # 先尝试精确匹配
    for f in "$DEV_SERVICES_DIR"/*.env; do
        [[ ! -f "$f" ]] && continue
        local basename=$(basename "$f" .env)
        if [[ "$basename" == "dev-$normalized_service" ]] || [[ "$basename" == "$normalized_service" ]]; then
            env_file="$f"
            break
        fi
    done

    # 如果没找到，尝试模糊匹配
    if [[ -z "$env_file" ]]; then
        for f in "$DEV_SERVICES_DIR"/*.env; do
            [[ ! -f "$f" ]] && continue
            if basename "$f" .env | grep -qi "$service"; then
                env_file="$f"
                break
            fi
        done
    fi

    if [[ -z "$env_file" ]]; then
        log_error "No configuration found for service: $service"
        echo ""
        echo "Available services:"
        ls -1 "$DEV_SERVICES_DIR"/*.env 2>/dev/null | xargs -I{} basename {} .env || echo "  (none)"
        return 1
    fi

    echo -e "${CYAN}=== Connection Info: $(basename "$env_file" .env) ===${NC}"
    echo ""
    cat "$env_file"
}

# ========================================
# 启动服务
# ========================================

start_service() {
    local service=$1

    if [[ -z "$service" ]]; then
        log_error "Please specify a service name"
        echo "Usage: $0 start <service>"
        return 1
    fi

    local script="${SERVICE_SCRIPTS[$service]}"
    if [[ -z "$script" ]]; then
        log_error "Unknown service: $service"
        echo "Available services: ${!SERVICE_SCRIPTS[*]}"
        return 1
    fi

    if [[ -f "$script" ]]; then
        "$script" start
    else
        log_error "Service script not found: $script"
        return 1
    fi
}

# ========================================
# 停止服务
# ========================================

stop_service() {
    local service=$1

    if [[ -z "$service" ]]; then
        log_error "Please specify a service name"
        echo "Usage: $0 stop <service>"
        return 1
    fi

    local script="${SERVICE_SCRIPTS[$service]}"
    if [[ -z "$script" ]]; then
        log_error "Unknown service: $service"
        echo "Available services: ${!SERVICE_SCRIPTS[*]}"
        return 1
    fi

    if [[ -f "$script" ]]; then
        "$script" stop
    else
        log_error "Service script not found: $script"
        return 1
    fi
}

# ========================================
# 查看服务日志
# ========================================

logs_service() {
    local service=$1

    if [[ -z "$service" ]]; then
        log_error "Please specify a service name"
        echo "Usage: $0 logs <service>"
        return 1
    fi

    local prefix="${CONTAINER_PREFIXES[$service]}"
    if [[ -z "$prefix" ]]; then
        # 尝试直接使用输入作为容器名前缀
        prefix="dev-$service"
    fi

    # 查找匹配的容器
    local container=$(docker ps -a --filter "name=^${prefix}" --format "{{.Names}}" | head -1)

    if [[ -z "$container" ]]; then
        log_error "No container found for service: $service"
        return 1
    fi

    log_info "Showing logs for: $container"
    docker logs -f --tail 100 "$container"
}

# ========================================
# 停止所有服务
# ========================================

stop_all() {
    log_info "Stopping all dev services..."

    for prefix in "dev-postgres" "dev-redis" "dev-mysql" "dev-mongodb"; do
        local containers=$(docker ps --filter "name=^${prefix}" --format "{{.Names}}")
        for container in $containers; do
            log_info "Stopping $container..."
            docker stop "$container" 2>/dev/null || true
        done
    done

    log_info "✅ All services stopped"
}

# ========================================
# 清理所有服务（删除容器）
# ========================================

cleanup() {
    log_warn "This will remove all dev service containers (data volumes preserved)"
    read -p "Continue? [y/N] " confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Cancelled"
        return 0
    fi

    for prefix in "dev-postgres" "dev-redis" "dev-mysql" "dev-mongodb"; do
        local containers=$(docker ps -a --filter "name=^${prefix}" --format "{{.Names}}")
        for container in $containers; do
            log_info "Removing $container..."
            docker rm -f "$container" 2>/dev/null || true
        done
    done

    log_info "✅ All containers removed"
}

# ========================================
# 主入口
# ========================================

main() {
    local command=${1:-list}
    local service=${2:-}

    # 确保 Docker 可用
    if ! docker info &>/dev/null; then
        log_error "Docker is not running"
        exit 1
    fi

    case "$command" in
        list|ls)
            list_services
            ;;
        get|info)
            get_connection "$service"
            ;;
        start)
            start_service "$service"
            ;;
        stop)
            stop_service "$service"
            ;;
        logs)
            logs_service "$service"
            ;;
        stop-all)
            stop_all
            ;;
        cleanup)
            cleanup
            ;;
        *)
            echo "Usage: $0 {list|get|start|stop|logs|stop-all|cleanup}"
            echo ""
            echo "Commands:"
            echo "  list      List all dev services"
            echo "  get       Get connection info for a service"
            echo "  start     Start a service"
            echo "  stop      Stop a service"
            echo "  logs      View service logs"
            echo "  stop-all  Stop all dev services"
            echo "  cleanup   Remove all containers (keeps data)"
            exit 1
            ;;
    esac
}

main "$@"
