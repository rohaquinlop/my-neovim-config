vim.pack.add({
	"https://github.com/nvim-tree/nvim-tree.lua",
	"https://github.com/echasnovski/mini.nvim",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
	},
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
	},
	"https://github.com/folke/which-key.nvim",
	"https://github.com/dmtrKovalenko/fff.nvim",
	"https://codeberg.org/andyg/leap.nvim",
	"https://github.com/tpope/vim-repeat",
})

require("nvim-tree").setup({
	view = {
		width = 35,
	},
	filters = {
		dotfiles = false,
	},
	renderer = {
		group_empty = true,
	},
})
vim.keymap.set("n", "<leader>e", function()
	require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })

-- NvimTree transparency removed to match catppuccin solid backgrounds

-- Load fff.nvim (first startup: binary missing → pcall catches the Rust error)
-- Download binary only if missing (guards against re-download every startup)
pcall(vim.cmd.packadd, "fff.nvim")
if
	vim.fn.filereadable(vim.fn.stdpath("data") .. "/site/pack/core/opt/fff.nvim/target/release/libfff_nvim.dylib") == 0
then
	require("fff.download").download_or_build_binary()
end
require("fff").setup({})
vim.keymap.set("n", "<leader>ff", function()
	require("fff").find_files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", function()
	require("fff").live_grep()
end, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", function()
	vim.cmd("ls")
end, { desc = "List buffers" })
vim.keymap.set("n", "<leader>fh", function()
	vim.cmd("help")
end, { desc = "Open help" })

require("mini.ai").setup({})
require("mini.comment").setup({})
require("mini.move").setup({})
require("mini.surround").setup({
	mappings = {
		add = "ms", -- Helix: ms{char} surrounds selection/motion
		delete = "md", -- Helix: md{char} deletes surrounding
		replace = "mr", -- Helix: mr{old}{new} replaces surrounding
		find = "mf",
		find_left = "mF",
		highlight = "mh",
		suffix_last = "l",
		suffix_next = "n",
	},
})
require("mini.cursorword").setup({})
require("mini.indentscope").setup({})
require("mini.pairs").setup({})
require("mini.trailspace").setup({})
require("mini.bufremove").setup({})
require("mini.notify").setup({})
require("mini.icons").setup({})

require("mini.diff").setup({
	view = {
		style = "sign",
		signs = { add = "▎", change = "▎", delete = "▎" },
	},
})

require("mini.git").setup({})

local MiniDiff = require("mini.diff")
vim.keymap.set("n", "]h", function()
	MiniDiff.goto_hunk("next")
end, { desc = "Next git hunk" })
vim.keymap.set("n", "[h", function()
	MiniDiff.goto_hunk("prev")
end, { desc = "Prev git hunk" })
vim.keymap.set("n", "<leader>hs", MiniDiff.operator, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hp", function()
	MiniDiff.toggle_overlay()
end, { desc = "Preview diff overlay" })
vim.keymap.set("n", "<leader>hb", function()
	require("mini.git").show_at_cursor()
end, { desc = "Git blame/show" })

local setup_treesitter = function()
	local treesitter = require("nvim-treesitter")
	treesitter.setup({})
	local ensure_installed = {
		"vim",
		"vimdoc",
		"rust",
		"c",
		"cpp",
		"go",
		"html",
		"css",
		"javascript",
		"json",
		"lua",
		"markdown",
		"python",
		"typescript",
		"vue",
		"svelte",
		"bash",
	}

	local config = require("nvim-treesitter.config")

	local already_installed = config.get_installed()
	local parsers_to_install = {}

	for _, parser in ipairs(ensure_installed) do
		if not vim.tbl_contains(already_installed, parser) then
			table.insert(parsers_to_install, parser)
		end
	end

	if #parsers_to_install > 0 then
		treesitter.install(parsers_to_install)
	end
end

setup_treesitter()

-- Treesitter textobjects (Helix-style ]f / [f function navigation)
local ts_textobjects = require("nvim-treesitter-textobjects")
ts_textobjects.setup({})
local ts_move = require("nvim-treesitter-textobjects.move")
vim.keymap.set({ "n", "x", "o" }, "]f", function()
	ts_move.goto_next_start("@function.outer")
end, { desc = "Next function" })
vim.keymap.set({ "n", "x", "o" }, "[f", function()
	ts_move.goto_previous_start("@function.outer")
end, { desc = "Prev function" })
vim.keymap.set({ "n", "x", "o" }, "]F", function()
	ts_move.goto_next_end("@function.outer")
end, { desc = "Next function end" })
vim.keymap.set({ "n", "x", "o" }, "[F", function()
	ts_move.goto_previous_end("@function.outer")
end, { desc = "Prev function end" })

-- Leap.nvim (Helix-style 2-char jump)
-- gw = bidirectional jump (Helix convention)
-- S  = jump to other windows
vim.keymap.set({ "n", "x", "o" }, "gw", "<Plug>(leap)", { desc = "Leap (bidirectional)" })
vim.keymap.set("n", "S", "<Plug>(leap-from-window)", { desc = "Leap (all windows)" })

local wk = require("which-key")

wk.setup({
	preset = "modern",
	delay = function(ctx)
		return ctx.plugin and 0 or 50
	end,
	icons = {
		mappings = true,
		colors = true,
		breadcrumb = "»",
		separator = "➜",
		group = "+",
	},
	win = {
		padding = { 1, 2 },
		title = true,
		title_pos = "center",
		no_overlap = true,
		border = "rounded",
	},
	layout = {
		width = { min = 20 },
		spacing = 3,
	},
	sort = { "local", "order", "group", "alphanum", "mod" },
	plugins = {
		marks = true,
		registers = true,
		spelling = {
			enabled = true,
			suggestions = 20,
		},
		presets = {
			operators = true,
			motions = true,
			text_objects = true,
			windows = true,
			nav = true,
			z = true,
			g = true,
		},
	},
	show_help = true,
	show_keys = true,
})

wk.add({
	{ "<leader>f", group = "Find" },
	{ "<leader>g", group = "Go To" },
	{ "<leader>b", group = "Buffer" },
	{ "<leader>s", group = "Split" },
	{ "<leader>h", group = "Git Hunk" },
	{ "gw", desc = "Leap (Helix jump)" },
	{ "]f", desc = "Next function" },
	{ "[f", desc = "Prev function" },
	{ "ms", desc = "Surround" },
	{ "md", desc = "Delete surrounding" },
	{ "mr", desc = "Replace surrounding" },
})
