import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / ".github/workflows/build-openjdk.yml"


def workflow_text() -> str:
    return WORKFLOW.read_text()


class OpenJDKWorkflowTest(unittest.TestCase):
    def test_mainline_arches_use_ubuntu_resolute(self) -> None:
        content = workflow_text()
        for java in ("8", "11", "17", "21", "25"):
            for suffix in ("amd64", "arm64v8", "ppc64le", "s390x"):
                with self.subTest(java=java, suffix=suffix):
                    self.assertRegex(
                        content,
                        rf'java: "{java}"[\s\S]*?suffix: {suffix}[\s\S]*?base_image: ghcr\.io/zarraxx/ubuntu:resolute',
                    )

        for java in ("11", "17", "21", "25"):
            with self.subTest(java=java, suffix="riscv64"):
                self.assertRegex(
                    content,
                    rf'java: "{java}"[\s\S]*?suffix: riscv64[\s\S]*?base_image: ghcr\.io/zarraxx/ubuntu:resolute',
                )

    def test_openjdk8_uses_dedicated_riscv64_rpm_repack_job(self) -> None:
        content = workflow_text()
        self.assertIn("build-riscv64-jdk8:", content)
        self.assertIn("openjdk/riscv64", content)
        self.assertIn("openjdk-8-jdk_*_riscv64.deb", content)
        self.assertIn("ghcr.io/zarraxx/ubuntu:resolute", content)

    def test_mips64le_keeps_debian_base_images(self) -> None:
        content = workflow_text()
        expected = {
            "8": "ghcr.io/zarraxx/debian:buster-mips64el",
            "11": "ghcr.io/zarraxx/debian:buster-mips64el",
            "17": "ghcr.io/zarraxx/debian:bookworm-mips64el",
        }
        for java, base_image in expected.items():
            with self.subTest(java=java):
                self.assertRegex(
                    content,
                    rf'java: "{java}"[\s\S]*?suffix: mips64le[\s\S]*?base_image: {re.escape(base_image)}',
                )

    def test_manifest_arch_sets_match_supported_paths(self) -> None:
        content = workflow_text()
        self.assertIn("arch_tags: amd64 arm64v8 ppc64le riscv64 s390x mips64le loong64", content)
        self.assertIn("arch_tags: amd64 arm64v8 ppc64le riscv64 s390x mips64le loong64", content)
        self.assertIn("arch_tags: amd64 arm64v8 ppc64le riscv64 s390x loong64", content)

    def test_workflow_no_longer_depends_on_debian_base_workflows_for_mainline_arches(self) -> None:
        content = workflow_text()
        self.assertNotIn('"debian/10/rootfs/**"', content)
        self.assertNotIn('"debian/12/rootfs/**"', content)
        self.assertNotIn('"debian/13/Dockerfile"', content)
        self.assertIn('"ubuntu/Dockerfile"', content)
        self.assertIn('BASE_IMAGE=${{ matrix.target.base_image }}', content)

    def test_all_official_matrix_images_have_non_blocking_smoke_tests(self) -> None:
        content = workflow_text()
        self.assertIn("Build local smoke image", content)
        self.assertIn("Smoke test local image", content)
        self.assertIn("docker run --rm --platform \"${{ matrix.target.platform }}\"", content)
        self.assertIn("::warning::openjdk ${{ matrix.java }}-${{ matrix.target.suffix }} smoke test failed", content)

    def test_riscv64_jdk8_tests_warn_without_stopping_workflow(self) -> None:
        content = workflow_text()
        self.assertIn("Test riscv64 OpenJDK 8 deb", content)
        self.assertIn("::warning::riscv64 OpenJDK 8 deb test failed", content)
        self.assertIn("::warning::openjdk 8-riscv64 JVM smoke test failed", content)


if __name__ == "__main__":
    unittest.main()
