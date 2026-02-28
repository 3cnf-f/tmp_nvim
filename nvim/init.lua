-- =============================================================================
-- init.lua  –  entry point for both Windows and Linux
-- On Windows this lives at:  %USERPROFILE%\AppData\Local\nvim\init.lua
-- On Linux this lives at:    ~/.config/nvim/init.lua
-- =============================================================================

-- OS flag (used throughout the config to branch behaviour)
vim.g.is_windows = vim.fn.has("win32") == 1

-- Windows: inject portable-git into PATH so lazy.nvim can clone plugins
if vim.g.is_windows then
  local portable_git = "H:\\007git\\bin"   -- adjust to your portable-git location
  vim.env.PATH = portable_git .. ";" .. vim.env.PATH
end

-- Leader keys must be set before lazy loads any plugin
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

require("config.lazy")
