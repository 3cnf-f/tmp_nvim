return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        -- Base options used for all mappings
        local opts = { buffer = args.buf, noremap = true, silent = true }
        
        -- Helper function to merge 'desc' with the base 'opts'
        local function map(keys, func, desc)
          vim.keymap.set("n", keys, func, vim.tbl_extend("force", opts, { desc = desc }))
        end

        -- Core navigation (now with descriptions)
        map("gd", require("fzf-lua").lsp_definitions, "Go to Definition")
        map("gr", require("fzf-lua").lsp_references, "Go to References")
        map("K", vim.lsp.buf.hover, "Hover Documentation")
        map("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
        
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
