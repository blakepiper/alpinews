#!/bin/sh
# Only run in a disposable test HOME, never against a personal browser profile.
set -eu
[ "${ALPINEWS_DISPOSABLE_TEST:-0}" = 1 ] || {
    echo 'Set ALPINEWS_DISPOSABLE_TEST=1 in a disposable test environment.' >&2
    exit 1
}
for cmd in firefox jq; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing test command: $cmd" >&2; exit 1; }
done
work=$(mktemp -d)
pid=''
cleanup() {
    trap - EXIT
    if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; fi
    [ ! -f "$work/firefox.log" ] || tail -n 60 "$work/firefox.log"
    rm -rf "$work"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
mkdir "$work/profile"
firefox --headless --no-remote --profile "$work/profile" about:blank > "$work/firefox.log" 2>&1 &
pid=$!
tries=0
while [ "$tries" -lt 180 ]; do
    if [ -s "$work/profile/extensions.json" ] && jq -e '
        .addons as $addons |
        all(["uBlock0@raymondhill.net", "addon@darkreader.org", "enhancerforyoutube@maximerf.addons.mozilla.org"][];
            . as $id | any($addons[]; .id == $id and .active == true and .appDisabled == false))
    ' "$work/profile/extensions.json" >/dev/null 2>&1; then
        echo 'PASS: Firefox first launch installed and activated all three requested extensions.'
        exit 0
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
        echo 'Firefox exited before extension setup completed.' >&2
        exit 1
    fi
    sleep 1
    tries=$((tries + 1))
done
if [ -f "$work/profile/extensions.json" ]; then
    jq '[.addons[] | {id, active, appDisabled}]' "$work/profile/extensions.json" >&2 || :
fi
echo 'The requested Firefox extensions did not all activate within 180 seconds.' >&2
exit 1
