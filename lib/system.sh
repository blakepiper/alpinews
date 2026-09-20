#!/bin/sh
# Only these stages run with privilege. Sources and builds never do.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$ROOT/lib/common.sh"
[ "$(id -u)" = 0 ] || die 'This stage requires root.'
[ "$#" = 3 ] || die 'Internal usage: system.sh packages|configure USER REPLACE'
phase=$1 user=$2 REPLACE_CONFIG=$3
case "$user" in ''|*[!a-zA-Z0-9_-]*) die 'Unsupported user name.' ;; esac
[ "$(id -u "$user")" != 0 ] || die 'Refusing root desktop configuration.'
case "$(cat /etc/alpine-release)" in 3.24.*) ;; *) die 'Alpine 3.24 required.' ;; esac
[ "$(uname -m)" = x86_64 ] || die 'x86_64 required.'
export REPLACE_CONFIG
case "$phase" in
packages)
    check_repositories /etc/apk/repositories
    # Add the same mirror's community repo, not edge or another release.
    if ! grep -Eq '^https://.*/v3\.24/community/?[[:space:]]*$' /etc/apk/repositories; then
        main=$(sed -n 's|^\(https://.*/v3\.24\)/main/*[[:space:]]*$|\1|p' /etc/apk/repositories | head -n 1)
        [ -n "$main" ] || die 'No HTTPS Alpine 3.24 main repository.'
        cp /etc/apk/repositories "/etc/apk/repositories.backup.$(date +%Y%m%d-%H%M%S).$$"
        printf '\n%s/community\n' "$main" >> /etc/apk/repositories
    fi
    log 'Resolving official Alpine packages before making changes'
    apk update
    # No wildcard removal or replacement of an existing network manager.
    set -- $(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$ROOT/config/packages")
    apk add --simulate "$@"
    apk add --simulate --virtual .alpinews-build zig pkgconf musl-dev libx11-dev libxft-dev libxinerama-dev libxfixes-dev fontconfig-dev
    apk upgrade
    apk add "$@"
    apk add --virtual .alpinews-build zig pkgconf musl-dev libx11-dev libxft-dev libxinerama-dev libxfixes-dev fontconfig-dev
    ;;
configure)
    for group in audio video render; do
        if grep -q "^$group:" /etc/group; then
            case " $(id -Gn "$user") " in
                *" $group "*) ;;
                *) addgroup "$user" "$group" ;;
            esac
        fi
    done
    # Alpine's supported Xorg device setup switches mdev to standalone eudev.
    setup-devd udev
    rc-update add dbus default
    rc-service dbus status >/dev/null 2>&1 || rc-service dbus start
    put_file "$ROOT/config/xorg.conf" /etc/X11/xorg.conf.d/90-alpinews.conf
    put_file "$ROOT/config/Xwrapper.config" /etc/X11/Xwrapper.config
    put_file "$ROOT/config/input.rules" /etc/udev/rules.d/90-alpinews-input.rules
    put_file "$ROOT/config/iwlwifi.conf" /etc/modprobe.d/alpinews-iwlwifi.conf
    put_file "$ROOT/config/policies.json" /etc/firefox/policies/policies.json
    # A distribution policy has precedence over /etc/firefox/policies.
    if [ -e /usr/lib/firefox/distribution/policies.json ]; then
        put_file "$ROOT/config/policies.json" /usr/lib/firefox/distribution/policies.json
    fi
    mkdir -p /usr/local/libexec /etc/doas.d
    [ ! -L /usr/local/libexec ] || die 'Refusing a symlinked privileged helper directory.'
    [ "$(stat -c %u /usr/local/libexec)" = 0 ] || die 'Helper directory must be root-owned.'
    mode=$(stat -c %a /usr/local/libexec)
    [ "$((0$mode & 0022))" = 0 ] || die 'Helper directory must not be writable by other users.'
    # Privileged code is always replaced, never trusted as a preserved user edit.
    (REPLACE_CONFIG=1; put_file "$ROOT/config/power-root" /usr/local/libexec/alpinews-power 755)
    chown root:root /usr/local/libexec/alpinews-power
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    for action in suspend reboot poweroff; do
        printf 'permit nopass %s as root cmd /usr/local/libexec/alpinews-power args %s\n' "$user" "$action"
    done > "$tmp"
    doas -C "$tmp"
    put_file "$tmp" /etc/doas.d/alpinews.conf 600
    udevadm control --reload-rules
    # Apply rules at next boot/hotplug, without interrupting current input.
    ;;
*) die 'Unknown internal stage.' ;;
esac
