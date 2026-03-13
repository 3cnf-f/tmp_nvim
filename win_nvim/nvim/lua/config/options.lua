-- =============================================================================
-- config/options.lua  –  vim.opt settings (OS-agnostic unless noted)
-- =============================================================================

local o = vim.opt

-- Line numbers
o.number      = true
o.cursorline  = true
o.signcolumn  = "yes"
o.scrolloff   = 5
o.cmdheight   = 1

-- Splits
o.splitright  = true
o.splitbelow  = true

-- Search
o.ignorecase  = true
o.smartcase   = true

-- Whitespace display
o.list      = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Indentation
o.expandtab   = true
o.shiftwidth  = 4
o.tabstop     = 4
o.softtabstop = 4
o.smarttab    = true
o.smartindent = true
o.autoindent  = true
o.breakindent = true

-- Persistence
o.undofile  = true
o.swapfile  = false

-- UI
o.showmode = false
o.fillchars:append({ vert = "│", eob = " " })

-- =============================================================================
-- Working directory
-- =============================================================================
if vim.g.is_windows then
  vim.fn.chdir("H:\\dokument\\")
end

-- =============================================================================
-- Clipboard
-- =============================================================================
if vim.g.is_windows then
  -- Windows: Neovim talks to the OS clipboard directly via win32yank / built-in
  o.clipboard = "unnamedplus"
else
  -- Linux/remote: use OSC 52 so it works over SSH / inside tmux.
  -- Paste is intentionally left as a no-op; use Ctrl-Shift-V in the terminal.
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = function() return {} end,
      ["*"] = function() return {} end,
    },
  }
end
