#!/bin/sh
# A post-install configuration, never a disk installer.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$ROOT/lib/common.sh"
REPLACE_CONFIG=0 CONFIG_ONLY=0 KEEP_BUILD=0
for arg in "$@"; do
    case "$arg" in
        --replace-config) REPLACE_CONFIG=1 ;;
        --config-only) CONFIG_ONLY=1 ;;
        --keep-build-deps) KEEP_BUILD=1 ;;
        --help|-h)
            printf '%s\n' 'Usage: sh install.sh [--replace-config] [--config-only] [--keep-build-deps]' \
                'Run as your normal user on an installed Alpine 3.24 x86_64 system.' \
                'No partitions, bootloader, network manager, or user passwords are changed.' \
                '--config-only fetches pinned Blix defaults and installs user files only.'
            exit 0 ;;
        *) die "Unknown option: $arg" ;;
    esac
done
[ "$(id -u)" != 0 ] || die 'Run as a normal user, not root.'
[ -n "${HOME:-}" ] && [ -d "$HOME" ] || die 'HOME must be an existing directory.'
case "$HOME" in /*) ;; *) die 'HOME must be absolute.' ;; esac
for cmd in git curl; do
    command -v "$cmd" >/dev/null 2>&1 || die "Install $cmd first (doas apk add git curl ca-certificates)."
done
if [ "$CONFIG_ONLY" = 0 ]; then
    [ -r /etc/alpine-release ] || die 'This installer requires Alpine Linux.'
    case "$(cat /etc/alpine-release)" in 3.24.*) ;; *) die 'Use Alpine 3.24 stable, not edge.' ;; esac
    [ "$(uname -m)" = x86_64 ] || die 'This profile targets the x86_64 ThinkPad T490.'
    [ -x /sbin/rc-service ] || die 'OpenRC is required.'
    command -v doas >/dev/null 2>&1 || die 'Configure doas for your user before installation.'
    doas true || die 'Working doas access is required.'
fi
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/alpinews
mkdir -p "$STATE"
[ ! -L "$STATE" ] && [ "$(stat -c %u "$STATE")" = "$(id -u)" ] || die 'Unsafe state directory.'
LOCK="$STATE/install.lock"
mkdir "$LOCK" 2>/dev/null || die "Another install may be running. If not, remove $LOCK and retry."
printf '%s\n' "$$" > "$LOCK/pid"
WORK=$(mktemp -d "$STATE/work.XXXXXX")
cleanup() {
    rc=$?
    trap - EXIT
    rm -rf "$WORK" "$LOCK"
    if [ "$rc" != 0 ]; then
        printf '\nInstallation stopped. Fix the reported error and rerun; existing files are preserved.\n' >&2
        printf 'Temporary build packages, if installed, can be removed with: doas apk del .alpinews-build\n' >&2
    fi
    exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
export ROOT WORK STATE REPLACE_CONFIG
BLIX_REV=4a4b8017d07421796047e12edceba87e21e3f24e
OXWM_REV=fc4ada9ac4ee8e34ace203290a2b14d10e4671cc
export BLIX_REV OXWM_REV
log "Fetching read-only Blix defaults at $BLIX_REV"
fetch_repo https://github.com/blakepiper/blix.git "$BLIX_REV" "$WORK/blix"
if [ "$CONFIG_ONLY" = 0 ]; then
    doas sh "$ROOT/lib/system.sh" packages "$(id -un)" "$REPLACE_CONFIG"
    . "$ROOT/lib/build.sh"
    build_desktop
fi
. "$ROOT/lib/configure.sh"
configure_user
if [ "$CONFIG_ONLY" = 0 ]; then
    if diff -qr "$WORK/blix/home/przvl/config/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" >/dev/null 2>&1; then
        . "$ROOT/lib/editor.sh"
        prepare_editor
    else
        log 'Preserved custom Neovim configuration; leaving its language-tool installation alone'
    fi
    doas sh "$ROOT/lib/system.sh" configure "$(id -un)" "$REPLACE_CONFIG"
    "$HOME/.local/bin/oxwm" --validate "${XDG_CONFIG_HOME:-$HOME/.config}/oxwm/config.lua"
    if [ "$KEEP_BUILD" = 0 ]; then
        doas apk del .alpinews-build
    fi
    apk info -v > "$STATE/packages-installed.txt"
fi
printf '%s\n' "Blix $BLIX_REV" "OXWM $OXWM_REV" 'st 0.9.3' > "$STATE/sources.txt"
printf '\nAlpineWS configuration installed. Review every Preserved message above.\n'
if [ "$CONFIG_ONLY" = 0 ]; then
    printf 'Reboot for device permissions/firmware, log in on a local TTY, then run startx.\n'
else
    printf 'Config-only does not install programs or system settings.\n'
fi
printf 'Run sh tests/smoke.sh on the T490; hardware operation still needs local verification.\n'
