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

      -- FIXME: Allow for dynamic keymaps
      vim.keymap.set("n", "<leader>go", function() M.swap(targets) end,
        { buffer = ev.buf, desc = "go to source/header file" })
    end
  })
end


--- @param extensions string[]: target extensions
M.swap = function(extensions)
  local dir = vim.fn.expand("%:p:h")
  local file = vim.fn.expand("%:t:r")

  ---@type string[]
  local targets = {}
  for _, e in ipairs(extensions) do
    table.insert(targets, file .. "." .. e)
  end


  local found = vim.fs.find(
    targets,
    { limit = math.huge, type = "file", path = dir })

  if #found == 0 then return end
  local t = found[1]

  -- TODO: Check if file is already open in a buffer and open that buffer to current window
  -- TODO: Check if buffer is already open in another window / tab and change focus to that window/tab
  pcall(vim.cmd(string.format("%s %s", "edit", vim.fn.fnameescape(t))))
end

M.setup()

return M
