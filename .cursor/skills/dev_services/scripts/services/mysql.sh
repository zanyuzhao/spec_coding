#!/bin/bash
# mysql.sh - MySQL 服务模板
#
# 用法:
#   ./scripts/services/mysql.sh create [name]
#   ./scripts/services/mysql.sh status [name]
#   ./scripts/services/mysql.sh stop [name]

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
CONTAINER_PREFIX="dev-mysql"
DEFAULT_PORT_START=3306
DEFAULT_PORT_END=3399
IMAGE="mysql:8"

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
# 创建 MySQL 服务
# ========================================

create_mysql() {
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
    local root_password=$(generate_password)

    log_info "Creating MySQL service..."
    log_info "  Container: $container_name"
    log_info "  Port: $port"

    # 创建容器
    docker run -d \
        --name "$container_name" \
        -e MYSQL_ROOT_PASSWORD="$root_password" \
        -e MYSQL_USER="$user" \
        -e MYSQL_PASSWORD="$password" \
        -e MYSQL_DATABASE="$db" \
        -p "$port:3306" \
        -v "${container_name}-data:/var/lib/mysql" \
        "$IMAGE"

    # 等待服务启动
    log_info "Waiting for MySQL to start (this may take a minute)..."

    for i in {1..60}; do
        if docker exec "$container_name" mysqladmin ping -h localhost -u root -p"$root_password" &>/dev/null; then
            log_info "MySQL is ready!"
            break
        fi
        sleep 2
    done

    # 创建配置目录
    mkdir -p "$DEV_SERVICES_DIR"

    # 写入配置文件
    local env_file="$DEV_SERVICES_DIR/${name}.env"
    cat > "$env_file" << EOF
# MySQL Dev Service - $(date)
MYSQL_HOST=127.0.0.1
MYSQL_PORT=$port
MYSQL_USER=$user
MYSQL_PASSWORD=$password
MYSQL_DATABASE=$db
MYSQL_ROOT_PASSWORD=$root_password
DATABASE_URL=mysql+pymysql://${user}:${password}@127.0.0.1:${port}/${db}
EOF

    log_info "✅ MySQL service created!"
    echo ""
    echo -e "${CYAN}Connection Info:${NC}"
    echo "  Host:     127.0.0.1"
    echo "  Port:     $port"
    echo "  User:     $user"
    echo "  Password: $password"
    echo "  Database: $db"
    echo ""
    echo -e "${CYAN}Connection URL (PyMySQL):${NC}"
    echo "  mysql+pymysql://${user}:${password}@127.0.0.1:${port}/${db}"
    echo ""
    echo -e "${CYAN}Config file:${NC}"
    echo "  $env_file"
}

# ========================================
# 查看服务状态
# ========================================

status_mysql() {
    local name=$(get_service_name "$1")

    if ! docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
        log_warn "Service $name does not exist"
        return 1
    fi

    echo -e "${CYAN}=== MySQL Service Status ===${NC}"
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

stop_mysql() {
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

start_mysql() {
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

remove_mysql() {
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
            create_mysql "$name"
            ;;
        start)
            start_mysql "$name"
            ;;
        stop)
            stop_mysql "$name"
            ;;
        status)
            status_mysql "$name"
            ;;
        remove|rm)
            remove_mysql "$name"
            ;;
        *)
            echo "Usage: $0 {create|start|stop|status|remove} [name]"
            exit 1
            ;;
    esac
}

main "$@"
