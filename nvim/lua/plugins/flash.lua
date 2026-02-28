-- Flash: jump anywhere on screen by typing a short label sequence.
--
-- After pressing ä, Flash highlights every word on screen with a 1-2 character
-- label. Type those characters to teleport the cursor there — no arrow keys needed.
-- Works in normal, visual, and operator-pending modes, so you can combine it
-- with operators: e.g. "yä<label>" yanks from here to any visible position.
--
-- Keymaps
-- -------
--   ä          Jump: highlight all positions, type label to land there.
--              (Swedish key — sits where 's' would be on an English layout.)
--
--   Ä          Treesitter select: same as ä but labels whole AST nodes (functions,
--              loops, blocks…). Jump into a node to select it structurally.
--
--   r          Remote (operator-pending only): apply the operator to a flash-selected
--              position WITHOUT moving the cursor.
--              Example: "yr<label>" yanks text at another location into the register.
--
--   R          Treesitter search (operator-pending + visual): jump and select the
--              next matching AST node based on a typed search pattern.
--
--   <C-s>      Toggle flash overlay on top of a running / or : search.
--              Flash labels appear over the search matches so you can jump directly.
--
-- Why s/S are disabled here:
--   nvim-surround uses s/S for surrounding operations (ys…, ds, cs, S in visual).
--   Flash's built-in s/S would conflict, so they are removed here and ä/Ä are
--   used instead (see nvimsurround.lua).

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts  = {},
  keys  = {
    -- Free s/S so nvim-surround can own them unconflicted
    { "s", mode = { "n", "x", "o" }, false },
    { "S", mode = { "n", "x", "o" }, false },

    -- ä → jump to any visible position (labels appear, type to land)
    { "ä",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "[flash] jump" },
    -- Ä → same but labels entire treesitter nodes for structural selection
    { "Ä",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "[flash] treesitter select" },
    -- r (op-pending) → remote: apply operator at a flash-selected spot, cursor stays
    { "r",     mode = "o",               function() require("flash").remote() end,             desc = "[flash] remote" },
    -- R → search + select AST nodes matching a pattern
    { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "[flash] treesitter search" },
    -- <C-s> in command mode → overlay flash labels on an active / search
    { "<C-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "[flash] toggle" },
  },
}
