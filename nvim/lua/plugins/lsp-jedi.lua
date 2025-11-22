return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local opts = { buffer = args.buf, noremap = true, silent = true }
        
        -- Core navigation (most frequent, keep short)
        vim.keymap.set("n", "gd", require("fzf-lua").lsp_definitions, opts)
        vim.keymap.set("n", "gr", require("fzf-lua").lsp_references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        
        -- ä prefix: Information & Diagnostics
        vim.keymap.set("n", "än", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "äp", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "äf", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "äl", require("fzf-lua").diagnostics_document, opts)
        vim.keymap.set("n", "äh", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "äs", vim.lsp.buf.signature_help, opts)
        vim.keymap.set("n", "äd", require("fzf-lua").lsp_document_symbols, opts)
        vim.keymap.set("n", "äa", require("fzf-lua").lsp_code_actions, opts)
        vim.keymap.set("n", "äj", require("fzf-lua").helptags, opts)
        
        vim.diagnostic.config({ virtual_text = true })
      end,
    })

    vim.lsp.config('jedi_language_server', {
      cmd = { 'jedi-language-server' },
      filetypes = { 'python' },
      root_markers = { 'pyproject.toml', 'setup.py', '.git' },
    })

    vim.lsp.enable('jedi_language_server')
  end,
}
