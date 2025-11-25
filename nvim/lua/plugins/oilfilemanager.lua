return {
  'stevearc/oil.nvim',
  opts = {
    show_hidden = true,
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-s>"] = "actions.select_vsplit",
      ["<C-h>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["<C-p>"] = "actions.preview",
      ["<C-c>"] = "actions.close",
      ["<C-l>"] = "actions.refresh",
      ["-"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = "actions.tcd",
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      
      -- === CUSTOM DADBOD ACTION (Variables Method) ===
      ["<leader>db"] = {
        desc = "Add SQLite file to Dadbod UI",
        callback = function()
          local oil = require("oil")
          local entry = oil.get_cursor_entry()
          local dir = oil.get_current_dir()
          
          if not entry or entry.type ~= "file" then 
            vim.notify("Cursor is not on a file.", vim.log.levels.WARN)
            return 
          end
          
          local full_path = dir .. entry.name
          local connection_url = "sqlite:" .. full_path
          
          -- 1. Get existing connections or initialize empty table
          -- We use deepcopy to avoid reference issues with vim.g
          local dbs = {}
          if vim.g.dbs then
            dbs = vim.deepcopy(vim.g.dbs)
          end
          
          -- 2. Add the new connection silently
          table.insert(dbs, { name = entry.name, url = connection_url })
          
          -- 3. Save back to global variable
          vim.g.dbs = dbs
          
          -- 4. Force load the plugin and refresh the UI
          require("lazy").load({ plugins = { "vim-dadbod-ui" } })
          vim.cmd("DBUI")
          
          vim.notify("Added DB: " .. entry.name, vim.log.levels.INFO)
        end,
      },
    },
    use_default_keymaps = true,
  },
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  lazy = false,
}
