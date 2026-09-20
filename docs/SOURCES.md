# Sources and deliberate changes

## User repositories (read-only)

- Blix: `4a4b8017d07421796047e12edceba87e21e3f24e`
  <https://github.com/blakepiper/blix/tree/4a4b8017d07421796047e12edceba87e21e3f24e>
  OXWM/Neovim/MIME configuration under `home/przvl/config`, st/OXWM patches
  under `packaging`, browser policies under `home/przvl/programs/browser.nix`,
  T490 monitor settings in `hosts/t490/home.nix`, and input/Wi-Fi preferences in
  `modules/common/desktop-session.nix` and `hosts/t490/default.nix`.
- Minarch: `f954da42f061c5e4806a33fec593315f002bd192`
  <https://github.com/blakepiper/minarch/tree/f954da42f061c5e4806a33fec593315f002bd192>
  Post-install/preservation workflow reference; st source checksum; initial
  Xfe color settings from `config/xfe/xferc`. No runtime clone of Minarch.

A fresh temporary Git checkout verifies the exact Blix commit. Only configuration
and patch files are used; no Blix/Minarch installer is executed. Temporary source
checkouts are removed after installation. Upstream licenses remain applicable;
OXWM/st licenses are installed beside the locally built binaries. This repository
does not claim authorship of the imported editor theme, plugins or upstream patches.

## Software and packaging

- OXWM 0.13.0: `fc4ada9ac4ee8e34ace203290a2b14d10e4671cc`
  <https://github.com/tonybanters/oxwm/tree/fc4ada9ac4ee8e34ace203290a2b14d10e4671cc>
  Uses the two Blix patches. Its `use_lld = false` build settings are changed to
  `true` to use Zig/LLVM instead of requiring GNU binutils. Lua's source is pinned
  and hash-verified by the upstream `build.zig.zon` dependency.
- st 0.9.3: <https://dl.suckless.org/st/st-0.9.3.tar.gz>
  SHA-256: `9ed9feabcded713d4ded38c8cebf36a3b08f0042ef7934a0e2b2409da56e649b`
  Builds `st.c` and `x.c` directly with Zig's C compiler, using Blix's patch/config.
- Alpine 3.24 release information: <https://alpinelinux.org/releases/>
- Alpine Xorg setup: <https://github.com/alpinelinux/alpine-conf/blob/master/setup-xorg-base.in>
- Xorg package: <https://github.com/alpinelinux/aports/blob/3.24-stable/community/xorg-server/APKBUILD>
  Builds with `systemd_logind=false` and installs a setuid console wrapper.
- Zig package: <https://github.com/alpinelinux/aports/blob/3.24-stable/community/zig/APKBUILD>
- Firmware: <https://github.com/alpinelinux/aports/blob/3.24-stable/main/linux-firmware/APKBUILD>
  Intel Wi-Fi lives in `linux-firmware-intel`, not the older `-iwlwifi` split.
- WirePlumber: <https://github.com/alpinelinux/aports/blob/3.24-stable/community/wireplumber/APKBUILD>
  Elogind support is separately packaged. This profile does not install it.
- Doas: <https://github.com/alpinelinux/aports/blob/3.24-stable/main/doas/APKBUILD>
  Alpine enables `/etc/doas.d` support.
- Firefox extension policy: <https://firefox-admin-docs.mozilla.org/reference/policies/extensionsettings/>
- Firefox AI policy: <https://firefox-admin-docs.mozilla.org/reference/policies/aicontrols/>
- i3lock: <https://github.com/i3/i3lock>
  The default parent exits after the lock's MapNotify; do not add `--nofork` to
  the lock helper without changing the suspend handshake.

APK packages track security updates within Alpine 3.24; only custom source builds
and imported user preferences are pinned. Firefox extensions use Mozilla's signed,
compatible releases rather than frozen XPI binaries.
