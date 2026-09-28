#!/usr/bin/env bash
# Appends mozilla-gnome-theme-update to systemUpdateCommand in /etc/bazzite-updater/config.ini

set -euo pipefail

CONFIG="/etc/bazzite-updater/config.ini"
APPEND=" \&\& /usr/libexec/topgrade/mozilla-gnome-theme-update"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: $CONFIG not found" >&2
    exit 1
fi

# Check if already patched
if grep -qP "^systemUpdateCommand=.*mozilla-gnome-theme-update" "$CONFIG"; then
    echo "Already patched, skipping."
    exit 0
fi

# Append to the systemUpdateCommand line
if grep -qP "^systemUpdateCommand=" "$CONFIG"; then
    sed -i "s#^\(systemUpdateCommand=.*\)#\1${APPEND}#" "$CONFIG"
    echo "Patched systemUpdateCommand in $CONFIG"
else
    echo "ERROR: systemUpdateCommand not found in $CONFIG" >&2
    exit 1
fi
