"""仓库根安装入口：构建时自动从 .cursor 与 docs 生成 spec_cli/templates。"""

import sys
from pathlib import Path

root = Path(__file__).resolve().parent
sys.path.insert(0, str(root))

from setuptools import setup
from setuptools.command.build_py import build_py


class BuildPyWithTemplates(build_py):
    """先从仓库根生成 templates，再执行默认 build_py，完成后删除 templates 保持干净。"""

    def run(self) -> None:
        try:
            import spec_cli.build_templates
            spec_cli.build_templates.build()
        except Exception:
            pass  # 非仓库内安装（如从 sdist）时跳过
        super().run(self)
        try:
            spec_cli.build_templates.cleanup_templates()
        except Exception:
            pass


setup(cmdclass={"build_py": BuildPyWithTemplates})
