#!/usr/bin/env bash
# Adds legacy BIOS (CSM) boot to an ISO built by Titanoboa, which is UEFI-only.
#
# Titanoboa already writes /boot/grub2/grub.cfg into the ISO. This script adds GRUB's BIOS
# modules plus a BIOS El Torito boot image (and a hybrid MBR for USB sticks), keeping the
# existing UEFI boot partition. GRUB comes from this machine (Ubuntu runner), not from the image.
#
# Usage: add-bios-boot.sh <iso>
set -euo pipefail

ISO="${1:?usage: add-bios-boot.sh <iso>}"
GRUB_DIR=/usr/lib/grub/i386-pc
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO=sudo
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq xorriso grub-pc-bin grub-common

xorriso -indev "$ISO" -find /boot/grub2/grub.cfg -name grub.cfg 2>/dev/null | grep -q grub.cfg || {
    echo "ERROR: /boot/grub2/grub.cfg is missing from the ISO" >&2
    exit 1
}

# GRUB core image + CD boot sector = El Torito BIOS boot image
mkdir -p "$WORK/bios"
cp -a "$GRUB_DIR" "$WORK/bios/i386-pc"
grub-mkimage -O i386-pc -o "$WORK/core.img" -p /boot/grub2 -d "$GRUB_DIR" \
    biosdisk iso9660 part_gpt part_msdos search search_label configfile normal linux echo test
cat "$GRUB_DIR/cdboot.img" "$WORK/core.img" >"$WORK/bios/i386-pc/eltorito.img"

# xorriso drops the appended UEFI partition when it rewrites an ISO, so pull it out and add it back
read -r ESP_START ESP_SECTORS < <(python3 - "$ISO" <<'PY'
import struct, sys, uuid

ESP = uuid.UUID("C12A7328-F81F-11D2-BA4B-00A0C93EC93B")
with open(sys.argv[1], "rb") as f:
    f.seek(512)
    hdr = f.read(92)
    if hdr[:8] != b"EFI PART":
        sys.exit("no GPT header found in the ISO")
    entries_lba, count, size = struct.unpack_from("<QII", hdr, 72)
    f.seek(entries_lba * 512)
    for _ in range(count):
        e = f.read(size)
        if uuid.UUID(bytes_le=e[:16]) == ESP:
            first, last = struct.unpack_from("<QQ", e, 32)
            print(first, last - first + 1)
            sys.exit(0)
sys.exit("no EFI System Partition found in the ISO")
PY
)
dd if="$ISO" of="$WORK/esp.img" bs=512 skip="$ESP_START" count="$ESP_SECTORS" status=none

xorriso -indev "$ISO" -outdev "$ISO.bios" \
    -map "$WORK/bios/i386-pc" /boot/grub2/i386-pc \
    -boot_image any discard \
    -boot_image any partition_offset=16 \
    -boot_image any appended_part_as=gpt \
    -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B "$WORK/esp.img" \
    -boot_image any iso_mbr_part_type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7 \
    -boot_image grub grub2_mbr="$GRUB_DIR/boot_hybrid.img" \
    -boot_image any bin_path=/boot/grub2/i386-pc/eltorito.img \
    -boot_image any emul_type=no_emulation \
    -boot_image any boot_info_table=on \
    -boot_image grub grub2_boot_info=on \
    -boot_image any cat_path=/boot/grub2/boot.cat \
    -boot_image any next \
    -boot_image any efi_path=--interval:appended_partition_2:all:: \
    -boot_image any emul_type=no_emulation \
    -commit

# Make sure both boot entries made it in before replacing the original
REPORT="$(xorriso -indev "$ISO.bios" -report_el_torito plain 2>/dev/null)"
grep -q "BIOS" <<<"$REPORT" && grep -q "UEFI" <<<"$REPORT" || {
    echo "ERROR: rebuilt ISO is missing a BIOS or UEFI boot entry" >&2
    echo "$REPORT" >&2
    exit 1
}

mv -f "$ISO.bios" "$ISO"
echo "Legacy BIOS boot added to $ISO"