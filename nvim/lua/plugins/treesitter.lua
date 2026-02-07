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
      ensure_installed = { "python", "lua", "markdown", "vim", "bash","json" },
      
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
  end,
}
