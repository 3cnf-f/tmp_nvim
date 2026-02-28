if vim.g.is_windows then return {} end

return {
    {
        "3cnf-f/f_tmux_panetitle.nvim",
        config = function()
            require("f_tmux_panetitle").setup()
        end,
    }
}
