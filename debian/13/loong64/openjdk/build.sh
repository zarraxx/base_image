#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
OUT_DIR="${OUT_DIR:-${SCRIPT_DIR}/dist}"
CACHE_DIR="${CACHE_DIR:-${SCRIPT_DIR}/.cache}"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/.build}"

usage() {
  cat <<'EOF'
Usage:
  ./build.sh [major ...]

Examples:
  ./build.sh
  ./build.sh 17 21

Each major version is built from its own directory, for example:
  17/package.conf
  17/DEBIAN/control
  17/DEBIAN/postinst
  17/DEBIAN/prerm
  17/usr/share/doc/openjdk-17-jdk/*

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

download_tarball() {
  local url="$1"
  local tarball="${CACHE_DIR}/$(basename "${url}")"

  mkdir -p "${CACHE_DIR}"
  if [ ! -s "${tarball}" ]; then
    echo "Downloading ${url}" >&2
    curl -fL --retry 5 --retry-delay 5 -o "${tarball}" "${url}"
  else
    echo "Using cached ${tarball}" >&2
  fi

  printf '%s\n' "${tarball}"
}

package_dirs() {
  if [ "$#" -gt 0 ]; then
    local major
    for major in "$@"; do
      printf '%s\n' "${SCRIPT_DIR}/${major}"
    done
    return
  fi

  find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*' | sort -V
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
  TARBALL_URL=
  JAVA_HOME=
  # shellcheck source=/dev/null
  . "${config}"

  if [ -z "${PACKAGE}" ] || [ -z "${VERSION}" ] || [ -z "${TARBALL_URL}" ] || [ -z "${JAVA_HOME}" ]; then
    echo "Incomplete package config: ${config}" >&2
    exit 1
  fi
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
  local tarball="$1"
  local stage="$2"
  local extract_dir="$3"
  local target_home="${stage}${JAVA_HOME}"
  local jdk_bin
  local extracted_home

  mkdir -p "${extract_dir}" "${target_home}"
  tar -xzf "${tarball}" -C "${extract_dir}"

  jdk_bin=$(find "${extract_dir}" -type f -path '*/bin/javac' -perm /111 -print -quit)
  if [ -z "${jdk_bin}" ]; then
    jdk_bin=$(find "${extract_dir}" -type f -path '*/bin/java' -perm /111 -print -quit)
  fi

  if [ -z "${jdk_bin}" ]; then
    echo "Could not find executable bin/java or bin/javac in ${tarball}" >&2
    exit 1
  fi

  extracted_home=$(dirname "$(dirname "${jdk_bin}")")
  cp -a "${extracted_home}/." "${target_home}/"
}

build_package_dir() (
  local package_dir="$1"
  local package_build_dir
  local extract_dir
  local stage
  local tarball
  local output

  cd "${package_dir}"
  load_package_config "."

  package_build_dir="${BUILD_DIR}/${PACKAGE}"
  extract_dir="${BUILD_DIR}/extract-${PACKAGE}"
  stage="${package_build_dir}/stage"
  output="${OUT_DIR}/${PACKAGE}_${VERSION}_loong64.deb"

  rm -rf "${package_build_dir}" "${extract_dir}"
  mkdir -p "${OUT_DIR}"

  echo "==> Building ${PACKAGE} ${VERSION}"
  copy_package_files "." "${stage}"
  tarball=$(download_tarball "${TARBALL_URL}")
  install_jdk_payload "${tarball}" "${stage}" "${extract_dir}"

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
  need_command tar
  need_command find
  need_command dpkg-deb

  rm -rf "${BUILD_DIR}"
  mkdir -p "${OUT_DIR}" "${BUILD_DIR}"

  local built=0
  local package_dir
  while IFS= read -r package_dir; do
    if [ ! -d "${package_dir}" ]; then
      echo "Unknown OpenJDK directory: ${package_dir}" >&2
      exit 1
    fi

    build_package_dir "${package_dir}"
    built=$((built + 1))
  done < <(package_dirs "$@")

  if [ "${built}" -eq 0 ]; then
    echo "No OpenJDK package directories found" >&2
    exit 1
  fi
}

main "$@"
