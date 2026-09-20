# AlpineWS

A minimal **Alpine Linux 3.24 x86_64 desktop for the ThinkPad T490**: BusyBox ash,
musl, OpenRC, Xorg, OXWM, patched st, Firefox, and the complete pinned Blix Neovim
configuration. The full installer also sets a **79% battery charge-stop limit**.

No systemd init, desktop environment, display manager, compositor, tmux, TLP,
Bash or GNU command-line suite is added. This is not literally GNU-free: stock
applications need some GNU runtime libraries, and Alpine's normal UEFI disk
installation uses GRUB. AlpineWS does not replace Alpine's bootloader.

**There are two separate installations:** Alpine's `setup-alpine` installs the
operating system; this repository's `install.sh` configures the installed system.
Do not run AlpineWS from the live USB. Blix and Minarch are read-only sources.

Already running Alpine 3.24 on the SSD? Start at **step 5**. Already using
AlpineWS? See [updating](#updating-an-existing-alpinews-installation).

## 1. Back up the T490 and download Alpine

This guide is for a **single-boot installation using the whole internal SSD**.
Alpine's disk-install step erases that selected disk, including Arch/NixOS,
partitions and personal files. Back up files, SSH keys and anything uncommitted
somewhere outside this laptop. A GitHub repository is not a backup of your home
directory. Dual boot and disk encryption require a different partitioning guide.

Keep the charger connected. Use a spare USB drive whose contents can be erased.
Ethernet is the simplest initial network connection; Wi-Fi steps are below.

On your existing Linux computer, download **Standard, x86_64, 3.24.x** from
[Alpine downloads](https://alpinelinux.org/downloads/). Do not select Virtual,
Mini root filesystem, x86 (32-bit), aarch64 or edge. On September 20, 2026 the
current 3.24 image is **3.24.2**. These commands deliberately stay on that release:

```sh
mkdir -p ~/Downloads/alpinews-install
cd ~/Downloads/alpinews-install
curl -fLO https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-standard-3.24.2-x86_64.iso
curl -fLO https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-standard-3.24.2-x86_64.iso.sha256
sha256sum -c alpine-standard-3.24.2-x86_64.iso.sha256
```

Continue only when the checksum says **OK**. A newer 3.24.x image is also suitable;
change both filenames together and verify its matching checksum. Do not change
the guide to a different Alpine release without updating and testing the profile.

## 2. Write the USB on your existing Linux computer

**This step erases the USB. Selecting the wrong device can erase your SSD.**
Identify it by size/model and the USB transport, not by guessing a device letter:

```sh
lsblk -o NAME,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS
```

Unmount each mounted partition belonging to that USB. For example, run
`sudo umount /dev/sdX1` after replacing `sdX1` with the partition actually shown.
Do not unmount your system partitions.

Still in the download directory, replace `/dev/sdX` below with the **whole USB
device**, such as `/dev/sdb`, not `/dev/sdb1`. Never use the internal NVMe SSD here.

```sh
USB=/dev/sdX
test -b "$USB" && sudo dd if=alpine-standard-3.24.2-x86_64.iso of="$USB" bs=4M conv=fsync && sync
```

These are commands for your existing Linux system, where `sudo` is assumed.
The installed Alpine system will use `doas`. Do not remove the USB until the
write and sync finish and the shell prompt returns.

## 3. Boot the T490 from the USB

Insert the USB and restart. Use the ThinkPad startup menu: **F1** opens firmware
settings and **F12** selects a boot device; pressing Enter at the Lenovo splash
can expose these choices. Select the USB's UEFI entry.

For this installation path, use **UEFI boot with Secure Boot disabled**. Do not
clear Secure Boot keys or alter unrelated firmware settings. Changing firmware
settings can affect an existing encrypted Windows installation, so retain any
recovery keys before changing them. Custom Secure Boot enrollment is outside
this guide.

At Alpine's login prompt enter `root`. The live image has no root password.
Check that the intended image and boot mode are active:

```sh
cat /etc/alpine-release
uname -m
test -d /sys/firmware/efi && echo 'UEFI boot confirmed'
```

Expect `3.24.x`, `x86_64` and the UEFI confirmation. If the final line is absent,
reboot and select the UEFI USB entry before proceeding.

## 4. Install Alpine onto the internal SSD

You are still **root on the live USB**. Run:

```sh
setup-alpine
```

Follow the prompts. Their order can vary slightly; use these choices:

| Prompt | Choice for this setup |
| --- | --- |
| Keyboard layout and variant | `us`, then `us` |
| Hostname | `t490` |
| Network interface | Your Ethernet interface, or the listed Wi-Fi interface |
| Wireless network | Your SSID and Wi-Fi password when prompted |
| IP address | `dhcp` for an ordinary home network |
| Other interfaces | `done` once your intended connection is configured |
| Manual network configuration | `no` unless your network needs it |
| DNS | Use the DHCP-provided settings; leave search domain empty unless needed |
| Root password | Set a strong password and keep it |
| Timezone | `America/New_York` |
| HTTP/FTP proxy | `none`, unless your network requires one |
| NTP client | `busybox`, when offered |
| APK mirror | The official CDN / first mirror, or another working HTTPS mirror |
| Regular user | `przvl` (or your preferred username); set its password |
| SSH key | `none` when not configuring SSH |
| SSH server | `none` |
| Disk | The **internal SSD**, identified by model and size |
| Disk usage | **`sys`** |
| Erase confirmation | Confirm only after checking the selected disk again |

The SSD is commonly named `nvme0n1`, but use the name Alpine actually displays.
Do **not** choose the installer USB. Leave Alpine's normal partition, swap and
bootloader defaults alone for this path. Do not choose `data` or diskless mode.
If asked about configuration-backup storage or an APK cache, `none` is sufficient
for this `sys` installation.

### Wi-Fi does not appear or will not connect

Do not continue to the disk step without working downloads. Exit setup before
choosing/erasing a disk and inspect the connection as root:

```sh
ip link
rfkill list
modprobe iwlwifi
dmesg | grep -iE 'iwlwifi|firmware'
setup-interfaces
```

Choose the wireless interface actually listed, enter the SSID/password, then
use DHCP. If radio blocking is reported, check the laptop's radio setting;
`rfkill unblock wifi` clears a software block. A firmware error or missing
wireless package may require Ethernet to download it. With working Ethernet
and a configured Alpine mirror:

```sh
apk update
apk add linux-firmware-intel wpa_supplicant
setup-interfaces
```

Once connected, restart `setup-alpine` and complete the installation. Do not
install NetworkManager or a desktop environment just to get through this guide.
Use [Alpine's networking guide](https://wiki.alpinelinux.org/wiki/Configure_Networking)
for enterprise Wi-Fi, captive portals or more complex networks.

When Alpine reports that installation is complete:

```sh
reboot
```

Remove the USB during restart and boot the SSD. **Do not rerun `setup-alpine`
on the installed system just to install the desktop.**

## 5. Prepare the installed Alpine system

Log in as **root on the SSD**, using the password you set. Verify:

```sh
cat /etc/alpine-release
uname -m
awk '$2 == "/" { print }' /proc/mounts
```

You should be on Alpine 3.24 x86_64 with the internal disk (or its mapped device)
mounted at `/`, not the live image's RAM/overlay root. Confirm networking survived
reboot. `setup-interfaces` is available again if it needs correction.

AlpineWS accepts only HTTPS `v3.24/main` and `v3.24/community` repositories. On a
fresh installation, back up the mirror file and set these exact entries:

```sh
cp /etc/apk/repositories "/etc/apk/repositories.before-alpinews.$(date +%Y%m%d-%H%M%S)"
cat > /etc/apk/repositories <<'REPOS'
https://dl-cdn.alpinelinux.org/alpine/v3.24/main
https://dl-cdn.alpinelinux.org/alpine/v3.24/community
REPOS
apk update
apk add doas git curl ca-certificates
curl -fI https://github.com
```

On an existing customized Alpine installation, review the repository file
instead of blindly replacing it. Do not mix edge or different stable releases.
If HTTPS fails, check `date`, DNS and the network; do not bypass certificate
verification. The installer itself also upgrades packages within 3.24.

### Confirm your normal account and doas

The examples use `przvl`. Substitute your chosen username consistently:

```sh
id przvl
```

If the account does not exist, create it with `adduser przvl` and set a password.
Then, as root:

```sh
addgroup przvl wheel
mkdir -p /etc/doas.d
printf 'permit persist :wheel\n' > /etc/doas.d/20-wheel.conf
chmod 600 /etc/doas.d/20-wheel.conf
doas -C /etc/doas.d/20-wheel.conf
exit
```

The rule grants administrators in `wheel` root access using their password;
it is not a passwordless rule. On an existing installation, inspect your doas
rules before changing them. Log in at the console as **przvl**, then check:

```sh
whoami
echo "$HOME"
doas true
```

Expect your normal username, its `/home/...` directory and successful doas
authentication. Run all remaining installation commands as this normal user.

## 6. Run the AlpineWS installer

```sh
git clone https://github.com/blakepiper/alpinews.git ~/alpinews
cd ~/alpinews
sh install.sh --replace-config
```

Do **not** put `doas` before `sh install.sh`. The installer escalates only its
system-configuration stages; source downloads and builds run as your user.
Keep the network connected, keep the charger attached, and do not launch a second
installer. Read any error rather than continuing to `startx` after a failed run.

The full installer installs the package manifest, builds OXWM/st/the clipboard
listener, copies pinned Blix preferences, configures Xorg/eudev/D-Bus, bootstraps
the compatible Lua language server, and applies the battery limit. It never
partitions disks, changes passwords or replaces your networking configuration.

`--replace-config` backs up differing managed files before replacing them.
Without it, existing configurations are preserved and reported. Xfe's mutable
`xferc` is always preserved once it exists. Generated executables and privileged
helpers are replaced. No unrelated packages or old tmux files are removed.

When the installer finishes successfully:

```sh
doas reboot
```

Rebooting is required here for device permissions and the hardware configuration.

## 7. Start the desktop and check the battery cap

Log in again as your normal user on a local console, then run:

```sh
startx
```

There is no graphical login screen or autologin. You run `startx` after each
console login. **Super+Enter** opens st; **Super+B** opens Firefox;
**Super+F** opens Xfe. **Super+Shift+Q** exits OXWM back to the console.

In st, check the installed commands and the actual firmware threshold:

```sh
cd ~/alpinews
sh tests/smoke.sh
/usr/local/libexec/alpinews-battery-limit --check
```

For the T490's battery, expect `BAT0: charge stop 79% (requested 79%)`. Verify
the same command after a reboot and after suspend/resume, not just once.

### How the 79% clamp works

A root-owned BusyBox shell helper writes
`/sys/class/power_supply/BAT*/charge_control_end_threshold` and verifies that
firmware reads it back as **79**. A one-shot OpenRC service applies it at boot;
short udev power-supply handlers reapply it on AC/battery events. The control-menu
suspend helper also reapplies it immediately after resume. **No resident battery
process, timer, TLP or new package is needed.**

An existing charge-start threshold below 79 is preserved. A threshold of 79 or
higher is lowered to **78 first**, so it cannot conflict with the new stop limit.
The helper skips unchanged values, preventing its own writes from creating a
udev event loop. It does not request forced discharge. A battery already above
79% will not instantly drop to 79%, and displayed charge can round differently
from the firmware setting.

If the installer says **cap NOT applied**, do not assume charging is limited.
Missing threshold support is a visible warning, not a reason to prevent desktop
installation; an actual write/read-back failure stops the install. Inspect:

```sh
doas modprobe thinkpad_acpi
doas rc-service alpinews-battery-limit restart
/usr/local/libexec/alpinews-battery-limit --check
```

The check exits nonzero if no supported battery exists or its stop value is not
79. No guarantee is made for hardware that does not expose these attributes.
Stopping the OpenRC service does not reset the firmware limit to 100%.

## 8. Finish Firefox and Neovim setup

Open Firefox with **Super+B** while online. Let the policies install **uBlock
Origin, Dark Reader and Enhancer for YouTube**. Check `about:policies` for active
policies/errors and `about:addons` for all three enabled extensions. Automatic
extension updates and signature verification stay enabled. Dark content,
strict tracking protection, Global Privacy Control and reduced sponsored/AI
content are configured; existing conflicting policies need `--replace-config`.

Open `nvim` or `nvimide` and leave the first session open while its plugins and
parsers finish installing. Do not start several initial Neovim sessions at once.
`nvimide` opens Blix's explorer/terminal layout; no tmux session is involved.

The entire Neovim configuration is copied unchanged from Blix commit
`4a4b8017d07421796047e12edceba87e21e3f24e`, including its lockfile and
`BLIX_NVIMIDE=1` behavior. Blix itself names the color scheme `seafoam`; no
separate Alpine theme or feature-disabling override is added.

Zig, musl headers and Tree-sitter's CLI remain installed for later parser
compilation. Alpine's CLI package also brings Node.js. These use disk space,
not idle services. The `cc`/`c++` wrappers normalize Alpine's target for Zig.
Other temporary build packages are removed after a successful install.

**LuaLS compatibility pin:** the installer seeds the older **3.13.9 musl build**
when no working Mason Lua server exists, and adapts its generated Bash launcher
to POSIX sh. It preserves a working server and does not change Blix Lua files or
forge Mason receipts. Future Mason updates can replace the launcher or request
an unavailable musl build; rerun the full installer to repair the supported
entry point. Read [the editor notes](docs/EDITOR-BOOTSTRAP.md) before updating.
A preserved custom Neovim configuration is not bootstrapped automatically.

Test your actual hardware: browser video/audio, microphone, brightness keys,
touchpad, TrackPoint, external keyboard, monitor connection/disconnection, and
lock/unlock. Use **Super+Shift+Space**, then Suspend, to test lock and resume.

## Updating an existing AlpineWS installation

As your normal user, from the console after exiting OXWM:

```sh
cd ~/alpinews
git pull --ff-only
sh install.sh --replace-config
doas reboot
```

Use the **full installer** for package, battery and system fixes.
`--config-only` copies user files only; it does not install packages, apply the
battery clamp or seed the language server. `--keep-build-deps` retains the
temporary `.alpinews-build` group. `sh install.sh --help` lists all options.

AlpineWS reads fixed Blix/OXWM revisions rather than silently following their
moving branches. Installed revisions and the package inventory are recorded in
`~/.local/state/alpinews/`. Updating AlpineWS does not modify Blix or Minarch.

## Desktop reference

OXWM uses dwindle on nine tags, 8 px gaps, 2 px borders, JetBrainsMono Nerd Font
and Blix's palette/status bar. st includes the Blix palette, 5,000-line scrollback,
clickable URLs and copy/paste. Xfe handles files, mpv media and feh images.
The exact runtime package list is [config/packages](config/packages).

| Key | Action |
| --- | --- |
| Super+Enter | st |
| Super+Space or Super+D | dmenu |
| Super+B / Super+F | Firefox / Xfe |
| Super+1..9 / Super+Shift+1..9 | View tag / move window to tag |
| Super+arrows / Super+Shift+arrows | Focus / reorder stack |
| Super+Ctrl+arrows | Focus monitor |
| Super+Q / Super+P | Close window / toggle floating |
| Super+R / Super+C | Dwindle / classic tiling |
| Super+Shift+F | Fullscreen |
| Super+L / Super+Shift+Space | Lock / control menu |
| Super+Shift+S / Print / Alt+Print | Region / full / window screenshot |
| Super+V | Text clipboard history |
| Super+Shift+Q | Exit OXWM to the console |

Bindings live in `~/.config/oxwm/config.lua`; there is no reload key. Input uses
US layout and 200 ms/50 Hz repeat. The Command/Alt swap applies only to the
external `Gaming Keyboard` with USB ID `1fc9:e8c7`, not the laptop keyboard.
Touchpads use tapping, natural scrolling, clickfinger and disable-while-typing.
Ordinary mice scroll naturally; TrackPoint/tablets are excluded from that rule.

The default external display mirrors the laptop at **1920x1080/60 Hz** when both
support it. Connector names are detected; unplugging restores the internal
panel's native mode. Change `~/.config/alpinews/display.conf` for another setup.

PipeWire/WirePlumber and the PulseAudio compatibility process run with X only.
System D-Bus and eudev are enabled. No Bluetooth, printing, discovery, automount,
SSH server, portal, glibc compatibility layer, Codex, Parsec or SDK collection is
installed by AlpineWS. Audio/video/render permissions replace elogind. Wi-Fi
power saving is disabled as in Blix.

## Recovery and limits

**Installer failed:** read the error, correct the network/package/prerequisite
problem, then rerun the same command. Do not rerun the disk installation. Failed
builds may leave the `.alpinews-build` package group; remove only that temporary
group with `doas apk del .alpinews-build` when no install is running. Normal
failures release the install lock. After power loss, check that no installer is
running before removing the stale `~/.local/state/alpinews/install.lock` directory.
Do not delete your editor data or all caches as a routine repair.

**X does not start:** run it as your normal user from the local console, not from
SSH or a root shell. Check `/var/log/Xorg.0.log`,
`~/.local/share/xorg/Xorg.0.log` (whichever exists), and
`~/.local/state/alpinews/`. Only one managed X session per user is supported.
After an unclean crash, check for surviving X/audio processes before removing
its stale `alpinews-session` directory inside `$XDG_RUNTIME_DIR` or
`/tmp/alpinews-runtime-$(id -u)`.

**Locking:** the menu locks with i3lock before suspend. There is **no automatic
lid lock, global suspend inhibitor, idle lock or display-blanking timer**. Existing
ACPI handlers are untouched; inspect `/etc/acpi/handler.sh` before trusting lid
behavior. Suspending elsewhere can bypass the lock. This profile uses Alpine's
console-only root Xorg wrapper without logind, disabling VT switching and the
X-server kill shortcut during X. Exit OXWM to return to the console. Test this
security-sensitive behavior on the laptop.

**Clipboard:** at most 100 text entries, each capped at 1 MiB, are stored privately
and cleared on normal X-session exit. They may still contain secrets. Run
`clipboard-history --clear` to remove them. Screenshot copying uses actual PNG
contents. No compositor or clipboard polling loop is added.

Offline checks, from this checkout:

```sh
sh tests/test.sh
sh tests/nvim-config.sh
sh tests/compiler.sh
sh tests/battery.sh
```

Check [GitHub Actions](https://github.com/blakepiper/alpinews/actions) for the
exact commit. Desktop tests use a clean Alpine container/Xvfb and check package
resolution, compilation, configuration, st, screenshot clipboard data, audio
connectivity and session cleanup after build-dependency removal. Editor tests
exercise Blix plugins, native parsers, compiler arguments and actual Mason tools.
The battery test uses fake sysfs attributes, checking write order, 79% read-back,
reruns, absent batteries and failures; it does not claim to test battery firmware.
Do not run disposable-home integration scripts against your real desktop.

**Not yet verified on a physical T490:** disk boot, privileged device/service
setup, real TTY-to-Xorg startup, acceleration, Wi-Fi, input, HDMI, sound/microphone,
Firefox extension activation, battery enforcement and suspend/resume. Passing
container tests do not guarantee these, and downloads can fail independently.
No measured 200 MiB idle claim is made.

## Sources

[Alpine downloads](https://alpinelinux.org/downloads/),
[installation](https://wiki.alpinelinux.org/wiki/Installation),
[setup-alpine](https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html),
[system disk mode](https://wiki.alpinelinux.org/wiki/System_Disk_Mode),
[networking](https://wiki.alpinelinux.org/wiki/Configure_Networking),
[users and doas](https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user),
[setup options](https://wiki.alpinelinux.org/wiki/Using_an_answerfile_with_setup-alpine),
[Secure Boot](https://wiki.alpinelinux.org/wiki/UEFI_Secure_Boot), and
[kernel ThinkPad charge-control documentation](https://docs.kernel.org/admin-guide/laptops/thinkpad-acpi.html#battery-charge-control).
See also [configuration provenance](docs/SOURCES.md) and
[editor bootstrap details](docs/EDITOR-BOOTSTRAP.md).
