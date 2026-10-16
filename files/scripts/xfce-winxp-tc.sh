#!/usr/bin/env bash
set -oue pipefail

git clone --depth=1 --single-branch https://github.com/rozniak/xfce-winxp-tc.git /tmp/xfce-winxp-tc
cd /tmp/xfce-winxp-tc

PLYMOUTH_CMAKE="base/bootvid/plymouth.cmake"
if [ -f "$PLYMOUTH_CMAKE" ]; then
    awk '
    /# Pick sources based on SKU/ {
        print "# Pick sources based on SKU (Hardcoded XP Pro)"
        print "set(PLYMOUTH_THEME_NAME whistler)"
        print "set(PLYMOUTH_IMAGE_SPLASH splshclt.png)"
        print "set(PLYMOUTH_IMAGE_CHUNKS chunkpro.png)"
        print "set(PLYMOUTH_IMAGE_SKU skupro.png)"
        skip = 1; next
    }
    skip {
        if ($0 ~ /^endif\(\)/) { skip = 0; next }
        next
    }
    { print }
    ' "$PLYMOUTH_CMAKE" > "$PLYMOUTH_CMAKE.tmp" && mv "$PLYMOUTH_CMAKE.tmp" "$PLYMOUTH_CMAKE"
fi

DESKTOP_VIEW_FILE="shared/shell/src/vwdesk.c"
if [ -f "$DESKTOP_VIEW_FILE" ]; then
    awk '
    /for \(gulong i = 0; i < G_N_ELEMENTS\(S_DESKTOP_ITEMS\); i\+\+\)/,/^    \}/ {
        if ($0 ~ /for \(/) {
            print "    /* Skipping static item registration"
        }
        print $0
        if ($0 ~ /^    \}/) {
            print "    */"
            next
        }
        next
    }
    { print }
    ' "$DESKTOP_VIEW_FILE" > "$DESKTOP_VIEW_FILE.tmp" && mv "$DESKTOP_VIEW_FILE.tmp" "$DESKTOP_VIEW_FILE"
fi

DESKTOP_WINDOW_FILE="shell/desktop/src/window.c"
if [ -f "$DESKTOP_WINDOW_FILE" ]; then
    sed -i '/\/\/ Rough watermark drawing/,/if (wnd->shext_host)/ {
        s/if (wnd->shext_host)/if (0 \&\& wnd->shext_host)/
    }' "$DESKTOP_WINDOW_FILE"
fi

CLOCK_FILE="shell/taskband/src/systray/clock.c"
if [ -f "$CLOCK_FILE" ]; then
    awk '
    /g_date_time_format\(time, "%H:%M"\)/ {
        sub(/g_date_time_format\(time, "%H:%M"\)/, "g_date_time_format(time, \"%b %-e, %-l:%M %p\")")
    }
    { print }
    ' "$CLOCK_FILE" > "$CLOCK_FILE.tmp" && mv "$CLOCK_FILE.tmp" "$CLOCK_FILE"
fi

cd packaging
dnf install -y --setopt=disable_excludes=* $(./chkdeps.sh -l | cut -d':' -f2 | tr '\n' ' ')
./buildall.sh
cd xptc
find . -name "*.rpm" -exec dnf install -y {} +

if [ -f /etc/lightdm/lightdm.conf ]; then
    sed -i 's/^#greeter-session=.*/greeter-session=wintc-logonui/' /etc/lightdm/lightdm.conf
fi

plymouth-set-default-theme bootvid
rm -rf /tmp/xfce-winxp-tc
