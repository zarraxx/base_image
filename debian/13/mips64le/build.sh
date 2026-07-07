#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOTFS="${SCRIPT_DIR}/rootfs-mips64le"
MIRROR="https://deb.debian.org/debian"
SECURITY_MIRROR="https://deb.debian.org/debian-security"
IMAGE_TAG="localhost/debian:trixie-mips64le"
DEBIAN_ARCH="mips64el"
IMAGE_ARCH="mips64le"
KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"

sudo apt install -y ca-certificates debootstrap debian-archive-keyring qemu-user qemu-user-binfmt binfmt-support

if command -v update-binfmts >/dev/null 2>&1; then
  sudo update-binfmts --enable qemu-mips64el || true
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl restart systemd-binfmt || true
fi

if [ ! -e /proc/sys/fs/binfmt_misc/register ]; then
  sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
fi

if [ ! -e /proc/sys/fs/binfmt_misc/qemu-mips64el ]; then
  sudo sh -c 'cat /usr/share/qemu/binfmt.d/qemu-mips64el.conf > /proc/sys/fs/binfmt_misc/register'
fi

sudo rm -rf "${ROOTFS}"
mkdir -p "${ROOTFS}"

sudo debootstrap \
  --arch="${DEBIAN_ARCH}" \
  --foreign \
  --keyring="${KEYRING}" \
  --variant=minbase \
  trixie \
  "${ROOTFS}" \
  "${MIRROR}"

sudo chroot "${ROOTFS}" /debootstrap/debootstrap --second-stage

sudo tee "${ROOTFS}/etc/apt/sources.list" >/dev/null <<EOF
deb ${MIRROR} trixie main
deb ${MIRROR} trixie-updates main
deb ${SECURITY_MIRROR} trixie-security main
EOF

sudo chroot "${ROOTFS}" apt-get update
sudo chroot "${ROOTFS}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  git \
  curl wget \
  ca-certificates \
  python3 \
  python3-setuptools \
  xz-utils \
  unzip \
  zip \
  bzip2 \
  file
sudo chroot "${ROOTFS}" rm -rf /var/lib/apt/lists/*

if command -v podman >/dev/null 2>&1; then
  sudo tar -C "${ROOTFS}" -c . | podman import --arch "${IMAGE_ARCH}" --os linux - "${IMAGE_TAG}"
else
  sudo tar -C "${ROOTFS}" -c . | docker import --platform "linux/${IMAGE_ARCH}" - "${IMAGE_TAG}"
fi

echo "Imported ${IMAGE_TAG}"
echo "Run with: podman run --rm --platform linux/${IMAGE_ARCH} -it ${IMAGE_TAG} /bin/bash"
