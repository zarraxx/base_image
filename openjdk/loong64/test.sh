#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DIST_DIR="${DIST_DIR:-${SCRIPT_DIR}/dist}"
IMAGE="${IMAGE:-ghcr.io/zarraxx/debian:trixie}"
PLATFORM="${PLATFORM:-linux/loong64}"
CONTAINER_TOOL="${CONTAINER_TOOL:-docker}"
ALLOW_RUNTIME_FAILURE="${ALLOW_RUNTIME_FAILURE:-false}"

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
  -e "ALLOW_RUNTIME_FAILURE=${ALLOW_RUNTIME_FAILURE}" \
  -v "${DIST_DIR}":/packages:ro \
  "${IMAGE}" \
  /bin/bash -lc '
set -euo pipefail
ALLOW_RUNTIME_FAILURE="${ALLOW_RUNTIME_FAILURE:-false}"

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

run_java() {
  local home="$1"
  local label
  shift

  label=$(basename "${home}")
  if [[ "${label}" == loongson-8-* ]]; then
    JAVA_TOOL_OPTIONS="-Xint" "${home}/bin/java" "$@"
  else
    "${home}/bin/java" "$@"
  fi
}

run_javac() {
  local home="$1"
  local label
  shift

  label=$(basename "${home}")
  if [[ "${label}" == loongson-8-* ]]; then
    JAVA_TOOL_OPTIONS="-Xint" "${home}/bin/javac" "$@"
  else
    "${home}/bin/javac" "$@"
  fi
}

run_alt_java() {
  local label="$1"
  shift

  if [[ "${label}" == loongson-8-* ]]; then
    JAVA_TOOL_OPTIONS="-Xint" java "$@"
  else
    java "$@"
  fi
}

run_alt_javac() {
  local label="$1"
  shift

  if [[ "${label}" == loongson-8-* ]]; then
    JAVA_TOOL_OPTIONS="-Xint" javac "$@"
  else
    javac "$@"
  fi
}

run_runtime_step() {
  local label="$1"
  shift

  if [[ "${ALLOW_RUNTIME_FAILURE}" == "true" ]]; then
    set +e
    "$@"
    local status=$?
    set -e
    if [ "${status}" -ne 0 ]; then
      echo "::warning::${label} runtime command failed with exit ${status}: $*"
    fi
    return 0
  fi

  "$@"
}

run_jdk() {
  local home="$1"
  local label
  label=$(basename "${home}")

  echo "==> run ${label}"
  run_runtime_step "${label}" run_java "${home}" -version
  run_runtime_step "${label}" run_javac "${home}" -version
  rm -f /tmp/Hello.class
  run_runtime_step "${label}" run_javac "${home}" /tmp/Hello.java
  run_runtime_step "${label}" run_java "${home}" -cp /tmp Hello
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

  run_runtime_step "${label}" run_alt_java "${label}" -version
  run_runtime_step "${label}" run_alt_javac "${label}" -version
  rm -f /tmp/Hello.class
  run_runtime_step "${label}" run_alt_javac "${label}" /tmp/Hello.java
  run_runtime_step "${label}" run_alt_java "${label}" -cp /tmp Hello
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
