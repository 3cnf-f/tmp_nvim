-- vim.cmd([[
--   command! ToggleRelativeNumber lua vim.opt.relativenumber = not vim.opt.relativenumber
-- ]])
vim.api.nvim_create_user_command('ToggleRelativeNumber', function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, {})
