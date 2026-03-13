-- =============================================================================
-- config/lazy.lua  –  bootstrap lazy.nvim and load all plugins
-- =============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                             "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- Core config (no plugin deps)
require("config.options")
require("config.commands")

-- Plugin specs – every file under lua/plugins/ is auto-imported.
-- Individual plugin files can check vim.g.is_windows to self-disable.
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install    = { colorscheme = { "kanagawa", "default" } },
  checker    = { enabled = false },   -- no automatic update nags on Windows
  change_detection = { notify = false },
})

-- Keymaps last (so plugins are available)
require("config.keymaps")
