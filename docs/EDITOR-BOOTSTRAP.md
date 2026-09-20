# Blix editor on Alpine

The Neovim configuration starts from the pinned Blix commit, with one tracked
AlpineWS overlay at `config/nvim/lua/config/ide.lua` for the `nvimide` layout.
The overlay opens two stacked Snacks terminal panes and resizes both with the
editor. Compatibility work beyond that layout is confined to system prerequisites
and generated tool launchers.

The runtime manifest retains Zig, musl headers and Tree-sitter's CLI. Node.js is
an Alpine dependency of that CLI. The `cc` and `c++` wrappers translate only the
Alpine target spelling `x86_64-alpine-linux-musl` to Zig's `x86_64-linux-musl`,
including `--target=` forms. All other arguments and targets are preserved.
This fixes real parser compilation, not only a compiler-presence check.

## Lua language server

LuaLS 3.19.1's release does not publish the musl archive requested by Mason.
The full installer therefore bootstraps the **older 3.13.9 musl release** through
Mason when no working Mason Lua language server exists. It does not downgrade
an existing working installation. This is an explicit compatibility pin, not
a claim that 3.13.9 is the newest release or that it has all newer fixes.

The bootstrap uses the mason.nvim commit from Blix's lockfile:
`2a6940af80375532e5e9e7c1f2fc6319a1b7a69d`. It runs as the normal user in an
isolated `nvim -u NONE` process, before Blix can start a competing automatic
language-server installation. Mason creates the package and its real receipt.
The temporary plugin source checkout is removed with the installer workspace.

Mason's generated executable launcher requires Bash. Bash is an explicit AlpineWS
runtime dependency and login shell. AlpineWS saves that entry point as
`lua-language-server.alpinews-original` and replaces the entry point with a short
POSIX shell wrapper for the same actual musl binary. It does not pretend ash is
Bash, modify the language-server binary, forge a Mason receipt, or alter Blix's
other Lua files. Both the binary and the final wrapper must execute successfully
before this stage succeeds.

Mason updates can replace that launcher, and a release without a musl archive
will still fail to download. Rerun the full installer to repair a broken entry
point. Keep this pin until a newer compatible release has been verified. The
bootstrap and compatibility workaround are deliberately not hidden in CI.

`--config-only` only copies configuration; it does not seed the language server.
A preserved custom Neovim directory is not bootstrapped automatically. StyLua,
shfmt and other plugin-managed tools still follow Blix's normal setup. General
Mason musl compatibility is not guaranteed for arbitrary future packages.

Primary sources:
- https://github.com/LuaLS/lua-language-server/releases/tag/3.19.1
- https://github.com/LuaLS/lua-language-server/releases/tag/3.13.9
- https://github.com/mason-org/mason-registry/blob/main/packages/lua-language-server/package.yaml
