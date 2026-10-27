#!/usr/bin/bash
#
# Runs inside the live-image build (see ../Containerfile).
# Adds everything Titanoboa expects from a bootable container:
# a live-capable initramfs, a live user session, Anaconda, the flatpaks,
# the EFI files and /usr/lib/bootc-image-builder/iso.yaml.
#
# Inputs (environment, set by the Containerfile ARGs):
#   IMAGE_REF  registry reference of the payload, e.g. ghcr.io/shadowelixir/shadowos-gnome
#   IMAGE_TAG  latest | beta
#   FLAVOR     bazzite | lite
#   DESKTOP    cosmic | kde | gnome | xfce | lite
#   NVIDIA     true | false
set -exo pipefail

{ export PS4='+( ${BASH_SOURCE}:${LINENO} ): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; } 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${IMAGE_REF:?}" "${IMAGE_TAG:?}" "${FLAVOR:?}" "${DESKTOP:?}"
NVIDIA="${NVIDIA:-false}"
ARCH="$(uname -m)"
export IMAGE_REF IMAGE_TAG FLAVOR DESKTOP NVIDIA ARCH

# Create the directory that /root is symlinked to
mkdir -p "$(realpath /root)"

# bwrap tries to write /proc/sys/user/max_user_namespaces which is mounted as ro
# so we need to remount it as rw
mount -o remount,rw /proc/sys

# ---------------------------------------------------------------- flatpaks
mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo

if [ -s "$SCRIPT_DIR/flatpaks" ]; then
    while IFS= read -r ref; do
        [ -n "$ref" ] || continue
        if ! flatpak install -y --noninteractive "$ref"; then
            # Not every app is published for aarch64, skip those instead of failing
            if [ "$ARCH" = "aarch64" ]; then
                echo "::warning::Skipping $ref (not installable on $ARCH)"
            else
                echo "::error::Failed to install flatpak $ref"
                exit 1
            fi
        fi
    done <"$SCRIPT_DIR/flatpaks"
fi

# ----------------------------------------------- payload for the installer
# Anaconda installs this image from the live system's container storage.
# Lite images may not ship podman, and we need it here.
command -v podman >/dev/null || dnf install -y podman

if mountpoint -q /usr/lib/containers/storage; then
    # The host's container storage is mounted read-only (see ../Containerfile),
    # so copy the image from there instead of downloading it a second time.
    podman save --format oci-archive "${IMAGE_REF}:${IMAGE_TAG}" | podman load --storage-opt additionalimagestore=''
else
    tries=0
    until podman pull "${IMAGE_REF}:${IMAGE_TAG}"; do
        tries=$((tries + 1))
        [ "$tries" -ge 5 ] && exit 1
        sleep 20
    done
fi

# ---------------------------------------------------------- kernel/initramfs
if [ "$FLAVOR" = "bazzite" ]; then
    bash "$SCRIPT_DIR/titanoboa_hook_preinitramfs.sh"
fi

dnf install -y dracut-live

# Titanoboa expects exactly one kernel in /usr/lib/modules
kernels=$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
if [ "$(echo "$kernels" | wc -l)" -ne 1 ] || [ -z "$kernels" ]; then
    echo "::error::Expected exactly one kernel in /usr/lib/modules, found: $kernels"
    exit 1
fi
kernel="$kernels"

DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# Ensure vmlinuz is located at /usr/lib/modules/${kernel}/vmlinuz as required by Titanoboa
if [ ! -f "/usr/lib/modules/${kernel}/vmlinuz" ]; then
    found_vmlinuz=$(find /boot -name "vmlinuz-${kernel}" -o -name "vmlinuz" | head -n 1)
    if [ -z "$found_vmlinuz" ]; then
        found_vmlinuz=$(find /lib/modules/${kernel} -name "vmlinuz" | head -n 1)
    fi
    if [ -n "$found_vmlinuz" ]; then
        cp -v "$found_vmlinuz" "/usr/lib/modules/${kernel}/vmlinuz"
    else
        echo "::error::Could not find vmlinuz for kernel ${kernel}"
        exit 1
    fi
fi

# Safeguard: Ensure a clean, single symlink/fallback directory exists so the wildcard '*' never misses
mkdir -p /usr/lib/modules/default
ln -sf "/usr/lib/modules/${kernel}/initramfs.img" /usr/lib/modules/default/initramfs.img
ln -sf "/usr/lib/modules/${kernel}/vmlinuz" /usr/lib/modules/default/vmlinuz

# ----------------------------------------------------------- live session
dnf install -y livesys-scripts

# Must match /usr/libexec/livesys/sessions.d/livesys-<session>
case "$DESKTOP" in
cosmic | kde | gnome | xfce) livesys_session="$DESKTOP" ;;
lite) livesys_session="lxqt" ;;
*)
    echo "::error::Unknown DESKTOP: $DESKTOP"
    exit 1
    ;;
esac

if [ -e "/usr/libexec/livesys/sessions.d/livesys-$livesys_session" ]; then
    sed -i "s/^livesys_session=.*/livesys_session=$livesys_session/" /etc/sysconfig/livesys
elif [ "$DESKTOP" = "lite" ]; then
    echo "::warning::livesys-scripts has no '$livesys_session' session, relying on the LightDM autologin fallback"
else
    echo "::error::livesys-scripts has no '$livesys_session' session"
    exit 1
fi
systemctl enable livesys.service livesys-late.service

if [ "$DESKTOP" = "lite" ]; then
    # Log the live user straight into LXQt (X11) and put the installer on the desktop
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat >/etc/lightdm/lightdm.conf.d/60-liveuser.conf <<'LIGHTDM'
[Seat:*]
autologin-user=liveuser
autologin-user-timeout=0
autologin-session=lxqt
LIGHTDM
    mkdir -p /etc/skel/Desktop
    cp /usr/share/applications/liveinst.desktop /etc/skel/Desktop/ 2>/dev/null || :
fi

# --------------------------------------------------------------- installer
bash "$SCRIPT_DIR/titanoboa_hook_postrootfs.sh"

# ------------------------------------------------------------------ EFI
# Titanoboa needs the grub EFI binaries and expects the EFI dir in /boot/efi
if [ "$ARCH" = "x86_64" ]; then
    dnf install -y grub2-efi-x64-cdboot
elif [ "$ARCH" = "aarch64" ]; then
    dnf install -y grub2-efi-aa64-modules
fi

mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/

# Remove fallback efi
if [ "$ARCH" = "x86_64" ]; then
    cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi
elif [ "$ARCH" = "aarch64" ]; then
    cp -v /boot/efi/EFI/fedora/grubaa64.efi /boot/efi/EFI/BOOT/fbaa64.efi
fi

# ----------------------------------------------------------------- misc
# Set the timezone to UTC
rm -f /etc/localtime
systemd-firstboot --timezone UTC

# / in a booted live ISO is an overlayfs with upperdir pointed somewhere under /run
# This means that /var/tmp is also technically under /run.
# /run is of course a tmpfs, but set with quite a small size.
# ostree needs quite a lot of space on /var/tmp for temporary files so /run is not enough.
# Mount a larger tmpfs to /var/tmp at boot time to avoid this issue.
mkdir -p /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'UNIT'
[Unit]
Description=Larger tmpfs for /var/tmp on live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m,x-systemd.graceful-option=usrquota

[Install]
WantedBy=local-fs.target
UNIT
systemctl enable var-tmp.mount

# Mount /var/lib/flatpak as readonly.
# This is in order to ensure the files dont get tainted when installing them in disk.
cat >/etc/systemd/system/var-lib-flatpak.mount <<'UNIT'
[Mount]
Type=none
What=/var/lib/flatpak
Where=/var/lib/flatpak
Options=bind,ro

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable var-lib-flatpak.mount

# Copy in the iso config for Titanoboa (and the path the newer image-builder contract uses)
mkdir -p /usr/lib/bootc-image-builder /usr/lib/image-builder/bootc
cp "$SCRIPT_DIR/iso.yaml" /usr/lib/bootc-image-builder/iso.yaml
cp "$SCRIPT_DIR/iso.yaml" /usr/lib/image-builder/bootc/iso.yaml
