-- nvim-surround: add, change, and delete surrounding character pairs.
--
-- Supported surroundings: () [] {} "" '' `` <tags> and custom user-defined pairs.
--
-- ADD a surrounding
--   ys <motion> <char>   Surround the text covered by motion with <char>.
--                        Examples:  ysiw"   → surround word with "…"
--                                   ys3j(   → surround 3 lines with (…)
--                                   ysa')   → surround 'text' with (…) → ('text')
--   yss <char>           Surround the entire current line.
--   yS  <motion> <char>  Like ys but places content on its own line (linewise indent).
--   ySS <char>           Linewise surround of the whole current line.
--
-- CHANGE a surrounding
--   cs <old> <new>       Replace the surrounding <old> with <new>.
--                        Examples:  cs"'   → change "…" to '…'
--                                   cs'(   → change '…' to (…)
--                                   cst"   → change <tag>…</tag> to "…"
--   cS <old> <new>       Same as cs but places content on its own line.
--
-- DELETE a surrounding
--   ds <char>            Remove the surrounding pair.
--                        Examples:  ds"    → delete surrounding quotes
--                                   ds(    → delete surrounding parentheses
--
-- VISUAL mode
--   S  <char>            Surround the selection with <char>.
--   gS <char>            Linewise surround the selection.
--
-- Note: s/S in normal/visual/operator-pending mode are freed by flash.lua so
-- surround can own them without conflict (see flash.lua).
--
-- Keymaps are re-declared below (via <Plug> targets) only to attach [surround]
-- description tags so <leader>k search finds them.

return {
  "kylechui/nvim-surround",
  version = "*",
  event   = "VeryLazy",
  config  = function()
    require("nvim-surround").setup({})

    -- Re-declare with [surround] prefix so <leader>k search works
    local km = vim.keymap.set
    km("n", "ys",  "<Plug>(nvim-surround-normal)",         { desc = "[surround] add      ys<motion><char>  e.g. ysiw\"" })
    km("n", "yss", "<Plug>(nvim-surround-normal-cur)",     { desc = "[surround] add line yss<char>" })
    km("n", "yS",  "<Plug>(nvim-surround-normal-line)",    { desc = "[surround] add (linewise)  yS<motion><char>" })
    km("n", "ySS", "<Plug>(nvim-surround-normal-cur-line)",{ desc = "[surround] add line (linewise)  ySS<char>" })
    km("x", "S",   "<Plug>(nvim-surround-visual)",         { desc = "[surround] add visual  S<char>" })
    km("x", "gS",  "<Plug>(nvim-surround-visual-line)",    { desc = "[surround] add visual (linewise)  gS<char>" })
    km("n", "ds",  "<Plug>(nvim-surround-delete)",         { desc = "[surround] delete  ds<char>  e.g. ds\"" })
    km("n", "cs",  "<Plug>(nvim-surround-change)",         { desc = "[surround] change  cs<old><new>  e.g. cs\"'" })
    km("n", "cS",  "<Plug>(nvim-surround-change-line)",    { desc = "[surround] change (linewise)  cS<old><new>" })
  end,
}
