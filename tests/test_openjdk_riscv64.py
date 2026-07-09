import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
RISCV64_DIR = REPO_ROOT / "openjdk/riscv64"


class OpenJDKRiscv64PackagingTest(unittest.TestCase):
    def test_build_script_uses_opensuse_official_rpms(self) -> None:
        content = (RISCV64_DIR / "build.sh").read_text()
        package_conf = (RISCV64_DIR / "8/package.conf").read_text()
        self.assertIn(
            "https://download.opensuse.org/ports/riscv/tumbleweed/repo/oss/riscv64",
            package_conf,
        )
        self.assertIn("java-1_8_0-openjdk-headless-1.8.0.492-4.1.riscv64.rpm", package_conf)
        self.assertIn("java-1_8_0-openjdk-devel-1.8.0.492-4.1.riscv64.rpm", package_conf)
        self.assertIn("java-1_8_0-openjdk-1.8.0.492-4.1.riscv64.rpm", package_conf)
        self.assertIn("zstd -dc", content)
        self.assertNotIn("rpmfind.net", package_conf)

    def test_control_declares_riscv64_and_libffi8(self) -> None:
        control = (RISCV64_DIR / "8/DEBIAN/control").read_text()
        self.assertIn("Package: openjdk-8-jdk", control)
        self.assertIn("Architecture: riscv64", control)
        self.assertIn("libffi8", control)

    def test_package_registers_java_alternatives(self) -> None:
        postinst = (RISCV64_DIR / "8/DEBIAN/postinst").read_text()
        prerm = (RISCV64_DIR / "8/DEBIAN/prerm").read_text()
        self.assertIn("/usr/lib/jvm/opensuse-8-jdk-riscv64", postinst)
        self.assertIn("update-alternatives --install", postinst)
        self.assertIn("update-alternatives --remove", prerm)

    def test_test_script_runs_on_ubuntu_resolute_riscv64(self) -> None:
        content = (RISCV64_DIR / "test.sh").read_text()
        self.assertIn("ghcr.io/zarraxx/ubuntu:resolute", content)
        self.assertIn("linux/riscv64", content)
        self.assertIn("javac /tmp/Hello.java", content)


if __name__ == "__main__":
    unittest.main()
