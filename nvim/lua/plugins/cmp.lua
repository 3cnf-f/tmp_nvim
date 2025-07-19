return {
  "hrsh7th/nvim-cmp",
  config = function()
    local cmp = require("cmp")
    require("cmp").setup({
      sources = cmp.config.sources({
        { name = "codeium" },
      }),
    })
  end
}
