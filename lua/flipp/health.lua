local health = vim.health
local TS = require('flipp.text.treesitter')

local M = {}

function M.check()
  health.start("flipp")

  if TS.has_lang("cpp") then
    health.ok("{Treesitter} `cpp` parser is installed")
  else
    health.error("{Treesitter} `cpp` parser is not installed.")
  end

  if vim.fn.executable("clangd") == 1 then
    health.ok("{clangd} is installed and executable")
  else
    health.warn("{clangd} is not installed or in path. flipp will not be able filter defined declarations")
  end
end

return M
