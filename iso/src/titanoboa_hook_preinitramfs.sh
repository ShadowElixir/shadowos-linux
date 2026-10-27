#!/usr/bin/env bash
#
# Bazzite-based images only (see build.sh).
#
# Swap the Bazzite kernel for the stock Fedora one and rebuild the initramfs,
# because the live ISO needs a kernel that is signed for Secure Boot.
# This only affects the live environment: the installed system comes from the
# published image and keeps its own kernel.
set -exo pipefail

kernel_pkgs=(
    kernel
    kernel-core
    kernel-devel
    kernel-devel-matched
    kernel-modules
    kernel-modules-core
    kernel-modules-extra
)

dnf -y versionlock delete "${kernel_pkgs[@]}" || :
dnf --setopt=protect_running_kernel=False -y remove "${kernel_pkgs[@]}"
(cd /usr/lib/modules && rm -rf -- ./*)
dnf -y --repo fedora,updates --setopt=tsflags=noscripts --setopt=disable_excludes=* install kernel kernel-core
kernel=$(find /usr/lib/modules -maxdepth 1 -mindepth 1 -type d -printf '%P\n' | grep .)
depmod "$kernel"

# Include nvidia-gpu-firmware package.
dnf install -yq nvidia-gpu-firmware || :
dnf clean all -yq
