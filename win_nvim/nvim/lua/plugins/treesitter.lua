-- Treesitter: syntax-aware code parsing for better highlighting, indentation,
-- and structural navigation.
--
-- SKIPPED on Windows because each language parser must be compiled from C source,
-- which requires gcc or clang. That toolchain is not available in a portable-git
-- setup. Enable this file on Windows only if you have a working C compiler in PATH.

if vim.g.is_windows then return {} end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build  = ":TSUpdate",
  dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
  config = function()
    require("nvim-treesitter.configs").setup({
      -- Parsers installed automatically on first launch
      ensure_installed = { "python", "lua", "markdown", "vim", "json" },
      highlight        = { enable = true },  -- semantic highlighting (better than regex syntax)
      indent           = { enable = true },  -- smarter = indentation

      -- -----------------------------------------------------------------------
      -- Text objects: select code units with motions
      -- -----------------------------------------------------------------------
      -- Convention:
      --   a = "around" — includes the outer delimiter / keyword
      --   i = "inner"  — content only, without surrounding syntax
      --
      -- Use these in visual mode or combined with operators:
      --   vaf   → select the whole function including its signature
      --   dif   → delete the function body only
      --   yac   → yank the whole class
      --   ciai  → change the argument under cursor
      textobjects = {
        select = {
          enable    = true,
          lookahead = true,  -- jump forward to find the next match if not already inside one
          keymaps = {
            ["af"] = "@function.outer",   -- around function (signature + body)
            ["if"] = "@function.inner",   -- inside function body only
            ["ac"] = "@class.outer",      -- around class
            ["ic"] = "@class.inner",      -- inside class body
            ["ia"] = "@parameter.inner",  -- inside a single argument/parameter
            ["aa"] = "@parameter.outer",  -- argument including surrounding comma/space
            ["al"] = "@loop.outer",       -- around loop (for/while + body)
            ["il"] = "@loop.inner",       -- inside loop body
            ["ai"] = "@conditional.outer",-- around if/else block
            ["ii"] = "@conditional.inner",-- inside if/else body
          },
        },

        -- -----------------------------------------------------------------------
        -- Move between code units with ]f / [f etc.
        -- set_jumps = true adds each landing to the jump list so C-o/C-i works.
        -- -----------------------------------------------------------------------
        move = {
          enable    = true,
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

    -- ö-prefix navigation (Swedish keyboard — ö is a comfortable prefix key)
    -- Lowercase = next,  Uppercase = previous.
    -- These are aliases for the ]f / [f treesitter move bindings above,
    -- plus standard { / } paragraph jumps on öf/öb.
    vim.keymap.set("n", "ön", "]f", { remap = true, desc = "Next function" })
    vim.keymap.set("n", "öp", "[f", { remap = true, desc = "Previous function" })
    vim.keymap.set("n", "öc", "]c", { remap = true, desc = "Next class" })
    vim.keymap.set("n", "öC", "[c", { remap = true, desc = "Previous class" })
    vim.keymap.set("n", "öl", "]l", { remap = true, desc = "Next loop" })
    vim.keymap.set("n", "öL", "[l", { remap = true, desc = "Previous loop" })
    vim.keymap.set("n", "öi", "]i", { remap = true, desc = "Next if/else" })
    vim.keymap.set("n", "öI", "[i", { remap = true, desc = "Previous if/else" })
    vim.keymap.set("n", "öf", "}",  { desc = "Next paragraph" })
    vim.keymap.set("n", "öb", "{",  { desc = "Previous paragraph" })
  end,
}
