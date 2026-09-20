# AlpineWS

A small **Alpine Linux 3.24 x86_64 post-install profile for the ThinkPad T490**.
BusyBox ash, musl, OpenRC, Xorg, OXWM and patched st. No desktop environment,
graphical login manager, compositor, systemd, elogind, Bash configuration,
GNU coreutils replacement, Nix, containers, or background optimization suite.

This does **not install Alpine or partition a disk**. Install Alpine in `sys`
mode first, configure Wi-Fi and a normal user with doas access, then reboot into
that installed system. Existing networking, bootloader, passwords and storage
layout are left alone. Package upgrades can run their normal firmware/initramfs
hooks. The installer never writes or pushes to Blix or Minarch.

## Install

Use the current Alpine **3.24** Standard x86_64 installer, not edge. Enable HTTPS
`v3.24/main` in `/etc/apk/repositories`; this script adds the same mirror's
`v3.24/community` if needed. It rejects mixed releases, edge and non-HTTPS repos.
Do not run this on the live ISO or inside an existing Arch/NixOS installation.

As your normal doas-capable user:

```sh
doas apk add git curl ca-certificates
git clone https://github.com/blakepiper/alpinews.git ~/alpinews
cd ~/alpinews
sh install.sh --replace-config
```

`--replace-config` saves backups before replacing differing managed files.
Without it, existing files are preserved and reported. Xfe's mutable `xferc`
is always preserved once it exists. Generated binaries and the root-owned power
helper are replaced on upgrades. No unrelated packages are removed.

After installing, reboot, log in on a local TTY, and run:

```sh
startx
```

No autologin and no automatic X startup. Super+Shift+Q exits to the TTY.
`--config-only` downloads the pinned configuration snapshot and seeds user files
without root, packages or system changes. `--keep-build-deps` retains the Zig
compiler and development headers; by default `.alpinews-build` is removed after
success. An interrupted build can be rerun. Its error message explains how to
remove temporary build packages or clear an abandoned installation lock.

## What matches Blix

The installer reads a fixed, reviewed Blix commit, rather than following its
moving main branch. It imports the complete OXWM Lua configuration and Neovim
configuration, plus the st config and patches. Source revisions are recorded in
`~/.local/state/alpinews/sources.txt`.

- Dwindle on all nine tags, 8 px gaps, 2 px borders, the dark/seafoam palette,
  JetBrainsMono Nerd Font, and the built-in battery/RAM/CPU/clock bar.
- st 0.9.3 with Blix's font/palette, 5,000-line scrollback, keyboard/mouse
  scrolling, clickable URLs and copy/paste. No terminal server.
- Blix's Seafoam/LazyVim UI, plugin lockfile, `nvimide` explorer/terminal layout,
  and tmux mouse setting. `dev` opens the familiar editor-left, two-shells-right
  layout; the lower shell prints BusyBox system statistics instead of fastfetch.
- US keyboard, 200 ms/50 Hz repeat, and Command/Alt swapping **only** for the
  external `Gaming Keyboard` with USB ID `1fc9:e8c7`. The internal keyboard is
  not swapped. Touchpads use natural scrolling, tapping, clickfinger and
  disable-while-typing. Ordinary mice scroll naturally; TrackPoint/tablets are
  excluded from that mouse rule.
- `eDP-1` and `HDMI-2` mirror at 1920x1080/60 Hz when both support it. Connector
  names are auto-detected when they differ. Unplugging restores the internal
  panel's native mode. `~/.config/alpinews/display.conf` overrides the defaults.
  The mirrored-screen OXWM patch avoids duplicate bars.

### Main keys

| Key | Action |
| --- | --- |
| Super+Enter | st |
| Super+Space or Super+D | dmenu |
| Super+B / Super+F | Firefox / Xfe |
| Super+1..9 / Super+Shift+1..9 | View tag / move window to tag |
| Super+arrows / Super+Shift+arrows | Focus / reorder stack |
| Super+Ctrl+arrows | Focus monitor |
| Super+Q / Super+P | Close / toggle floating |
| Super+R / Super+C | Dwindle / classic tiling |
| Super+Shift+F | Fullscreen |
| Super+L / Super+Shift+Space | Lock / control menu |
| Super+Shift+S / Print / Alt+Print | Region / full / window screenshot |
| Super+V | Text clipboard history |

Other bindings remain in `~/.config/oxwm/config.lua`. There is no reload key.

## Alpine-specific choices

**Not literally GNU-free.** The shell and core command-line utilities stay
BusyBox. Builds use Zig/LLVM rather than adding GCC, GNU make or binutils.
Stock Firefox/GTK/C++ packages may still require GNU runtime libraries, and st
keeps ncurses terminfo. Stripping necessary libraries is not a supported way to
make this application stack smaller. GPL-licensed software is not automatically
a GNU component.

**Small, usable audio stack.** PipeWire, its PulseAudio compatibility process,
and WirePlumber run only with X. There is no separate PulseAudio server and no
parallel OpenRC user audio service. The installer enables only the system D-Bus
service and Alpine's eudev device management for the desktop. It does not add
Bluetooth, printing, discovery, automounting, SSH servers, portals or power
management daemons. Audio/video/render group permissions are used instead of
elogind. Intel i915 and Intel Wi-Fi firmware, Intel microcode and the Intel media
driver support the T490's integrated graphics/Wi-Fi configuration. Intel Wi-Fi
power saving is disabled to match the T490 Blix setting.

**Firefox is preconfigured, not bundled with unsigned extensions.** The policy
installs uBlock Origin, Dark Reader and Enhancer for YouTube from Mozilla on
Firefox's first connected launch, including private windows. Firefox retains
extension signature verification and normal extension updates. Policies also
set strict tracking protection, Global Privacy Control, dark content defaults,
no sponsored/recommended home content, no studies/telemetry and blocked Firefox
AI features. Check `about:policies` and `about:addons`. Existing conflicting
policies are preserved unless `--replace-config` is used.

**Neovim does not silently download a development environment.** The Blix UI
and plugin versions are retained, but automatic update checks, Mason-managed
binaries and Tree-sitter are disabled; completion uses its Lua implementation.
This avoids glibc-only downloads and compiler requirements after setup. Plugins
still download on first editor launch. Use native Alpine packages for language
servers/formatters and edit `lua/plugins/alpinews.lua` to enable those features.
The initial lockfile seeds the writable state lockfile, as in Blix. No Codex,
Parsec, Node, Python, or language SDK is installed by this desktop profile.

**Session processes.** Hotplug waits for udev events. A small XFixes
listener records at most 100 plain-text clipboard entries, capped at 1 MiB each.
It skips image-only selections so screenshot pastes remain intact. History is
private but can contain passwords or secrets; `clipboard-history --clear`
clears it, and a normal X-session exit deletes it. Do not treat clipboard history
as a secret store. There are no idle lock/blanking timers or compositor.

## Locking and power

Super+L uses i3lock. Control-menu suspend runs the locker first and proceeds
only after it successfully daemonizes with input grabbed. Reboot, poweroff and
logout require a Yes confirmation. Doas grants this user only three exact,
argument-restricted operations through a root-owned helper; it does not grant a
passwordless root shell. The installer itself still needs normal doas access.

This small profile has **no global suspend inhibitor or automatic lid-lock
service**. Only control-menu suspend has the lock-before-suspend sequence.
Existing ACPI handlers are left untouched: inspect `/etc/acpi/handler.sh` before
relying on lid-close behavior. A suspend from another program/root or an existing
lid handler bypasses that sequence. Test lock/resume on the actual T490 before
relying on it.

Alpine's Xorg build lacks logind integration. This profile uses its console-only
root Xorg wrapper. VT switching and the X-server kill shortcut are disabled
while X runs, so a locked screen cannot simply reveal its logged-in parent TTY.
Exit OXWM to return to the console. This is a security/complexity tradeoff, not a
claim that a root X server is equivalent to a sandboxed Wayland session.

Only one managed X session per user is supported. Session logs are in
`~/.local/state/alpinews/`. After an unclean crash, check for surviving X/audio
processes before removing the stale `alpinews-session` directory inside
`$XDG_RUNTIME_DIR` (or `/tmp/alpinews-runtime-$(id -u)`).

## Validation and limits

```sh
sh tests/test.sh       # Offline shell/config/monitor tests
sh tests/smoke.sh      # Post-install command checks, from the normal user
```

Offline tests were run with BusyBox ash **and BusyBox utilities**. JSON policies
were parsed separately. Preservation/replacement, symlink safety, whole-directory
backups, repository guards, screenshot cancellation, mirroring, disconnect recovery and renamed connectors
are exercised with temporary files and mocked xrandr output.

The full Alpine package installation, Zig builds, Xorg session, Firefox policy
activation, keyboard/mouse hardware, HDMI, sound and suspend were **not run on a
T490 during authoring**. Network access from the authoring container was
unavailable, so do not mistake shell tests for an installed-system test. This is
an initial implementation requiring on-device verification, not a measured
200 MiB idle-RAM claim. The installer fails on missing packages/build errors and
never substitutes an unverified binary or mixes edge packages to work around one.

See [source provenance](docs/SOURCES.md) for the pinned inputs and primary references.
