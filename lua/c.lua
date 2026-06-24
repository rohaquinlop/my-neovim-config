-- C language support

local augroup = vim.api.nvim_create_augroup("CConfig", { clear = true })

-- C-specific indentation (uses global tab settings: 2 spaces, expandtab)
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "c", "h" },
	callback = function()
		vim.bo.cindent = true
		vim.bo.cinoptions = "l1,(0,t0,g0"
		vim.wo.colorcolumn = "80"
	end,
})

-- Enhanced clangd configuration
vim.lsp.config("clangd", {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--completion-style=detailed",
		"--header-insertion=never",
		"--function-arg-placeholders=false",
		"--all-scopes-completion",
	},
})

-- Auto-detect compile_commands.json
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup,
	pattern = { "*.c", "*.h" },
	callback = function()
		local compile_commands = vim.fs.find("compile_commands.json", {
			upward = true,
			path = vim.fn.expand("%:p:h"),
		})
		if #compile_commands > 0 then
			local root = vim.fs.dirname(compile_commands[1])
			local clients = vim.lsp.get_clients({ name = "clangd" })
			if #clients == 0 then
				vim.lsp.start({
					name = "clangd",
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--completion-style=detailed",
						"--header-insertion=never",
						"--function-arg-placeholders=false",
						"--compile-commands-dir=" .. root,
					},
				})
			end
		end
	end,
})

-- C-specific keymaps
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "c", "h" },
	callback = function()
		-- Toggle between .c and .h (header/source switch)
		vim.keymap.set("n", "<leader>ah", function()
			local current = vim.fn.expand("%")
			local alt
			if current:match("%.c$") then
				alt = current:gsub("%.c$", ".h")
			elseif current:match("%.h$") then
				alt = current:gsub("%.h$", ".c")
			else
				vim.notify("Not a .c or .h file", vim.log.levels.WARN)
				return
			end
			if vim.fn.filereadable(alt) == 1 then
				vim.cmd("edit " .. alt)
			else
				vim.cmd("split " .. alt)
			end
		end, { desc = "Switch header/source", buffer = true })

		-- Run make (respects compile_commands.json or Makefile)
		vim.keymap.set("n", "<leader>am", function()
			vim.cmd("make")
		end, { desc = "Run make", buffer = true })

		-- Compile current file (quick compilation check)
		vim.keymap.set("n", "<leader>ac", function()
			local file = vim.fn.expand("%")
			local out = vim.fn.expand("%:r")
			vim.cmd("!gcc -Wall -Wextra -std=c11 -o " .. vim.fn.shellescape(out) .. " " .. vim.fn.shellescape(file))
		end, { desc = "Compile current file", buffer = true })

		-- Run compiled binary
		vim.keymap.set("n", "<leader>ar", function()
			local out = vim.fn.expand("%:r")
			if vim.fn.executable(out) == 1 then
				vim.cmd("!./" .. vim.fn.shellescape(out))
			else
				vim.notify("No binary found: " .. out, vim.log.levels.WARN)
			end
		end, { desc = "Run compiled binary", buffer = true, noremap = true, silent = true })
	end,
})

-- Include .h files get C filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup,
	pattern = "*.h",
	callback = function()
		-- Only set if not already set to something more specific (like cpp)
		if vim.bo.filetype == "" then
			vim.bo.filetype = "c"
		end
	end,
})

-- Man pages are read-only and benefit from C syntax
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = "man",
	callback = function()
		vim.bo.readonly = true
		vim.bo.buflisted = false
	end,
})
