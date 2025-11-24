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
        
        -- Removed 'ä' mappings to free it for Flash.nvim
        
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
