#!/bin/sh
# Shared by the installer and offline tests. BusyBox ash; no Bash/GNU tools.
log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Preserve user edits, including symlinks. Replacement is opt-in and backed up.
put_file() (
    src=$1 dest=$2 mode=${3:-644}
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ ! -L "$dest" ] && [ -f "$dest" ] && cmp -s "$src" "$dest"; then
            chmod "$mode" "$dest"
            return 0
        fi
        if [ "${REPLACE_CONFIG:-0}" != 1 ]; then
            printf 'Preserved: %s (use --replace-config to replace with a backup)\n' "$dest"
            return 0
        fi
        backup="$dest.backup.$(date +%Y%m%d-%H%M%S).$$"
        [ ! -e "$backup" ] && [ ! -L "$backup" ] || die "Backup already exists: $backup"
        mv "$dest" "$backup"
        printf 'Backup: %s\n' "$backup"
    fi
    tmp=$(mktemp "$(dirname "$dest")/.alpinews.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    cp "$src" "$tmp"
    chmod "$mode" "$tmp"
    mv "$tmp" "$dest"
)

fetch_repo() (
    url=$1 rev=$2 dest=$3
    mkdir -p "$dest"
    git -C "$dest" init -q
    git -C "$dest" -c core.hooksPath=/dev/null -c protocol.file.allow=never \
        fetch -q --depth=1 "$url" "$rev"
    git -C "$dest" -c core.hooksPath=/dev/null checkout -q --detach FETCH_HEAD
    [ "$(git -C "$dest" rev-parse HEAD)" = "$rev" ] || die "Source revision mismatch: $url"
)

# All enabled repos must belong to the same supported stable branch.
check_repositories() {
    awk '
      /^[[:space:]]*($|#)/ { next }
      { if ($0 !~ /^https:\/\/[^[:space:]]+\/v3\.24\/(main|community)\/?[[:space:]]*$/) bad=1 }
      END { exit bad }
    ' "$1" || die 'Use only HTTPS v3.24/main and v3.24/community repositories; no edge or mixed releases.'
}

put_tree() (
    src=$1 dest=$2
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ ! -L "$dest" ] && [ -d "$dest" ] && diff -qr "$src" "$dest" >/dev/null 2>&1; then
            return 0
        fi
        if [ "${REPLACE_CONFIG:-0}" != 1 ]; then
            printf 'Preserved: %s (the entire directory; no partial plugin overwrite)\n' "$dest"
            return 0
        fi
        backup="$dest.backup.$(date +%Y%m%d-%H%M%S).$$"
        [ ! -e "$backup" ] && [ ! -L "$backup" ] || die "Backup already exists: $backup"
        mv "$dest" "$backup"
        printf 'Backup: %s\n' "$backup"
    fi
    cp -R "$src" "$dest"
)
