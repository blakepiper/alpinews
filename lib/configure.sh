#!/bin/sh
make_nvim_config() (
    set -eu
    dest=$1
    source="$WORK/blix/home/przvl/config/nvim"
    [ ! -e "$dest" ] || die "Refusing to reuse the Neovim staging directory: $dest"
    mkdir -p "$dest"
    cp -R "$source/." "$dest/"
    # Keep the pinned Blix tree as the base, with the local nvimide layout as
    # the only managed Lua overlay.
    cp "$ROOT/config/nvim/lua/config/ide.lua" "$dest/lua/config/ide.lua"
)

configure_user() (
    set -eu
    cfg=${XDG_CONFIG_HOME:-$HOME/.config}
    seed=$(mktemp -d "$WORK/user-seed.XXXXXX")
    mkdir -p "$cfg" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/Pictures/Screenshots"
    # Create the parser runtime root before the first editor launch, so it is
    # present when Neovim/Lazy initialize their runtime search paths. No Lua
    # override or parser state replacement is needed.
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser"
    # Copy Blix's complete Neovim configuration, then apply the small local
    # nvimide layout overlay. Keep its plugin choices, lockfile and theme.
    make_nvim_config "$seed/nvim"
    put_tree "$seed/nvim" "$cfg/nvim"
    sed -e 's/BLIX_BATTERY/ALPINEWS_BATTERY/g; s/blix-lock/alpinews-lock/g; s/blix-brightness/alpinews-brightness/g' \
        -e 's/oxwm.set_terminal("st")/oxwm.set_terminal("st-bash")/' \
        -e '/oxwm.key.bind({ mod }, "Return", oxwm.spawn_terminal())/a\
oxwm.key.bind({ "Mod1" }, "Return", oxwm.spawn_terminal())' \
        "$WORK/blix/home/przvl/config/oxwm/config.lua" > "$seed/oxwm.lua"
    grep -q 'oxwm.set_terminal("st-bash")' "$seed/oxwm.lua" || die 'Pinned OXWM config no longer exposes the terminal setting.'
    grep -q 'oxwm.key.bind({ "Mod1" }, "Return", oxwm.spawn_terminal())' "$seed/oxwm.lua" || die 'Pinned OXWM config no longer exposes the compatibility terminal binding.'
    put_file "$seed/oxwm.lua" "$cfg/oxwm/config.lua"
    put_file "$ROOT/config/xinitrc" "$HOME/.xinitrc" 755
    put_file "$ROOT/config/profile" "$HOME/.profile"
    put_file "$ROOT/config/bash_profile" "$HOME/.bash_profile"
    put_file "$ROOT/config/bashrc" "$HOME/.bashrc"
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
