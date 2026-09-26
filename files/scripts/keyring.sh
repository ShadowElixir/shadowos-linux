#!/usr/bin/env bash
set -euo pipefail

KEYRING_DESKTOP="/etc/xdg/autostart/gnome-keyring-ssh.desktop"

if [ -f "$KEYRING_DESKTOP" ]; then
    echo "Removing OnlyShowIn restriction from gnome-keyring-ssh.desktop..."
    sed -i '/^OnlyShowIn=/d' "$KEYRING_DESKTOP"
else
    echo "Skipping: gnome-keyring-ssh.desktop not found"
fi
