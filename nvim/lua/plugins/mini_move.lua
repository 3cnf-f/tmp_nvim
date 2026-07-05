return {
  'echasnovski/mini.move',
  version = false, -- Wait for latest features
  opts = {
    mappings = {
      -- Move visual selection in Visual mode
      left  = '<M-a>',
      right = '<M-d>',
      down  = '<M-s>',
      up    = '<M-w>',

      -- Move current line in Normal mode
      line_left  = '<M-a>',
      line_right = '<M-d>',
      line_down  = '<M-s>',
      line_up    = '<M-w>',
    },
    -- Optional: define options for movement behavior
    options = {
      -- Automatically re-indent when moving lines down/up
      reindent_linewise = true,
    },
  }
}
