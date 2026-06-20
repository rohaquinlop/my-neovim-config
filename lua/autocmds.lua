local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	pattern = {
		"*.lua",
		"*.py",
		"*.rs",
		"*.json",
		"*.sh",

		"*.js",
		"*.jsx",
		"*.ts",
		"*.tsx",
		"*.css",
		"*.scss",
		"*.html",

		"*.c",
		"*.cpp",
		"*.h",
		"*.hpp",
	},
	callback = function(args)
		-- avoid formatting non-file buffers (helps prevent weird write prompts)
		if vim.bo[args.buf].buftype ~= "" then
			return
		end
		if not vim.bo[args.buf].modifiable then
			return
		end
		if vim.api.nvim_buf_get_name(args.buf) == "" then
			return
		end

		local clients = vim.lsp.get_clients({ bufnr = args.buf })

		-- Find the best formatter:
		--   efm (clang-format, stylua, ruff, prettier, etc.) is preferred
		--   clangd as fallback for C/C++ when efm formatter isn't available
		local formatter_name = nil
		for _, c in ipairs(clients) do
			if c.name == "efm" then
				formatter_name = "efm"
				break
			end
		end

		-- Fallback: clangd for C/C++ (handles formatting based on .clang-format)
		if not formatter_name then
			local ft = vim.bo[args.buf].filetype
			if ft == "c" or ft == "cpp" then
				for _, c in ipairs(clients) do
					if c.name == "clangd" then
						formatter_name = "clangd"
						break
					end
				end
			end
		end

		if not formatter_name then
			return
		end

		local ok, err = pcall(vim.lsp.buf.format, {
			bufnr = args.buf,
			timeout_ms = 2000,
			filter = function(c)
				return c.name == formatter_name
			end,
		})
		if not ok then
			vim.notify("Format error: " .. tostring(err), vim.log.levels.WARN)
		end
	end,
})

-- highlight yanked test
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank()
	end,
})

-- return to last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup,
	desc = "Restore last cursor position",
	callback = function()
		if vim.o.diff then
			return
		end

		local last_pos = vim.api.nvim_buf_get_mark(0, '"')
		local last_line = vim.api.nvim_buf_line_count(0)

		local row = last_pos[1]
		if row < 1 or row > last_line then
			return
		end

		pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
	end,
})

-- wrap, linebreak and spellcheck on markdown and text files
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.spell = true
	end,
})
