-- Enable true color support
vim.opt.termguicolors = true

-- Disable mouse support
vim.opt.mouse = ""

-- Copy to system clipboard
vim.opt.clipboard = "unnamedplus"

-- Display line numbers
vim.opt.number = true

-- Use spaces instead of tabs
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- 72 character notice for git commit messages
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.colorcolumn = "72"
  end,
})

-- require("config.lazy")
