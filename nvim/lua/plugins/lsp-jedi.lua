return {
  "neovim/nvim-lspconfig",
  config = function()
    -- Keybindings when LSP attaches
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>lp", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "<leader>ln", vim.diagnostic.goto_next, opts)

        -- Optional (use less often):
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)      -- Show error in floating window
        vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)      -- Put all diagnostics in location list
        vim.diagnostic.config({ virtual_text = true })                          -- Show errors inline (on by default)

      end,
    })

    -- New syntax for Neovim 0.11+
    vim.lsp.config('jedi_language_server', {
      cmd = { 'jedi-language-server' },
      filetypes = { 'python' },
      root_markers = { 'pyproject.toml', 'setup.py', '.git' },
    })

    -- Enable it
    vim.lsp.enable('jedi_language_server')
  end,
}
