return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {},
  keys = {
    -- 1. Disable default 's' mappings so nvim-surround works perfectly
    { "s", mode = { "n", "x", "o" }, false },
    { "S", mode = { "n", "x", "o" }, false },

    -- 2. Map 'ä' to Flash Jump (Normal, Visual, and Operator modes)
    --    Usage: 'ä' to jump, 'dä' to delete-to-jump, 'yä' to yank-to-jump
    { "ä", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },

    -- 3. Map 'Ä' (Shift+ä) to Flash Treesitter
    --    Usage: 'Ä' to select a function/class/loop
    { "Ä", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },

    -- 4. Keep existing standard mappings for remote and toggle
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}
