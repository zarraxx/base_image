import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (REPO_ROOT / path).read_text()


class UbuntuWorkflowTest(unittest.TestCase):
    def test_ubuntu_dockerfile_has_base_arg_and_default_command(self) -> None:
        content = read("ubuntu/Dockerfile")
        self.assertIn("ARG BASE_IMAGE=ubuntu:24.04", content)
        self.assertIn('CMD ["/bin/bash"]', content)

    def test_ubuntu_24_04_workflow_builds_expected_tags_and_platforms(self) -> None:
        content = read(".github/workflows/ubuntu-24.04.yml")
        self.assertIn("IMAGE_TAG_VERSION: \"24.04\"", content)
        self.assertIn("IMAGE_TAG_CODENAME: noble", content)
        self.assertIn("file: ubuntu/Dockerfile", content)
        self.assertIn("BASE_IMAGE=ubuntu:${{ env.IMAGE_TAG_VERSION }}", content)
        self.assertIn('--tag "${image}:${IMAGE_TAG_VERSION}"', content)
        self.assertIn('--tag "${image}:${IMAGE_TAG_CODENAME}"', content)

        for suffix, platform in (
            ("amd64", "linux/amd64"),
            ("arm64v8", "linux/arm64/v8"),
            ("ppc64le", "linux/ppc64le"),
            ("riscv64", "linux/riscv64"),
            ("s390x", "linux/s390x"),
        ):
            with self.subTest(suffix=suffix):
                self.assertIn(f"suffix: {suffix}", content)
                self.assertIn(f"platform: {platform}", content)
                self.assertIn(f'"${{image}}:${{IMAGE_TAG_CODENAME}}-{suffix}"', content)

    def test_ubuntu_26_04_workflow_builds_expected_tags_and_platforms(self) -> None:
        content = read(".github/workflows/ubuntu-26.04.yml")
        self.assertIn("IMAGE_TAG_VERSION: \"26.04\"", content)
        self.assertIn("IMAGE_TAG_CODENAME: resolute", content)
        self.assertIn("file: ubuntu/Dockerfile", content)
        self.assertIn("BASE_IMAGE=ubuntu:${{ env.IMAGE_TAG_VERSION }}", content)
        self.assertIn('--tag "${image}:${IMAGE_TAG_VERSION}"', content)
        self.assertIn('--tag "${image}:${IMAGE_TAG_CODENAME}"', content)

        for suffix, platform in (
            ("amd64", "linux/amd64"),
            ("arm64v8", "linux/arm64/v8"),
            ("ppc64le", "linux/ppc64le"),
            ("riscv64", "linux/riscv64"),
            ("s390x", "linux/s390x"),
        ):
            with self.subTest(suffix=suffix):
                self.assertIn(f"suffix: {suffix}", content)
                self.assertIn(f"platform: {platform}", content)
                self.assertIn(f'"${{image}}:${{IMAGE_TAG_CODENAME}}-{suffix}"', content)


if __name__ == "__main__":
    unittest.main()
