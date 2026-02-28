# 归档自动化设计

## 概述

本文档定义 Spec 和 Harnesses 两种开发模式的**统一归档流程**，实现自动归档以避免活跃目录膨胀。

---

## 归档触发时机

### 自动触发（无需用户明确说「归档」）

| 触发点 | 条件 | 操作 |
|--------|------|------|
| **开启新需求前** | `docs/spec/active/` 或 `docs/harnesses/` 有未归档的已完成需求 | 提示并自动归档 |
| **Push 前** | 检测到已完成的未归档需求 | 执行归档后继续 push |
| **需求开发完毕** | 所有 features 完成 + 用户确认 | 询问归档 |

### 手动触发

| 用户表述 | 操作 |
|----------|------|
| 「归档」「开发完成」「收尾」 | 立即执行归档 |

---

## 归档检测逻辑

```
触发点: 开启新需求 / Push 前 / 用户确认完成
    │
    ├─ 检查 docs/spec/active/
    │   ├─ 有文件？ → 检查状态
    │   │   ├─ status: implementation + 所有任务完成 → 【自动归档】
    │   │   └─ status: proposal → 保留（等待用户确认）
    │   └─ 无文件 → 跳过
    │
    ├─ 检查 docs/harnesses/
    │   ├─ 有 feature_list.json？
    │   │   └─ 所有 passes: true → 【自动归档】
    │   └─ 无文件 → 跳过
    │
    └─ 执行归档
```

---

## Spec 归档流程

### 归档目录结构

```
docs/spec/
├── active/                    # 进行中的需求（归档后清空）
├── archive/                   # 归档目录
│   ├── 2026-02-28_user_auth/  # 按日期+需求名
│   │   ├── spec.md           # 原始 spec
│   │   ├── design.md         # 设计文档（如有）
│   │   └── tasks.md          # 任务列表（如有）
│   └── specs/                 # Source of Truth
       └── auth/
           └── spec.md          # 合并后的系统规格
```

### 归档步骤

```bash
# 1. 检测可归档的 active 项
for dir in docs/spec/active/*/; do
  spec_file="$dir/spec.md"
  if [[ -f "$spec_file" ]]; then
    status=$(grep "^status:" "$spec_file" | cut -d' ' -f2)
    if [[ "$status" == "implementation" ]]; then
      # 检查是否所有任务完成
      if all_tasks_completed "$dir"; then
        archive_spec "$dir"
      fi
    fi
  fi
done

# 2. 归档函数
archive_spec() {
  local spec_dir=$1
  local spec_name=$(basename "$spec_dir")
  local archive_date=$(date +%Y-%m-%d)
  local archive_dir="docs/spec/archive/${archive_date}_${spec_name}"

  # 创建归档目录
  mkdir -p "$archive_dir"

  # 移动文件
  mv "$spec_dir"/* "$archive_dir/"

  # 合并 delta 到 Source of Truth
  merge_to_specs "$archive_dir/spec.md"

  # 删除原目录
  rmdir "$spec_dir"
}
```

---

## Harnesses 归档流程

### 归档目录结构

```
docs/harnesses/
├── scope.md                   # 当前需求范围（归档后移走）
├── feature_list.json          # 功能列表（归档后移走）
├── claude-progress.txt        # 进度文件（归档后移走）
├── *.md                       # 设计文档（归档后移走）
│
├── init.sh                    # 【保留】启动脚本
├── verify_harnesses.sh        # 【保留】验证脚本
├── mcp_setup.md               # 【保留】MCP 配置文档
│
└── archive/                   # 归档目录
    └── 2026-02-28_toolchain/   # 按日期+需求名
        ├── scope.md
        ├── feature_list.json
        ├── claude-progress.txt
        └── dev_services_design.md
```

### 保留文件规则

| 文件 | 是否保留 | 原因 |
|------|----------|------|
| `init.sh` | ✅ 保留 | 持续使用的启动脚本 |
| `verify_harnesses.sh` | ✅ 保留 | 持续使用的验证脚本 |
| `mcp_setup.md` | ✅ 保留 | 持续参考的配置文档 |
| `scope.md` | ❌ 归档 | 需求特定 |
| `feature_list.json` | ❌ 归档 | 需求特定 |
| `claude-progress.txt` | ❌ 归档 | 需求特定 |
| `*_design.md` | ❌ 归档 | 设计文档（实现后归档） |

### 归档步骤

```bash
archive_harnesses() {
  local project_root=$1
  local harnesses_dir="$project_root/docs/harnesses"
  local archive_dir="$harnesses_dir/archive"

  # 从 scope.md 或 feature_list.json 获取需求名
  local requirement_name=$(get_requirement_name "$harnesses_dir")
  local archive_date=$(date +%Y-%m-%d)
  local target_dir="$archive_dir/${archive_date}_${requirement_name}"

  # 创建归档目录
  mkdir -p "$target_dir"

  # 归档需求特定文件
  [[ -f "$harnesses_dir/scope.md" ]] && mv "$harnesses_dir/scope.md" "$target_dir/"
  [[ -f "$harnesses_dir/feature_list.json" ]] && mv "$harnesses_dir/feature_list.json" "$target_dir/"
  [[ -f "$harnesses_dir/claude-progress.txt" ]] && mv "$harnesses_dir/claude-progress.txt" "$target_dir/"

  # 归档设计文档（已实现的功能）
  for design_file in "$harnesses_dir"/*_design.md; do
    if [[ -f "$design_file" ]]; then
      local design_name=$(basename "$design_file")
      # 检查对应功能是否已实现
      if design_implemented "$design_name"; then
        mv "$design_file" "$target_dir/"
      fi
    fi
  done

  echo "✅ Harnesses 归档完成: $target_dir"
}
```

---

## 统一归档脚本

### 脚本位置

```
scripts/
└── archive.sh        # 统一归档脚本
```

### 脚本实现

```bash
#!/bin/bash
# archive.sh - 统一归档脚本
#
# 用法:
#   ./scripts/archive.sh                    # 交互式归档
#   ./scripts/archive.sh --auto             # 自动归档（开启新需求前）
#   ./scripts/archive.sh --spec "auth"       # 归档指定 spec
#   ./scripts/archive.sh --harnesses        # 归档 harnesses
#   ./scripts/archive.sh --check            # 仅检查，不执行

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 颜色输出
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}═══ $1 ═══${NC}"; }

# 检查 Spec 是否可归档
check_spec_archive() {
    local active_dir="$PROJECT_ROOT/docs/spec/active"
    local archive_needed=()

    for dir in "$active_dir"/*/; do
        [[ ! -d "$dir" ]] && continue
        local spec_file="$dir/spec.md"
        [[ ! -f "$spec_file" ]] && continue

        local status=$(grep "^status:" "$spec_file" 2>/dev/null | cut -d' ' -f2)
        if [[ "$status" == "implementation" ]]; then
            archive_needed+=("$(basename "$dir")")
        fi
    done

    echo "${archive_needed[@]}"
}

# 检查 Harnesses 是否可归档
check_harnesses_archive() {
    local harnesses_dir="$PROJECT_ROOT/docs/harnesses"
    local feature_list="$harnesses_dir/feature_list.json"

    if [[ ! -f "$feature_list" ]]; then
        echo ""
        return
    fi

    # 检查是否所有 features 完成
    local completed=$(python3 -c "
import json
data = json.load(open('$feature_list'))
total = len(data['features'])
done = sum(1 for f in data['features'] if f['passes'])
print(f'{done}/{total}')
")

    if [[ "$completed" == */* && ! "$completed" =~ ^0/ ]]; then
        local name=$(python3 -c "
import json
data = json.load(open('$feature_list'))
print(data.get('project', 'unknown'))
")
        echo "$name"
    else
        echo ""
    fi
}

# 归档 Spec
archive_spec() {
    local spec_name=$1
    local active_dir="$PROJECT_ROOT/docs/spec/active"
    local archive_dir="$PROJECT_ROOT/docs/spec/archive"
    local spec_dir="$active_dir/$spec_name"

    [[ ! -d "$spec_dir" ]] && { log_error "Spec not found: $spec_name"; return 1; }

    local archive_date=$(date +%Y-%m-%d)
    local target_dir="$archive_dir/${archive_date}_${spec_name}"

    mkdir -p "$target_dir"
    mv "$spec_dir"/* "$target_dir/" 2>/dev/null || true
    rmdir "$spec_dir" 2>/dev/null || true

    # 合并到 Source of Truth
    merge_spec_to_sot "$target_dir"

    log_info "✅ Spec 归档完成: $target_dir"
}

# 归档 Harnesses
archive_harnesses() {
    local harnesses_dir="$PROJECT_ROOT/docs/harnesses"
    local archive_dir="$harnesses_dir/archive"

    # 获取需求名
    local requirement_name=$(python3 -c "
import json
data = json.load(open('$harnesses_dir/feature_list.json'))
print(data.get('project', 'unknown'))
")

    local archive_date=$(date +%Y-%m-%d)
    local target_dir="$archive_dir/${archive_date}_${requirement_name}"

    mkdir -p "$target_dir"

    # 归档需求特定文件
    [[ -f "$harnesses_dir/scope.md" ]] && mv "$harnesses_dir/scope.md" "$target_dir/"
    [[ -f "$harnesses_dir/feature_list.json" ]] && mv "$harnesses_dir/feature_list.json" "$target_dir/"
    [[ -f "$harnesses_dir/claude-progress.txt" ]] && mv "$harnesses_dir/claude-progress.txt" "$target_dir/"

    # 归档设计文档
    for design in "$harnesses_dir"/*_design.md; do
        [[ -f "$design" ]] && mv "$design" "$target_dir/"
    done

    log_info "✅ Harnesses 归档完成: $target_dir"
}

# 合并 Spec 到 Source of Truth
merge_spec_to_sot() {
    local archive_dir=$1
    local spec_file="$archive_dir/spec.md"

    [[ ! -f "$spec_file" ]] && return

    # 解析 spec 中的领域
    local domain=$(grep "^domain:" "$spec_file" | cut -d' ' -f2)
    [[ -z "$domain" ]] && domain="general"

    local sot_dir="$PROJECT_ROOT/docs/spec/specs/$domain"
    local sot_file="$sot_dir/spec.md"

    mkdir -p "$sot_dir"

    # 如果 SOT 文件存在，合并；否则创建
    if [[ -f "$sot_file" ]]; then
        # 追加 delta
        echo -e "\n\n--- 归档于 $(date +%Y-%m-%d) ---\n" >> "$sot_file"
        cat "$spec_file" >> "$sot_file"
    else
        cp "$spec_file" "$sot_file"
    fi

    log_info "Source of Truth 已更新: $sot_file"
}

# 主流程
main() {
    local mode=${1:-check}
    local target=${2:-}

    case "$mode" in
        --check)
            log_section "检查归档状态"

            # 检查 Spec
            local specs=$(check_spec_archive)
            if [[ -n "$specs" ]]; then
                log_warn "可归档的 Spec: ${specs}"
            else
                log_info "没有可归档的 Spec"
            fi

            # 检查 Harnesses
            local harnesses=$(check_harnesses_archive)
            if [[ -n "$harnesses" ]]; then
                log_warn "可归档的 Harnesses: $harnesses"
            else
                log_info "没有可归档的 Harnesses"
            fi
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
            ;;

        --spec)
            [[ -z "$target" ]] && { log_error "请指定 spec 名称"; exit 1; }
            archive_spec "$target"
            ;;

        --harnesses)
            archive_harnesses
            ;;

        *)
            log_error "未知模式: $mode"
            echo "用法: $0 [--check|--auto|--spec NAME|--harnesses]"
            exit 1
            ;;
    esac
}

main "$@"
```

---

## 与开发流程的集成

### Spec 模式集成点

```markdown
# 在 spec_trigger.md 中添加

## 归档触发检查

在以下时机自动检查并提示归档：

1. **开启新需求时**
   - 检查 `docs/spec/active/` 是否有已完成的未归档项
   - 如有，提示：「检测到已完成的需求 [X]，是否先归档？」

2. **用户说「开发完成」「需求完成」时**
   - 自动执行归档流程

3. **Push 前检查**
   - 执行 `./scripts/archive.sh --check`
   - 如有可归档项，询问是否归档后 push
```

### Harnesses 模式集成点

```markdown
# 在 harnesses_coding_session 中添加

## 归档触发

当所有 features 完成后（passes: true）：

1. **提示归档**: 「所有 features 已完成！是否归档？」
2. **开启新 Harnesses 需求时**:
   - 检查 `docs/harnesses/feature_list.json` 是否所有 passes: true
   - 如是，提示：「检测到已完成的 Harnesses 需求，是否先归档？」
```

---

## .gitignore 更新

```gitignore
# 开发过程文件（归档后移走）
# docs/harnesses/scope.md
# docs/harnesses/feature_list.json
# docs/harnesses/claude-progress.txt
# docs/harnesses/*_design.md

# 保留的开发工具
!docs/harnesses/init.sh
!docs/harnesses/verify_harnesses.sh
!docs/harnesses/mcp_setup.md
!docs/harnesses/archive/
```

---

## 归档确认提示模板

### 开启新需求时

```
🔍 检测到已完成的未归档需求：

| 类型 | 名称 | 完成时间 |
|------|------|----------|
| Spec | user_auth | 2天前 |
| Harnesses | toolchain | 1天前 |

是否先归档这些需求？
[A] 全部归档  [S] 选择归档  [N] 不归档，继续
```

### Push 前

```
⚠️ Push 前检查：检测到未归档的已完成需求

归档后继续 push？
[Y] 是，归档后 push  [N] 否，直接 push
```

### 所有 Features 完成时

```
🎉 所有 features 已完成！

需要归档吗？
[Y] 是，归档  [N] 否，保留在活跃目录
```

---

## 总结

| 维度 | 说明 |
|------|------|
| **自动触发** | 开启新需求前、Push 前、需求完成时 |
| **归档位置** | `docs/spec/archive/` 和 `docs/harnesses/archive/` |
| **保留文件** | 持续使用的工具脚本和参考文档 |
| **归档文件** | 需求特定的 spec、feature_list、progress、design |
| **脚本位置** | `scripts/archive.sh` |

---

## 下一步

1. **实现归档脚本** - 创建 `scripts/archive.sh`
2. **更新规则文件** - 在 `spec_trigger.md` 和 harnesses skill 中集成归档检查
3. **更新 .gitignore** - 忽略活跃目录中的需求特定文件
