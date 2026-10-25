#!/usr/bin/env bash
set -euo pipefail

APPS_TO_HIDE=(
    "qt5ct"
    "qt6ct"
    "bazzite-documentation"
    "discourse"
    "waydroid-container-restart"
    "com.gerbilsoft.rom-properties.rp-config"
    "org.gnome.Yelp"
    "scrcpy-console"
    "btop"
    "htop"
    "nvtop"
    "yad-icon-browser"
)

for app in "${APPS_TO_HIDE[@]}"; do
    FILE="/usr/share/applications/${app}.desktop"
    
    if [ -f "$FILE" ]; then
        if grep -q "^NoDisplay=" "$FILE"; then
            echo "Updating existing NoDisplay for: $app"
            sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$FILE"
        
        else
            echo "Hiding: $app (adding new entry)"
            sed -i '/\[Desktop Entry\]/a NoDisplay=true' "$FILE"
        fi
    else
        echo "Skipping: $app (not installed)"
    fi
done

if [ -f "/etc/skel/.config/autostart/steam.desktop" ]; then
    echo "Removing Steam autostart..."
    rm -f "/etc/skel/.config/autostart/steam.desktop"
fi

if [ -f "/etc/xdg/autostart/com.system76.CosmicInitialSetup.desktop" ]; then
    echo "Removing COSMIC Initial Setup autostart..."
    rm -f "/etc/xdg/autostart/com.system76.CosmicInitialSetup.desktop"
fi
