-- lsp
vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	{
		src = "https://github.com/creativenull/efmls-configs-nvim",
		name = "efm",
	},
	{
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},
	"https://github.com/L3MON4D3/LuaSnip",
	"https://github.com/mrcjkb/rustaceanvim",
})

require("mason").setup({})

local diagnostic_signs = {
	Error = "\u{f057} ",
	Warn = "\u{f071} ",
	Hint = "\u{ea61}",
	Info = "\u{f05a}",
}

vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
		header = "",
		prefix = "",
		focusable = false,
		style = "minimal",
	},
})

do
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end

local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local function lsp_opts(desc)
		return { noremap = true, silent = true, buffer = bufnr, desc = desc }
	end

	vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, lsp_opts("Goto Definition"))

	vim.keymap.set("n", "<leader>gD", vim.lsp.buf.declaration, lsp_opts("Goto Declaration"))

	vim.keymap.set("n", "<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, lsp_opts("Definition (Split)"))

	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, lsp_opts("Code Action"))
	vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, lsp_opts("Rename"))

	vim.keymap.set("n", "<leader>D", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, lsp_opts("Line Diagnostics"))
	vim.keymap.set("n", "<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, lsp_opts("Cursor Diagnostics"))
	vim.keymap.set("n", "<leader>nd", function()
		vim.diagnostic.jump({ count = 1 })
	end, lsp_opts("Next Diagnostic"))

	vim.keymap.set("n", "<leader>pd", function()
		vim.diagnostic.jump({ count = -1 })
	end, lsp_opts("Prev Diagnostic"))

	vim.keymap.set("n", "K", vim.lsp.buf.hover, lsp_opts("Hover"))
	vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, lsp_opts("Hover (variable info)"))

	vim.keymap.set("n", "<leader>fr", vim.lsp.buf.references, lsp_opts("References"))
	vim.keymap.set("n", "<leader>ft", vim.lsp.buf.type_definition, lsp_opts("Type Definitions"))
	vim.keymap.set("n", "<leader>fs", vim.lsp.buf.document_symbol, lsp_opts("Document Symbols"))
	vim.keymap.set("n", "<leader>fw", vim.lsp.buf.workspace_symbol, lsp_opts("Workspace Symbols"))
	vim.keymap.set("n", "<leader>fi", vim.lsp.buf.implementation, lsp_opts("Implementations"))

	if client:supports_method("textDocument/codeAction", bufnr) then
		vim.keymap.set("n", "<leader>oi", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports" }, diagnostics = {} },
				apply = true,
				bufnr = bufnr,
			})
			vim.defer_fn(function()
				vim.lsp.buf.format({
					bufnr = bufnr,
					filter = function(c)
						return c.name == "efm"
					end,
				})
			end, 50)
		end, lsp_opts("Organize Imports"))
	end
end

vim.api.nvim_create_autocmd("LspAttach", { group = "UserConfig", callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-Space>"] = { "show", "hide" },
		["<CR>"] = { "accept", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<Down>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<Up>"] = { "select_prev", "fallback" },
		["<Tab>"] = { "snippet_forward", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "fallback" },
	},
	appearance = { nerd_font_variant = "mono" },
	completion = {
		menu = {
			auto_show = function()
				return vim.bo.filetype ~= "markdown"
			end,
		},
	},
	sources = { default = { "lsp", "path", "buffer", "snippets" } },
	snippets = {
		expand = function(snippet)
			require("luasnip").lsp_expand(snippet)
		end,
	},
	fuzzy = {
		implementation = "prefer_rust",
		prebuilt_binaries = { download = true },
	},
})

vim.lsp.config["*"] = {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
}

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})
vim.lsp.config("ruff", {
	init_options = {
		settings = {
			lineLength = 80,
		},
	},
})
vim.lsp.config("ty", {})

local function detect_venv(buf)
	local root = vim.fs.root(buf, { ".venv", "venv", "pyproject.toml", ".git" })
	if not root then
		return
	end
	for _, venv_name in ipairs({ ".venv", "venv" }) do
		local venv_path = root .. "/" .. venv_name
		if vim.fn.isdirectory(venv_path) == 1 then
			vim.env.VIRTUAL_ENV = venv_path
			return
		end
	end
end

vim.api.nvim_create_autocmd("FileType", {
	group = "UserConfig",
	pattern = "python",
	callback = function(ev)
		detect_venv(ev.buf)
	end,
})

vim.api.nvim_create_autocmd("DirChanged", {
	group = "UserConfig",
	callback = function(ev)
		if vim.bo.filetype == "python" then
			detect_venv(ev.buf)
		end
	end,
})
vim.lsp.config("bashls", {})
vim.lsp.config("ts_ls", {})
vim.lsp.config("clangd", {})
vim.lsp.config("nixd", {})
vim.lsp.config("nil", {})
vim.lsp.config("pyright", {
	before_init = function(params, config)
		local root = params.rootPath
		if not root or root == "" then
			return
		end
		for _, venv_name in ipairs({ ".venv", "venv" }) do
			local venv_path = root .. "/" .. venv_name
			if vim.fn.isdirectory(venv_path) == 1 then
				local python_bin = venv_path .. "/bin/python"
				if vim.fn.executable(python_bin) == 1 then
					config.settings = config.settings or {}
					config.settings.python = config.settings.python or {}
					config.settings.python.pythonPath = python_bin
					return
				end
			end
		end
	end,
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "off",
				diagnosticMode = "off",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
			},
		},
	},
})

vim.g.rustaceanvim = {
	server = {
		capabilities = require("blink.cmp").get_lsp_capabilities(),
	},
}

do
	local luacheck = require("efmls-configs.linters.luacheck")
	local stylua = require("efmls-configs.formatters.stylua")

	local prettier_d = require("efmls-configs.formatters.prettier_d")
	local eslint_d = require("efmls-configs.linters.eslint_d")

	local fixjson = require("efmls-configs.formatters.fixjson")

	local shellcheck = require("efmls-configs.linters.shellcheck")
	local shfmt = require("efmls-configs.formatters.shfmt")

	local cpplint = require("efmls-configs.linters.cpplint")
	local cppcheck = require("efmls-configs.linters.cppcheck")
	local clangfmt = require("efmls-configs.formatters.clang_format")
	local cpp_clangfmt = {
		formatCommand = "clang-format --style=Google -",
		formatStdin = true,
	}

	local ruff_fmt = require("efmls-configs.formatters.ruff")

	vim.lsp.config("efm", {
		filetypes = {
			"c",
			"cpp",
			"css",
			"html",
			"javascript",
			"javascriptreact",
			"json",
			"jsonc",
			"lua",
			"markdown",
			"python",
			"sh",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
		},
		init_options = { documentFormatting = true },
		settings = {
			languages = {
				c = { clangfmt, cppcheck },
				cpp = { cpp_clangfmt, cpplint },
				css = { prettier_d },
				html = { prettier_d },
				javascript = { eslint_d, prettier_d },
				javascriptreact = { eslint_d, prettier_d },
				json = { eslint_d, fixjson },
				jsonc = { eslint_d, fixjson },
				lua = { luacheck, stylua },
				markdown = { prettier_d },
				python = { ruff_fmt },
				sh = { shellcheck, shfmt },
				typescript = { eslint_d, prettier_d },
				typescriptreact = { eslint_d, prettier_d },
				vue = { eslint_d, prettier_d },
				svelte = { eslint_d, prettier_d },
			},
		},
	})
end

vim.lsp.enable({
	"ruff",
	"lua_ls",
	"bashls",
	"ty",
	"pyright",
	"ts_ls",
	"clangd",
	"nixd",
	"nil",
	"efm",
})
