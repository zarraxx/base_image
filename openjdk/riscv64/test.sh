#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DIST_DIR="${DIST_DIR:-${SCRIPT_DIR}/dist}"
IMAGE="${IMAGE:-ghcr.io/zarraxx/ubuntu:resolute}"
PLATFORM="${PLATFORM:-linux/riscv64}"
CONTAINER_TOOL="${CONTAINER_TOOL:-docker}"

if [ ! -d "${DIST_DIR}" ]; then
  echo "Package directory does not exist: ${DIST_DIR}" >&2
  exit 1
fi

if ! find "${DIST_DIR}" -maxdepth 1 -name 'openjdk-8-jdk_*_riscv64.deb' | grep -q .; then
  echo "No riscv64 OpenJDK 8 .deb package found in ${DIST_DIR}" >&2
  exit 1
fi

"${CONTAINER_TOOL}" run --rm \
  --platform "${PLATFORM}" \
  -v "${DIST_DIR}":/packages:ro \
  "${IMAGE}" \
  /bin/bash -lc '
set -euo pipefail

echo "==> riscv64 container"
uname -m
dpkg --print-architecture

echo "==> install deb package"
apt-get update
apt-get install -y --no-install-recommends /packages/openjdk-8-jdk_*_riscv64.deb

echo "==> java smoke test"
java -version
javac -version

cat >/tmp/Hello.java <<'"'"'EOF'"'"'
public class Hello {
    public static void main(String[] args) {
        System.out.println(System.getProperty("java.version")
            + " / " + System.getProperty("java.vm.name")
            + " / " + System.getProperty("os.arch"));
    }
}
EOF

javac /tmp/Hello.java
java -cp /tmp Hello

echo "==> alternatives test"
test "$(readlink -f /usr/bin/java)" = "/usr/lib/jvm/opensuse-8-jdk-riscv64/bin/java"
test "$(readlink -f /usr/bin/javac)" = "/usr/lib/jvm/opensuse-8-jdk-riscv64/bin/javac"

echo "riscv64 OpenJDK 8 install/run tests passed"
'
