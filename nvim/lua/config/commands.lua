-- vim.cmd([[
--   command! ToggleRelativeNumber lua vim.opt.relativenumber = not vim.opt.relativenumber
-- ]])
vim.api.nvim_create_user_command('ToggleRelativeNumber', function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, {})

vim.api.nvim_create_user_command("FoldFunctions", function()
  -- 1. Open all folds first to start with a clean slate
  vim.cmd("normal! zR")
  
  -- 2. Determine the search pattern based on the current filetype
  local ft = vim.bo.filetype
  local pattern = ""
  
  if ft == "python" then
    vim.notify("Found Python file" .. ft, vim.log.levels.WARN)

    
    vim.cmd("normal! zR")
    vim.cmd("g/^def/normal zfaf")

  else
    vim.notify("FoldFunctions not configured for filetype: " .. ft, vim.log.levels.WARN)
    return
  end
  
end, { desc = "Auto-fold only functions based on filetype" })
