-- mini.comment: toggle comments with gc / gcc.
--
-- The correct comment syntax is detected from the filetype automatically:
--   Lua   →  --
--   Python →  #
--   JS/TS →  //
--   HTML  →  <!-- -->
-- pad_comment_parts = true always inserts a space after the token (-- text, not --text).
--
-- Keymaps
-- -------
--   gcc              Toggle comment on the current line.
--   gc <motion>      Toggle comment on lines covered by the motion.
--                    Examples:  gc3j  (3 lines down)   gc ip  (inner paragraph)
--   gc (visual)      Toggle comment on the selected lines.
--
-- These keymaps are re-declared below (pointing back at themselves via remap=true)
-- only to attach [comment] description tags so <leader>k search finds them.

return {
  "echasnovski/mini.comment",
  version = false,
  config  = function()
    require("mini.comment").setup({
      options = {
        pad_comment_parts = true,  -- always add a space: // text, not //text
      },
      mappings = {
        comment        = "gc",
        comment_line   = "gcc",
        comment_visual = "gc",
        textobject     = "gc",
      },
    })

    -- Re-declare with [comment] prefix so <leader>k search works
    local km = vim.keymap.set
    km("n", "gcc", "gcc", { remap = true, desc = "[comment] toggle line" })
    km("n", "gc",  "gc",  { remap = true, desc = "[comment] toggle (+ motion)" })
    km("x", "gc",  "gc",  { remap = true, desc = "[comment] toggle selection" })
  end,
}
