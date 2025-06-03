local M = {}

---@class flipp.Opts
---@field extensions {[string]:string[]}

---@type flipp.Opts
local options = {
  extensions = {
    h = { "c", "cpp" },
    hpp = { "c", "cpp" },
    c = { "h", "hpp" },
    cpp = { "h", "hpp" },
  }
}

local symbol_kinds = {
  File = 1,
  Module = 2,
  Namespace = 3,
  Package = 4,
  Class = 5,
  Method = 6,
  Property = 7,
  Field = 8,
  Constructor = 9,
  Enum = 10,
  Interface = 11,
  Function = 12,
  Variable = 13,
  Constant = 14,
  String = 15,
  Number = 16,
  Boolean = 17,
  Array = 18,
  Object = 19,
  Key = 20,
  Null = 21,
  EnumMember = 22,
  Struct = 23,
  Event = 24,
  Operator = 25,
  TypeParameter = 26
}

---@param opts flipp.Opts|nil: opts
M.setup = function(opts)
  opts = opts or options
  opts.extensions = opts.extensions or options.extensions

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
    callback = function(ev)
      local ext = vim.fn.expand("%:e")
      local targets = opts.extensions[ext]
      if not targets then return end

      vim.api.nvim_buf_create_user_command(0, 'Flipp', function(_)
          M.swap(targets)
        end,
        { nargs = 0 })
    end
  })
end

M.has_definition = function()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })[1]
  if vim.tbl_isempty(client) then
    vim.notify("Clangd is not running", vim.log.levels.ERROR)
    return
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  client:request("textDocument/definition", params, function(err, result)
    if err then
      vim.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end

    if result and not vim.tbl_isempty(result) then
      print("Definition already exists.", vim.inspect(result))
      return
    end

    print("Need to generate implementations")
  end, 0)
end

M.get_fully_qualified_symbol = function(callback)
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })
  if vim.tbl_isempty(clients) then
    vim.notify("clangd is not running", vim.log.levels.ERROR)
    return
  end

  ---@type vim.lsp.Client
  local clangd = clients[1]

  local params = { textDocument = vim.lsp.util.make_text_document_params(0) }
  clangd:request("textDocument/documentSymbol", params, function(err, result)
    if err then
      vim.notify("LSP error: " .. err.message, vim.log.levels.ERROR)
      return
    end

    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local cursor_line = cursor_pos[1] - 1
    local cursor_col = cursor_pos[2]

    local function is_inside(range)
      local start = range.start
      local end_ = range["end"]
      if cursor_line < start.line or cursor_line > end_.line then
        return false
      end
      if cursor_line == start.line and cursor_col < start.character then
        return false
      end
      if cursor_line == end_.line and cursor_col > end_.character then
        return false
      end
      return true
    end

    local function find_symbol_path(symbols, path)
      for _, sym in ipairs(symbols) do
        if is_inside(sym.range) then
          print(sym.text)
          local new_path = vim.deepcopy(path)
          table.insert(new_path, { name = sym.name, detail = sym.detail, kind = sym.kind })
          if sym.children then
            local deeper = find_symbol_path(sym.children, new_path)
            if deeper then return deeper end
          end
          return new_path
        end
      end
      return nil
    end

    local symbol_path = find_symbol_path(result, {})
    callback(symbol_path)
  end, 0)
end

--- @class flipp.Definition
--- @field name string|nil
--- @field returnType string|nil
--- @field parameters string
--- @field namespaces string[]
--- @field classes string[]

M.get_definition_symbol = function()
  M.get_fully_qualified_symbol(function(symbol_path)
    if not symbol_path then
      vim.notify("No symbol hovered", vim.log.levels.INFO)
      return
    end

    --- @type flipp.Definition
    local def = {
      name = nil,
      returnType = nil,
      parameters = "()",
      namespaces = {},
      classes = {},
    }

    for _, sym in ipairs(symbol_path) do
      if sym.kind == symbol_kinds.Namespace then
        table.insert(def.namespaces, sym.name)
      elseif sym.kind == symbol_kinds.Class then
        table.insert(def.classes, sym.name)
      elseif sym.kind == symbol_kinds.Function or sym.kind == symbol_kinds.Constructor or sym.kind == symbol_kinds.Method then
        local ret, params = sym.detail:match("^(.-)%s*(%b())$")
        def.returnType = ret
        def.parameters = params

        def.name = sym.name
      end
    end

    ---@param def flipp.Definition
    local def_to_string = function(def)
      local str = ""
      if def.returnType then
        str = str .. def.returnType .. " "
      end
      str = str .. table.concat(def.namespaces, "::")
      if #def.namespaces > 0 then str = str .. "::" end
      str = str .. table.concat(def.classes, "::")
      if #def.classes > 0 then str = str .. "::" end
      str = str .. def.name .. def.parameters .. " {}"
      return str
    end

    if not def.name then return end


    print(def_to_string(def))
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local str = def_to_string(def)
    vim.api.nvim_buf_set_lines(0, row, row, false, { str })
  end)
end

vim.keymap.set("n", "<leader>x", M.has_definition)
vim.keymap.set("n", "<leader>h", M.get_definition_symbol)

M.setup()

return M
