#!/bin/bash
# init.sh - 启动 spec_coding 开发环境
# 用法: ./docs/plan_auto/init.sh [--backend-only | --frontend-only | --check]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# 默认启动全部
START_BACKEND=true
START_FRONTEND=true
CHECK_ONLY=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --backend-only)
            START_FRONTEND=false
            shift
            ;;
        --frontend-only)
            START_BACKEND=false
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [--backend-only | --frontend-only | --check]"
            echo ""
            echo "选项:"
            echo "  --backend-only   仅启动后端"
            echo "  --frontend-only  仅启动前端"
            echo "  --check          仅检查服务健康状态"
            echo "  --help, -h       显示帮助"
            echo ""
            echo "环境配置:"
            echo "  首次运行会自动创建 .env 文件："
            echo "  - backend/.env        后端环境变量"
            echo "  - frontend/.env.local 前端环境变量"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 环境配置模板
setup_env_files() {
    # 后端 .env
    if [ ! -f "$BACKEND_DIR/.env" ]; then
        log_info "创建后端 .env 文件..."
        cat > "$BACKEND_DIR/.env" << 'EOF'
# 数据库配置
DATABASE_URL=sqlite:///./spec_coding.db

# JWT 配置
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API 配置
API_PREFIX=/api
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# 环境
ENVIRONMENT=development
EOF
        log_info "已创建 backend/.env（开发环境默认配置）"
    else
        log_info "后端 .env 已存在，跳过创建"
    fi

    # 前端 .env.local
    if [ ! -f "$FRONTEND_DIR/.env.local" ]; then
        log_info "创建前端 .env.local 文件..."
        cat > "$FRONTEND_DIR/.env.local" << 'EOF'
# API 地址
NEXT_PUBLIC_API_URL=http://127.0.0.1:8000

# 环境
NODE_ENV=development
EOF
        log_info "已创建 frontend/.env.local（开发环境默认配置）"
    else
        log_info "前端 .env.local 已存在，跳过创建"
    fi
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # 端口被占用
    else
        return 1  # 端口空闲
    fi
}

# 等待服务启动
wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            log_info "$name 已就绪"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done

    log_error "$name 启动超时"
    return 1
}

# 健康检查模式
if [ "$CHECK_ONLY" = true ]; then
    log_info "检查服务健康状态..."

    BACKEND_HEALTH="http://127.0.0.1:8000/health"
    FRONTEND_HEALTH="http://127.0.0.1:3000"

    if curl -s "$BACKEND_HEALTH" 2>/dev/null | grep -q '"status"'; then
        log_info "后端服务: ${GREEN}健康${NC}"
    else
        log_warn "后端服务: ${RED}未运行${NC}"
    fi

    if curl -s "$FRONTEND_HEALTH" >/dev/null 2>&1; then
        log_info "前端服务: ${GREEN}健康${NC}"
    else
        log_warn "前端服务: ${RED}未运行${NC}"
    fi

    exit 0
fi

# 启动后端
start_backend() {
    log_info "检查后端依赖..."
    cd "$BACKEND_DIR"

    # 检查 uv 是否可用
    if command -v uv &> /dev/null || [ -f "$HOME/.local/bin/uv" ]; then
        export PATH="$HOME/.local/bin:$PATH"

        # 使用 uv 安装依赖（如果需要）
        if [ ! -d ".venv" ]; then
            log_info "使用 uv 安装后端依赖..."
            uv sync --quiet 2>/dev/null || uv pip install -r requirements.txt --quiet 2>/dev/null || true
        fi

        if check_port 8000; then
            log_warn "端口 8000 已被占用，跳过后端启动"
            return 0
        fi

        log_info "启动后端服务 (FastAPI on port 8000)..."
        nohup uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload \
            > /tmp/spec_coding_backend.log 2>&1 &
    else
        # 回退到传统方式
        if [ ! -d ".venv" ]; then
            log_info "安装后端依赖..."
            python3 -m venv .venv
            .venv/bin/pip install -r requirements.txt >/dev/null 2>&1 || true
        fi

        if check_port 8000; then
            log_warn "端口 8000 已被占用，跳过后端启动"
            return 0
        fi

        log_info "启动后端服务 (FastAPI on port 8000)..."
        nohup .venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload \
            > /tmp/spec_coding_backend.log 2>&1 &
    fi

    wait_for_service "http://127.0.0.1:8000/health" "后端"
}

# 启动前端
start_frontend() {
    log_info "检查前端依赖..."
    cd "$FRONTEND_DIR"

    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        npm install >/dev/null 2>&1
    fi

    if check_port 3000; then
        log_warn "端口 3000 已被占用，跳过前端启动"
        return 0
    fi

    log_info "启动前端服务 (Next.js on port 3000)..."
    # 后台启动
    nohup npm run dev > /tmp/spec_coding_frontend.log 2>&1 &

    wait_for_service "http://127.0.0.1:3000" "前端"
}

# 主流程
main() {
    log_info "初始化 spec_coding 开发环境..."
    log_info "项目根目录: $PROJECT_ROOT"

    # 设置环境配置文件
    setup_env_files

    if [ "$START_BACKEND" = true ]; then
        start_backend
    fi

    if [ "$START_FRONTEND" = true ]; then
        start_frontend
    fi

    log_info "============================================"
    log_info "开发环境已启动!"
    log_info "后端 API 文档: http://127.0.0.1:8000/docs"
    log_info "前端应用:      http://127.0.0.1:3000"
    log_info "============================================"
    log_info ""
    log_info "日志文件:"
    log_info "  后端: /tmp/spec_coding_backend.log"
    log_info "  前端: /tmp/spec_coding_frontend.log"
    log_info ""
    log_info "停止服务: pkill -f 'uvicorn app.main' ; pkill -f 'next'"
}

main
