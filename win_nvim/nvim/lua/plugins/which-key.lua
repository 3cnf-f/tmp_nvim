-- which-key: shows a popup listing available keymaps when you pause after
-- typing a prefix key (e.g. <leader>, g, z, [ …).
--
-- The 500 ms delay is a comfortable balance — fast enough to appear before
-- you've given up, slow enough not to flicker on quick keystrokes.
--
-- Keymap descriptions throughout this config use [tag] prefixes
-- (e.g. [oil], [fzf], [flash]) so which-key groups and the <leader>k
-- fuzzy search both produce useful, scannable results.

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts  = {
    delay = 500,
  },
}
