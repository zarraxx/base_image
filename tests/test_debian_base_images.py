import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (REPO_ROOT / path).read_text()


class DebianBaseImageDefaultsTest(unittest.TestCase):
    def test_debian_dockerfiles_install_vim(self) -> None:
        for path in (
            "debian/10/Dockerfile",
            "debian/10/aliyun/Dockerfile",
            "debian/13/Dockerfile",
        ):
            with self.subTest(path=path):
                self.assertRegex(read(path), r"(?m)^\s+vim(?:\s|\\|&&)")

    def test_debian_rootfs_builds_install_vim(self) -> None:
        for path in (
            "debian/10/rootfs/build.sh",
            "debian/12/rootfs/build.sh",
            "debian/13/loong64/build.sh",
        ):
            with self.subTest(path=path):
                self.assertRegex(read(path), r"(?m)^\s+vim(?:\s|\\|$)")

    def test_rootfs_imports_set_bash_as_default_command(self) -> None:
        cmd_change = re.escape('CMD ["/bin/bash"]')
        for path in (
            "debian/10/rootfs/build.sh",
            "debian/12/rootfs/build.sh",
            "debian/13/loong64/build.sh",
        ):
            with self.subTest(path=path):
                content = read(path)
                self.assertRegex(content, rf"podman import .*--change '{cmd_change}'")
                self.assertRegex(content, rf"docker import .*--change '{cmd_change}'")

    def test_debian_dockerfiles_set_bash_as_default_command(self) -> None:
        for path in (
            "debian/10/Dockerfile",
            "debian/10/aliyun/Dockerfile",
            "debian/13/Dockerfile",
        ):
            with self.subTest(path=path):
                self.assertIn('CMD ["/bin/bash"]', read(path))


if __name__ == "__main__":
    unittest.main()
