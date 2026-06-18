vim.pack.add({ { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } })

require("catppuccin").setup({
	flavour = "macchiato",
	transparent_background = true,
	integrations = {
		nvimtree = true,
		mini = { enabled = true, indentscope_color = "" },
		treesitter = true,
		gitsigns = true,
		which_key = true,
	},
})

vim.cmd.colorscheme("catppuccin-macchiato")
