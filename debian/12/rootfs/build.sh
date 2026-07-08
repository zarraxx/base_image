#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEBIAN_ARCH="${DEBIAN_ARCH:-amd64}"
PLATFORM="${PLATFORM:-linux/amd64}"
SUFFIX="${SUFFIX:-${DEBIAN_ARCH}}"
ROOTFS="${SCRIPT_DIR}/rootfs-${SUFFIX}"
SUITE="${SUITE:-bookworm}"
MIRROR="${MIRROR:-http://deb.debian.org/debian}"
SECURITY_MIRROR="${SECURITY_MIRROR:-http://security.debian.org/debian-security}"
IMAGE_TAG="${IMAGE_TAG:-localhost/debian:bookworm-${SUFFIX}}"

qemu_binary() {
  case "$1" in
    amd64) echo "" ;;
    i386) echo "" ;;
    armel) echo "qemu-arm-static" ;;
    armhf) echo "qemu-arm-static" ;;
    arm64) echo "qemu-aarch64-static" ;;
    mipsel) echo "qemu-mipsel-static" ;;
    mips64el) echo "qemu-mips64el-static" ;;
    ppc64el) echo "qemu-ppc64le-static" ;;
    s390x) echo "qemu-s390x-static" ;;
    *) echo "Unsupported Debian arch: $1" >&2; exit 1 ;;
  esac
}

container_arch() {
  case "$1" in
    amd64) echo "amd64" ;;
    i386) echo "386" ;;
    armel) echo "arm" ;;
    armhf) echo "arm" ;;
    arm64) echo "arm64" ;;
    mipsel) echo "mipsle" ;;
    mips64el) echo "mips64le" ;;
    ppc64el) echo "ppc64le" ;;
    s390x) echo "s390x" ;;
    *) echo "Unsupported Debian arch: $1" >&2; exit 1 ;;
  esac
}

container_variant() {
  case "$1" in
    armel) echo "v5" ;;
    armhf) echo "v7" ;;
    arm64) echo "v8" ;;
    *) echo "" ;;
  esac
}

binfmt_name() {
  local qemu_bin="$1"
  echo "${qemu_bin%-static}"
}

QEMU_PACKAGES=(qemu-user qemu-user-binfmt)
if apt-cache policy qemu-user-static | awk '/Candidate:/ { exit ($2 == "(none)") }'; then
  QEMU_PACKAGES=(qemu-user-static)
fi

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates \
  debootstrap \
  debian-archive-keyring \
  binfmt-support \
  "${QEMU_PACKAGES[@]}"

QEMU_BIN=$(qemu_binary "${DEBIAN_ARCH}")
if [ -n "${QEMU_BIN}" ]; then
  if command -v update-binfmts >/dev/null 2>&1; then
    sudo update-binfmts --enable "$(binfmt_name "${QEMU_BIN}")" || true
  fi

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart systemd-binfmt || true
  fi

  if [ ! -e /proc/sys/fs/binfmt_misc/register ]; then
    sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
  fi
fi

sudo rm -rf "${ROOTFS}"
mkdir -p "${ROOTFS}"

if [ -n "${QEMU_BIN}" ]; then
  sudo debootstrap \
    --arch="${DEBIAN_ARCH}" \
    --foreign \
    --variant=minbase \
    "${SUITE}" \
    "${ROOTFS}" \
    "${MIRROR}"
  sudo cp "$(command -v "${QEMU_BIN}")" "${ROOTFS}/usr/bin/"
  sudo chroot "${ROOTFS}" /debootstrap/debootstrap --second-stage
else
  sudo debootstrap \
    --arch="${DEBIAN_ARCH}" \
    --variant=minbase \
    "${SUITE}" \
    "${ROOTFS}" \
    "${MIRROR}"
fi

sudo tee "${ROOTFS}/etc/apt/sources.list" >/dev/null <<EOF
deb ${MIRROR} ${SUITE} main contrib non-free non-free-firmware
deb ${SECURITY_MIRROR} ${SUITE}-security main contrib non-free non-free-firmware
deb ${MIRROR} ${SUITE}-updates main contrib non-free non-free-firmware
EOF

sudo chroot "${ROOTFS}" apt-get update
sudo chroot "${ROOTFS}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bash \
  curl wget \
  ca-certificates \
  iputils-ping \
  telnet \
  ftp \
  net-tools iproute2 \
  procps \
  xz-utils \
  unzip \
  zip \
  bzip2 \
  file
sudo chroot "${ROOTFS}" rm -rf /var/lib/apt/lists/*

if [ -n "${QEMU_BIN}" ]; then
  sudo rm -f "${ROOTFS}/usr/bin/${QEMU_BIN}"
fi

CONTAINER_TOOL="${CONTAINER_TOOL:-}"
if [ -z "${CONTAINER_TOOL}" ]; then
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_TOOL=podman
  else
    CONTAINER_TOOL=docker
  fi
fi

case "${CONTAINER_TOOL}" in
  podman)
    PODMAN_IMPORT_ARGS=(--arch "$(container_arch "${DEBIAN_ARCH}")" --os linux)
    VARIANT=$(container_variant "${DEBIAN_ARCH}")
    if [ -n "${VARIANT}" ]; then
      PODMAN_IMPORT_ARGS+=(--variant "${VARIANT}")
    fi
    sudo tar -C "${ROOTFS}" -c . | podman import "${PODMAN_IMPORT_ARGS[@]}" - "${IMAGE_TAG}"
    ;;
  docker)
    sudo tar -C "${ROOTFS}" -c . | docker import --platform "${PLATFORM}" - "${IMAGE_TAG}"
    ;;
  *)
    echo "Unsupported CONTAINER_TOOL: ${CONTAINER_TOOL}" >&2
    exit 1
    ;;
esac

echo "Imported ${IMAGE_TAG}"
echo "Run with: ${CONTAINER_TOOL} run --rm --platform ${PLATFORM} -it ${IMAGE_TAG} /bin/bash"
