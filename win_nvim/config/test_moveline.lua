local function move_line(direction)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(win)[1]
  local col = vim.api.nvim_win_get_cursor(win)[2]
  local target = lnum + direction

  if target < 1 or target > vim.api.nvim_buf_line_count(buf) then
    return
  end

  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
  vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, false, {})
  vim.api.nvim_buf_set_lines(buf, target - 1, target - 1, false, { line })

  local len = #vim.api.nvim_buf_get_lines(buf, target - 1, target, false)[1]
  if col > len then
    col = len
  end
  vim.api.nvim_win_set_cursor(win, { target, col })
end

vim.keymap.set("n", "<M-w>", function() move_line(-1) end, { silent = true })
vim.keymap.set("n", "<M-s>", function() move_line(1) end, { silent = true })

vim.keymap.set("i", "<M-w>", function()
  vim.schedule(function() move_line(-1) end)
end, { silent = true })
vim.keymap.set("i", "<M-s>", function()
  vim.schedule(function() move_line(1) end)
end, { silent = true })
