#!/bin/sh
# Run after installation as the desktop user. Never changes configuration.
set -u
fail=0
check() { if "$@"; then printf 'PASS: %s\n' "$*"; else printf 'FAIL: %s\n' "$*"; fail=1; fi; }
has_st_terminfo() {
    # Alpine's ncurses-terminfo-base installs in /etc, not /usr/share.
    for directory in /etc/terminfo /usr/share/terminfo /lib/terminfo /usr/lib/terminfo; do
        for bucket in s 73; do
            [ ! -r "$directory/$bucket/st-256color" ] || return 0
        done
    done
    return 1
}
export PATH="$HOME/.local/bin:$PATH"
for cmd in oxwm st nvim firefox xfe dmenu pipewire wireplumber wpctl i3lock \
    brightnessctl xrandr xclip alpinews-monitors alpinews-clipwatch; do
    check command -v "$cmd"
done
check oxwm --validate "${XDG_CONFIG_HOME:-$HOME/.config}/oxwm/config.lua"
check has_st_terminfo
check rc-service dbus status
check test -r /etc/firefox/policies/policies.json
check test -r /etc/X11/xorg.conf.d/90-alpinews.conf
if [ -n "${DISPLAY:-}" ]; then
    check xrandr --query
    check wpctl status
fi
printf '\nManual checks: about:policies and about:addons; sound/mic; brightness;\n'
printf 'Gaming Keyboard versus internal keyboard; mouse versus TrackPoint; HDMI unplug/replug;\n'
printf 'Super+L and control-menu suspend/resume; screenshot paste; Super+V text history.\n'
printf 'No hardware behavior is inferred from these command checks.\n'
exit "$fail"
