"""CLI entry and init logic."""

import argparse
import os
import shutil
import sys
from pathlib import Path


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
) -> None:
    templates = _templates_dir()
    # 模板不存在或缺少关键内容时，尝试从仓库根生成（可编辑安装时）
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

    def write_file(dest: Path, content: str, *, binary: bool = False) -> None:
        dest.parent.mkdir(parents=True, exist_ok=True)
        if binary:
            dest.write_bytes(content.encode("utf-8"))
        else:
            dest.write_text(content, encoding="utf-8")
        # 始终覆盖，便于再次 init 时更新框架文件

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

    # docs/spec + docs/spec_process
    for name in ("docs",):
        src = templates / name
        if src.is_dir():
            copy_tree(src, target_root / name, substitute_text=False)

    # .claude/rules + .claude/skills + CLAUDE.md（Claude Code 使用，始终注入，--docs-only 时也保留以便仅用 Claude 的项目可用）
    claude_rules_src = templates / "claude" / "rules"
    if claude_rules_src.is_dir():
        claude_dest = target_root / ".claude" / "rules"
        copy_tree(claude_rules_src, claude_dest, substitute_text=True)
    if not docs_only:
        claude_skills_src = templates / "claude" / "skills"
        if claude_skills_src.is_dir():
            claude_skills_dest = target_root / ".claude" / "skills"
            copy_tree(claude_skills_src, claude_skills_dest, substitute_text=True)
    claude_md_src = templates / "CLAUDE.md"
    if claude_md_src.is_file():
        content = claude_md_src.read_text(encoding="utf-8")
        content = _substitute(content, backend_dir, frontend_dir, app_package)
        write_file(target_root / "CLAUDE.md", content)

    if docs_only:
        return

    # .cursor/rules
    cursor_rules_src = templates / "cursor" / "rules"
    if cursor_rules_src.is_dir():
        cursor_dest = target_root / ".cursor" / "rules"
        copy_tree(cursor_rules_src, cursor_dest, substitute_text=True)

    # .cursor/skills (optional)
    if not skip_skills:
        cursor_skills_src = templates / "cursor" / "skills"
        if cursor_skills_src.is_dir():
            cursor_dest = target_root / ".cursor" / "skills"
            copy_tree(cursor_skills_src, cursor_dest, substitute_text=True)

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
    _copy_templates(
        target,
        backend_dir=args.backend_dir,
        frontend_dir=args.frontend_dir,
        app_package=args.app_package,
        docs_only=args.docs_only,
        skip_skills=args.docs_only,  # docs_only 时不写 skills
    )
    print(f"已在 {target} 初始化 Spec 框架。")
    print("  - docs/spec/ 与 docs/spec_process/")
    print("  - .claude/rules/、.claude/skills/ 与 CLAUDE.md（Claude Code）")
    if not args.docs_only:
        print("  - .cursor/rules/ 与 .cursor/skills/（Cursor）")
    else:
        print("  - （仅文档 + Claude 规则与技能，未写入 .cursor）")
    print("  （再次执行 init 会覆盖上述框架文件以更新）")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="spec-coding",
        description="在项目根目录初始化 Spec 驱动开发框架（docs/spec、.cursor 规则与技能）",
    )
    sub = parser.add_subparsers(dest="command", required=True)

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
    init_p.set_defaults(func=_cmd_init)

    parsed = parser.parse_args()
    parsed.func(parsed)
