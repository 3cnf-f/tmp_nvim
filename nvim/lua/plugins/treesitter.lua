return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master", -- <--- FORCE STABLE LEGACY BRANCH
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function()
    require("nvim-treesitter.configs").setup({
      -- Languages to install
      ensure_installed = { "python", "lua", "markdown", "vim", "bash" },
      
      -- Enable highlighting
      highlight = { enable = true },
      
      -- Enable better indentation
      indent = { enable = true },
      
      -- Enable textobjects
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            -- Functions
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            
            -- Classes
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            
            -- Parameters
            ["ia"] = "@parameter.inner",
            ["aa"] = "@parameter.outer",
            
            -- Loops
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
            
            -- Conditionals
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
          },
        },
        
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
            ["]l"] = "@loop.outer",
            ["]i"] = "@conditional.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
            ["[l"] = "@loop.outer",
            ["[i"] = "@conditional.outer",
          },
        },
      },
    })
    
    -- ö prefix: Movement (Swedish keyboard friendly)
    local opts = { noremap = true, silent = true }
    
    -- Functions
    vim.keymap.set("n", "ön", "]f", { remap = true, desc = "Next function" })
    vim.keymap.set("n", "öp", "[f", { remap = true, desc = "Previous function" })
    
    -- Classes
    vim.keymap.set("n", "öc", "]c", { remap = true, desc = "Next class" })
    vim.keymap.set("n", "öC", "[c", { remap = true, desc = "Previous class" })
    
    -- Loops
    vim.keymap.set("n", "öl", "]l", { remap = true, desc = "Next loop" })
    vim.keymap.set("n", "öL", "[l", { remap = true, desc = "Previous loop" })
    
    -- Conditionals
    vim.keymap.set("n", "öi", "]i", { remap = true, desc = "Next if/else" })
    vim.keymap.set("n", "öI", "[i", { remap = true, desc = "Previous if/else" })
    
    -- Paragraphs (replaces { })
    vim.keymap.set("n", "öf", "}", { desc = "Next paragraph" })
    vim.keymap.set("n", "öb", "{", { desc = "Previous paragraph" })
    local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

-- Repeat the last Treesitter movement with ; and ,
    vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next, { desc = "Repeat next move" })
    vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous, { desc = "Repeat previous move" })

    -- Make built-in f, F, t, T also play nicely with this system
    vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

  end,
}
