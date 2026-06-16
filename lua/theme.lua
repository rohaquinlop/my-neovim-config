vim.pack.add({ { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } })

vim.cmd.colorscheme("catppuccin-macchiato")

local function set_transparent()
	local groups = {
		"Normal",
		"NormalNC",
		"EndofBuffer",
		"FloatBorder",
		"SignColumn",
		"StatusLine",
		"StatusLineNC",
		"TabLine",
		"TabLineFill",
		"TabLineSel",
		"ColorColumn",
	}
	for _, g in ipairs(groups) do
		vim.api.nvim_set_hl(0, g, { bg = "none" })
	end
	vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none", fg = "#767676" })
end

set_transparent()
