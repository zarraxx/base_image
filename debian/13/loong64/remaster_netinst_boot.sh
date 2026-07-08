#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WORK_DIR="${WORK_DIR:-${TMPDIR:-/tmp}/loong64-netinst-remaster}"
ESP_BLOCKS="${ESP_BLOCKS:-14336}"
VOLID="${VOLID:-}"

usage() {
  cat <<'EOF'
Remaster a Debian loong64 netinst ISO with a GPT ESP boot layout.

Usage:
  remaster_netinst_boot.sh INPUT.iso [OUTPUT.iso]

Environment:
  WORK_DIR     Temporary work directory. Default: /tmp/loong64-netinst-remaster
  ESP_BLOCKS  FAT16 ESP size in 1 KiB blocks. Default: 14336
  VOLID       Override ISO volume id. Default: read from input ISO

The script keeps the Debian installer content unchanged, but rebuilds the
boot shell with:
  - a FAT16 ESP of at least 14 MiB
  - BOOTLOONGARCH64.EFI and BOOTLOONGARCH.EFI fallback filenames
  - GPT entries for the ISO and appended ESP
  - a protective MBR label
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage >&2
  exit 2
fi

require_cmd xorriso
require_cmd mkfs.msdos
require_cmd mmd
require_cmd mcopy

INPUT_ISO=$1
OUTPUT_ISO=${2:-}

[ -f "${INPUT_ISO}" ] || die "input ISO not found: ${INPUT_ISO}"

if [ -z "${OUTPUT_ISO}" ]; then
  base=${INPUT_ISO##*/}
  OUTPUT_ISO="${PWD}/${base%.iso}-gpt-esp-uppercase.iso"
fi

if [ -z "${VOLID}" ]; then
  VOLID=$(xorriso -indev "${INPUT_ISO}" -pvd_info 2>/dev/null |
    sed -n "s/^Volume [Ii]d[[:space:]]*:[[:space:]]*'\\(.*\\)'/\\1/p; s/^Volume [Ii]d[[:space:]]*:[[:space:]]*\\(.*\\)/\\1/p" |
    head -n1)
fi
[ -n "${VOLID}" ] || VOLID="Debian loong64 netinst"

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/tree"

echo "Extracting ISO: ${INPUT_ISO}"
xorriso -osirrox on -indev "${INPUT_ISO}" -extract / "${WORK_DIR}/tree" >/dev/null
chmod -R u+w "${WORK_DIR}/tree"

EFI_DIR="${WORK_DIR}/tree/EFI/BOOT"
mkdir -p "${EFI_DIR}"

efi_source=
for candidate in \
  "${WORK_DIR}/tree/EFI/boot/bootloongarch64.efi" \
  "${WORK_DIR}/tree/EFI/BOOT/bootloongarch64.efi" \
  "${WORK_DIR}/tree/EFI/BOOT/BOOTLOONGARCH64.EFI" \
  "${WORK_DIR}/tree/EFI/BOOT/BOOTLOONGARCH.EFI"; do
  if [ -f "${candidate}" ]; then
    efi_source=${candidate}
    break
  fi
done

[ -n "${efi_source}" ] || die "LoongArch EFI binary was not found in ISO tree"

cp -f "${efi_source}" "${EFI_DIR}/BOOTLOONGARCH64.EFI"
cp -f "${efi_source}" "${EFI_DIR}/BOOTLOONGARCH.EFI"
rm -f "${EFI_DIR}/bootloongarch64.efi" "${WORK_DIR}/tree/EFI/boot/bootloongarch64.efi"
rmdir "${WORK_DIR}/tree/EFI/boot" 2>/dev/null || true

ESP_IMG="${WORK_DIR}/efi.img"
rm -f "${ESP_IMG}"
echo "Creating FAT16 ESP: ${ESP_BLOCKS} KiB"
mkfs.msdos --invariant -F 16 -i deb00001 -C "${ESP_IMG}" "${ESP_BLOCKS}" >/dev/null
mmd -i "${ESP_IMG}" ::EFI
mmd -i "${ESP_IMG}" ::EFI/BOOT
mcopy -o -i "${ESP_IMG}" "${EFI_DIR}/BOOTLOONGARCH64.EFI" "::EFI/BOOT/"
mcopy -o -i "${ESP_IMG}" "${EFI_DIR}/BOOTLOONGARCH.EFI" "::EFI/BOOT/"

mkdir -p "${WORK_DIR}/tree/boot/grub"
cp -f "${ESP_IMG}" "${WORK_DIR}/tree/boot/grub/efi.img"

echo "Writing remastered ISO: ${OUTPUT_ISO}"
xorriso -as mkisofs \
  -r -J -joliet-long -cache-inodes -l \
  -V "${VOLID}" \
  -o "${OUTPUT_ISO}" \
  -e boot/grub/efi.img -no-emul-boot \
  -append_partition 2 0xef "${ESP_IMG}" \
  -appended_part_as_gpt --protective-msdos-label \
  -partition_cyl_align off \
  "${WORK_DIR}/tree" >/dev/null

echo "Done: ${OUTPUT_ISO}"
