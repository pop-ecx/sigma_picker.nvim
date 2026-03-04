-- tests/minimal_init.lua
local root = vim.fn.fnamemodify(".", ":p")
vim.opt.rtp:append(root)

local plenary_path = vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
vim.opt.rtp:append(plenary_path)

local telescope_path = vim.fn.expand("~/.local/share/nvim/lazy/telescope.nvim")
vim.opt.rtp:append(telescope_path)

vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/telescope.lua")
