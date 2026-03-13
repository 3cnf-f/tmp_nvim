return {
  "echasnovski/mini.comment",
  version = false, -- Recommended for 'mini' plugins to use main branch
  dependencies = { 
    -- Integrates with your existing Treesitter text objects
    "nvim-treesitter/nvim-treesitter-textobjects", 
  },
  opts = {
    -- Options
    options = {
      custom_commentstring = nil, -- Uses nvim-ts-context-commentstring if installed
      ignore_blank_line = false,  -- Allow commenting blank lines
      start_of_line = false,      -- Place comment at indentation, not start of line
      pad_comment_parts = true,   -- Add space after comment symbol (e.g., "# Text")
    },
    
    -- Mappings (Standard Vim)
    mappings = {
      comment = "gc",      -- Operator-pending (e.g., 'gc' + 'af' = Comment Around Function)
      comment_line = "gcc", -- Comment current line
      comment_visual = "gc", -- Comment selection in visual mode
      textobject = "gc",   -- Text object for "comment" (e.g., 'dgc' deletes a comment)
    },
  },
}
