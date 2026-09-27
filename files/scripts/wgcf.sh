#!/bin/bash
set -euo pipefail

TARGET="/usr/bin/wgcf"

REDIRECT_URL=$(curl -sL -o /dev/null --connect-timeout 10 -w "%{url_effective}" "https://github.com/ViRb3/wgcf/releases/latest")
TAG_VERSION="${REDIRECT_URL##*/}"

if [ -z "$TAG_VERSION" ] || [ "$TAG_VERSION" = "latest" ]; then
    echo "Error: Unable to resolve latest wgcf release tag."
    exit 1
fi

CLEAN_VERSION="${TAG_VERSION#v}"
DOWNLOAD_URL="https://github.com/ViRb3/wgcf/releases/download/${TAG_VERSION}/wgcf_${CLEAN_VERSION}_linux_amd64"

echo "Downloading wgcf ${TAG_VERSION}..."
if curl -fL --connect-timeout 10 --retry 3 --retry-delay 2 "$DOWNLOAD_URL" -o "$TARGET"; then
    chmod +x "$TARGET"
    echo "wgcf ${TAG_VERSION} installed to ${TARGET}."
else
    echo "Error: Failed to download wgcf from GitHub."
    exit 1
fi