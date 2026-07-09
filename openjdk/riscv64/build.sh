#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
OUT_DIR="${OUT_DIR:-${SCRIPT_DIR}/dist}"
CACHE_DIR="${CACHE_DIR:-${SCRIPT_DIR}/.cache}"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/.build}"

usage() {
  cat <<'EOF'
Usage:
  ./build.sh

Environment:
  OUT_DIR    Output directory for .deb files. Defaults to ./dist
  CACHE_DIR  Download cache directory. Defaults to ./.cache
  BUILD_DIR  Temporary package build directory. Defaults to ./.build
EOF
}

need_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

load_package_config() {
  local package_dir="$1"
  local config="${package_dir}/package.conf"

  if [ ! -f "${config}" ]; then
    echo "Missing package config: ${config}" >&2
    exit 1
  fi

  PACKAGE=
  VERSION=
  JAVA_HOME=
  OPENSUSE_BASE_URL=
  RPMS=()
  # shellcheck source=/dev/null
  . "${config}"

  if [ -z "${PACKAGE}" ] || [ -z "${VERSION}" ] || [ -z "${JAVA_HOME}" ] || [ -z "${OPENSUSE_BASE_URL}" ] || [ "${#RPMS[@]}" -eq 0 ]; then
    echo "Incomplete package config: ${config}" >&2
    exit 1
  fi
}

download_rpm() {
  local rpm="$1"
  local url="${OPENSUSE_BASE_URL}/${rpm}"
  local output="${CACHE_DIR}/${rpm}"

  mkdir -p "${CACHE_DIR}"
  if [ ! -s "${output}" ]; then
    echo "Downloading ${url}" >&2
    curl -fL --retry 5 --retry-delay 5 -o "${output}" "${url}"
  else
    echo "Using cached ${output}" >&2
  fi

  printf '%s\n' "${output}"
}

rpm_payload_offset() {
  local rpm="$1"
  python3 - "${rpm}" <<'PY'
from pathlib import Path
import sys

data = Path(sys.argv[1]).read_bytes()
offset = data.find(b"\x28\xb5\x2f\xfd")
if offset < 0:
    raise SystemExit(f"Could not find zstd payload in {sys.argv[1]}")
print(offset)
PY
}

extract_rpm() {
  local rpm="$1"
  local extract_dir="$2"
  local offset

  offset=$(rpm_payload_offset "${rpm}")
  dd if="${rpm}" bs=1M iflag=skip_bytes skip="${offset}" status=none | \
    zstd -dc | \
    (cd "${extract_dir}" && cpio -idmu --quiet)
}

copy_package_files() {
  local package_dir="$1"
  local stage="$2"

  if [ ! -f "${package_dir}/DEBIAN/control" ]; then
    echo "Missing control file: ${package_dir}/DEBIAN/control" >&2
    exit 1
  fi

  mkdir -p "${stage}"
  cp -a "${package_dir}/DEBIAN" "${stage}/"

  if [ -d "${package_dir}/usr" ]; then
    cp -a "${package_dir}/usr" "${stage}/"
  fi

  if [ -f "${stage}/DEBIAN/postinst" ]; then
    chmod 0755 "${stage}/DEBIAN/postinst"
  fi

  if [ -f "${stage}/DEBIAN/prerm" ]; then
    chmod 0755 "${stage}/DEBIAN/prerm"
  fi

  local changelog="${stage}/usr/share/doc/${PACKAGE}/changelog"
  if [ -f "${changelog}" ]; then
    gzip -9n "${changelog}"
  fi
}

install_jdk_payload() {
  local extract_dir="$1"
  local stage="$2"
  local source_home="${extract_dir}/usr/lib64/jvm/java-1.8.0-openjdk-1.8.0"
  local target_home="${stage}${JAVA_HOME}"

  if [ ! -x "${source_home}/bin/java" ] || [ ! -x "${source_home}/bin/javac" ]; then
    echo "Could not find openSUSE OpenJDK java/javac under ${source_home}" >&2
    exit 1
  fi

  mkdir -p "${target_home}"
  cp -a "${source_home}/." "${target_home}/"
}

build_package() (
  local package_dir="${SCRIPT_DIR}/8"
  local package_build_dir
  local extract_dir
  local stage
  local output
  local rpm
  local rpm_path

  cd "${package_dir}"
  load_package_config "."

  package_build_dir="${BUILD_DIR}/${PACKAGE}"
  extract_dir="${BUILD_DIR}/extract-${PACKAGE}"
  stage="${package_build_dir}/stage"
  output="${OUT_DIR}/${PACKAGE}_${VERSION}_riscv64.deb"

  rm -rf "${package_build_dir}" "${extract_dir}"
  mkdir -p "${OUT_DIR}" "${extract_dir}"

  echo "==> Building ${PACKAGE} ${VERSION}"
  copy_package_files "." "${stage}"

  for rpm in "${RPMS[@]}"; do
    rpm_path=$(download_rpm "${rpm}")
    extract_rpm "${rpm_path}" "${extract_dir}"
  done

  install_jdk_payload "${extract_dir}" "${stage}"
  find "${stage}" -type d -exec chmod 0755 {} +
  dpkg-deb --root-owner-group --build "${stage}" "${output}"
  echo "Built ${output}"
)

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  need_command curl
  need_command cpio
  need_command dd
  need_command dpkg-deb
  need_command python3
  need_command zstd

  rm -rf "${BUILD_DIR}"
  mkdir -p "${OUT_DIR}" "${BUILD_DIR}"
  build_package
}

main "$@"
