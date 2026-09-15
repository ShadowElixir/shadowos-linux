#!/bin/bash
set -euo pipefail

APP_NAME="ABDownloadManager"
INSTALL_DIR="/usr/lib/abdownloadmanager"
BIN_LINK="/usr/bin/abdownloadmanager"
ICON_PATH="${INSTALL_DIR}/lib/${APP_NAME}.png"
DESKTOP_FILE="/usr/share/applications/com.abdownloadmanager.desktop"

TARGET_DIR="/tmp/abdm-build"
mkdir -p "$TARGET_DIR"

REDIRECT_URL=$(curl -sL -o /dev/null --connect-timeout 10 -w "%{url_effective}" "https://github.com/amir1376/ab-download-manager/releases/latest")
TAG_VERSION="${REDIRECT_URL##*/}"

if [ -z "$TAG_VERSION" ] || [ "$TAG_VERSION" = "latest" ]; then
    echo "Error: Network timeout or unable to resolve current release tag metadata."
    exit 1
fi

CLEAN_VERSION="${TAG_VERSION#v}"
DOWNLOAD_URL="https://github.com/amir1376/ab-download-manager/releases/download/${TAG_VERSION}/${APP_NAME}_${CLEAN_VERSION}_linux_x64.tar.gz"
OUTPUT_FILE="${TARGET_DIR}/abdm-latest.tar.gz"

if curl -fL --connect-timeout 10 --retry 3 --retry-delay 2 "$DOWNLOAD_URL" -o "$OUTPUT_FILE"; then
    tar -xzf "$OUTPUT_FILE" -C "$TARGET_DIR"
    rm -rf "$INSTALL_DIR"
    mv "$TARGET_DIR/$APP_NAME" "$INSTALL_DIR"

    ln -sf "${INSTALL_DIR}/bin/${APP_NAME}" "$BIN_LINK"

    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=AB Download Manager
Comment=Manage and organize your download files better than before
GenericName=Downloader
Categories=Utility;Network;
Exec=${BIN_LINK}
Icon=${ICON_PATH}
Terminal=false
Type=Application
StartupWMClass=com-abdownloadmanager-desktop-AppKt
EOF

    rm -rf "$TARGET_DIR"
else
    echo "Error: Failed to fetch the specified tar.gz package from GitHub storage endpoints."
    rm -rf "$TARGET_DIR"
    exit 1
fi
