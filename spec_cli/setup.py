"""构建前从仓库根生成 templates，保证单一来源（只改 .cursor 与 docs）。"""

import sys
from pathlib import Path

from setuptools import setup
from setuptools.command.build_py import build_py


class BuildPyWithTemplates(build_py):
    def run(self) -> None:
        root = Path(__file__).resolve().parent
        sys.path.insert(0, str(root))
        try:
            import spec_cli.build_templates
            spec_cli.build_templates.build()
        except Exception:
            pass
        super().run(self)
        try:
            spec_cli.build_templates.cleanup_templates()
        except Exception:
            pass


setup(cmdclass={"build_py": BuildPyWithTemplates})
