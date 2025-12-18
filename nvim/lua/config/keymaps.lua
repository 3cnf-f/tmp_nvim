vim.keymap.set("n","-","<cmd>Oil --float<CR>",{desc="Open parent directory in Oil"})
vim.keymap.set("n", "<leader>tr", ":ToggleRelativeNumber<CR>", { silent = true })

local keymap = vim.keymap -- for conciseness
local km = vim.keymap

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement
-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", function() vim.cmd("tabnew") end, { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", function() vim.cmd("tabclose") end, { desc = "Close tab" }) -- open new tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab
km.set("n", "<leader>p", require("fzf-lua").files, { desc = "FZF Files" })

km.set("n", "<leader><leader>", require("fzf-lua").resume, { desc = "FZF Resume" })

km.set("n", "<leader>r", require("fzf-lua").registers, { desc = "Registers" })
vim.keymap.set("n", "<leader>RT", "<cmd>FTmuxRun<CR>", { desc = "Run This File" })                                                                                                                                                                          
vim.keymap.set("n", "<leader>RM", "<cmd>FTmuxRunRoot<CR>", { desc = "Run Root main.py" })                                                                                                                                                                   
vim.keymap.set("n", "<leader>RA", "<cmd>FTmuxRunRoot /interface/app.py<CR>", { desc = "Run Root app.py" })

km.set("n", "<leader>m", require("fzf-lua").marks, { desc = "Marks" })

km.set("n", "<leader>k", require("fzf-lua").keymaps, { desc = "Keymaps" })

km.set("n", "<leader>f", require("fzf-lua").live_grep, { desc = "FZF Grep" })

km.set("n", "<leader>b", require("fzf-lua").buffers, { desc = "FZF Buffers" })

km.set("v", "<leader>8", require("fzf-lua").grep_visual, { desc = "FZF Selection" })

km.set("n", "<leader>7", require("fzf-lua").grep_cword, { desc = "FZF Word" })

km.set("n", "<leader>j", require("fzf-lua").helptags, { desc = "Help Tags" })

km.set("n", "<leader>gc", require("fzf-lua").git_bcommits, { desc = "Browse File Commits" })

km.set("n", "<leader>gs", require("fzf-lua").git_status, { desc = "Git Status" })

km.set("n", "<leader>s", require("fzf-lua").spell_suggest, { desc = "Spelling Suggestions" })


km.set("n", "<leader>cj", require("fzf-lua").lsp_definitions, { desc = "Jump to Definition" })

km.set(
  "n",
  "<leader>cs",
  ":lua require'fzf-lua'.lsp_document_symbols({winopts = {preview={wrap='wrap'}}})<cr>",
  { desc = "Document Symbols" }
)

km.set("n", "<leader>cr", require("fzf-lua").lsp_references, { desc = "LSP References" })

km.set(
  "n",
  "<leader>cd",
  ":lua require'fzf-lua'.diagnostics_document({fzf_opts = { ['--wrap'] = true }})<cr>",
  { desc = "Document Diagnostics" }
)
-- === PANE NAVIGATION (Alt-Arrows) ===
-- Jump between windows in Normal Mode
vim.keymap.set("n", "<M-Left>", "<C-w>h", { desc = "Go to Left Window" })
vim.keymap.set("n", "<M-Down>", "<C-w>j", { desc = "Go to Lower Window" })
vim.keymap.set("n", "<M-Up>", "<C-w>k", { desc = "Go to Upper Window" })
vim.keymap.set("n", "<M-Right>", "<C-w>l", { desc = "Go to Right Window" })

km.set(
  "n",
  "<leader>ca",
  
  ":lua require'fzf-lua'.lsp_code_actions({ winopts = {relative='cursor',row=1.01, col=0, height=0.2, width=0.4} })<cr>",
  { desc = "Code Actions" }
)
-- "Code Peek": Force FZF to open so you can see the preview pane
-- even if there is only one definition found.
vim.keymap.set("n", "<leader>cp", function()
  require('fzf-lua').lsp_definitions({
    jump1 = false,       -- CHANGED: 'jump_to_single_result' is now 'jump1'
    winopts = {
      preview = {
        layout = 'vertical',
        vertical = 'up:60%'
      }
    }
  })
end, { desc = "Peek Definition" })
-- cmp keymaps  
-- vim.keymap.set("i", "<A-Space>", function() cmp.complete() end, { expr = true, silent = true })

local neocodeium = require("neocodeium")

vim.keymap.set("i", "<A-l>", neocodeium.accept)
vim.keymap.set("i", "<A-j>", function() require("neocodeium").cycle_or_complete() end)
vim.keymap.set("i", "<A-k>", function() require("neocodeium").cycle_or_complete(-1) end)
vim.keymap.set("i", "<A-h>", neocodeium.clear)
vim.keymap.set("i", "<A-c>", neocodeium.cycle_or_complete)

-- ============================================================================
-- "DANK" CLIPBOARD OPERATOR (Alt-y)
-- Usage:
--  <A-y> + motion  -> Copy motion to System Clipboard (e.g., <A-y>iw, <A-y>$)
--  <A-y><A-y>      -> Copy whole line to System Clipboard
--  <A-Y>           -> Copy from cursor to end of line to System Clipboard
-- ============================================================================

-- 1. The Operator: Maps Alt-y to the system register yank ("+y)
-- This works with Flash, Treesitter, and standard motions.
vim.keymap.set({'n', 'x'}, '<M-y>', '"+y', { desc = 'Dank (System Copy)' })

-- 2. The Line Double-Tap: Maps Alt-y in "Operator Pending" mode to the line motion (_)
-- This makes pressing Alt-y twice work exactly like 'yy'
vim.keymap.set('o', '<M-y>', '_', { desc = 'Dank Line Motion' })

-- 3. The End-of-Line Shortcut: Alt-Shift-Y
vim.keymap.set('n', '<M-Y>', '"+y$', { desc = 'Dank to End of Line' })
