-- Lualine: fast, customisable statusline with icons and live information.
--
-- Layout (left → right across the bottom of the screen):
--   [mode]  [branch · diff · diagnostics]  filename  ···  [encoding · fileformat · filetype]  [progress]  [line:col]
--
-- globalstatus = true: one shared statusline at the bottom instead of a
-- separate bar per split window.
--
-- Windows differences:
--   • nvim-web-devicons is NOT loaded (pure Lua but large; icons unused in
--     paste-edit-copy workflow).
--   • icons_enabled = false (no devicons, no Nerd Font requirement).
--   • branch / diff components are removed — they call git as a subprocess
--     on every refresh, which triggers Windows Defender scans.

local is_win = vim.g.is_windows

-- Statusline badge: shows "x0b" when the line-break normaliser is active.
-- Uses lualine's `cond` so the component is completely absent (no separator
-- gap) when the toggle is off.
local x0b_badge = {
  function() return "x0b" end,
  cond = function() return vim.g.x0b_convert == true end,
}

return {
  "nvim-lualine/lualine.nvim",
  -- devicons is only useful with icons; skip it on Windows to avoid the
  -- large startup cost and the Defender hit on the icon-font lookup.
  dependencies = is_win and {} or { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled        = not is_win,  -- no Nerd Font / devicons on Windows
        theme                = "kanagawa",
        component_separators = { left = "", right = "" },
        section_separators   = { left = "", right = "" },
        globalstatus         = true,        -- single bar shared by all split windows
      },
      sections = {
        lualine_a = { "mode" },
        -- On Windows: drop branch + diff — both shell out to git on every refresh.
        lualine_b = is_win and {} or { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { x0b_badge, "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_c = { "filename" },
        lualine_x = { "location" },
      },
    })
  end,
}
