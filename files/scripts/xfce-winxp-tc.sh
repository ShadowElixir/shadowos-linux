#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

REPO_DIR=/tmp/xfce-winxp-tc

git clone --depth=1 --single-branch https://github.com/rozniak/xfce-winxp-tc.git "$REPO_DIR"
cd "$REPO_DIR"

PLYMOUTH_CMAKE="base/bootvid/plymouth.cmake"
DESKTOP_VIEW_FILE="shared/shell/src/vwdesk.c"
DESKTOP_WINDOW_FILE="shell/desktop/src/window.c"
CLOCK_FILE="shell/taskband/src/systray/clock.c"

# Check if files exist
for f in "$PLYMOUTH_CMAKE" "$DESKTOP_VIEW_FILE" "$DESKTOP_WINDOW_FILE" "$CLOCK_FILE"; do
    [ -f "$f" ] || die "Missing expected file: $f"
done

# --- Plymouth: hardcode XP Pro splash ---
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
grep -q 'Hardcoded XP Pro' "$PLYMOUTH_CMAKE" || die "Plymouth patch did not apply"
grep -q 'WINTC_SKU' "$PLYMOUTH_CMAKE" && die "Plymouth patch left SKU logic behind"

# --- Desktop icons: skip static item registration ---
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
grep -q 'Skipping static item registration' "$DESKTOP_VIEW_FILE" || die "Desktop items patch did not apply"
[ "$(grep -c 'Skipping static item registration' "$DESKTOP_VIEW_FILE")" -eq 1 ] || die "Desktop items patch applied more than once"
grep -q '^    \*/$' "$DESKTOP_VIEW_FILE" || die "Desktop items patch has no closing comment"

# --- Desktop watermark ---
sed -i '/\/\/ Rough watermark drawing/,/if (wnd->is_primary)/ {
    s/if (wnd->is_primary)/if (0 \&\& wnd->is_primary)/
}' "$DESKTOP_WINDOW_FILE"
grep -q 'if (0 && wnd->is_primary)' "$DESKTOP_WINDOW_FILE" || die "Watermark patch did not apply"

# --- Clock format ---
awk '
/g_date_time_format\(time, "%H:%M"\)/ {
    sub(/g_date_time_format\(time, "%H:%M"\)/, "g_date_time_format(time, \"%b %-e, %-l:%M %p\")")
}
{ print }
' "$CLOCK_FILE" > "$CLOCK_FILE.tmp" && mv "$CLOCK_FILE.tmp" "$CLOCK_FILE"
grep -q '%b %-e, %-l:%M %p' "$CLOCK_FILE" || die "Clock patch did not apply"

# --- Build and install ---
cd packaging

DEPS=$(./chkdeps.sh -l | cut -d':' -f2 | tr '\n' ' ')
[ -n "${DEPS// /}" ] || die "chkdeps.sh returned no dependencies"
dnf install -y --setopt=disable_excludes=* $DEPS

./buildall.sh

cd xptc
mapfile -t RPMS < <(find . -name "*.rpm")
[ "${#RPMS[@]}" -gt 0 ] || die "buildall.sh produced no RPMs"
dnf install -y "${RPMS[@]}"

# --- LightDM greeter ---
[ -f /etc/lightdm/lightdm.conf ] || die "/etc/lightdm/lightdm.conf not found"
sed -i 's/^#greeter-session=.*/greeter-session=wintc-logonui/' /etc/lightdm/lightdm.conf
grep -q '^greeter-session=wintc-logonui' /etc/lightdm/lightdm.conf || die "greeter-session was not set"

# --- Plymouth theme ---
plymouth-set-default-theme bootvid
[ "$(plymouth-set-default-theme)" = "bootvid" ] || die "Plymouth theme was not set to bootvid"

rm -rf "$REPO_DIR"
echo "XP theme build complete"
