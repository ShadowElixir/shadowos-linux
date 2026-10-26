#!/bin/bash
set -euo pipefail

DES=("cosmic" "kde" "gnome" "xfce")
GPUS=("base" "nvidia" "nvidia-legacy")
STEAMS=("steam" "nosteam")
CHANNELS=("stable" "beta")

OUT="recipes/variants"
mkdir -p "$OUT"

# ---------- shared helpers ----------
nvidia_pad() {
  case "$1" in
    nvidia)        echo "-nvidia-open" ;;
    nvidia-legacy) echo "-nvidia" ;;
    *)             echo "" ;;
  esac
}

gpu_desc() {
  case "$1" in
    nvidia)        echo "Nvidia " ;;
    nvidia-legacy) echo "Nvidia Legacy " ;;
    *)             echo "" ;;
  esac
}

gpu_suffix() {
  [ "$1" = "base" ] && echo "" || echo "-$1"
}

os_release() {
  echo
  echo "  - type: os-release"
  echo "    properties:"
  echo "      VARIANT_ID: $1"
}

# ---------- bazzite ----------
make_bazzite() {
  local de=$1 gpu=$2 steam=$3 channel=$4

  local de_name="$de"
  [ "$de" = "cosmic" ] && de_name="linux"

  local gnome_pad=""
  [ "$de" != "kde" ] && gnome_pad="-gnome"

  local name="shadowos-${de_name}$(gpu_suffix "$gpu")"
  [ "$steam" = "steam" ] && name="${name}-steam"

  local file="$name" version="stable"
  if [ "$channel" = "beta" ]; then
    file="${name}-beta"
    version="testing"
  fi

  {
    echo "name: ${name}"
    echo "description: Custom Bazzite $(gpu_desc "$gpu")image with ${de^^} (${channel})."
    echo "base-image: ghcr.io/ublue-os/bazzite${gnome_pad}$(nvidia_pad "$gpu")"
    echo "image-version: ${version}"

    if [ "$channel" = "beta" ]; then
      echo "alt-tags:"
      echo "  - beta"
      echo "  - testing"
      echo "  - unstable"
    fi

    echo
    echo "modules:"
    echo "  - from-file: common-${de}.yml"
    echo "  - from-file: common-${steam}.yml"
    os_release "$name"

    if [ "$channel" = "beta" ]; then
      echo "      RELEASE_TYPE: beta"
    fi
  } > "${OUT}/${file}.yml"
}

# ---------- fedora (lite) ----------
make_fedora() {
  local gpu=$1
  local name="shadowos-lite$(gpu_suffix "$gpu")"

  {
    echo "name: ${name}"
    echo "description: Custom Fedora $(gpu_desc "$gpu")lite image."
    echo "base-image: ghcr.io/blue-build/base-images/fedora-base$(nvidia_pad "$gpu")"
    echo "image-version: latest"
    echo
    echo "platforms:"
    echo "  - linux/amd64"
    echo "  - linux/arm64"
    echo
    echo "modules:"
    echo "  - from-file: common-lite.yml"
    os_release "$name"
  } > "${OUT}/${name}.yml"
}

# ---------- generate ----------
for de in "${DES[@]}"; do
  for gpu in "${GPUS[@]}"; do
    for steam in "${STEAMS[@]}"; do
      for channel in "${CHANNELS[@]}"; do
        make_bazzite "$de" "$gpu" "$steam" "$channel"
      done
    done
  done
done

for gpu in "${GPUS[@]}"; do
  make_fedora "$gpu"
done