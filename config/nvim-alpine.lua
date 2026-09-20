-- Preserve Blix's UI and keybindings without automatically installing toolchains.
-- Install native language servers with apk when a project needs them.
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "nvim-treesitter/nvim-treesitter", enabled = false },
  { "nvim-treesitter/nvim-treesitter-textobjects", enabled = false },
  { "neovim/nvim-lspconfig", opts = { servers = { lua_ls = { enabled = false } } } },
  { "saghen/blink.cmp", opts = { fuzzy = { implementation = "lua" } } },
  {
    "stevearc/conform.nvim",
    opts = { formatters = { stylua = { condition = function() return vim.fn.executable("stylua") == 1 end } } },
  },
}
