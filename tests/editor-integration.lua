-- Disposable CI HOME only. Load the real plugins; do not override their options.
local ok, err = pcall(function()
  require("lazy").load({ plugins = { "nvim-treesitter" } })
  local config = require("nvim-treesitter.config")
  local parsers = require("nvim-treesitter.parsers")
  local parser_dir = config.get_install_dir("parser")
  local info_dir = config.get_install_dir("parser-info")
  -- get_installed() only lists directory entries. An asynchronous fs_copyfile
  -- exposes a .so pathname before its contents are complete; loading that file
  -- can SIGBUS. The pinned installer writes .revision AFTER the copy finishes.
  -- Wait for that completion marker, not merely the shared-library pathname.
  assert(vim.wait(180000, function()
    for _, lang in ipairs({ "bash", "json" }) do
      local marker = info_dir .. "/" .. lang .. ".revision"
      if vim.fn.filereadable(marker) ~= 1 then
        return false
      end
      local revision = vim.fn.readfile(marker)[1]
      if revision ~= parsers[lang].install_info.revision then
        return false
      end
      local stat = vim.uv.fs_stat(parser_dir .. "/" .. lang .. ".so")
      if not stat or stat.size == 0 then
        return false
      end
    end
    return true
  end, 100), "Blix did not finish installing the bash and json parsers")
  for lang, text in pairs({ bash = "echo alpinews\n", json = '{"alpinews":true}' }) do
    -- Test exactly the locally compiled library, never a bundled fallback.
    vim.treesitter.language.add(lang, { path = parser_dir .. "/" .. lang .. ".so" })
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
