#!/bin/bash
set -euo pipefail

TARGET_DIR=$(mktemp -d)
trap 'rm -rf "$TARGET_DIR"' EXIT

case "$(uname -m)" in
    x86_64|amd64)  ARCH_SUFFIX="x86_64" ;;
    aarch64|arm64) ARCH_SUFFIX="aarch64" ;;
    *) echo "Error: Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

API_URL="https://api.github.com/repos/ShadowElixir/HeroicGamesLauncher/releases/latest"

DOWNLOAD_URL=$(curl -fsSL --connect-timeout 10 --retry 3 "$API_URL" \
    | grep -oE '"browser_download_url": *"[^"]+"' \
    | grep -oE 'https://[^"]+' \
    | grep -E "linux-${ARCH_SUFFIX}\.rpm$" \
    | head -n1 || true)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: No ${ARCH_SUFFIX} RPM found in the latest release."
    exit 1
fi

OUTPUT_FILE="${TARGET_DIR}/heroic-latest.rpm"
curl -fL --connect-timeout 10 --retry 3 --retry-delay 2 "$DOWNLOAD_URL" -o "$OUTPUT_FILE"
dnf install -y "$OUTPUT_FILE"
