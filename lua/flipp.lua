-- TODO: Avoid generating definitions that are already implemented
-- TODO: Get parameter names with their types
-- TODO: Automatically paste definitions into the source file
-- TODO: Automatically paste namespaces
-- TODO: Automatically detect matching namespaces in source file

---@class flipp.lsp.clangd.Symbol
---@field name string
---@field kind integer
---@field detail? string
---@field range flipp.Range
---@field selectionRange flipp.Range
---@field children? flipp.lsp.clangd.Symbol[]

---@class flipp.Symbol
---@field name string
---@field kind integer
---@field detail? string
---@field children? flipp.Symbol[]

---@type table<string, integer>
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

--- @class flipp.Definition
--- @field name string|nil
--- @field returnType string|nil
--- @field parameters string
--- @field namespaces string[]
--- @field classes string[]

---@class flipp.Position
---@field line integer
---@field character integer

---@class flipp.Range
---@field start flipp.Position
---@field end flipp.Position
---@field block? boolean -- defaults to false

---Get the cursor selection in the current window
---Positions are 0 indexed
---@return flipp.Range
local function get_cursor_range()
  local pos_start = vim.fn.getpos(".") -- cursor position
  local pos_end = vim.fn.getpos("v")   -- defaults to '.' when not in visual mode

  -- Normalize to 0-indexed to match clangd
  local start_row = math.min(pos_start[2], pos_end[2]) - 1
  local end_row = math.max(pos_start[2], pos_end[2]) - 1
  local start_col = math.min(pos_start[3], pos_end[3]) - 1
  local end_col = math.max(pos_start[3], pos_end[3]) - 1

  -- Correct the range based on the current mode
  local mode = vim.fn.mode()
  local block = mode == "\22"
  if mode == "V" then
    start_col = 0
    end_col = vim.v.maxcol
  end

  ---@type flipp.Range
  return {
    ["start"] = { line = start_row, character = start_col },
    ["end"] = { line = end_row, character = end_col },
    ["block"] = block
  }
end

---@param r1 flipp.Range
---@param r2 flipp.Range
---@return boolean
local function is_range_intersect(r1, r2)
  -- FIXME: Handle block intersections properly
  if r1["end"].line < r2["start"].line then return false end
  if r1["end"].line == r2["start"].line and r1["end"].character < r2["start"].character then return false end
  if r1["start"].line > r2["end"].line then return false end
  if r1["start"].line == r2["end"].line and r1["start"].character > r2["end"].character then return false end
  return true
end

---@param range flipp.Range
---@param symbols flipp.lsp.clangd.Symbol[]
---@return flipp.Symbol[]
local function find_symbols_in_range(range, symbols)
  local t = {}
  for _, sym in ipairs(symbols) do
    if is_range_intersect(sym.range, range) then
      local s = { name = sym.name, detail = sym.detail, kind = sym.kind }
      if sym.children then
        s.children = find_symbols_in_range(range, sym.children)
      end
      table.insert(t, s)
    end
  end
  return t
end

---@param symbols flipp.Symbol[]
---@return flipp.Definition[]
local function build_symbols_fully_qualified_definitions(symbols)
  ---@param symbol flipp.Symbol
  ---@param def flipp.Definition
  ---@return flipp.Definition[]
  local function helper(symbol, def)
    if symbol.kind == symbol_kinds.Namespace then
      table.insert(def.namespaces, symbol.name)
    elseif symbol.kind == symbol_kinds.Class then
      table.insert(def.classes, symbol.name)
    elseif symbol.kind == symbol_kinds.Function or symbol.kind == symbol_kinds.Constructor or symbol.kind == symbol_kinds.Method then
      local ret, params
      if not symbol.detail then
        ret, params = "", "()" -- Handles destructors
      else
        -- FIXME: Does not include paramter names
        ret, params = symbol.detail:match("^(.-)%s*(%b())$")
      end
      def.returnType = ret
      def.parameters = params
      def.name = symbol.name
    end

    if not symbol.children or vim.tbl_isempty(symbol.children) then return { def } end

    ---@type flipp.Definition[]
    local defs = {}
    for _, child in ipairs(symbol.children) do
      for _, res in ipairs(helper(child, vim.deepcopy(def))) do
        if res.name and res.name ~= "" then
          table.insert(defs, res)
        end
      end
    end
    return defs
  end

  for _, sym in ipairs(symbols) do
    --- @type flipp.Definition
    local def = {
      name = nil,
      returnType = nil,
      parameters = "()",
      namespaces = {},
      classes = {},
    }
    return helper(sym, def)
  end
  return {}
end

---@param def flipp.Definition
---@param includeNamespaces? boolean defaults to false
---@return string
local def_to_string = function(def, includeNamespaces)
  if not def.name then return "" end
  if includeNamespaces == nil then
    includeNamespaces = false
  end
  local str = ""
  if def.returnType and def.returnType ~= "" then
    str = str .. def.returnType .. " "
  end
  if includeNamespaces then
    str = str .. table.concat(def.namespaces, "::")
    if #def.namespaces > 0 then str = str .. "::" end
  end
  str = str .. table.concat(def.classes, "::")
  if #def.classes > 0 then str = str .. "::" end
  str = str .. def.name .. def.parameters .. " {}"
  return str
end

local M = {}

---@class flipp.Opts

---@type flipp.Opts
local default_opts = {}


---@param opts flipp.Opts|nil: opts
M.setup = function(opts)
  opts = opts or default_opts

  vim.api.nvim_create_user_command('FlippGenerate', function()
      M.get_definition_symbols()
    end,
    { nargs = 0, range = true })
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

---@param range flipp.Range
---@param callback fun(symbols: flipp.Symbol[])
M.get_fully_qualified_selected_symbols = function(range, callback)
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

    print(vim.inspect(result))
    local selected_symbols = find_symbols_in_range(range, result)

    callback(selected_symbols)
  end, 0)
end


M.get_definition_symbols = function()
  local cursor_range = get_cursor_range()
  M.get_fully_qualified_selected_symbols(cursor_range, function(selected_symbols)
    -- FIXME: Includes definitions of those already implemented
    local defs = build_symbols_fully_qualified_definitions(selected_symbols)
    if vim.tbl_isempty(defs) then
      vim.notify("No declaration hovered", vim.log.levels.INFO)
      return
    end

    local def_strings = vim.tbl_map(def_to_string, defs)
    -- HACK: Preferably, would paste the strings into the source file
    vim.fn.setreg('d', def_strings, "l")
    vim.notify("Copied " .. #def_strings .. " definitions to 'd' register", vim.log.levels.INFO)
  end)
end

vim.keymap.set({ "n", "v" }, "<leader>gd", M.get_definition_symbols, { desc = "Generate Definitions" })

return M
