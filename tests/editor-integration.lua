-- Disposable CI HOME only. Load the real plugins; do not override their options.
local ok, err = pcall(function()
  require("lazy").load({ plugins = { "nvim-treesitter" } })
  local ts = require("nvim-treesitter")
  -- Blix starts its own asynchronous parser installs. Wait for representative
  -- grammars rather than launching competing installations of the same files.
  assert(vim.wait(180000, function()
    local installed = ts.get_installed()
    return vim.tbl_contains(installed, "bash") and vim.tbl_contains(installed, "json")
  end, 100), "Blix did not install the bash and json parsers")
  for lang, text in pairs({ bash = "echo alpinews\n", json = '{"alpinews":true}' }) do
    vim.treesitter.language.add(lang)
    local parser = vim.treesitter.get_string_parser(text, lang)
    local trees = parser:parse()
    assert(trees[1] and not trees[1]:root():has_error(), "Parser failed: " .. lang)
  end
  assert(vim.v.errmsg == "", vim.v.errmsg)
end)
if not ok then
  io.stderr:write(tostring(err), "\n")
  vim.cmd.cquit(1)
end
print("PASS: unchanged Blix Tree-sitter bootstrap and native bash/json parsing")
vim.cmd("qa!")
