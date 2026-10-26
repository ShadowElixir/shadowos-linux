#!/bin/bash
set -euo pipefail

TARGET_DIR="/tmp/heroic-build"
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

REDIRECT_URL=$(curl -sL -o /dev/null --connect-timeout 10 -w "%{url_effective}" "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest")
TAG_VERSION="${REDIRECT_URL##*/}"

if [ -z "$TAG_VERSION" ] || [ "$TAG_VERSION" = "latest" ]; then
    echo "Error: Network timeout or unable to resolve current release tag metadata."
    exit 1
fi

CLEAN_VERSION="${TAG_VERSION#v}"
DOWNLOAD_URL="https://github.com/ShadowElixir/HeroicGamesLauncher/releases/latest/download/Heroic-${CLEAN_VERSION}-linux-${ARCH_SUFFIX}.rpm"
OUTPUT_FILE="${TARGET_DIR}/heroic-latest.rpm"

if curl -fL --connect-timeout 10 --retry 3 --retry-delay 2 "$DOWNLOAD_URL" -o "$OUTPUT_FILE"; then
    dnf install -y "$OUTPUT_FILE"
    rm -rf "$TARGET_DIR"
else
    echo "Error: Failed to fetch the specified RPM binary package from GitHub storage endpoints."
    rm -rf "$TARGET_DIR"
    exit 1
fi