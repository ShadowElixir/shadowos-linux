<p align="center">
    <img src="files/system/usr/share/pixmaps/fedora_whitelogo.svg" 
         alt="ShadowOS" 
         style="height: 140px; width: auto;" />
</p>

<p align="center">
  <a href="https://github.com/ShadowElixir/shadowos-linux/actions/workflows/build.yml"><img src="https://github.com/ShadowElixir/shadowos-linux/actions/workflows/build.yml/badge.svg" alt="image build badge"/></a>
  <a href="https://github.com/ShadowElixir/shadowos-linux/actions/workflows/build-iso.yml"><img src="https://github.com/ShadowElixir/shadowos-linux/actions/workflows/build-iso.yml/badge.svg" alt="iso build badge"/></a>
</p>

<p align="center">
  <a href="https://shadowelixir.github.io/linux">
    <img src="https://raw.githubusercontent.com/ShadowElixir/linux/refs/heads/main/images/Download.svg" alt="Download ShadowOS" style="height: 48px; width: auto;" />
  </a>
</p>

<h1 align="center">Overview</h1>

- All the benefits of [Bazzite](https://github.com/ublue-os/bazzite#about--features), [Universal Blue](https://github.com/ublue-os/bazzite#universal-blue) and [Fedora Atomic](https://github.com/ublue-os/bazzite#features-from-fedora-linux-kinoite--silverblue).
- 4 choices of Desktop Environments (Cosmic, XFCE, KDE and Gnome) instead of just 2 (KDE/Gnome)
- Windows 7 theme included in KDE Plasma *([AeroThemePlasma](https://gitgud.io/aeroshell/atp/aerothemeplasma))*
- Windows XP theme included in XFCE *(slightly tweaked [xfce-winxp-tc](https://github.com/rozniak/xfce-winxp-tc))*
- Gnome pre-configured with extensions
- Windows-like configuration for Cosmic
- Always have the latest version of Cosmic thanks to the `ryanabx/cosmic-epoch` copr repo
- Firefox replaced by LibreWolf *(with user-friendly settings applied)*
- [Firefox Gnome theme](https://github.com/rafaelmardojai/firefox-gnome-theme) and [compact extensions panel](https://github.com/MrOtherGuy/firefox-csshacks/blob/master/chrome/compact_extensions_panel.css) from [firefox-csshacks](https://github.com/MrOtherGuy/firefox-csshacks) applied by default with auto-updates
- Replaced Lutris with a [custom build](https://github.com/ShadowElixir/HeroicGamesLauncher) of [Heroic Games Launcher](https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher) that [fixes console mode](https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/pull/5620).
- Have an android phone? ADB, [scrcpy](https://github.com/Genymobile/scrcpy) and [Universal Android Debloater](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation) are included in ShadowOS
- `ujust scrcpy-cam` command included if you want to use your phone's camera as your camera *(you might want to run `ujust scrcpy-cam edit` first)*
- `ujust toggle-autologin` command included in Cosmic/XFCE variants if you prefer to auto-login into your desktop *(KDE/Gnome should have the option in settings)*
- Automatic system, flatpak, appimage, brew and theme updates
- Replaced Bazaar with Gnome Software *(Cosmic Store in the Cosmic variant)*
- Run MangoHUD in any game out-of-the-box just by pressing the `END` key
- Automatic DLSS upgrades in all games
- Steam is optional

<h1 align="center">Screenshots</h1>

<table>
  <tr>
    <td align="center" valign="top" width="50%">
      <img src="https://raw.githubusercontent.com/ShadowElixir/linux/refs/heads/main/images/cosmic.png" alt="Cosmic" width="100%"/>
      <br />
      <b>Cosmic</b>
    </td>
    <td align="center" valign="top" width="50%">
      <img src="https://raw.githubusercontent.com/ShadowElixir/linux/refs/heads/main/images/gnome.png" alt="Gnome" width="100%"/>
      <br />
      <b>Gnome</b>
    </td>
  </tr>
  <tr>
    <td align="center" valign="top" width="50%">
      <img src="https://raw.githubusercontent.com/ShadowElixir/linux/refs/heads/main/images/kde.png" alt="KDE Plasma" width="100%"/>
      <br />
      <b>KDE Plasma</b>
    </td>
    <td align="center" valign="top" width="50%">
      <img src="https://raw.githubusercontent.com/ShadowElixir/linux/refs/heads/main/images/xfce.png" alt="XFCE" width="100%"/>
      <br />
      <b>XFCE</b>
    </td>
  </tr>
</table>

<h1 align="center">Installation</h1>

<h2 align="center">ISO</h2>

You can download the latest ISO file from:
- **[The official website](https://shadowelixir.github.io/linux/)*** *([Source Code](https://github.com/ShadowElixir/linux))*
- The '[Actions](https://github.com/ShadowElixir/shadowos-linux/actions/workflows/build-iso.yml)' page

**credits to [nightly.link](https://github.com/oprypin/nightly.link) for allowing artifact downloads without needing an account*

<h2 align="center">Rebase</h2>

> [!WARNING]  
> [This is an experimental feature](https://fedoraproject.org/wiki/Changes/OstreeNativeContainer), try at your own discretion.

<details>
<summary><b>First, make an environment variable for the variant of your choice</b></summary>

First, pick a desktop environment:

<details>
<summary><b>Cosmic (Recommended)</b></summary>

```bash
DE=linux
```
</details>
  
<details>
<summary><b>Gnome</b></summary>

```bash
DE=gnome
```
</details>

<details>
<summary><b>KDE Plasma</b></summary>

```bash
DE=kde
```
</details>

<details>
<summary><b>XFCE</b></summary>

```bash
DE=xfce
```
</details>

Then, select your gpu:

<details>
<summary><b>AMD/Intel</b></summary>

```bash
GPU=
```
</details>

<details>
<summary><b>NVIDIA (GTX 16xx and RTX series)</b></summary>

```bash
GPU=-nvidia
```
</details>

<details>
<summary><b>NVIDIA Legacy (GTX 745 and later)</b></summary>

```bash
GPU=-nvidia-legacy
```
</details>

After that, choose if you would like steam or not:

<details>
<summary><b>Steam</b></summary>

```bash
STEAM=-steam
```
</details>

<details>
<summary><b>No Steam</b></summary>

```bash
STEAM=
```
</details>

Then, pick your release channel:

<details>
<summary><b>Stable</b></summary>

```bash
RELEASE=latest
```
</details>

<details>
<summary><b>Beta</b></summary>

```bash
RELEASE=beta
```
</details>

Then, run this command:
```bash
VARIANT="shadowos-${DE}${GPU}${STEAM}:${RELEASE}"
```

</details>

After that, either:

<details>
<summary><b>Rebase an existing atomic Fedora installation to the latest build</b></summary>

- Rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/shadowelixir/$VARIANT
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  (source /etc/os-release && rpm-ostree rebase ostree-image-signed:docker://ghcr.io/shadowelixir/$VARIANT_ID:$RELEASE_TYPE)
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```
  
</details>

<details>
<summary><b>Rebase an existing ShadowOS Linux installation to another variant</b></summary>

  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/shadowelixir/$VARIANT
  ```
</details>

<h1 align="center">Verification</h1>

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/shadowelixir/shadowos-linux
```

<h1 align="center">Disclaimer</h1>

> [!WARNING]
> *I prohibit the usage of this software in areas where age verification is required by law.*
> 
> *I am therefore not responsible if you downloaded ShadowOS Linux in those areas.*
