#!/usr/bin/env bash
set -oue pipefail

mkdir -p /tmp/win7theme/
cd /tmp/win7theme/

# fonts (script by github.com/winblues)
git clone --depth=1 --single-branch https://github.com/mrbvrz/segoe-ui-linux
mkdir -p /usr/share/fonts/Microsoft/TrueType/SegoeUI/
mv segoe-ui-linux/font/* /usr/share/fonts/Microsoft/TrueType/SegoeUI
fc-cache -f /usr/share/fonts/Microsoft/TrueType/SegoeUI/

# plymouth
git clone --depth=1 --single-branch https://github.com/furkrn/PlymouthVista
cd PlymouthVista

bash compile.sh

## force it to use windows 7 theme
bash pv_conf.sh -s UseLegacyBootScreen -v 0
bash pv_conf.sh -s UseShadow -v 1
bash pv_conf.sh -s AuthuiStyle -v 7
bash pv_conf.sh -s Pref -v 2

bash gen_blur.sh
bash install.sh -s -n -o -q
plymouth-set-default-theme PlymouthVista

## fixes copyright symbol
mkdir -p /etc/dracut.conf.d/
echo 'omit_dracutmodules+=" plymouth "' > /etc/dracut.conf.d/omit-plymouth.conf

cd ..

# theme
## theme dependencies
dnf install -y gcc gcc-c++ cmake make extra-cmake-modules plasma-workspace-devel libksysguard-devel unzip kvantum qt6-qtmultimedia-devel qt6-qt5compat-devel libplasma-devel qt6-qtbase-devel qt6-qtwayland-devel plasma-activities-devel kf6-kpackage-devel kf6-kglobalaccel-devel qt6-qtsvg-devel wayland-devel plasma-wayland-protocols kf6-ksvg-devel kf6-kcrash-devel kf6-kguiaddons-devel kf6-kcmutils-devel kf6-kio-devel kdecoration-devel kf6-ki18n-devel kf6-knotifications-devel kf6-kirigami-devel kf6-kiconthemes-devel gmp-ecm-devel kf5-plasma-devel libepoxy-devel kwin-devel kf6-karchive kf6-karchive-devel plasma-wayland-protocols-devel qt6-qtbase-private-devel qt6-qtbase-devel kf6-knewstuff-devel kf6-knotifyconfig-devel kf6-attica-devel kf6-krunner-devel kf6-kdbusaddons-devel kf6-sonnet-devel plasma5support-devel plasma-activities-stats-devel polkit-qt6-1-devel qt-devel libdrm-devel kf6-kitemmodels-devel kf6-kstatusnotifieritem-devel kf6-frameworkintegration-devel wayland-protocols-devel kscreenlocker-devel ninja-build --setopt=disable_excludes=*

git clone --single-branch https://gitgud.io/aeroshell/atp/aerothemeplasma.git aerothemeplasma
cd aerothemeplasma

## fake sudo
function sudo() { "$@"; }
export -f sudo

CMAKE_GENERATOR=Ninja LIBEXEC_DIR=libexec UAC_LIBEXEC_DIR=libexec/kf6 bash install.sh --skip-x11

cd ..

# execbin
git clone --depth=1 --single-branch https://gitgud.io/catpswin56/execbin
cd execbin
bash install.sh --ninja
bash add_rule.sh
cd ..

## removing fake sudo
unset -f sudo

# gtk theme
git clone --depth=1 --single-branch https://gitgud.io/Gamer95875/Windows-7-Better /etc/skel/.themes/Windows-7-Better
ln -s ../.themes/Windows-7-Better/gtk-4.0 /etc/skel/.config/gtk-4.0
chmod +x /usr/libexec/topgrade/windows-7-gtk-theme-update
echo '"Windows 7 GTK Theme" = "/usr/libexec/topgrade/windows-7-gtk-theme-update"' >> /etc/ublue-os/topgrade.toml

CONFIG="/etc/bazzite-updater/config.ini"
APPEND=" \&\& /usr/libexec/topgrade/windows-7-gtk-theme-update"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: $CONFIG not found" >&2
    exit 1
fi

if grep -qP "^systemUpdateCommand=.*windows-7-gtk-theme-update" "$CONFIG"; then
    echo "Already patched, skipping."
    exit 0
fi

if grep -qP "^systemUpdateCommand=" "$CONFIG"; then
    sed -i "s#^\(systemUpdateCommand=.*\)#\1${APPEND}#" "$CONFIG"
    echo "Patched systemUpdateCommand in $CONFIG"
else
    echo "ERROR: systemUpdateCommand not found in $CONFIG" >&2
    exit 1
fi

rm -rf /tmp/win7theme
