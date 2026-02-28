#!/bin/bash
# mongodb.sh - MongoDB 服务模板
#
# 用法:
#   ./scripts/services/mongodb.sh create [name]
#   ./scripts/services/mongodb.sh status [name]
#   ./scripts/services/mongodb.sh stop [name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
DEV_SERVICES_DIR="$PROJECT_ROOT/.dev-services"

# ========================================
# 颜色和输出
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ========================================
# 配置
# ========================================
CONTAINER_PREFIX="dev-mongodb"
DEFAULT_PORT_START=27017
DEFAULT_PORT_END=27099
IMAGE="mongo:7"

# ========================================
# 工具函数
# ========================================

get_available_port() {
    local start=$1
    local end=$2

    for port in $(seq $start $end); do
        if ! docker ps --format '{{.Ports}}' 2>/dev/null | grep -q ":$port->"; then
            echo $port
            return 0
        fi
    done

    log_error "No available port in range $start-$end"
    return 1
}

generate_password() {
    openssl rand -base64 24 | tr -d '/+=' | head -c 24
}

check_docker() {
    if ! docker info &>/dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

get_service_name() {
    local provided_name="${1:-}"
    if [[ -n "$provided_name" ]]; then
        echo "$CONTAINER_PREFIX-$provided_name"
    else
        echo "$CONTAINER_PREFIX"
    fi
}

# ========================================
# 创建 MongoDB 服务
# ========================================

create_mongodb() {
    local name=$(get_service_name "$1")
    local container_name="${name}"

    check_docker

    # 检查是否已存在
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_warn "Container $container_name already exists"

        if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            log_info "Starting existing container..."
            docker start "$container_name"
        fi

        if [[ -f "$DEV_SERVICES_DIR/${name}.env" ]]; then
            log_info "Service configuration:"
            cat "$DEV_SERVICES_DIR/${name}.env"
        fi
        return 0
    fi

    # 分配端口
    local port=$(get_available_port $DEFAULT_PORT_START $DEFAULT_PORT_END)

    # 生成密码
    local password=$(generate_password)
    local user="devuser"
    local db="devdb"

    log_info "Creating MongoDB service..."
    log_info "  Container: $container_name"
    log_info "  Port: $port"

    # 创建容器
    docker run -d \
        --name "$container_name" \
        -e MONGO_INITDB_ROOT_USERNAME="$user" \
        -e MONGO_INITDB_ROOT_PASSWORD="$password" \
        -e MONGO_INITDB_DATABASE="$db" \
        -p "$port:27017" \
        -v "${container_name}-data:/data/db" \
        "$IMAGE"

    # 等待服务启动
    log_info "Waiting for MongoDB to start..."
    sleep 3

    # 检查健康状态
    for i in {1..30}; do
        if docker exec "$container_name" mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
            log_info "MongoDB is ready!"
            break
        fi
        sleep 1
    done

    # 创建配置目录
    mkdir -p "$DEV_SERVICES_DIR"

    # 写入配置文件
    local env_file="$DEV_SERVICES_DIR/${name}.env"
    cat > "$env_file" << EOF
# MongoDB Dev Service - $(date)
MONGO_HOST=127.0.0.1
MONGO_PORT=$port
MONGO_USER=$user
MONGO_PASSWORD=$password
MONGO_DATABASE=$db
MONGO_URL=mongodb://${user}:${password}@127.0.0.1:${port}/${db}?authSource=admin
EOF

    log_info "✅ MongoDB service created!"
    echo ""
    echo -e "${CYAN}Connection Info:${NC}"
    echo "  Host:     127.0.0.1"
    echo "  Port:     $port"
    echo "  User:     $user"
    echo "  Password: $password"
    echo "  Database: $db"
    echo ""
    echo -e "${CYAN}Connection URL:${NC}"
    echo "  mongodb://${user}:${password}@127.0.0.1:${port}/${db}?authSource=admin"
    echo ""
    echo -e "${CYAN}Config file:${NC}"
    echo "  $env_file"
}

# ========================================
# 查看服务状态
# ========================================

status_mongodb() {
    local name=$(get_service_name "$1")

    if ! docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
        log_warn "Service $name does not exist"
        return 1
    fi

    echo -e "${CYAN}=== MongoDB Service Status ===${NC}"
    docker ps -a --filter "name=^${name}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    if [[ -f "$DEV_SERVICES_DIR/${name}.env" ]]; then
        echo ""
        echo -e "${CYAN}Configuration:${NC}"
        cat "$DEV_SERVICES_DIR/${name}.env"
    fi
}

# ========================================
# 停止服务
# ========================================

stop_mongodb() {
    local name=$(get_service_name "$1")

    if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
        log_info "Stopping $name..."
        docker stop "$name"
        log_info "✅ Service stopped"
    else
        log_warn "Service $name is not running"
    fi
}

# ========================================
# 启动服务
# ========================================

start_mongodb() {
    local name=$(get_service_name "$1")

    if docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
        log_info "Starting $name..."
        docker start "$name"
        log_info "✅ Service started"
    else
        log_error "Service $name does not exist. Use 'create' first."
        return 1
    fi
}

# ========================================
# 删除服务
# ========================================

remove_mongodb() {
    local name=$(get_service_name "$1")

    if docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
        log_info "Removing $name..."
        docker rm -f "$name"
        log_info "✅ Container removed (data volume preserved)"
    else
        log_warn "Service $name does not exist"
    fi
}

# ========================================
# 主入口
# ========================================

main() {
    local command=${1:-create}
    local name=${2:-}

    case "$command" in
        create)
            create_mongodb "$name"
            ;;
        start)
            start_mongodb "$name"
            ;;
        stop)
            stop_mongodb "$name"
            ;;
        status)
            status_mongodb "$name"
            ;;
        remove|rm)
            remove_mongodb "$name"
            ;;
        *)
            echo "Usage: $0 {create|start|stop|status|remove} [name]"
            exit 1
            ;;
    esac
}

main "$@"
