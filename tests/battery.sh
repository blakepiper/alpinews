#!/bin/sh
# Run on a fake sysfs tree; never touch the host battery or require root.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
# Source exactly the production functions, omitting only the final main call.
sed '$d' "$ROOT/config/battery-limit" > "$WORK/functions.sh"
. "$WORK/functions.sh"
SUPPLY="$WORK/power supply"
mkdir -p "$SUPPLY/BAT0"
END="$SUPPLY/BAT0/charge_control_end_threshold"
START="$SUPPLY/BAT0/charge_control_start_threshold"

printf '100\n' > "$END"
printf '96\n' > "$START"
# Enforce the real start < stop constraint and log every attempted write.
write_threshold() {
    [ "$(read_threshold "$1")" != "$2" ] || return 0
    case "$1" in
        */charge_control_start_threshold) [ "$2" -lt "$(cat "${1%/*}/charge_control_end_threshold")" ] || return 1 ;;
        */charge_control_end_threshold)
            if [ -e "${1%/*}/charge_control_start_threshold" ]; then
                [ "$2" -gt "$(cat "${1%/*}/charge_control_start_threshold")" ] || return 1
            fi ;;
    esac
    printf '%s %s\n' "${1##*/}" "$2" >> "$WORK/writes"
    printf '%s\n' "$2" > "$1"
}
apply_battery_limit "$SUPPLY" apply
[ "$(cat "$END")" = 79 ] && [ "$(cat "$START")" = 78 ]
printf 'charge_control_start_threshold 78\ncharge_control_end_threshold 79\n' > "$WORK/expected"
cmp "$WORK/expected" "$WORK/writes"
apply_battery_limit "$SUPPLY" event
cmp "$WORK/expected" "$WORK/writes"
apply_battery_limit "$SUPPLY" check
printf '60\n' > "$START"
apply_battery_limit "$SUPPLY" apply
[ "$(cat "$START")" = 60 ]
printf '0\n' > "$START"
apply_battery_limit "$SUPPLY" apply
[ "$(cat "$START")" = 0 ]
printf '100\n' > "$END"
if apply_battery_limit "$SUPPLY" check; then exit 1; fi
mkdir "$SUPPLY/BAT1"
printf '90\n' > "$SUPPLY/BAT1/charge_control_end_threshold"
apply_battery_limit "$SUPPLY" apply
[ "$(cat "$SUPPLY/BAT1/charge_control_end_threshold")" = 79 ]
printf '0\n' > "$SUPPLY/BAT1/present"
printf '90\n' > "$SUPPLY/BAT1/charge_control_end_threshold"
apply_battery_limit "$SUPPLY" apply
[ "$(cat "$SUPPLY/BAT1/charge_control_end_threshold")" = 90 ]
mkdir "$WORK/empty"
rc=0
apply_battery_limit "$WORK/empty" apply || rc=$?
[ "$rc" = 2 ]
printf 'invalid\n' > "$END"
if apply_battery_limit "$SUPPLY" apply; then exit 1; fi

# Restore the actual write/read-back implementation.
. "$WORK/functions.sh"
printf '100\n' > "$END"
apply_battery_limit "$SUPPLY" apply
[ "$(cat "$END")" = 79 ]
# Simulate firmware accepting a write but reporting a different threshold.
read_threshold() { printf '100\n'; }
if write_threshold "$END" 79; then exit 1; fi
. "$WORK/functions.sh"
# A filesystem permission/write failure must not be reported as success.
if write_threshold /proc/version 79 2>/dev/null; then exit 1; fi

# Check the one-shot service, root installation and resume/event wiring.
grep -Fq 'rc-update add alpinews-battery-limit boot' "$ROOT/lib/system.sh"
grep -Fq 'config/battery-limit.initd' "$ROOT/lib/system.sh"
grep -Fq 'config/battery-limit.rules' "$ROOT/lib/system.sh"
grep -Fq '/usr/local/libexec/alpinews-battery-limit' "$ROOT/config/battery-limit.initd"
grep -Fq '/usr/local/libexec/alpinews-battery-limit --event' "$ROOT/config/battery-limit.rules"
grep -Fq '/usr/local/libexec/alpinews-battery-limit ||' "$ROOT/config/power-root"
for file in "$ROOT/config/battery-limit" "$ROOT/config/battery-limit.initd" "$ROOT/config/power-root" "$ROOT/lib/system.sh"; do
    sh -n "$file"
done
printf '%s\n' 'PASS: 79% cap, ordering, idempotency, preserved start, multiple/absent batteries, read-back/write failures and boot/resume wiring.'
