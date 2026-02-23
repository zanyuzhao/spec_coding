"""
从仓库根目录的 .cursor 与 docs 生成 spec_cli 的 templates（带占位符）。
唯一编辑处：仓库根 .cursor/ 与 docs/；本脚本在发布或本地安装前运行，生成 spec_cli/templates/。
"""

import re
import shutil
import sys
from pathlib import Path

PLACEHOLDER_BACKEND = "{{BACKEND_DIR}}"
PLACEHOLDER_FRONTEND = "{{FRONTEND_DIR}}"
PLACEHOLDER_APP = "{{APP_PACKAGE}}"


def _repo_root() -> Path:
    """仓库根目录（spec_coding）。"""
    return Path(__file__).resolve().parent.parent.parent


def _templates_dir() -> Path:
    """spec_cli 内 templates 目录。"""
    return Path(__file__).resolve().parent / "templates"


def _to_placeholders(content: str) -> str:
    """将仓库中的 backend/frontend/app 转为占位符（用于 .cursor 与 .claude 下的规则、技能及 CLAUDE.md）。"""
    s = content.replace("backend", PLACEHOLDER_BACKEND)
    s = s.replace("frontend", PLACEHOLDER_FRONTEND)
    # 仅替换作为包名的 app：app/、app.，避免改到 application 等
    s = re.sub(r"\bapp/", f"{PLACEHOLDER_APP}/", s)
    s = re.sub(r"\bapp\.", f"{PLACEHOLDER_APP}.", s)
    return s


def _copy_with_placeholders(src: Path, dest: Path, apply_placeholders: bool) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    text = src.read_text(encoding="utf-8")
    if apply_placeholders:
        text = _to_placeholders(text)
    dest.write_text(text, encoding="utf-8")


def build() -> bool:
    """从仓库根生成 templates。若不在仓库内（无 .cursor/docs）则跳过并返回 False。"""
    repo = _repo_root()
    templates = _templates_dir()

    if not (repo / ".cursor").is_dir() or not (repo / "docs").is_dir():
        return False

    # 清空并重建 templates
    if templates.exists():
        shutil.rmtree(templates)
    templates.mkdir(parents=True)

    # .cursor/rules -> templates/cursor/rules（替换占位符）
    rules_src = repo / ".cursor" / "rules"
    rules_dst = templates / "cursor" / "rules"
    if rules_src.is_dir():
        for f in rules_src.glob("*.mdc"):
            _copy_with_placeholders(f, rules_dst / f.name, apply_placeholders=True)

    # .cursor/skills -> templates/cursor/skills（替换占位符）
    skills_src = repo / ".cursor" / "skills"
    skills_dst = templates / "cursor" / "skills"
    if skills_src.is_dir():
        for item in skills_src.iterdir():
            if item.is_dir():
                for f in item.rglob("*"):
                    if f.is_file():
                        rel = f.relative_to(item)
                        dest_file = skills_dst / item.name / rel
                        _copy_with_placeholders(f, dest_file, apply_placeholders=True)

    # docs/spec -> templates/docs/spec（不替换）
    spec_src = repo / "docs" / "spec"
    spec_dst = templates / "docs" / "spec"
    if spec_src.is_dir():
        for f in spec_src.rglob("*"):
            if f.is_file():
                rel = f.relative_to(spec_src)
                dest_file = spec_dst / rel
                _copy_with_placeholders(f, dest_file, apply_placeholders=False)

    # docs/spec_process -> templates/docs/spec_process（不替换）
    process_src = repo / "docs" / "spec_process"
    process_dst = templates / "docs" / "spec_process"
    if process_src.is_dir():
        for f in process_src.rglob("*"):
            if f.is_file():
                rel = f.relative_to(process_src)
                dest_file = process_dst / rel
                _copy_with_placeholders(f, dest_file, apply_placeholders=False)

    # .claude/rules -> templates/claude/rules（替换占位符，供 Claude Code 使用）
    claude_rules_src = repo / ".claude" / "rules"
    claude_rules_dst = templates / "claude" / "rules"
    if claude_rules_src.is_dir():
        for f in claude_rules_src.rglob("*"):
            if f.is_file():
                rel = f.relative_to(claude_rules_src)
                dest_file = claude_rules_dst / rel
                _copy_with_placeholders(f, dest_file, apply_placeholders=True)

    # CLAUDE.md -> templates/CLAUDE.md（替换占位符）
    claude_md_src = repo / "CLAUDE.md"
    if claude_md_src.is_file():
        _copy_with_placeholders(claude_md_src, templates / "CLAUDE.md", apply_placeholders=True)

    print(f"已从 {repo} 生成 templates -> {templates}")
    return True


def cleanup_templates() -> None:
    """删除 templates 目录（仅当在仓库内、可重新生成时），保证代码中只保留一套流程。"""
    repo = _repo_root()
    templates = _templates_dir()
    if not (repo / ".cursor").is_dir() or not (repo / "docs").is_dir():
        return
    if templates.exists():
        try:
            shutil.rmtree(templates)
        except OSError:
            pass


def main() -> None:
    if not build():
        print("跳过：未在仓库根找到 .cursor 或 docs（如从 sdist 安装则正常）", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
