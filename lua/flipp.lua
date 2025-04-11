local M = {}

---@class flipp.Extensions
---@field filetype string: Pattern to match the filetype agains
---@field header string[]: Patterns to match against for header files
---@field source string[]: Patterns to match against for source files

---@class flipp.Opts
---@field extensions flipp.Extensions


---@type flipp.Opts
local options = {
  extensions = {
    filetype = "{c,cpp}",
    header = { "h", "hpp" },
    source = { "c", "cpp" },
  }
}

---@param opts flipp.Opts|nil: opts
M.setup = function(opts)
  --HACK: This should more fully extend extensions
  opts = opts or options
  opts.extensions = opts.extensions or options.extensions

  vim.api.nvim_create_autocmd({ "FileType", "BufReadPost" }, {
    pattern = opts.extensions.filetype,
    callback = function(ev)
      vim.api.nvim_buf_create_user_command(0, 'Flipp', function(_)
          M.swap(opts.extensions)
        end,
        { nargs = 0 })

      -- FIXME: Allow for dynamic keymaps
      vim.keymap.set("n", "<leader>go", function() M.swap(opts.extensions) end,
        { buffer = ev.buf, desc = "go to source/header file" })
    end
  })
end


--- @param extensions flipp.Extensions
M.swap = function(extensions)
  local buf_name = vim.api.nvim_buf_get_name(0)
  local base_name = vim.fs.basename(buf_name)
  local dir_name = vim.fs.dirname(buf_name)

  local ext_index = string.find(base_name, ".", 0, true) or string.len(base_name)
  local file_name = string.sub(base_name, 0, ext_index)
  local file_ext = string.sub(base_name, ext_index + 1)

  ---@type string[]|nil
  local exs = nil
  if vim.list_contains(extensions.header, file_ext) then
    exs = extensions.source
  elseif vim.list_contains(extensions.source, file_ext) then
    exs = extensions.header
  else
    return
  end

  ---@type string[]
  local targets = {}
  for _, e in ipairs(exs) do
    table.insert(targets, file_name .. e)
  end


  local found = vim.fs.find(
    targets,
    { limit = math.huge, type = "file", path = dir_name })


  ---@type string|nil
  local t
  for _, file in ipairs(found) do
    t = file
    break
  end

  if t == nil then return end

  -- TODO: Check if file is already open in a buffer and open that buffer to current window
  -- TODO: Check if buffer is already open in another window / tab and change focus to that window/tab
  vim.cmd(string.format("%s %s", "edit", vim.fn.fnameescape(t)))
end

M.setup()

return M
