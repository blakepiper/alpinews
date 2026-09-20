-- Disposable CI HOME only. Load real plugins without overriding their options.
-- Run in the SAME process as the first Lazy restore. Quitting that process
-- while parsers compile leaves fresh build locks and breaks the next startup.
local ok, err = pcall(function()
  require("lazy").load({ plugins = { "nvim-treesitter" } })
  local ts = require("nvim-treesitter")
  local plugin = require("lazy.core.config").plugins["nvim-treesitter"]
  local options = require("lazy.core.plugin").values(plugin, "opts", false)
  local wanted = options.ensure_installed
  assert(type(wanted) == "table" and #wanted > 0, "No configured parser list")
  local missing = {}
  assert(vim.wait(420000, function()
    local installed = ts.get_installed()
    missing = {}
    for _, name in ipairs(wanted) do
      if not vim.tbl_contains(installed, name) then
        table.insert(missing, name)
      end
    end
    return #missing == 0
  end, 100), "Blix parser installation incomplete: " .. table.concat(missing, ", "))
  for _, name in ipairs(wanted) do
    assert(vim.treesitter.language.add(name), "Unable to load parser: " .. name)
  end
  for lang, text in pairs({ bash = "echo alpinews\n", json = '{"alpinews":true}' }) do
    local parser = vim.treesitter.get_string_parser(text, lang)
    local trees = parser:parse()
    assert(trees[1] and not trees[1]:root():has_error(), "Parser failed: " .. lang)
  end
  assert(vim.v.errmsg == "", vim.v.errmsg)
  print("PASS: all " .. #wanted .. " Blix parsers installed and loaded; native bash/json parsing")
end)
if not ok then
  io.stderr:write(tostring(err), "\n")
  vim.cmd.cquit(1)
end
vim.cmd("qa!")
