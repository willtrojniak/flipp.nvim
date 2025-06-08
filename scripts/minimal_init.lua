vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append("../plenary.nvim/")
vim.opt.runtimepath:append("../nvim-treesitter/")
vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/nvim-treesitter.lua")

local nvim_ts = require('nvim-treesitter.configs')
nvim_ts.setup({
  sync_install = true,
  ensure_installed = { "cpp" },
  ignore_install = {},
  auto_install = false,

  modules = {},
})
