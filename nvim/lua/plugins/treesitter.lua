return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main", 
  build = ":TSUpdate",
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      branch = "main",
    },
    {
      "kiyoon/repeatable-move.nvim", 
    }
  },
  config = function()
    -- 1. Core Treesitter Setup
    require("nvim-treesitter").setup({
      highlight = { enable = true },
      indent = { enable = true },
    })
    
    -- 2. Textobjects Selection Engine Setup
    require("nvim-treesitter-textobjects").setup({
      select = {
        enable = true,
        lookahead = true,
      },
    })

    -- 3. Direct API Bindings for Treesitter Selection ("vaf", "daf", "cil", etc.)
    local ts_select = require("nvim-treesitter-textobjects.select")
    
    vim.keymap.set({ "x", "o" }, "af", function() ts_select.select_textobject("@function.outer", "textobjects") end, { desc = "Select around function" })
    vim.keymap.set({ "x", "o" }, "if", function() ts_select.select_textobject("@function.inner", "textobjects") end, { desc = "Select inner function" })
    vim.keymap.set({ "x", "o" }, "ac", function() ts_select.select_textobject("@class.outer", "textobjects") end, { desc = "Select around class" })
    vim.keymap.set({ "x", "o" }, "ic", function() ts_select.select_textobject("@class.inner", "textobjects") end, { desc = "Select inner class" })
    vim.keymap.set({ "x", "o" }, "aa", function() ts_select.select_textobject("@parameter.outer", "textobjects") end, { desc = "Select around parameter" })
    vim.keymap.set({ "x", "o" }, "ia", function() ts_select.select_textobject("@parameter.inner", "textobjects") end, { desc = "Select inner parameter" })
    vim.keymap.set({ "x", "o" }, "al", function() ts_select.select_textobject("@loop.outer", "textobjects") end, { desc = "Select around loop" })
    vim.keymap.set({ "x", "o" }, "il", function() ts_select.select_textobject("@loop.inner", "textobjects") end, { desc = "Select inner loop" })
    vim.keymap.set({ "x", "o" }, "ai", function() ts_select.select_textobject("@conditional.outer", "textobjects") end, { desc = "Select around conditional" })
    vim.keymap.set({ "x", "o" }, "ii", function() ts_select.select_textobject("@conditional.inner", "textobjects") end, { desc = "Select inner conditional" })

    -- 4. Direct API Bindings for Treesitter Movement
    local ts_move = require("nvim-treesitter-textobjects.move")

    vim.keymap.set({ "n", "x", "o" }, "]f", function() ts_move.goto_next_start("@function.outer") end, { desc = "Next function" })
    vim.keymap.set({ "n", "x", "o" }, "[f", function() ts_move.goto_previous_start("@function.outer") end, { desc = "Previous function" })
    vim.keymap.set({ "n", "x", "o" }, "]c", function() ts_move.goto_next_start("@class.outer") end, { desc = "Next class" })
    vim.keymap.set({ "n", "x", "o" }, "[c", function() ts_move.goto_previous_start("@class.outer") end, { desc = "Previous class" })
    vim.keymap.set({ "n", "x", "o" }, "]l", function() ts_move.goto_next_start("@loop.outer") end, { desc = "Next loop" })
    vim.keymap.set({ "n", "x", "o" }, "[l", function() ts_move.goto_previous_start("@loop.outer") end, { desc = "Previous loop" })
    vim.keymap.set({ "n", "x", "o" }, "]i", function() ts_move.goto_next_start("@conditional.outer") end, { desc = "Next conditional" })
    vim.keymap.set({ "n", "x", "o" }, "[i", function() ts_move.goto_previous_start("@conditional.outer") end, { desc = "Previous conditional" })

    -- 5. Custom Swedish (ö) Keyboard Mappings
    vim.keymap.set("n", "ön", "]f", { remap = true, desc = "Next function" })
    vim.keymap.set("n", "öp", "[f", { remap = true, desc = "Previous function" })
    vim.keymap.set("n", "öc", "]c", { remap = true, desc = "Next class" })
    vim.keymap.set("n", "öC", "[c", { remap = true, desc = "Previous class" })
    vim.keymap.set("n", "öl", "]l", { remap = true, desc = "Next loop" })
    vim.keymap.set("n", "öL", "[l", { remap = true, desc = "Previous loop" })
    vim.keymap.set("n", "öi", "]i", { remap = true, desc = "Next if/else" })
    vim.keymap.set("n", "öI", "[i", { remap = true, desc = "Previous if/else" })
    
    vim.keymap.set("n", "öf", "}", { desc = "Next paragraph" })
    vim.keymap.set("n", "öb", "{", { desc = "Previous paragraph" })

    -- 6. Repeatable Move Integration
    local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

    vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next, { desc = "Repeat next move" })
    vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous, { desc = "Repeat previous move" })

    vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
  end,
}

