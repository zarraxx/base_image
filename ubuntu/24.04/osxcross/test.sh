#!/bin/bash
set -euo pipefail

OSXCROSS_IMAGE="${1:-osxcross:MacOSX11.3}"
DARLING_IMAGE="${2:-ghcr.io/zarraxx/darling:noble-20260608}"
DOCKER_CMD="${DOCKER_CMD:-docker}"
read -r -a DOCKER <<< "${DOCKER_CMD}"

HOST_WORKDIR="${PWD}"
TEST_DIR="$(mktemp -d "${HOST_WORKDIR}/.osxcross-test.XXXXXX")"
TEST_SUBDIR="$(basename "${TEST_DIR}")"
cleanup() {
  rm -rf "${TEST_DIR}"
}
trap cleanup EXIT

"${DOCKER[@]}" run --rm \
  -e TEST_SUBDIR="${TEST_SUBDIR}" \
  -v "${HOST_WORKDIR}":/work \
  "${OSXCROSS_IMAGE}" \
  bash -lc '
set -euo pipefail
cd "/work/${TEST_SUBDIR}"

cat > hello.c <<EOF
#include <stdio.h>

int main(void) {
    printf("hello from osxcross under Darling\n");
    return 0;
}
EOF

compiler="$(command -v o64-clang || true)"
if [ -z "${compiler}" ]; then
  compiler="$(find /opt/osxcross/bin -maxdepth 1 -name "*-apple-darwin*-clang" -perm /111 | sort | head -n 1)"
fi

if [ -z "${compiler}" ]; then
  echo "osxcross clang wrapper not found" >&2
  exit 1
fi

"${compiler}" hello.c -o hello-macos
file hello-macos
'

"${DOCKER[@]}" pull "${DARLING_IMAGE}"

"${DOCKER[@]}" run --rm \
  --ulimit nofile=262144:262144 \
  --privileged \
  --userns=host \
  --security-opt seccomp=unconfined \
  --security-opt label=disable \
  --tmpfs /root:rw,exec,mode=755 \
  --tmpfs /tmp:rw,exec,mode=1777 \
  -e TEST_SUBDIR="${TEST_SUBDIR}" \
  -v "${HOST_WORKDIR}":/work \
  "${DARLING_IMAGE}" \
  darling shell /bin/sh -lc 'cd "/Volumes/SystemRoot/work/${TEST_SUBDIR}" && uname -a && ./hello-macos'
