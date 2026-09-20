#!/bin/sh
# Run only in a disposable Alpine test home, after installing this profile.
# Xvfb is a test dependency; it is never added to the desktop manifest.
set -eu
[ "${ALPINEWS_DISPOSABLE_TEST:-}" = 1 ] || {
    echo 'This test requires an isolated disposable HOME, not your desktop session.' >&2
    exit 1
}
export PATH="$HOME/.local/bin:$PATH"
export XDG_RUNTIME_DIR="$HOME/test-runtime"
export LANG=C.UTF-8
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
unset DBUS_SESSION_BUS_ADDRESS
xp='' sp=''
cleanup() {
    trap - EXIT
    [ -z "$sp" ] || kill "$sp" 2>/dev/null || :
    # Closing this test display also disconnects its WM and clipboard clients.
    [ -z "$xp" ] || kill "$xp" 2>/dev/null || :
    [ -z "$sp" ] || wait "$sp" 2>/dev/null || :
    [ -z "$xp" ] || wait "$xp" 2>/dev/null || :
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
Xvfb :99 -screen 0 1280x720x24 -nolisten tcp > "$HOME/xvfb.log" 2>&1 & xp=$!
export DISPLAY=:99
tries=0
until xset q >/dev/null 2>&1; do
    kill -0 "$xp"
    tries=$((tries + 1))
    [ "$tries" -lt 100 ]
    sleep 0.1
done
sh "$HOME/.xinitrc" > "$HOME/session.log" 2>&1 & sp=$!
tries=0
until xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q 'window id #'; do
    kill -0 "$sp"
    tries=$((tries + 1))
    [ "$tries" -lt 100 ]
    sleep 0.1
done
# Exercise the installed terminal and real screenshot/clipboard path.
st -e /bin/sh -c 'printf terminal-ok > "$HOME/st-result"'
[ "$(cat "$HOME/st-result")" = terminal-ok ]
screenshot-region --full
set -- "$HOME"/Pictures/Screenshots/*.png
[ "$#" -eq 1 ] && [ -s "$1" ]
timeout 10 xclip -selection clipboard -t image/png -o > "$HOME/screenshot-copy.png"
cmp "$1" "$HOME/screenshot-copy.png"
# A container has no T490 sound card. Check service connectivity, not sound.
tries=0
until wpctl status > "$HOME/wpctl.log" 2>&1 && pactl info > "$HOME/pactl.log" 2>&1; do
    kill -0 "$sp"
    tries=$((tries + 1))
    [ "$tries" -lt 100 ]
    sleep 0.1
done
# Ask the real WM to quit with its configured binding and verify cleanup.
xdotool key --clearmodifiers super+shift+q
tries=0
while [ -d "$XDG_RUNTIME_DIR/alpinews-session" ]; do
    tries=$((tries + 1))
    [ "$tries" -lt 100 ]
    sleep 0.1
done
wait "$sp"
sp=''
printf '\nPASS: installed X session, st, screenshot PNG clipboard, audio sockets, WM exit and session cleanup.\n'
