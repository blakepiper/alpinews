#!/bin/sh
build_desktop() (
    set -eu
    case "$(zig version)" in 0.16.*) ;; *) die 'The pinned OXWM requires Zig 0.16.x.' ;; esac
    log 'Building pinned OXWM as your user'
    fetch_repo https://github.com/tonybanters/oxwm.git "$OXWM_REV" "$WORK/oxwm"
    cd "$WORK/oxwm"
    for p in "$WORK/blix/packaging/oxwm/"*.patch; do
        git apply --check "$p"
        git apply "$p"
    done
    # Upstream requests an external linker. Use Zig/LLVM LLD instead of adding
    # GNU binutils; this is the sole Alpine-specific build-system change.
    grep -q 'use_lld = false;' build.zig || die 'OXWM linker setting changed.'
    sed 's/use_lld = false;/use_lld = true;/g' build.zig > build.zig.new
    mv build.zig.new build.zig
    zig build -j2 -Doptimize=ReleaseSmall -Dtarget=x86_64-linux-musl -Dcpu=baseline
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/licenses/oxwm"
    # Executables are generated artifacts, not editable configuration.
    cp zig-out/bin/oxwm "$HOME/.local/bin/oxwm.new"
    chmod 755 "$HOME/.local/bin/oxwm.new"
    mv "$HOME/.local/bin/oxwm.new" "$HOME/.local/bin/oxwm"
    cp LICENSE "$HOME/.local/share/licenses/oxwm/LICENSE"

    log 'Building st 0.9.3 with the Blix scrollback/URL patch and palette'
    cd "$WORK"
    curl --fail --location --proto '=https' --proto-redir '=https' \
        --connect-timeout 15 --max-time 180 --retry 2 \
        https://dl.suckless.org/st/st-0.9.3.tar.gz -o st.tar.gz
    printf '%s\n' '9ed9feabcded713d4ded38c8cebf36a3b08f0042ef7934a0e2b2409da56e649b  st.tar.gz' | sha256sum -c -
    tar -xzf st.tar.gz
    cd st-0.9.3
    git apply --check "$WORK/blix/packaging/st/0001-scrollback-and-urls.patch"
    git apply "$WORK/blix/packaging/st/0001-scrollback-and-urls.patch"
    cp "$WORK/blix/packaging/st/config.h" config.h
    # This is the upstream two-source-file build without a make dependency.
    # pkgconf output is intentionally word-split into compiler arguments.
    zig cc -target x86_64-linux-musl -O2 -D_XOPEN_SOURCE=600 '-DVERSION="0.9.3"' \
        $(pkgconf --cflags x11 xft fontconfig) st.c x.c -o st \
        $(pkgconf --libs x11 xft fontconfig) -lutil -lm -lrt
    cp st "$HOME/.local/bin/st.new"
    chmod 755 "$HOME/.local/bin/st.new"
    mv "$HOME/.local/bin/st.new" "$HOME/.local/bin/st"
    mkdir -p "$HOME/.local/share/man/man1" "$HOME/.local/share/licenses/st"
    cp st.1 "$HOME/.local/share/man/man1/st.1"
    cp LICENSE "$HOME/.local/share/licenses/st/LICENSE"
    log 'Building the event-driven clipboard listener'
    zig cc -target x86_64-linux-musl -Os $(pkgconf --cflags x11 xfixes) \
        "$ROOT/src/clipwatch.c" -o "$HOME/.local/bin/alpinews-clipwatch.new" \
        $(pkgconf --libs x11 xfixes)
    chmod 755 "$HOME/.local/bin/alpinews-clipwatch.new"
    mv "$HOME/.local/bin/alpinews-clipwatch.new" "$HOME/.local/bin/alpinews-clipwatch"
)
