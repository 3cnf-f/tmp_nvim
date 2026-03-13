return {
	"rebelot/kanagawa.nvim",
	config = function()
		require('kanagawa').setup({
			compile = true,
			overrides = function(colors)
				return {
					-- "WinSeparator" controls the vertical split line color.
					-- We set it to 'fujiGray' (light grey) to make it visible.
					WinSeparator = { fg = colors.palette.fujiGray },
				}
			end,
		});
		vim.cmd("colorscheme kanagawa");
	end,
	build = function()
		vim.cmd("KanagawaCompile");
	end,
}
