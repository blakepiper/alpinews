# AlpineWS

An **Alpine Linux 3.24 x86_64 post-install profile for the ThinkPad T490**.
BusyBox ash, musl, OpenRC, Xorg, OXWM and patched st. No desktop environment,
graphical login manager, compositor, systemd init, elogind, Bash configuration,
GNU coreutils replacement, Nix, containers, or background optimization suite.

This does **not install Alpine or partition a disk**. Install Alpine in `sys`
mode first, configure Wi-Fi and a normal user with doas access, then reboot into
that installed system. Existing networking, bootloader, passwords and storage
layout are left alone. Package upgrades can run their normal firmware/initramfs
hooks. The installer never writes or pushes to Blix or Minarch.

## Install

Use Alpine **3.24** Standard x86_64, not edge. Enable HTTPS `v3.24/main` in
`/etc/apk/repositories`; this script adds the same mirror's `v3.24/community`
if needed. It rejects mixed releases, edge and non-HTTPS repos. Do not run this
on the live ISO or inside an existing Arch/NixOS installation.

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
`--config-only` fetches the pinned configuration and seeds user files without
root, packages or system changes. It does not repair missing packages.
`--keep-build-deps` retains the temporary desktop-build dependency group;
otherwise `.alpinews-build` is removed after success. **Zig and musl headers
remain installed because Blix's Neovim needs a compiler for parsers later.**
An interrupted build can be rerun. Its error message explains how to remove
temporary build packages or clear an abandoned installation lock.

For an existing checkout, use `git pull --ff-only`, then rerun the full
`sh install.sh --replace-config` to receive both package and configuration fixes.
Review the backup messages: this replaces all differing managed user defaults,
not just Neovim. Backups and user plugin/tool state are not deleted.

## What matches Blix

The installer reads a fixed, reviewed Blix commit, rather than following its
moving main branch. It imports OXWM and Neovim configuration, plus st config
and patches. Source revisions are recorded in
`~/.local/state/alpinews/sources.txt`.

- Dwindle on all nine tags, 8 px gaps, 2 px borders, Blix's colors,
  JetBrainsMono Nerd Font, and the built-in battery/RAM/CPU/clock bar.
- st 0.9.3 with Blix's font/palette, 5,000-line scrollback, keyboard/mouse
  scrolling, clickable URLs and copy/paste. No terminal server.
- Blix's complete Neovim configuration, unchanged, including its plugin lockfile
  and `nvimide` explorer/terminal layout. Run `nvim` or `nvimide` directly in st.
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

**No tmux.** The installer does not install tmux, import its configuration, or
provide the old tmux-based `dev` launcher. OXWM manages terminal windows, and
`nvimide` retains Blix's own editor/terminal layout. Updating an existing install
does not uninstall an already installed tmux package or delete old user files.

**Not literally GNU-free.** The shell and core command-line utilities stay
BusyBox. Builds use Zig/LLVM rather than adding GCC, GNU make or binutils.
Stock Firefox/GTK/C++ packages still require runtime libraries; st keeps ncurses
terminfo. Removing required libraries is not a supported way to shrink this
stack. GPL-licensed software is not automatically a GNU component.

**Audio and hardware.** PipeWire, its PulseAudio compatibility process, and
WirePlumber run only with X. There is no separate PulseAudio server and no
parallel OpenRC user audio service. The desktop enables system D-Bus and Alpine's
eudev device management. It does not add Bluetooth, printing, discovery,
automounting, SSH servers, portals or power-management daemons. Audio/video/render
group permissions are used instead of elogind. Intel i915 and Intel Wi-Fi firmware,
Intel microcode and the Intel media driver target the T490's integrated graphics
and Wi-Fi. Intel Wi-Fi power saving is disabled to match the T490 Blix setting.

**Firefox.** Policy installs uBlock Origin, Dark Reader and Enhancer for YouTube
from Mozilla on the first connected launch, including private windows. Signature
verification and normal extension updates remain enabled. Policies also set
strict tracking protection, Global Privacy Control, dark content defaults,
no sponsored/recommended home content, no studies/telemetry and blocked Firefox
AI features. Check `about:policies` and `about:addons`. Conflicting existing
policies are preserved unless `--replace-config` is used.

**Neovim follows Blix, without an Alpine-specific variant.** The installer copies
`home/przvl/config/nvim` byte-for-byte from Blix commit
`4a4b8017d07421796047e12edceba87e21e3f24e`, checked against Blix's `main`
on September 20, 2026. It does not rewrite Lua files, add plugin overrides,
disable Mason/Tree-sitter, change completion, or alter update checks. `nvimide`
sets the original `BLIX_NVIMIDE=1` flag. The source's color scheme is still named
`seafoam`; that is part of Blix's configuration, not an alternative setup.

Keeping that editor means retaining its actual prerequisites: `tree-sitter-cli`,
`zig`, and `musl-dev`. Alpine's Tree-sitter CLI pulls in Node.js. Small `cc` and
`c++` wrappers in `~/.local/bin` invoke `zig cc` and `zig c++`, so the editor can
find a compiler without installing GCC. These tools use disk space but are not
idle services. This is not the smallest possible editor installation.

Plugin downloads, updates, Mason tools and the writable state lockfile follow
Blix's configuration. The installer does not add duplicate system copies of
Mason's Lua language server or formatter. First launch needs network access and
time for plugin/tool downloads and parser compilation. Not every future Mason
package supports musl; this profile does not install glibc compatibility layers.
Codex, Parsec, Python and general-purpose language SDK collections are not added.

**Session processes.** The runtime directory is validated before starting the
session D-Bus, so audio and other children inherit the same private path. Hotplug
waits for udev events. A small XFixes listener records at most 100 plain-text
clipboard entries, capped at 1 MiB each. It skips image-only selections so
screenshots can be pasted. History is private but can contain secrets;
`clipboard-history --clear` clears it, and a normal X-session exit deletes it.
There are no idle lock/blanking timers or compositor.

## Locking and power

Super+L uses i3lock. Control-menu suspend runs the locker first and proceeds
only after it successfully daemonizes with input grabbed. Reboot, poweroff and
logout require confirmation. Doas grants this user only three exact,
argument-restricted operations through a root-owned helper, not a passwordless
root shell. The installer still needs normal doas access.

There is **no global suspend inhibitor or automatic lid-lock service**. Only
control-menu suspend has the lock-before-suspend sequence. Existing ACPI handlers
are left untouched: inspect `/etc/acpi/handler.sh` before relying on lid-close
behavior. Suspend from another program/root or an existing lid handler bypasses
that sequence. Test lock/resume on the actual T490 before relying on it.

Alpine's Xorg build lacks logind integration. This profile uses its console-only
root Xorg wrapper. VT switching and the X-server kill shortcut are disabled while
X runs, so a locked screen cannot simply reveal its logged-in parent TTY. Exit
OXWM to return to the console. A root X server has a different security model
from a sandboxed Wayland session.

Only one managed X session per user is supported. Session logs are in
`~/.local/state/alpinews/`. After an unclean crash, check for surviving X/audio
processes before removing the stale `alpinews-session` directory inside
`$XDG_RUNTIME_DIR` (or `/tmp/alpinews-runtime-$(id -u)`).

## Validation and limits

```sh
sh tests/test.sh        # Offline shell/config/monitor tests
sh tests/nvim-config.sh # Unchanged Blix copy, backups, nvimide and no-tmux checks
sh tests/smoke.sh       # Post-install command checks, as the normal user
```

Two GitHub Actions workflows run in clean Alpine 3.24 x86_64 containers. Check
[Actions](https://github.com/blakepiper/alpinews/actions) for results for the exact
commit being installed; a workflow's existence alone does not mean it passed.

`Alpine installation checks` installs the real runtime and build manifests,
builds pinned OXWM, patched st and the clipboard listener as an unprivileged user,
compares installed Neovim files against Blix, and removes the temporary build
group. It then runs the installed X-session script under Xvfb and checks terminal
execution, real screenshot PNG clipboard round-tripping, PipeWire/WirePlumber/
PulseAudio-protocol connectivity, the OXWM quit binding and session cleanup.

`Blix editor bootstrap` uses the runtime manifest and the real config-only
installer, checks the retained compiler, restores the Blix plugin versions,
executes Mason-installed tools, and checks representative parser compilation
and parsing. It does not change the copied editor configuration to make tests pass.
The disposable session/editor integration tests belong in CI, not a live desktop.
Xvfb and CI-only diagnostic packages are not desktop dependencies.

Offline tests exercise preservation, backups, symlink safety, whole-directory
replacement, repository guards, screenshot cancellation, mirrored outputs,
unplugging and renamed connectors under BusyBox.

**Still requires on-device verification:** boot/TTY-to-Xorg startup, the root
service/device setup on a real installed system, Intel hardware acceleration,
Wi-Fi, physical keyboard/mouse, HDMI hotplug, actual sound/microphone, Firefox
extension activation, locking and suspend/resume. A successful container/Xvfb
run is not a T490 hardware test or a measured idle-memory result. There is no
promise of 200 MiB idle usage. Downloads and future upstream packages can also
fail independently of this snapshot. Missing dependencies or failed builds stop
the installer; it never mixes edge packages or substitutes unverified binaries.

See [source provenance](docs/SOURCES.md) for pinned inputs and primary references.
