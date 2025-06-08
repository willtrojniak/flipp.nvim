vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append("../plenary.nvim/")
vim.opt.runtimepath:append("../nvim-treesitter/")
vim.cmd("runtime! plugin/plenary.vim")

local nvim_ts = require('nvim-treesitter.configs')
nvim_ts.setup({ ensure_installed = { "cpp" } })
