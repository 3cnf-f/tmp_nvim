return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- Required for file icons
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = true, -- Enable Nerd Fonts icons
        theme = "everforest", -- Auto-detects your colorscheme (or change to 'tokyonight', 'gruvbox', etc.)
        component_separators = { left = "", right = "" }, -- Nerd Font separators for a sleek look
        section_separators = { left = "", right = "" },
        disabled_filetypes = { -- Hide statusline in these filetypes if needed
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = true, -- Set to true if you want a single statusline for all windows
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
      },
      sections = {
        lualine_a = { "mode" }, -- Current mode (e.g., NORMAL with icon)
        lualine_b = { "branch", "diff", "diagnostics" }, -- Git branch, diff status, LSP diagnostics
        lualine_c = { "filename" }, -- File name with path if modified
        lualine_x = { "encoding", "fileformat", "filetype" }, -- Encoding, line endings, file type with icon
        lualine_y = { "progress" }, -- % progress in file
        lualine_z = { "location" }, -- Line:column position
      },
      inactive_sections = { -- Dimmed sections for inactive windows
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {}, -- Optional: Customize tabline if needed
      winbar = {}, -- Optional: Winbar (top bar) setup
      inactive_winbar = {},
      extensions = {}, -- Add extensions like 'fugitive' for Git, 'nvim-tree', etc.
    })
  end,
}
