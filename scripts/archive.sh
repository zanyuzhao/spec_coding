#!/bin/bash
# archive.sh - 统一归档脚本
#
# 用法:
#   ./scripts/archive.sh --check          # 检查可归档项
#   ./scripts/archive.sh --status           # 显示当前状态
#   ./scripts/archive.sh --auto            # 自动归档所有
#   ./scripts/archive.sh --spec <name>    # 归档指定 Spec
#   ./scripts/archive.sh --harnesses       # 归档 Harnesses
#   ./scripts/archive.sh --all             # 归档所有

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ========================================
# 颜色和输出
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}════════════════════════════════════${NC}\n"; }

# ========================================
# 配置
# ========================================
SPEC_ACTIVE_DIR="$PROJECT_ROOT/docs/spec/active"
SPEC_ARCHIVE_DIR="$PROJECT_ROOT/docs/spec/archive"
SPEC_SOT_DIR="$PROJECT_ROOT/docs/spec/specs"
HARNESSES_DIR="$PROJECT_ROOT/docs/harnesses"
HARNESSES_ARCHIVE_DIR="$PROJECT_ROOT/docs/harnesses/archive"

# ========================================
# Spec 归档逻辑
# ========================================

# 检查 Spec 是否可归档
check_spec_archive() {
    local candidates=()

    if [[ ! -d "$SPEC_ACTIVE_DIR" ]]; then
        echo "$candidates"
        return
    fi

    for dir in "$SPEC_ACTIVE_DIR"/*/; do
        [[ ! -d "$dir" ]] && continue
        local spec_file="$dir/spec.md"
        [[ ! -f "$spec_file" ]] && continue

        # 检查状态
        local status=$(grep "^status:" "$spec_file" 2>/dev/null | head -1 | awk '{print $2}')

        if [[ "$status" == "implementation" ]]; then
            # 检查是否所有任务完成（简单检查）
            local has_pending=$(grep -c "^\s*-\s*\[.\*\]" "$spec_file" 2>/dev/null || grep -c "\[pending\]" "$spec_file" 2>/dev/null)
            if [[ -z "$has_pending" ]]; then
                local name=$(basename "$dir")
                candidates="$candidates $name"
            fi
        fi
    done

    echo "$candidates"
}

# 归档单个 Spec
archive_spec() {
    local spec_name=$1
    local spec_dir="$SPEC_ACTIVE_DIR/$spec_name"
    local archive_date=$(date +%Y-%m-%d)
    local target_dir="$SPEC_ARCHIVE_DIR/${archive_date}_${spec_name}"

    if [[ ! -d "$spec_dir" ]]; then
        log_error "Spec not found: $spec_name"
        return 1
    fi

    log_info "归档 Spec: $spec_name"

    # 创建归档目录
    mkdir -p "$target_dir"

    # 移动所有文件
    mv "$spec_dir"/* "$target_dir/" 2>/dev/null || true

    # 删除原目录
    rmdir "$spec_dir" 2>/dev/null || true

    # 合并到 Source of Truth
    merge_spec_to_sot "$target_dir/spec.md"

    log_info "✅ Spec 归档完成: $target_dir"
}

# 合并 Spec 到 Source of Truth
merge_spec_to_sot() {
    local archive_spec_file=$1
    [[ ! -f "$archive_spec_file" ]] && return

    # 解析领域
    local domain=$(grep "^domain:" "$archive_spec_file" 2>/dev/null | head -1 | awk '{print $2}')
    [[ -z "$domain" ]] && domain="general"

    local sot_dir="$SPEC_SOT_DIR/$domain"
    local sot_file="$sot_dir/spec.md"

    mkdir -p "$sot_dir"

    if [[ -f "$sot_file" ]]; then
        # 追加内容
        echo -e "\n\n--- 归档于 $(date +%Y-%m-%d) ---\n" >> "$sot_file"
        echo "---" >> "$sot_file"
        grep -v "^status:" "$archive_spec_file" >> "$sot_file"
    else
        # 创建新文件
        cp "$archive_spec_file" "$sot_file"
    fi

    log_info "Source of Truth 已更新: $sot_file"
}

# ========================================
# Harnesses 归档逻辑
# ========================================

# 检查 Harnesses 是否可归档
check_harnesses_archive() {
    local feature_list="$HARNESSES_DIR/feature_list.json"

    if [[ ! -f "$feature_list" ]]; then
        echo ""
        return
    fi

    # 检查是否所有 features 完成
    local total=$(python3 -c "import json; data=json.load(open('$feature_list')); print(len(data.get('features', []))" 2>/dev/null)
    local completed=$(python3 -c "import json; data=json.load(open('$feature_list')); print(sum(1 for f in data.get('features', []) if f.get('passes', False))" 2>/dev/null)

    if [[ "$completed" == "$total" ]] then
        # 获取项目名
        local name=$(python3 -c "import json; data=json.load(open('$feature_list')); print(data.get('project', 'unknown'))" 2>/dev/null)
        echo "$name"
    else
        echo ""
    fi
}

# 归档 Harnesses
archive_harnesses() {
    local archive_date=$(date +%Y-%m-%d)

    # 获取项目名
    local project_name=$(python3 -c "
import json
data = json.load(open('$HARNESSES_DIR/feature_list.json'))
print(data.get('project', 'unknown'))
" 2>/dev/null)

    local target_dir="$HARNESSES_ARCHIVE_DIR/${archive_date}_${project_name}"

    log_info "归档 Harnesses: $project_name"

    # 创建归档目录
    mkdir -p "$target_dir"

    # 归档需求特定文件
    local files_to_archive=("scope.md" "feature_list.json" "claude-progress.txt")

    for file in "${files_to_archive[@]}"; do
        local src="$HARNESSES_DIR/$file"
        if [[ -f "$src" ]]; then
            mv "$src" "$target_dir/"
            log_info "  归档: $file"
        fi
    done

    # 归档所有 *_feature_list.json
    for fl_file in "$HARNESSES_DIR"/*_feature_list.json; do
        if [[ -f "$fl_file" ]]; then
            mv "$fl_file" "$target_dir/"
            log_info "  归档: $(basename "$fl_file")"
        fi
    done

    # 归档所有 *_progress.txt
    for progress_file in "$HARNESSES_DIR"/*_progress.txt; do
        if [[ -f "$progress_file" ]]; then
            mv "$progress_file" "$target_dir/"
            log_info "  归档: $(basename "$progress_file")"
        fi
    done

    # 归档设计文档
    for design_file in "$HARNESSES_DIR"/*_design.md; do
        if [[ -f "$design_file" ]]; then
            mv "$design_file" "$target_dir/"
            log_info "  归档: $(basename "$design_file")"
        fi
    done

    # 归档设计文档（*.md 文件，除了保留的）
    for md_file in "$HARNESSES_DIR"/*.md; do
        if [[ -f "$md_file" ]]; then
            local filename=$(basename "$md_file")
            # 保留 mcp_setup.md
            if [[ "$filename" == "mcp_setup.md" ]]; then
                continue
            fi
            mv "$md_file" "$target_dir/"
            log_info "  归档: $filename"
        fi
    done

    log_info "✅ Harnesses 归档完成: $target_dir"
}

# ========================================
# 显示状态
# ========================================
show_status() {
    log_section "归档状态"

    # Spec 状态
    local specs=$(check_spec_archive)
    if [[ -n "$specs" ]]; then
        echo -e "${YELLOW}可归档的 Spec:${specs}${NC}"
    else
        echo -e "${GREEN}没有可归档的 Spec${NC}"
    fi

    # Harnesses 状态
    local harnesses=$(check_harnesses_archive)
    if [[ -n "$harnesses" ]]; then
        echo -e "${YELLOW}可归档的 Harnesses: ${harnesses}${NC}"
    else
        echo -e "${GREEN}没有可归档的 Harnesses${NC}"
    fi

    # 显示归档目录
    echo ""
    echo -e "${CYAN}归档目录:${NC}"
    echo "  Spec:       $SPEC_ARCHIVE_DIR"
    echo "  Harnesses: $HARNESSES_ARCHIVE_DIR"
}

# ========================================
# 主流程
# ========================================
main() {
    local mode=${1:---check}
    local target=${2:-}

    # 确保目录存在
    mkdir -p "$SPEC_ARCHIVE_DIR" "$HARNESSES_ARCHIVE_DIR"

    case "$mode" in
        --check)
            show_status
            ;;

        --status)
            show_status
            ;;

        --auto)
            log_section "自动归档"

            # 归档 Spec
            for spec in $(check_spec_archive); do
                [[ -n "$spec" ]] && archive_spec "$spec"
            done

            # 归档 Harnesses
            local harnesses=$(check_harnesses_archive)
            [[ -n "$harnesses" ]] && archive_harnesses

            log_info "自动归档完成"
            ;;

        --spec)
            if [[ -z "$target" ]]; then
                log_error "请指定 Spec 名称"
                echo "用法: $0 --spec <name>"
                exit 1
            fi
            archive_spec "$target"
            ;;

        --harnesses)
            archive_harnesses
            ;;

        --all)
            log_section "归档所有"

            # 归档所有 Spec
            for spec in $(check_spec_archive); do
                [[ -n "$spec" ]] && archive_spec "$spec"
            done

            # 归档 Harnesses
            archive_harnesses

            log_info "所有归档完成"
            ;;

        --help|-h)
            echo "Archive.sh - 统一归档脚本"
            echo ""
            echo "用法:"
            echo "  $0 --check          检查可归档项"
            echo "  $0 --status         显示当前状态"
            echo "  $0 --auto           自动归档所有"
            echo "  $0 --spec <name>    归档指定 Spec"
            echo "  $0 --harnesses       归档 Harnesses"
            echo "  $0 --all             归档所有"
            echo ""
            echo "归档目录:"
            echo "  Spec:       docs/spec/archive/"
            echo "  Harnesses: docs/harnesses/archive/"
            ;;

        *)
            log_error "未知模式: $mode"
            echo "用法: $0 [--check|--status|--auto|--spec|--harnesses|--all|--help]"
            exit 1
            ;;
    esac
}

main "$@"
