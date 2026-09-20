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
  local ready = vim.wait(420000, function()
    -- The no-argument API includes query-only directories. Those do not prove
    -- that the corresponding compiled parser has been installed yet.
    local installed = ts.get_installed("parsers")
    missing = {}
    for _, name in ipairs(wanted) do
      if not vim.tbl_contains(installed, name) then
        table.insert(missing, name)
      end
    end
    return #missing == 0
  end, 100)
  assert(ready, "Blix parser installation incomplete: " .. table.concat(missing, ", "))
  for _, name in ipairs(wanted) do
    -- Construct and use every parser, not just check a directory entry.
    local loaded, why = vim.treesitter.language.add(name)
    assert(loaded, tostring(why) .. " (parser: " .. name .. ")")
    local parser = vim.treesitter.get_string_parser("", name)
    assert(parser:parse()[1], "No syntax tree produced: " .. name)
  end
  for lang, text in pairs({ bash = "echo alpinews\n", json = '{"alpinews":true}' }) do
    local parser = vim.treesitter.get_string_parser(text, lang)
    local trees = parser:parse()
    assert(trees[1] and not trees[1]:root():has_error(), "Parser failed: " .. lang)
  end
  assert(vim.v.errmsg == "", vim.v.errmsg)
  print("PASS: all " .. #wanted .. " Blix parsers installed, loaded and exercised; native bash/json parsing")
end)
if not ok then
  io.stderr:write(tostring(err), "\n")
  io.stderr:write("Runtime path: ", vim.o.runtimepath, "\n")
  io.stderr:write("Parser files: ", vim.inspect(vim.api.nvim_get_runtime_file("parser/*", true)), "\n")
  vim.cmd.cquit(1)
end
vim.cmd("qa!")
