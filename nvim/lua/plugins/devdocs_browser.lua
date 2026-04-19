-- File: lua/plugins/devdocs_browser.lua

-- 1. The Logic
local function open_devdocs(query)
  local ft = vim.bo.filetype
  local word = query or vim.fn.expand("<cword>")
  
  -- Map your common Neovim filetypes to DevDocs slugs
  local slug_map = {
    python = "python~3.12",
    lua = "lua~5.4",
    bash = "bash",
    markdown = "markdown",
  }

  local slug = slug_map[ft] or ft
  local url = "https://devdocs.io/" .. slug .. "/#q=" .. word

  -- Use built-in open for Neovim 0.10+
  if vim.ui.open then
    vim.ui.open(url)
  else
    local cmd
    if vim.fn.has("mac") == 1 then cmd = { "open", url }
    elseif vim.fn.has("unix") == 1 then cmd = { "xdg-open", url }
    else cmd = { "explorer", url } end
    vim.fn.jobstart(cmd, { detach = true })
  end
end

-- 2. The Keybinding: <leader>h
vim.keymap.set("n", "<leader>h", function() 
  open_devdocs() 
end, { desc = "DevDocs: Jump to browser" })

-- 3. The Command: :Fdd (Renamed to remove underscore)
vim.api.nvim_create_user_command("Fdd", function(opts)
  open_devdocs(opts.args)
end, { nargs = 1, desc = "Search DevDocs in browser" })

-- Return an empty table so lazy.nvim doesn't error out
return {}
