#!/bin/bash
# verify_plan_auto.sh - 验证 Plan-Auto 流程完整性
# 用法: ./docs/plan_auto/verify_plan_auto.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

section() {
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  $1${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
}

# 1. 验证 feature_list.json 结构
section "1. 验证 feature_list.json"

FEATURE_LIST="$PROJECT_ROOT/docs/plan_auto/feature_list.json"
if [ -f "$FEATURE_LIST" ]; then
    pass "feature_list.json 存在"

    # 验证 JSON 语法
    if python3 -c "import json; json.load(open('$FEATURE_LIST'))" 2>/dev/null; then
        pass "feature_list.json JSON 语法正确"
    else
        fail "feature_list.json JSON 语法错误"
    fi

    # 验证必要字段
    if python3 -c "
import json
data = json.load(open('$FEATURE_LIST'))
assert 'project' in data, 'missing project'
assert 'features' in data, 'missing features'
for f in data['features']:
    assert 'id' in f, 'missing id'
    assert 'description' in f, 'missing description'
    assert 'passes' in f, 'missing passes'
print('OK')
" 2>/dev/null; then
        pass "feature_list.json 包含必要字段"
    else
        fail "feature_list.json 缺少必要字段"
    fi

    # 统计完成情况
    COMPLETED=$(python3 -c "
import json
data = json.load(open('$FEATURE_LIST'))
print(sum(1 for f in data['features'] if f['passes']))
")
    TOTAL=$(python3 -c "
import json
data = json.load(open('$FEATURE_LIST'))
print(len(data['features']))
")
    info "Features: $COMPLETED/$TOTAL 已完成"
else
    fail "feature_list.json 不存在"
fi

# 2. 验证 claude-progress.txt
section "2. 验证 claude-progress.txt"

PROGRESS_FILE="$PROJECT_ROOT/docs/plan_auto/claude-progress.txt"
if [ -f "$PROGRESS_FILE" ]; then
    pass "claude-progress.txt 存在"

    # 验证可读写
    if [ -r "$PROGRESS_FILE" ] && [ -w "$PROGRESS_FILE" ]; then
        pass "claude-progress.txt 可读写"
    else
        fail "claude-progress.txt 权限不足"
    fi

    # 验证内容格式
    if grep -q "Feature 总览" "$PROGRESS_FILE" && grep -q "进度历史" "$PROGRESS_FILE"; then
        pass "claude-progress.txt 包含必要章节"
    else
        fail "claude-progress.txt 缺少必要章节"
    fi
else
    fail "claude-progress.txt 不存在"
fi

# 3. 验证 init.sh
section "3. 验证 init.sh"

INIT_SCRIPT="$PROJECT_ROOT/docs/plan_auto/init.sh"
if [ -f "$INIT_SCRIPT" ]; then
    pass "init.sh 存在"

    # 验证可执行
    if [ -x "$INIT_SCRIPT" ]; then
        pass "init.sh 可执行"
    else
        fail "init.sh 不可执行"
    fi

    # 验证语法
    if bash -n "$INIT_SCRIPT" 2>/dev/null; then
        pass "init.sh 语法正确"
    else
        fail "init.sh 语法错误"
    fi

    # 验证帮助功能
    if "$INIT_SCRIPT" --help >/dev/null 2>&1; then
        pass "init.sh --help 正常工作"
    else
        fail "init.sh --help 失败"
    fi

    # 验证健康检查
    if "$INIT_SCRIPT" --check >/dev/null 2>&1; then
        pass "init.sh --check 正常工作"
    else
        fail "init.sh --check 失败"
    fi
else
    fail "init.sh 不存在"
fi

# 4. 验证 MCP 配置
section "4. 验证 MCP 配置"

MCP_CONFIG="$PROJECT_ROOT/.cursor/mcp.json"
if [ -f "$MCP_CONFIG" ]; then
    pass "mcp.json 存在"

    # 验证 JSON 语法
    if python3 -c "import json; json.load(open('$MCP_CONFIG'))" 2>/dev/null; then
        pass "mcp.json JSON 语法正确"
    else
        fail "mcp.json JSON 语法错误"
    fi

    # 验证 MCP 服务器配置
    if python3 -c "
import json
data = json.load(open('$MCP_CONFIG'))
assert 'mcpServers' in data, 'missing mcpServers'
servers = data['mcpServers']
print(f'已配置 {len(servers)} 个 MCP 服务器: ' + ', '.join(servers.keys()))
" 2>/dev/null; then
        pass "MCP 服务器配置正确"
    else
        fail "MCP 服务器配置错误"
    fi
else
    fail "mcp.json 不存在"
fi

# 5. 验证 Skills
section "5. 验证 Skills"

SKILLS_DIR="$PROJECT_ROOT/.claude/skills"
REQUIRED_SKILLS=("curl_test" "git_operations")

for skill in "${REQUIRED_SKILLS[@]}"; do
    SKILL_FILE="$SKILLS_DIR/$skill/SKILL.md"
    if [ -f "$SKILL_FILE" ]; then
        pass "Skill $skill 存在"

        # 验证 SKILL.md 格式
        if grep -q "^name:" "$SKILL_FILE" && grep -q "^description:" "$SKILL_FILE"; then
            pass "Skill $skill 格式正确"
        else
            fail "Skill $skill 格式错误（缺少 name 或 description）"
        fi
    else
        fail "Skill $skill 不存在"
    fi
done

# 6. 验证后端可启动
section "6. 验证后端服务"

cd "$PROJECT_ROOT/backend"

# 检查 uv 是否可用
if command -v uv &> /dev/null || [ -f "$HOME/.local/bin/uv" ]; then
    export PATH="$HOME/.local/bin:$PATH"

    # 检查依赖是否安装
    if [ -d ".venv" ]; then
        pass "后端虚拟环境存在"
    else
        info "正在创建后端虚拟环境..."
        uv sync --quiet 2>/dev/null || true
        if [ -d ".venv" ]; then
            pass "后端虚拟环境创建成功"
        else
            fail "后端虚拟环境创建失败"
        fi
    fi

    # 测试后端启动
    info "测试后端启动（5秒超时）..."
    timeout 5 uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 &
    BACKEND_PID=$!
    sleep 3

    if curl -s http://127.0.0.1:8000/health | grep -q '"status"'; then
        pass "后端健康检查通过"
    else
        fail "后端健康检查失败"
    fi

    kill $BACKEND_PID 2>/dev/null || true
else
    fail "uv 未安装"
fi

# 总结
section "验证结果"

echo ""
echo -e "${GREEN}通过: $PASS_COUNT${NC}"
echo -e "${RED}失败: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 所有验证通过！Plan-Auto 流程已就绪。${NC}"
    exit 0
else
    echo -e "${RED}⚠️  有 $FAIL_COUNT 项验证失败，请检查。${NC}"
    exit 1
fi
