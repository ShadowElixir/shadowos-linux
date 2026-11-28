#!/bin/bash
set -euo pipefail

TARGET_DIR=$(mktemp -d)
trap 'rm -rf "$TARGET_DIR"' EXIT

case "$(uname -m)" in
    x86_64|amd64)  ARCH_SUFFIX="x86_64" ;;
    aarch64|arm64) ARCH_SUFFIX="aarch64" ;;
    *) echo "Error: Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

REPO="https://github.com/ShadowElixir/HeroicGamesLauncher"

TAG_URL=$(curl -fsSL --connect-timeout 10 --retry 3 -o /dev/null -w '%{url_effective}' "${REPO}/releases/latest")
TAG="${TAG_URL##*/}"

if [ -z "$TAG" ] || [ "$TAG" = "latest" ]; then
    echo "Error: Could not resolve the latest release."
    exit 1
fi

REL_PATH=$(curl -fsSL --connect-timeout 10 --retry 3 "${REPO}/releases/expanded_assets/${TAG}" \
    | grep -oE 'href="[^"]+linux-'"${ARCH_SUFFIX}"'\.rpm"' \
    | head -n1 | cut -d'"' -f2 || true)
DOWNLOAD_URL="${REL_PATH:+https://github.com${REL_PATH}}"

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: No ${ARCH_SUFFIX} RPM found in the latest release."
    exit 1
fi

OUTPUT_FILE="${TARGET_DIR}/heroic-latest.rpm"
curl -fL --connect-timeout 10 --retry 3 --retry-delay 2 "$DOWNLOAD_URL" -o "$OUTPUT_FILE"
dnf install -y "$OUTPUT_FILE"
