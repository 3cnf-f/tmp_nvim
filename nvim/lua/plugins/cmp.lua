return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", -- Required to talk to Jedi/Python
    "hrsh7th/cmp-buffer",   -- Optional: suggests words found in the current file
    "hrsh7th/cmp-path",     -- Optional: suggests file paths
  },
  config = function()
    local cmp = require("cmp")
    cmp.setup({
      -- 1. Key Mappings
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(), -- CTRL+SPACE to force open menu
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- ENTER to confirm
        ["<Tab>"] = cmp.mapping.select_next_item(), -- TAB to go down
        ["<S-Tab>"] = cmp.mapping.select_prev_item(), -- SHIFT+TAB to go up
      }),
      
      -- 2. Sources (Order matters: top is higher priority)
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- This enables 'bot.' completion
        { name = "codeium" },
        { name = "buffer" },
        { name = "path" },
      }),
    })
  end
}
