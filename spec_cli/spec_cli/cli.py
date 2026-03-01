"""CLI entry and init logic."""

import argparse
import json
import os
import shutil
import sys
from pathlib import Path

# 框架版本号，每次发布更新时递增
VERSION = "0.2.0"
VERSION_FILE = ".spec-coding-version"


def _get_version() -> str:
    """获取当前框架版本。"""
    return VERSION


def _read_installed_version(target_root: Path) -> str | None:
    """读取目标项目已安装的版本，返回 None 表示未安装。"""
    version_file = target_root / VERSION_FILE
    if version_file.is_file():
        try:
            data = json.loads(version_file.read_text(encoding="utf-8"))
            return data.get("version")
        except (json.JSONDecodeError, KeyError):
            return "0.0.0"  # 旧版本格式，视为需要更新
    return None


def _write_version(target_root: Path, version: str) -> None:
    """写入版本标记文件。"""
    version_file = target_root / VERSION_FILE
    data = {
        "version": version,
        "backend_dir": None,  # 可扩展：记录安装时的配置
        "frontend_dir": None,
        "app_package": None,
    }
    version_file.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def _templates_dir() -> Path:
    return Path(__file__).resolve().parent / "templates"


def _substitute(content: str, backend_dir: str, frontend_dir: str, app_package: str) -> str:
    return (
        content.replace("{{BACKEND_DIR}}", backend_dir)
        .replace("{{FRONTEND_DIR}}", frontend_dir)
        .replace("{{APP_PACKAGE}}", app_package)
    )


def _copy_templates(
    target_root: Path,
    backend_dir: str,
    frontend_dir: str,
    app_package: str,
    docs_only: bool,
    skip_skills: bool,
    is_update: bool,
) -> None:
    templates = _templates_dir()

    def _templates_need_build() -> bool:
        if not templates.is_dir():
            return True
        if not (templates / "cursor" / "rules").is_dir():
            return True
        if not (templates / "docs" / "spec").is_dir():
            return True
        if not (templates / "claude" / "rules").is_dir() and not (templates / "CLAUDE.md").is_file():
            return True
        return False

    if _templates_need_build():
        try:
            import spec_cli.build_templates
            spec_cli.build_templates.build()
        except Exception as e:
            if _templates_need_build():
                print(f"自动生成模板失败: {e}", file=sys.stderr)
        if _templates_need_build():
            print(f"错误：模板目录不存在或为空: {templates}", file=sys.stderr)
            print("请在 spec_coding 仓库根执行 pip install -e . 以生成模板。", file=sys.stderr)
            sys.exit(1)

    def write_file(dest: Path, content: str) -> None:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(content, encoding="utf-8")

    def copy_tree(
        src: Path,
        dest: Path,
        substitute_text: bool = True,
    ) -> None:
        for item in src.rglob("*"):
            rel = item.relative_to(src)
            dest_file = dest / rel
            if item.is_dir():
                dest_file.mkdir(parents=True, exist_ok=True)
                continue
            content = item.read_text(encoding="utf-8")
            if substitute_text:
                content = _substitute(content, backend_dir, frontend_dir, app_package)
            write_file(dest_file, content)

    # docs/spec + docs/spec_process（仅首次安装或强制模式时写入）
    if not is_update:
        for name in ("docs",):
            src = templates / name
            if src.is_dir():
                copy_tree(src, target_root / name, substitute_text=False)

    # .claude/rules（始终更新）
    claude_rules_src = templates / "claude" / "rules"
    if claude_rules_src.is_dir():
        claude_dest = target_root / ".claude" / "rules"
        copy_tree(claude_rules_src, claude_dest, substitute_text=True)

    # .claude/skills（始终更新，除非 docs_only）
    if not docs_only:
        claude_skills_src = templates / "claude" / "skills"
        if claude_skills_src.is_dir():
            claude_skills_dest = target_root / ".claude" / "skills"
            copy_tree(claude_skills_src, claude_skills_dest, substitute_text=True)

    # CLAUDE.md（始终更新）
    claude_md_src = templates / "CLAUDE.md"
    if claude_md_src.is_file():
        content = claude_md_src.read_text(encoding="utf-8")
        content = _substitute(content, backend_dir, frontend_dir, app_package)
        write_file(target_root / "CLAUDE.md", content)

    if docs_only:
        return

    # .cursor/rules（始终更新）
    cursor_rules_src = templates / "cursor" / "rules"
    if cursor_rules_src.is_dir():
        cursor_dest = target_root / ".cursor" / "rules"
        copy_tree(cursor_rules_src, cursor_dest, substitute_text=True)

    # .cursor/skills（始终更新）
    if not skip_skills:
        cursor_skills_src = templates / "cursor" / "skills"
        if cursor_skills_src.is_dir():
            cursor_dest = target_root / ".cursor" / "skills"
            copy_tree(cursor_skills_src, cursor_dest, substitute_text=True)

    # .cursor/mcp.json（始终更新，框架保证向后兼容）
    mcp_src = templates / "cursor" / "mcp.json"
    if mcp_src.is_file():
        content = mcp_src.read_text(encoding="utf-8")
        mcp_dest = target_root / ".cursor" / "mcp.json"
        write_file(mcp_dest, content)

    # 写入/更新版本文件
    _write_version(target_root, _get_version())

    # init 成功后删除模板目录，保证代码中只保留仓库根一套流程；下次 init 会再按需生成
    try:
        import spec_cli.build_templates as bt
        bt.cleanup_templates()
    except Exception:
        pass


def _cmd_init(args: argparse.Namespace) -> None:
    target = Path(args.target).resolve()
    if not target.is_dir():
        print(f"错误：目标不是目录或不存在: {target}", file=sys.stderr)
        sys.exit(1)

    # 检测是否已初始化
    installed_version = _read_installed_version(target)
    has_docs = (target / "docs" / "spec").is_dir() or (target / "docs" / "spec_process").is_dir()
    is_update = installed_version is not None or has_docs

    if is_update and not args.force:
        print(f"检测到已安装版本: {installed_version or '未知（旧版本）'}")
        print(f"当前框架版本: {_get_version()}")
        print()
        if installed_version == _get_version():
            print("版本相同，仅更新框架文件（rules/skills/CLAUDE.md）。")
        else:
            print("版本不同，执行更新模式：")
            print("  - 跳过 docs/ 目录（保留现有业务文档）")
            print("  - 更新框架文件（rules/skills/CLAUDE.md/mcp.json）")
            print("  - 更新版本标记")
        print()
        print("提示：使用 --force 可强制重新初始化（会覆盖 docs/）。")
        print()
    elif args.force:
        print("强制模式：将覆盖所有文件（包括 docs/）。")
        is_update = False  # 强制模式视为全新安装

    _copy_templates(
        target,
        backend_dir=args.backend_dir,
        frontend_dir=args.frontend_dir,
        app_package=args.app_package,
        docs_only=args.docs_only,
        skip_skills=args.docs_only,
        is_update=is_update,
    )

    # 输出结果
    print()
    print(f"{'更新' if is_update else '初始化'}完成: {target}")
    print(f"  版本: {_get_version()}")
    print()
    if is_update:
        print("  已更新:")
        print("  - .claude/rules/ 与 .claude/skills/（Claude Code）")
        print("  - .cursor/rules/ 与 .cursor/skills/（Cursor）")
        print("  - .cursor/mcp.json（MCP 服务器配置）")
        print("  - CLAUDE.md")
        print()
        print("  已跳过（保留现有）:")
        print("  - docs/spec/ 与 docs/spec_process/")
    else:
        print("  已安装:")
        print("  - docs/spec/ 与 docs/spec_process/")
        print("  - .claude/rules/、.claude/skills/ 与 CLAUDE.md（Claude Code）")
        if not args.docs_only:
            print("  - .cursor/rules/ 与 .cursor/skills/（Cursor）")
            if (target / ".cursor" / "mcp.json").is_file():
                print("  - .cursor/mcp.json（MCP 服务器配置）")
        else:
            print("  - （仅文档 + Claude 规则与技能，未写入 .cursor）")


def _cmd_version(args: argparse.Namespace) -> None:
    """显示版本信息。"""
    print(f"spec-coding version {_get_version()}")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="spec-coding",
        description="在项目根目录初始化 Spec 驱动开发框架（docs/spec、.cursor/.claude 规则与技能）",
    )
    parser.add_argument("--version", action="store_true", help="显示版本信息")

    sub = parser.add_subparsers(dest="command")

    # version 子命令
    version_p = sub.add_parser("version", help="显示版本信息")
    version_p.set_defaults(func=_cmd_version)

    # init 子命令
    init_p = sub.add_parser("init", help="在当前或指定目录初始化 Spec 框架")
    init_p.add_argument(
        "target",
        nargs="?",
        default=os.getcwd(),
        help="目标目录，默认当前目录",
    )
    init_p.add_argument("--backend-dir", default="backend", help="后端代码目录名，用于规则 globs")
    init_p.add_argument("--frontend-dir", default="frontend", help="前端代码目录名，用于规则 globs")
    init_p.add_argument("--app-package", default="app", help="后端 Python 包名，用于规则与技能中的路径")
    init_p.add_argument(
        "--docs-only",
        action="store_true",
        help="仅创建 docs/spec 与 docs/spec_process，不写入 .cursor",
    )
    init_p.add_argument(
        "--force",
        action="store_true",
        help="强制重新初始化（覆盖 docs/ 目录）",
    )
    init_p.set_defaults(func=_cmd_init)

    # 解析参数
    parsed = parser.parse_args()

    # 处理 --version 标志
    if parsed.version:
        print(f"spec-coding version {_get_version()}")
        return

    # 需要子命令
    if not parsed.command:
        parser.print_help()
        sys.exit(1)

    parsed.func(parsed)
