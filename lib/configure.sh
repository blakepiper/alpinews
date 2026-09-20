#!/bin/sh
configure_user() (
    set -eu
    cfg=${XDG_CONFIG_HOME:-$HOME/.config}
    seed="$WORK/user-seed"
    mkdir -p "$seed" "$cfg" "$HOME/.local/bin" "$HOME/Pictures/Screenshots"
    # Copy Blix's complete Neovim configuration unchanged. Keep its plugin
    # choices, lockfile, theme and BLIX_NVIMIDE integration; do not inject overrides.
    put_tree "$WORK/blix/home/przvl/config/nvim" "$cfg/nvim"
    sed 's/BLIX_BATTERY/ALPINEWS_BATTERY/g; s/blix-lock/alpinews-lock/g; s/blix-brightness/alpinews-brightness/g' \
        "$WORK/blix/home/przvl/config/oxwm/config.lua" > "$seed/oxwm.lua"
    put_file "$seed/oxwm.lua" "$cfg/oxwm/config.lua"
    put_file "$ROOT/config/xinitrc" "$HOME/.xinitrc" 755
    put_file "$ROOT/config/profile" "$HOME/.profile"
    put_file "$ROOT/config/ashrc" "$cfg/ash/rc"
    put_file "$WORK/blix/home/przvl/config/mimeapps.list" "$cfg/mimeapps.list"
    put_file "$ROOT/config/display.conf" "$cfg/alpinews/display.conf"
    # Xfe rewrites history and layout into xferc. Seed it once, as Blix does.
    (REPLACE_CONFIG=0; put_file "$ROOT/config/xferc" "$cfg/xfe/xferc")
    put_file "$ROOT/config/gtk.ini" "$cfg/gtk-3.0/settings.ini"
    put_file "$ROOT/config/gtk.ini" "$cfg/gtk-4.0/settings.ini"
    for src in "$ROOT/bin/"*; do
        put_file "$src" "$HOME/.local/bin/$(basename "$src")" 755
    done
)
