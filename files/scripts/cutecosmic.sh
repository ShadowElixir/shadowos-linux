#!/bin/bash
set -euo pipefail

TARGET_DIR="/tmp/cutecosmic-build"
mkdir -p "$TARGET_DIR"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        ARCH_SUFFIX="x86_64"
        ;;
    aarch64|arm64)
        ARCH_SUFFIX="aarch64"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://github.com/ShadowElixir/cutecosmic/releases/latest/download/cutecosmic-qt6.${ARCH_SUFFIX}.rpm"
OUTPUT_FILE="${TARGET_DIR}/cutecosmic-latest.rpm"

if curl -fL --connect-timeout 10 --retry 3 --retry-delay 2 "$DOWNLOAD_URL" -o "$OUTPUT_FILE"; then
    dnf install -y "$OUTPUT_FILE"
    rm -rf "$TARGET_DIR"
else
    echo "Error: Failed to fetch the CuteCosmic RPM from GitHub releases."
    rm -rf "$TARGET_DIR"
    exit 1
fi