#!/bin/sh
# User-level shell dependencies installed after the privileged package stage.
install_blesh() (
    set -eu
    blesh_dir="$HOME/.local/share/blesh"
    # Avoid downloading the same immutable nightly on every full update.
    if [ "${REPLACE_CONFIG:-0}" != 1 ] && [ -r "$blesh_dir/ble.sh" ] &&
        grep -Fq '_ble_init_version=0.4.0-nightly+d81fd54' "$blesh_dir/ble.sh"; then
        log 'Preserving the pinned ble.sh nightly already installed'
        return 0
    fi

    archive="$WORK/ble-nightly.tar.xz"
    expected=${BLE_NIGHTLY_SHA256:-1b9b78ea0633ac331df150bf178fcf86210ce5916db54fb713252a51cd67cb97}
    log 'Fetching the pinned ble.sh nightly'
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
        --connect-timeout 15 --max-time 180 --retry 2 \
        https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
        -o "$archive"
    printf '%s  %s\n' "$expected" "$archive" | sha256sum -c -
    tar -xJf "$archive" -C "$WORK"
    [ -r "$WORK/ble-nightly/ble.sh" ] || die 'The pinned ble.sh archive has an unexpected layout.'

    staged="$WORK/blesh"
    mkdir -p "$staged"
    cp -R "$WORK/ble-nightly/." "$staged/"
    put_tree "$staged" "$blesh_dir"
)
