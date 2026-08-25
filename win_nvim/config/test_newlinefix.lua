vim.api.nvim_create_user_command("NormalizeNewlines", function()
  local buf = vim.api.nvim_get_current_buf()
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

  text = text:gsub("\n\n+", "\r\n")

  text = text:gsub("\n", "")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
end, {}) 
