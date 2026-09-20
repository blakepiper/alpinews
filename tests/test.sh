#!/bin/sh
# Offline tests: BusyBox shell syntax, preservation and mocked monitor behavior.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$ROOT/lib/common.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export REPLACE_CONFIG=0
printf old > "$tmp/source"
put_file "$tmp/source" "$tmp/dest"
cmp "$tmp/source" "$tmp/dest"
printf changed > "$tmp/source"
put_file "$tmp/source" "$tmp/dest"
[ "$(cat "$tmp/dest")" = old ]
REPLACE_CONFIG=1
put_file "$tmp/source" "$tmp/dest"
[ "$(cat "$tmp/dest")" = changed ]
[ "$(cat "$tmp/dest".backup.*)" = old ]
# Replacing a symlink must not overwrite its original target.
printf private > "$tmp/target"
ln -s "$tmp/target" "$tmp/link"
put_file "$tmp/source" "$tmp/link"
[ ! -L "$tmp/link" ] && [ "$(cat "$tmp/target")" = private ]
# Directories are preserved/replaced together, not partially merged.
mkdir "$tmp/tree"
printf new > "$tmp/tree/a"
put_tree "$tmp/tree" "$tmp/tree-dest"
printf custom > "$tmp/tree-dest/a"
REPLACE_CONFIG=0
put_tree "$tmp/tree" "$tmp/tree-dest"
[ "$(cat "$tmp/tree-dest/a")" = custom ]
REPLACE_CONFIG=1
put_tree "$tmp/tree" "$tmp/tree-dest"
[ "$(cat "$tmp/tree-dest/a")" = new ]

printf '%s\n' 'https://dl-cdn.alpinelinux.org/alpine/v3.24/main' \
    'https://dl-cdn.alpinelinux.org/alpine/v3.24/community' > "$tmp/repos"
check_repositories "$tmp/repos"
printf '%s\n' 'https://dl-cdn.alpinelinux.org/alpine/edge/main' > "$tmp/repos"
if (check_repositories "$tmp/repos"); then die 'Mixed/edge repositories were accepted.'; fi
grep -qx 'bash' "$ROOT/config/packages" || die 'Bash is missing from the runtime manifest.'
grep -qx 'shadow' "$ROOT/config/packages" || die 'Shadow is missing from the runtime manifest.'
grep -Fq 'chsh -s /bin/bash' "$ROOT/lib/system.sh" || die 'The installer does not select Bash as the login shell.'

mkdir -p "$tmp/bin" "$tmp/home/.config/alpinews"
cat > "$tmp/bin/xrandr" <<'MOCK'
#!/bin/sh
if [ "$1" = --query ]; then cat "$XR_FIXTURE"; else printf '%s\n' "$*" >> "$XR_CALLS"; fi
MOCK
chmod +x "$tmp/bin/xrandr"
export XR_FIXTURE="$tmp/query" XR_CALLS="$tmp/calls" DISPLAY=:99
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config"
export PATH="$tmp/bin:$PATH"
cat > "$XR_FIXTURE" <<'FIXTURE'
eDP-1 connected primary 1920x1080+0+0
   1920x1080 60.00*+
HDMI-2 connected
   1920x1080 60.00+
FIXTURE
sh "$ROOT/bin/alpinews-monitors"
grep -q -- '--same-as eDP-1' "$XR_CALLS"
: > "$XR_CALLS"
cat > "$XR_FIXTURE" <<'FIXTURE'
eDP-1 connected primary 1920x1080+0+0
   1920x1080 60.00*+
HDMI-2 disconnected
FIXTURE
sh "$ROOT/bin/alpinews-monitors"
grep -q -- '--output HDMI-2 --off' "$XR_CALLS"
grep -q -- '--auto --scale 1x1 --primary' "$XR_CALLS"
: > "$XR_CALLS"
cat > "$XR_FIXTURE" <<'FIXTURE'
eDP-2 connected primary 1920x1080+0+0
   1920x1080 60.00*+
HDMI-1 connected
   1920x1080 60.00+
FIXTURE
sh "$ROOT/bin/alpinews-monitors"
grep -q -- '--output HDMI-1' "$XR_CALLS"
grep -q -- '--same-as eDP-2' "$XR_CALLS"
: > "$XR_CALLS"
cat > "$XR_FIXTURE" <<'FIXTURE'
eDP-1 connected primary 1920x1080+0+0
   1920x1080 60.00*+
HDMI-2 connected
   1280x720 60.00+
FIXTURE
sh "$ROOT/bin/alpinews-monitors"
if grep -q -- '--same-as' "$XR_CALLS"; then die 'Unsupported mode was forced.'; fi

# Screenshot capture and cancellation under BusyBox, with clipboard calls logged.
cat > "$tmp/bin/scrot" <<'MOCK'
#!/bin/sh
[ "${SCROT_FAIL:-0}" = 0 ] || exit 1
for arg in "$@"; do file=$arg; done
printf 'PNG-test-fixture' > "$file"
MOCK
cat > "$tmp/bin/xclip" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" >> "$XR_CALLS"
MOCK
chmod +x "$tmp/bin/scrot" "$tmp/bin/xclip"
: > "$XR_CALLS"
sh "$ROOT/bin/screenshot-region" --full
grep -q -- '-t image/png' "$XR_CALLS"
[ "$(find "$HOME/Pictures/Screenshots" -name '*.png' | wc -l)" -eq 1 ]
: > "$XR_CALLS"
if SCROT_FAIL=1 sh "$ROOT/bin/screenshot-region"; then die 'Cancelled screenshot succeeded.'; fi
[ ! -s "$XR_CALLS" ]
[ "$(find "$HOME/Pictures/Screenshots" -name '*.png' | wc -l)" -eq 1 ]
[ -z "$(find "$HOME/Pictures/Screenshots" -name '.capture.*')" ]

for file in "$ROOT/install.sh" "$ROOT/lib/"*.sh "$ROOT/bin/"* "$ROOT/tests/"*.sh \
    "$ROOT/config/xinitrc" "$ROOT/config/profile" "$ROOT/config/ashrc" \
    "$ROOT/config/lid-suspend-handler" "$ROOT/config/power-root"; do
    sh -n "$file"
done
printf '\nPASS: offline shell, config-preservation, repository-guard, monitor and screenshot tests.\n'
