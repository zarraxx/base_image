#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOTFS="${SCRIPT_DIR}/rootfs-loong64"
MIRROR="https://loong13.debian.net/debian-loong64/"
IMAGE_TAG="localhost/debian:trixie-loong64"
KEY_URL="https://raw.githubusercontent.com/triloong/debian-loong64-keyring/master/active-keys/debian-loong64-non-official-2025.key"
KEY_FINGERPRINT="734FAB8ADC636909C6625883D81ED514A07B9DA8"
KEYRING="${SCRIPT_DIR}/debian-loong64-non-official-archive-keyring.gpg"
TMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

sudo apt install -y ca-certificates curl debootstrap gpg qemu-user qemu-user-binfmt binfmt-support

if command -v update-binfmts >/dev/null 2>&1; then
  sudo update-binfmts --enable qemu-loongarch64 || true
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl restart systemd-binfmt || true
fi

if [ ! -e /proc/sys/fs/binfmt_misc/register ]; then
  sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
fi

if [ ! -e /proc/sys/fs/binfmt_misc/qemu-loongarch64 ]; then
  sudo sh -c 'cat /usr/share/qemu/binfmt.d/qemu-loongarch64.conf > /proc/sys/fs/binfmt_misc/register'
fi

curl -fsSL "${KEY_URL}" -o "${TMP_DIR}/loong64-archive.key"
ACTUAL_FINGERPRINT=$(gpg --show-keys --with-colons "${TMP_DIR}/loong64-archive.key" 2>/dev/null | awk -F: '$1 == "fpr" { print $10; exit }')

if [ "${ACTUAL_FINGERPRINT}" != "${KEY_FINGERPRINT}" ]; then
  echo "Unexpected loong64 archive key fingerprint: ${ACTUAL_FINGERPRINT}" >&2
  exit 1
fi

rm -f "${KEYRING}"
gpg --dearmor --yes -o "${KEYRING}" "${TMP_DIR}/loong64-archive.key"

sudo rm -rf "${ROOTFS}"
mkdir -p "${ROOTFS}"

sudo debootstrap \
  --arch=loong64 \
  --foreign \
  --keyring="${KEYRING}" \
  --variant=minbase \
  trixie \
  "${ROOTFS}" \
  "${MIRROR}"

sudo chroot "${ROOTFS}" /debootstrap/debootstrap --second-stage

sudo tee "${ROOTFS}/etc/apt/sources.list" >/dev/null <<EOF
deb [signed-by=/usr/share/keyrings/debian-loong64-non-official-archive-keyring.gpg] ${MIRROR} trixie main contrib non-free non-free-firmware
EOF
sudo install -m 0644 "${KEYRING}" "${ROOTFS}/usr/share/keyrings/debian-loong64-non-official-archive-keyring.gpg"

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
  sudo tar -C "${ROOTFS}" -c . | podman import --arch loong64 --os linux - "${IMAGE_TAG}"
else
  sudo tar -C "${ROOTFS}" -c . | docker import --platform linux/loong64 - "${IMAGE_TAG}"
fi

echo "Imported ${IMAGE_TAG}"
echo "Run with: podman run --rm --platform linux/loong64 -it ${IMAGE_TAG} /bin/bash"
