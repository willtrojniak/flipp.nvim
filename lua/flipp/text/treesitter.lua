local M = {}

---The following is from folke/noice
---@param lang string
function M.has_lang(lang)
  if vim.treesitter.language.get_lang then
    lang = vim.treesitter.language.get_lang(lang) or lang
    local ok, ret = pcall(vim.treesitter.language.add, lang)
    return ok and ret
  end

  ---@diagnostic disable-next-line: deprecated
  return vim.treesitter.language.require_language(lang, nil, true)
end

return M
