-- Kanagawa: dark colorscheme inspired by Japanese woodblock art.
--
-- Loaded before everything else (priority 1000, lazy = false) so the theme
-- is applied before any other plugin renders its UI — preventing a white flash.
--
-- compile = true: pre-compiles the theme to Lua bytecode on install/update,
-- resulting in faster startup. After changing theme options, run :KanagawaCompile.

return {
  "rebelot/kanagawa.nvim",
  lazy     = false,
  priority = 1000,  -- must load before other plugins that draw UI
  config   = function()
    require("kanagawa").setup({
      compile   = true,
      overrides = function(colors)
        return {
          -- Soften window-border lines so splits don't look too heavy
          WinSeparator = { fg = colors.palette.fujiGray },
        }
      end,
    })
    vim.cmd("colorscheme kanagawa")
  end,
  build = function()
    -- Re-compile after a plugin update so cached bytecode stays in sync
    vim.cmd("KanagawaCompile")
  end,
}
