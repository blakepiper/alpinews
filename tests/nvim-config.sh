#!/bin/sh
# Offline regression tests. Exercise the real installer with a fake Blix checkout.
set -eu
SOURCE_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$SOURCE_ROOT/lib/common.sh"
. "$SOURCE_ROOT/lib/configure.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

# Only the installer and launcher under test are real. No network, root or
# Neovim plugin execution is needed; all writes stay inside this temporary HOME.
ROOT="$test_dir/installer"
WORK="$test_dir/work"
HOME="$test_dir/home"
XDG_CONFIG_HOME="$HOME/.config"
export ROOT WORK HOME XDG_CONFIG_HOME
upstream="$WORK/blix/home/przvl/config"
mkdir -p "$ROOT/config" "$ROOT/bin" "$HOME" \
    "$upstream/nvim/lua/config" "$upstream/nvim/lua/plugins" \
    "$upstream/oxwm" "$upstream/tmux"
for file in xinitrc profile ashrc display.conf xferc gtk.ini; do
    printf '# fixture\n' > "$ROOT/config/$file"
done
# Kept in the fixture so this test catches the old override-injection code.
printf 'return { { "mason-org/mason.nvim", enabled = false } }\n' > "$ROOT/config/nvim-alpine.lua"
cp "$SOURCE_ROOT/bin/nvimide" "$ROOT/bin/nvimide"
printf '%s\n' 'set -g mouse on' > "$upstream/tmux/tmux.conf"
printf '%s\n' '[Default Applications]' > "$upstream/mimeapps.list"
printf '%s\n' '-- OXWM fixture' > "$upstream/oxwm/config.lua"
cat > "$upstream/nvim/init.lua" <<'LUA'
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.ide")
LUA
cat > "$upstream/nvim/lua/config/ide.lua" <<'LUA'
if vim.env.BLIX_NVIMIDE ~= "1" then
  return
end
local group = vim.api.nvim_create_augroup("blix_nvimide", { clear = true })
LUA
cat > "$upstream/nvim/lua/config/lazy.lua" <<'LUA'
return {
  checker = {
    enabled = true, -- check for plugin updates periodically
  },
}
LUA
cat > "$upstream/nvim/lua/plugins/seafoam.lua" <<'LUA'
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "seafoam",
    },
  },
}
LUA
printf '%s\n' '{"fixture": {"commit": "unchanged"}}' > "$upstream/nvim/lazy-lock.json"
printf '%s\n' '{"fixture": true}' > "$upstream/nvim/.neoconf.json"
cp -R "$upstream/nvim" "$test_dir/original"

REPLACE_CONFIG=0
export REPLACE_CONFIG
configure_user
installed="$XDG_CONFIG_HOME/nvim"
diff -qr "$upstream/nvim" "$installed"
[ ! -e "$installed/lua/plugins/alpinews.lua" ]
# An unchanged rerun must not produce a backup or alter the source checkout.
configure_user
for backup in "$installed".backup.*; do
    [ ! -e "$backup" ] || die 'Unchanged Neovim config produced a backup.'
done
diff -qr "$test_dir/original" "$upstream/nvim"

# Simulate an old AlpineWS installation. Preserve it by default; replacing the
# whole tree must remove the obsolete override, but keep it in the backup.
printf 'old Alpine override\n' > "$installed/lua/plugins/alpinews.lua"
configure_user
[ "$(cat "$installed/lua/plugins/alpinews.lua")" = 'old Alpine override' ]
REPLACE_CONFIG=1
configure_user
diff -qr "$upstream/nvim" "$installed"
[ ! -e "$installed/lua/plugins/alpinews.lua" ]
backup_count=0
for backup in "$installed".backup.*; do
    [ -d "$backup" ] || continue
    [ "$(cat "$backup/lua/plugins/alpinews.lua")" = 'old Alpine override' ]
    backup_count=$((backup_count + 1))
done
[ "$backup_count" -eq 1 ]
diff -qr "$test_dir/original" "$upstream/nvim"

# The launcher must set Blix's unmodified environment switch, preserve quoting,
# consume a leading directory, and leave ordinary file arguments intact.
mkdir -p "$test_dir/mock-bin" "$test_dir/project with spaces"
cat > "$test_dir/mock-bin/nvim" <<'MOCK'
#!/bin/sh
printf '%s\n' "${BLIX_NVIMIDE:-missing}" "$PWD" "$#" "$@" > "$NVIM_CALLS"
MOCK
chmod +x "$test_dir/mock-bin/nvim"
NVIM_CALLS="$test_dir/nvim-calls"
export NVIM_CALLS
PATH="$test_dir/mock-bin:$PATH"
export PATH
unset BLIX_NVIMIDE ALPINEWS_NVIMIDE
sh "$HOME/.local/bin/nvimide" "$test_dir/project with spaces" 'file with spaces.lua' '+set number'
printf '%s\n' 1 "$test_dir/project with spaces" 2 'file with spaces.lua' '+set number' > "$test_dir/expected"
cmp "$test_dir/expected" "$NVIM_CALLS"
(cd "$HOME" && sh "$HOME/.local/bin/nvimide" 'another file.lua')
printf '%s\n' 1 "$HOME" 1 'another file.lua' > "$test_dir/expected"
cmp "$test_dir/expected" "$NVIM_CALLS"

printf '\nPASS: unchanged Blix Neovim copy, override migration with backup, and nvimide launcher.\n'
