#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DIST_DIR="${DIST_DIR:-${SCRIPT_DIR}/dist}"
IMAGE="${IMAGE:-ghcr.io/zarraxx/debian:trixie}"
PLATFORM="${PLATFORM:-linux/loong64}"
CONTAINER_TOOL="${CONTAINER_TOOL:-docker}"

if [ ! -d "${DIST_DIR}" ]; then
  echo "Package directory does not exist: ${DIST_DIR}" >&2
  exit 1
fi

if ! find "${DIST_DIR}" -maxdepth 1 -name 'openjdk-*-jdk_*_loong64.deb' | grep -q .; then
  echo "No loong64 OpenJDK .deb packages found in ${DIST_DIR}" >&2
  exit 1
fi

"${CONTAINER_TOOL}" run --rm \
  --platform "${PLATFORM}" \
  -v "${DIST_DIR}":/packages:ro \
  "${IMAGE}" \
  /bin/bash -lc '
set -euo pipefail

echo "==> loongarch container"
uname -m
dpkg --print-architecture

echo "==> install deb packages"
apt-get update
apt-get install -y --no-install-recommends /packages/openjdk-*-jdk_*_loong64.deb

cat >/tmp/Hello.java <<'"'"'EOF'"'"'
public class Hello {
    public static void main(String[] args) {
        System.out.println("hello from " + System.getProperty("java.version"));
    }
}
EOF

run_jdk() {
  local home="$1"
  local label
  label=$(basename "${home}")

  echo "==> run ${label}"
  "${home}/bin/java" -version
  "${home}/bin/javac" -version
  rm -f /tmp/Hello.class
  "${home}/bin/javac" /tmp/Hello.java
  "${home}/bin/java" -cp /tmp Hello
}

switch_jdk() {
  local home="$1"
  local label
  local java_target
  local javac_target

  label=$(basename "${home}")
  java_target="${home}/bin/java"
  javac_target="${home}/bin/javac"

  echo "==> switch ${label}"
  update-alternatives --set java "${java_target}"
  update-alternatives --set javac "${javac_target}"

  if [ "$(readlink -f /usr/bin/java)" != "${java_target}" ]; then
    echo "java alternative did not switch to ${java_target}" >&2
    exit 1
  fi

  if [ "$(readlink -f /usr/bin/javac)" != "${javac_target}" ]; then
    echo "javac alternative did not switch to ${javac_target}" >&2
    exit 1
  fi

  java -version
  javac -version
  rm -f /tmp/Hello.class
  javac /tmp/Hello.java
  java -cp /tmp Hello
}

mapfile -t homes < <(find /usr/lib/jvm -maxdepth 1 -type d -name "loongson-*-jdk-loong64" | sort -V)

if [ "${#homes[@]}" -ne 5 ]; then
  echo "Expected 5 Loongnix JDK homes, got ${#homes[@]}" >&2
  printf "%s\n" "${homes[@]}" >&2
  exit 1
fi

echo "==> direct run test"
for home in "${homes[@]}"; do
  run_jdk "${home}"
done

echo "==> update-alternatives switch test"
for home in "${homes[@]}"; do
  switch_jdk "${home}"
done

echo "==> alternatives summary"
update-alternatives --display java
update-alternatives --display javac

echo "loong64 OpenJDK install/run/switch tests passed"
'
