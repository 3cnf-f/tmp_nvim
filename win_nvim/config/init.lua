local M = {}

M.hello = "world"
_G.hello = "world"
vim.g.hello = "world"

-- Visual mode: Alt+y (or Alt+Shift+y) yanks selection into register 'k'
vim.keymap.set("x", "<M-y>", '"ky', { desc = "Yank selection to register k" })
vim.keymap.set("x", "<M-S-y>", '"ky', { desc = "Yank selection to register k" })

-- Normal mode: Alt+y + Alt+y yanks entire line into register 'k' (like 'yy')
vim.keymap.set("n", "<M-y><M-y>", '"kyy', { desc = "Yank whole line to register k" })

-- Normal mode: Alt+Shift+y yanks to end of line into register 'k' (like 'Y')
vim.keymap.set("n", "<M-S-y>", '"kY', { desc = "Yank rest of line to register k" })
vim.keymap.set("n", "<M-Y>", '"kY', { desc = "Yank rest of line to register k" })
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


return M

