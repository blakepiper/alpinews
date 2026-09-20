#!/bin/sh
# Keep Blix's editor base untouched. The managed nvimide layout overlay is
# applied before this stage; seed only a missing/broken LuaLS tool.
prepare_editor() (
    set -eu
    umask 077
    case "${NVIM_APPNAME:-nvim}" in
        nvim) ;;
        *) die 'Unset NVIM_APPNAME before installing the standard Blix editor.' ;;
    esac
    mason_root=${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason
    server=$mason_root/bin/lua-language-server
    binary=$mason_root/packages/lua-language-server/libexec/bin/lua-language-server
    if [ -x "$server" ] && "$server" --version >/dev/null 2>&1; then
        log 'Preserving the existing working Mason Lua language server'
        return 0
    fi
    if [ ! -x "$binary" ] || ! "$binary" --version >/dev/null 2>&1; then
        # mason.nvim revision recorded in the pinned Blix lockfile.
        mason_rev=2a6940af80375532e5e9e7c1f2fc6319a1b7a69d
        fetch_repo https://github.com/mason-org/mason.nvim.git "$mason_rev" "$WORK/mason-bootstrap"
        export ALPINEWS_MASON_SOURCE="$WORK/mason-bootstrap"
        log 'Installing the published LuaLS 3.13.9 musl build through Mason'
        mkdir -p "$STATE"
        # An isolated -u NONE process avoids a competing automatic LSP install.
        # No user Lua, plugin versions or Mason receipts are rewritten.
        if ! timeout 180 nvim --headless -u NONE \
            --cmd 'lua vim.opt.rtp:prepend(vim.env.ALPINEWS_MASON_SOURCE); require("mason").setup()' \
            '+MasonInstall lua-language-server@3.13.9' '+qa!' > "$STATE/editor-tools.log" 2>&1; then
            tail -n 60 "$STATE/editor-tools.log" >&2
            die 'Lua language-server bootstrap failed; see editor-tools.log and rerun.'
        fi
    fi
    "$binary" --version || die 'The installed musl Lua language-server binary does not execute.'
    # Mason's generated exec launcher requires Bash. Replace only this generated
    # entry point with a POSIX launcher for the same binary, not a fake Bash shim.
    # Keep its original entry point and leave the real Mason receipt intact.
    mkdir -p "$mason_root/bin"
    if { [ -e "$server" ] || [ -L "$server" ]; } && \
        [ ! -e "$server.alpinews-original" ] && [ ! -L "$server.alpinews-original" ]; then
        cp -P "$server" "$server.alpinews-original"
    fi
    launcher=$(mktemp "$mason_root/bin/.alpinews-luals.XXXXXX")
    trap 'rm -f "$launcher"' EXIT
    cat > "$launcher" <<'LAUNCHER'
#!/bin/sh
# AlpineWS POSIX entry point for the real Mason-managed musl binary.
exec "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/packages/lua-language-server/libexec/bin/lua-language-server" "$@"
LAUNCHER
    chmod 755 "$launcher"
    mv "$launcher" "$server"
    "$server" --version || die 'The POSIX Lua language-server launcher does not execute.'
)
