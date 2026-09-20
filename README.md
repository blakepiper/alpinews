# AlpineWS

An **Alpine Linux 3.24 x86_64 post-install profile for the ThinkPad T490**.
BusyBox ash, musl, OpenRC, Xorg, OXWM and patched st. No desktop environment,
display manager, compositor, systemd init, elogind, Bash, GNU CLI suite, tmux,
Nix, containers, or background optimization suite.

This does **not install Alpine or partition disks**. Install Alpine in `sys`
mode first, configure networking and a normal user with doas access, and reboot
into that installed system. Networking ownership, bootloader, passwords and
storage configuration are left alone. Package upgrades can run their normal
firmware/initramfs hooks. Blix and Minarch are only read, never modified.

## Install

Use Alpine **3.24 Standard x86_64**, not edge. Enable HTTPS `v3.24/main` in
`/etc/apk/repositories`; the installer adds the same mirror's `v3.24/community`
when needed. Mixed releases, edge and non-HTTPS repositories are rejected.
Do not run this on the live ISO or inside Arch/NixOS.

As your normal doas-capable user:

```sh
doas apk add git curl ca-certificates
git clone https://github.com/blakepiper/alpinews.git ~/alpinews
cd ~/alpinews
sh install.sh --replace-config
```

For an existing checkout:

```sh
cd ~/alpinews
git pull --ff-only
sh install.sh --replace-config
```

Use the full installer to receive package and compiler fixes, not just
`--config-only`. Differing managed files are backed up before replacement.
Without `--replace-config`, existing files are preserved and reported. Xfe's
mutable `xferc` is always preserved once it exists. Generated binaries and the
root-owned power helper are replaced. No unrelated packages are removed.

After installation, reboot, log in on a local TTY and run:

```sh
startx
```

There is no autologin or automatic X startup. Super+Shift+Q returns to the TTY.
`--config-only` copies user configuration without installing packages, changing
system settings or bootstrapping language tools. `--keep-build-deps` retains the
temporary `.alpinews-build` group; otherwise that group is removed on success.
**Zig and musl headers remain installed for Neovim's later parser builds.**
An interrupted installation can be repaired and rerun; errors stop the installer.

## Desktop preferences from Blix

The installer reads a fixed Blix commit, not a moving branch. Source revisions
are recorded in `~/.local/state/alpinews/sources.txt`.

- OXWM: dwindle on all nine tags, 8 px gaps, 2 px borders, Blix's colors,
  JetBrainsMono Nerd Font, and the battery/RAM/CPU/clock bar.
- st 0.9.3: Blix's font/palette, 5,000-line scrollback, mouse/keyboard scrolling,
  clickable URLs and copy/paste. No terminal server.
- Neovim: the complete Blix configuration and plugin lockfile, copied unchanged.
  `nvimide` retains the explorer/terminal layout. No tmux or `dev` launcher.
- Input: US layout and 200 ms/50 Hz repeat. Command/Alt positions are swapped
  only on the external `Gaming Keyboard`, USB ID `1fc9:e8c7`, not the laptop
  keyboard. Touchpads use natural scrolling, tapping, clickfinger and
  disable-while-typing. Ordinary mice scroll naturally; TrackPoint/tablets are
  excluded from the mouse rule.
- Monitors: `eDP-1` and `HDMI-2` mirror at 1920x1080/60 Hz when both support it.
  Connector names are detected when different. Unplugging restores the internal
  panel's native mode. Edit `~/.config/alpinews/display.conf` for other defaults.
  The OXWM mirrored-screen patch prevents duplicate bars.

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

All OXWM bindings are in `~/.config/oxwm/config.lua`. There is no reload key.

## Neovim and its prerequisites

The installer copies `home/przvl/config/nvim` byte-for-byte from Blix commit
`4a4b8017d07421796047e12edceba87e21e3f24e`, checked against Blix's `main` on
September 20, 2026. It does not rewrite Lua files, disable Mason/Tree-sitter,
change completion, add theme overrides or alter plugin update checks.
`nvimide` uses the original `BLIX_NVIMIDE=1` flag. The source itself still names
its color scheme `seafoam`; AlpineWS does not choose a separate editor setup.

That configuration needs `tree-sitter-cli`, `zig` and `musl-dev` after desktop
installation. Alpine's CLI package also requires Node.js. The `cc` and `c++`
wrappers use Zig and normalize Alpine's target spelling so parser compilation
works without GCC. These packages take disk space but are not idle services.
This is not the smallest possible editor installation.

**Lua-server compatibility exception:** the current LuaLS release does not
publish the musl archive Mason requests. On a fresh install, AlpineWS seeds the
older **3.13.9 musl release** through the pinned Mason plugin and replaces only
its generated Bash launcher with a POSIX launcher. The server binary, real Mason
receipt and Blix Lua files are not modified. An existing working server is
preserved. Both the real binary and launcher must execute before this stage
succeeds. The stage is skipped for a preserved custom Neovim configuration.

Mason updates can replace that launcher or select a release without a musl
archive. Rerun the full installer to repair a broken entry point. The older
version is a documented compatibility pin, not a claim of latest-version parity.
See [editor bootstrap details](docs/EDITOR-BOOTSTRAP.md) before updating it.

Other plugin downloads, updates, Mason tools and the writable state lockfile
follow Blix. First launch needs network access and time for downloads and parser
compilation. General musl support is not guaranteed for every future Mason
package. No glibc compatibility layer, Codex, Parsec, Python or language-SDK
collection is installed. Plugin and language-tool state is not routinely erased.

## Browser, media and session

Firefox policy installs **uBlock Origin, Dark Reader and Enhancer for YouTube**
from Mozilla on the first connected launch, including private windows. Extension
signature verification and normal extension updates remain enabled. Policies
also set strict tracking protection, Global Privacy Control, dark content
defaults, no sponsored/recommended home content, no studies/telemetry and blocked
Firefox AI features. Check `about:policies` and `about:addons`. Existing policy
conflicts are preserved unless `--replace-config` is supplied.

Xfe handles files, mpv handles media and feh handles images. The package manifest
is `config/packages`. The installer does not uninstall an existing tmux package
or erase old user tmux files; it simply no longer provisions them.

PipeWire, WirePlumber and the PulseAudio compatibility process run only with X.
There is no separate PulseAudio server or parallel OpenRC user audio service.
The desktop enables system D-Bus and Alpine's eudev device management. It adds
no Bluetooth, printing, discovery, automounting, SSH server, portal or
power-management daemon. Audio/video/render group permissions replace elogind.
Intel graphics/Wi-Fi firmware, microcode and the media driver target the T490's
integrated hardware. Intel Wi-Fi power saving is disabled as in Blix.

The X runtime directory is validated before session D-Bus starts. Hotplug waits
for udev events. A small XFixes listener records at most 100 plain-text clipboard
entries, capped at 1 MiB each, and skips image-only selections. Screenshots copy
the actual PNG to the clipboard. History can contain secrets despite being
private; `clipboard-history --clear` clears it, and normal X-session exit deletes
it. There are no idle locking/display-blanking timers or compositor.

**Not literally GNU-free:** the shell and core utilities remain BusyBox, and
builds use Zig/LLVM rather than GCC/GNU make/binutils. Stock application packages
still need their runtime libraries, and st uses ncurses terminfo. Removing
required libraries is not a supported way to shrink the stack. GPL licensing
alone does not make a package a GNU project.

## Locking and power

Super+L uses i3lock. Control-menu suspend locks first and proceeds only after the
locker successfully daemonizes with input grabbed. Reboot, poweroff and logout
require confirmation. Doas grants only three exact, argument-restricted actions
through a root-owned helper, not a passwordless root shell. Installation itself
still requires normal doas access.

There is **no global suspend inhibitor or automatic lid-lock service**. Existing
ACPI handlers are left untouched. Inspect `/etc/acpi/handler.sh` before relying
on lid behavior. Suspend from another program/root or an existing lid handler
bypasses the menu's locking sequence. Test lock/resume on the T490 before relying
on it.

Alpine's Xorg build lacks logind integration. This profile uses its console-only
root Xorg wrapper. VT switching and the X-server kill shortcut are disabled while
X runs, so a locked screen cannot simply reveal its logged-in parent TTY. Exit
OXWM to return to the console. A root X server has a different security model
from a sandboxed Wayland session.

Only one managed X session per user is supported. Logs are in
`~/.local/state/alpinews/`. After an unclean crash, check for surviving X/audio
processes before removing the stale `alpinews-session` directory inside
`$XDG_RUNTIME_DIR` or `/tmp/alpinews-runtime-$(id -u)`.

## Validation and limits

```sh
sh tests/test.sh        # Offline shell/config/monitor checks
sh tests/nvim-config.sh # Unchanged Blix copy, backups, nvimide and no-tmux checks
sh tests/compiler.sh    # Compiler argument/target regression tests
sh tests/smoke.sh       # Post-install command checks, as the normal user
```

Two GitHub Actions workflows run in clean Alpine 3.24 x86_64 containers. Check
[Actions](https://github.com/blakepiper/alpinews/actions) for the relevant commit;
a workflow file's existence alone does not mean its tests passed.

`Alpine installation checks` installs the actual runtime/build manifests, builds
pinned OXWM, patched st and the clipboard listener as an unprivileged user,
compares installed Neovim files against Blix, and removes the temporary build
group. It runs the installed X-session script under Xvfb and checks st execution,
real screenshot PNG clipboard round-tripping, audio-service connectivity, the
OXWM quit binding and session cleanup. A virtual soundless container cannot test
actual audio output.

`Blix editor bootstrap` runs the config-only installer and the same language-server
bootstrap function used by a full install. It checks rerun behavior, compiler
target normalization, plugin restoration, actual Mason tool execution and
representative parser compilation/parsing. It does not alter copied Blix Lua
to make tests pass. Integration scripts are for disposable CI homes, not a live
desktop. Xvfb and CI-only diagnostic packages are not runtime dependencies.

**Still needs physical-device verification:** boot/TTY-to-Xorg startup, root
service/device setup on an installed system, Intel acceleration, Wi-Fi, physical
input, HDMI hotplug, actual sound/microphone, Firefox extension activation,
locking and suspend/resume. Container/Xvfb success is not a T490 hardware test or
an idle-memory measurement. No 200 MiB idle claim is made. Downloads and future
upstream changes can fail independently. Missing dependencies or build failures
stop the installer; it never mixes edge packages or substitutes unverified builds.

See [source provenance](docs/SOURCES.md) and [editor bootstrap](docs/EDITOR-BOOTSTRAP.md).
