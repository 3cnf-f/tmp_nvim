-- At the very top, before plugins load
local portable_git = "H:\\007git\\bin"  -- change to your folder
vim.env.PATH = vim.env.PATH .. ";" .. portable_git

-- win_keymaps.lua
-- Portable settings for Windows neovim (no plugins required).
-- Load from nvim command line with:  :luafile C:\path\to\win_keymaps.lua

-- ============================================================================
-- LEADER
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- OPTIONS
-- ============================================================================
vim.opt.number        = true
vim.opt.cursorline    = true
vim.opt.signcolumn    = "yes"
vim.opt.scrolloff     = 5
vim.opt.cmdheight     = 1
vim.opt.splitright    = true
vim.opt.splitbelow    = true
vim.opt.breakindent   = true
vim.opt.undofile      = true  -- persistent undo across sessions

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase  = true

-- Whitespace display
vim.opt.list      = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Indentation
vim.opt.expandtab   = true  -- tabs → spaces
vim.opt.shiftwidth  = 4
vim.opt.tabstop     = 4
vim.opt.softtabstop = 4
vim.opt.smarttab    = true
vim.opt.smartindent = true
vim.opt.autoindent  = true

-- UI chrome
vim.opt.fillchars:append({ vert = "│", eob = " " })

-- ============================================================================
-- COMMANDS
-- ============================================================================
vim.api.nvim_create_user_command("ToggleRelativeNumber", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, {})

-- ============================================================================
-- KEYMAPS
-- ============================================================================
local km = vim.keymap

-- Misc
km.set("n", "<leader>tr", ":ToggleRelativeNumber<CR>", { silent = true, desc = "Toggle relative numbers" })
km.set("n", "<leader>nh", ":nohl<CR>",                 { desc = "Clear search highlights" })

-- Increment / decrement numbers
km.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
km.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- === SPLITS ===
km.set("n", "<leader>sv", "<C-w>v",         { desc = "Split window vertically" })
km.set("n", "<leader>sh", "<C-w>s",         { desc = "Split window horizontally" })
km.set("n", "<leader>se", "<C-w>=",         { desc = "Make splits equal size" })
km.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- === TABS ===
km.set("n", "<leader>to", function() vim.cmd("tabnew") end,   { desc = "Open new tab" })
km.set("n", "<leader>tx", function() vim.cmd("tabclose") end, { desc = "Close tab" })
km.set("n", "<leader>tn", "<cmd>tabn<CR>",                    { desc = "Next tab" })
km.set("n", "<leader>tp", "<cmd>tabp<CR>",                    { desc = "Previous tab" })
km.set("n", "<leader>tf", "<cmd>tabnew %<CR>",                { desc = "Open buffer in new tab" })

-- === WINDOW NAVIGATION (Alt-Arrows) ===
km.set("n", "<M-Left>",  "<C-w>h", { desc = "Go to left window" })
km.set("n", "<M-Down>",  "<C-w>j", { desc = "Go to lower window" })
km.set("n", "<M-Up>",    "<C-w>k", { desc = "Go to upper window" })
km.set("n", "<M-Right>", "<C-w>l", { desc = "Go to right window" })

-- === DANK CLIPBOARD OPERATOR (Alt-y) ===
-- <M-y> + motion  -> yank motion to system clipboard  (e.g. <M-y>iw, <M-y>$)
-- <M-y><M-y>      -> yank whole line to system clipboard
-- <M-Y>           -> yank from cursor to end of line
km.set({ "n", "x" }, "<M-y>", '"+y',  { desc = "Dank: system copy" })
km.set("o",          "<M-y>", "_",    { desc = "Dank: line motion" })
km.set("n",          "<M-Y>", '"+y$', { desc = "Dank: copy to end of line" })

print("win_keymaps.lua loaded OK")
