return {
  "nvim-mini/mini.files",
  -- Ensures the plugin doesn't auto-load on startup. 
  -- It will only load when one of the keys defined below is pressed.
  lazy = true,
  
  -- Regular keybindings to trigger mini.files
  keys = {
    {
      "<leader>e",
      function()
        -- Opens mini.files in the directory of the currently active buffer
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (Current File)",
    },
    {
      "<leader>E",
      function()
        -- Opens mini.files in the current working directory
        require("mini.files").open(vim.uv.cwd(), true)
      end,
      desc = "Open mini.files (CWD)",
    },
  },
  
  opts = {
    options = {
      -- Prevents mini.files from hijacking netrw / acting as the default explorer
      use_as_default_explorer = false,
    },
    
    -- Commented out UI tweaks you can enable if you want to alter default sizing or keys
    -- windows = {
    --   preview = true,
    --   width_focus = 30,
    --   width_preview = 30,
    -- },
    -- mappings = {
    --   go_in       = 'l',
    --   go_in_plus  = 'L',
    --   go_out      = 'h',
    --   go_out_plus = 'H',
    -- },
  },

  config = function(_, opts)
    require("mini.files").setup(opts)

    -- ========================================================================
    -- Special Use Functions (Commented out for later use)
    -- ========================================================================

    -- -- 1. Toggle Dotfiles (Hidden Files)
    -- -- Allows you to press 'g.' inside mini.files to show/hide hidden files
    -- local show_dotfiles = true
    -- local filter_show = function(fs_entry) return true end
    -- local filter_hide = function(fs_entry)
    --   return not vim.startswith(fs_entry.name, '.')
    -- end
    --
    -- local toggle_dotfiles = function()
    --   show_dotfiles = not show_dotfiles
    --   local new_filter = show_dotfiles and filter_show or filter_hide
    --   require('mini.files').refresh({ content = { filter = new_filter } })
    -- end
    --
    -- vim.api.nvim_create_autocmd('User', {
    --   pattern = 'MiniFilesBufferCreate',
    --   callback = function(args)
    --     local buf_id = args.data.buf_id
    --     vim.keymap.set('n', 'g.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle hidden files' })
    --   end,
    -- })

    -- -- 2. Create Window Splits directly from mini.files
    -- -- Allows you to press <C-s> or <C-v> to open the selected file in a split
    -- local map_split = function(buf_id, lhs, direction)
    --   local rhs = function()
    --     local cur_target = require('mini.files').get_explorer_state().target_window
    --     local new_target = vim.api.nvim_win_call(cur_target, function()
    --       vim.cmd(direction .. ' split')
    --       return vim.api.nvim_get_current_win()
    --     end)
    --
    --     require('mini.files').set_target_window(new_target)
    --     require('mini.files').go_in({ close_on_file = true })
    --   end
    --   vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = 'Split ' .. direction })
    -- end
    --
    -- vim.api.nvim_create_autocmd('User', {
    --   pattern = 'MiniFilesBufferCreate',
    --   callback = function(args)
    --     local buf_id = args.data.buf_id
    --     map_split(buf_id, '<C-s>', 'belowright horizontal')
    --     map_split(buf_id, '<C-v>', 'belowright vertical')
    --   end,
    -- })
    
    -- -- 3. Synchronize Current Working Directory (CWD) on Navigation
    -- -- Allows you to press 'gc' to change your Neovim CWD to the directory you are viewing
    -- local files_set_cwd = function()
    --   local cur_entry_path = require('mini.files').get_fs_entry().path
    --   local cur_directory = vim.fs.dirname(cur_entry_path)
    --   if cur_directory ~= nil then
    --     vim.fn.chdir(cur_directory)
    --   end
    -- end
    --
    -- vim.api.nvim_create_autocmd('User', {
    --   pattern = 'MiniFilesBufferCreate',
    --   callback = function(args)
    --     local buf_id = args.data.buf_id
    --     vim.keymap.set('n', 'gc', files_set_cwd, { buffer = buf_id, desc = 'Set cwd' })
    --   end,
    -- })
  end,
}

