local M = {}

M.hello = "world"
_G.hello = "world"
vim.g.hello = "world"

-- Visual mode: Alt+y (or Alt+Shift+y) yanks selection into register 'k'
vim.keymap.set("x", "<M-y>", '"+y', { desc = "Yank selection to register k" })

-- Normal mode: Alt+y + Alt+y yanks entire line into register 'k' (like 'yy')
vim.keymap.set("n", "<M-y><M-y>", '"+yy', { desc = "Yank whole line to register k" })

-- Normal mode: Alt+Shift+y yanks to end of line into register 'k' (like 'Y')
vim.keymap.set("n", "<M-Y>", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd('normal! gg"+yG')
  vim.api.nvim_win_set_cursor(0, pos)
end, { desc = "Yank entire buffer to + register" })
-- Set space as leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Window split creation
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Split horizontally" })
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split vertically" })

-- Window closing / only
vim.keymap.set("n", "<leader>wc", "<C-w>c", { desc = "Close current split" })
vim.keymap.set("n", "<leader>wo", "<C-w>o", { desc = "Close other splits" })

-- Directional navigation via leader + hjkl (fallback if Alt is eaten by browser)
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Focus left split" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Focus lower split" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Focus upper split" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Focus right split" })

-- Resizing
vim.keymap.set("n", "<leader>w=", "<C-w>=", { desc = "Equalize split sizes" })
-- Normal mode: Alt + Arrow keys to navigate splits
vim.keymap.set("n", "<M-Left>", "<C-w>h", { desc = "Focus left split" })
vim.keymap.set("n", "<M-Down>", "<C-w>j", { desc = "Focus lower split" })
vim.keymap.set("n", "<M-Up>", "<C-w>k", { desc = "Focus upper split" })
vim.keymap.set("n", "<M-Right>", "<C-w>l", { desc = "Focus right split" })

-- Terminal mode: jump out of terminal splits directly
vim.keymap.set("t", "<M-Left>", "<C-\\><C-n><C-w>h", { desc = "Focus left split from terminal" })
vim.keymap.set("t", "<M-Down>", "<C-\\><C-n><C-w>j", { desc = "Focus lower split from terminal" })
vim.keymap.set("t", "<M-Up>", "<C-\\><C-n><C-w>k", { desc = "Focus upper split from terminal" })
vim.keymap.set("t", "<M-Right>", "<C-\\><C-n><C-w>l", { desc = "Focus right split from terminal" })



return M

