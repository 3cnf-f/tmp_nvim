return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    -- UI Settings
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_execute_on_save = 0
  end,
  keys = {
    -- Keymap to open the DB UI drawer
    { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "Toggle Database UI" },
  },
  config = function()
    -- Autocomplete setup for SQL files
    local require_ok, cmp = pcall(require, "cmp")
    if require_ok then
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          cmp.setup.buffer({
            sources = {
              { name = "vim-dadbod-completion" },
              { name = "buffer" },
            },
          })
        end,
      })
    end
  end,
}
