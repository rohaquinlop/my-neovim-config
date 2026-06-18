-- Statusline

-- Async git branch (Issues 1, 2, 5)
local cached_branch = nil
local branch_buf = ""
local last_check = 0

local function fetch_git_branch()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		return
	end
	local file_dir = vim.fn.fnamemodify(bufname, ":h")
	if file_dir == "" then
		return
	end

	local now = vim.uv.now()
	if cached_branch ~= nil and branch_buf == bufname and now - last_check < 5000 then
		return
	end

	branch_buf = bufname
	last_check = now

	vim.system({ "git", "-C", file_dir, "branch", "--show-current" }, { text = true }, function(out)
		if out and out.code == 0 then
			local branch = vim.trim(out.stdout or "")
			if branch ~= cached_branch then
				cached_branch = branch
				vim.schedule(function()
					vim.cmd("redrawstatus")
				end)
			end
		else
			if cached_branch ~= "" then
				cached_branch = ""
				vim.schedule(function()
					vim.cmd("redrawstatus")
				end)
			end
		end
	end)
end

local function git_branch()
	if cached_branch and cached_branch ~= "" then
		return " " .. cached_branch
	end
	vim.schedule(fetch_git_branch)
	return cached_branch or ""
end

-- File type icon (for display after name)
local function file_type_icon()
	local ft = vim.bo.filetype
	local icons = {
		lua = "",
		python = "",
		javascript = "",
		typescript = "",
		javascriptreact = "",
		typescriptreact = "",
		html = "",
		css = "",
		scss = "",
		json = "",
		markdown = "",
		vim = "",
		sh = "",
		bash = "",
		zsh = "",
		rust = "",
		go = "",
		c = "",
		cpp = "",
		java = "",
		php = "",
		ruby = "",
		swift = "",
		kotlin = "",
		dart = "",
		elixir = "",
		haskell = "",
		sql = "",
		yaml = "",
		toml = "",
		xml = "",
		dockerfile = "",
		gitcommit = "",
		gitconfig = "",
		vue = "",
		svelte = "",
		astro = "",
	}
	return icons[ft] or ""
end

-- File type name
local function file_type()
	return vim.bo.filetype
end

-- File size (Issue 3: use nvim_buf_get_name instead of expand("%"))
local function file_size()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		return ""
	end
	local size = vim.fn.getfsize(bufname)
	if size < 0 then
		return ""
	end
	local size_str
	if size < 1024 then
		size_str = size .. "B"
	elseif size < 1024 * 1024 then
		size_str = string.format("%.1fK", size / 1024)
	else
		size_str = string.format("%.1fM", size / 1024 / 1024)
	end
	return size_str
end

-- Mode labels (Issue 9: use nvim_get_mode)
local function mode_label()
	local mode = vim.api.nvim_get_mode().mode
	local modes = {
		n = "NORMAL",
		i = "INSERT",
		v = "VISUAL",
		V = "V-LINE",
		["\22"] = "V-BLOCK",
		c = "COMMAND",
		s = "SELECT",
		S = "S-LINE",
		["\19"] = "S-BLOCK",
		R = "REPLACE",
		r = "REPLACE",
		["!"] = "SHELL",
		t = "TERMINAL",
	}
	return modes[mode] or mode
end

-- LSP diagnostics count (Issue 6: add INFO severity)
local function lsp_diagnostics()
	local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
	local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
	local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })

	local parts = {}
	if errors > 0 then
		table.insert(parts, "E:" .. errors)
	end
	if warnings > 0 then
		table.insert(parts, "W:" .. warnings)
	end
	if info > 0 then
		table.insert(parts, "I:" .. info)
	end
	if hints > 0 then
		table.insert(parts, "H:" .. hints)
	end

	if #parts == 0 then
		return ""
	end
	return table.concat(parts, " ")
end

local status_augroup = vim.api.nvim_create_augroup("StatusLineConfig", { clear = true })

-- Catppuccin Macchiato palette
local colors = {
	base = "#24273a",
	mantle = "#1e2030",
	crust = "#181926",
	surface0 = "#363a4f",
	surface1 = "#494d64",
	surface2 = "#5b6078",
	overlay0 = "#6e738d",
	overlay1 = "#8087a2",
	text = "#cad3f5",
	subtext0 = "#a5adcb",
	subtext1 = "#b8c0e0",
	blue = "#8aadf4",
	green = "#a6da95",
	red = "#ed8796",
	yellow = "#eed49f",
	peach = "#f5a97f",
	mauve = "#c6a0f6",
	teal = "#8bd5ca",
	lavender = "#b7bdf8",
	flamingo = "#f0c6c6",
	pink = "#f5bde6",
	sapphire = "#7dc4e4",
}

-- Mode colors for dynamic highlight updates
local mode_colors = {
	n = colors.blue,
	i = colors.green,
	v = colors.mauve,
	V = colors.mauve,
	["\22"] = colors.mauve,
	c = colors.peach,
	s = colors.mauve,
	S = colors.mauve,
	["\19"] = colors.mauve,
	R = colors.red,
	r = colors.red,
	["!"] = colors.peach,
	t = colors.green,
}

-- Setup highlight groups
local function setup_highlights()
	-- Static section highlights
	vim.api.nvim_set_hl(0, "SlGit", { bg = colors.surface0, fg = colors.teal })
	vim.api.nvim_set_hl(0, "SlFile", { bg = colors.surface0, fg = colors.text })
	vim.api.nvim_set_hl(0, "SlType", { bg = colors.surface1, fg = colors.lavender })
	vim.api.nvim_set_hl(0, "SlSize", { bg = colors.surface1, fg = colors.subtext0 })
	vim.api.nvim_set_hl(0, "SlPosition", { bg = colors.surface0, fg = colors.subtext0 })
	vim.api.nvim_set_hl(0, "SlDiagnostics", { bg = colors.surface0, fg = colors.yellow })

	-- Separator highlights
	vim.api.nvim_set_hl(0, "SlSepRight", { bg = colors.surface0, fg = colors.base })
	vim.api.nvim_set_hl(0, "SlSepLeft", { bg = colors.base, fg = colors.surface0 })

	-- Inactive window
	vim.api.nvim_set_hl(0, "SlInactive", { bg = colors.mantle, fg = colors.overlay0 })

	-- Dynamic mode highlight (updated on ModeChanged)
	vim.api.nvim_set_hl(0, "SlMode", { bg = colors.blue, fg = colors.base, bold = true })
end

-- Update mode highlight on mode change (Issue 9: use nvim_get_mode)
local function update_mode_highlight()
	local mode = vim.api.nvim_get_mode().mode
	local color = mode_colors[mode] or mode_colors.n
	vim.api.nvim_set_hl(0, "SlMode", { bg = color, fg = colors.base, bold = true })
end

-- Rounded separators
local Sep = {
	left = "",
	right = "",
	left_thin = "",
	right_thin = "",
}

local function setup_dynamic_statusline()
	setup_highlights()

	-- Update mode highlight on every mode change
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = status_augroup,
		callback = function()
			update_mode_highlight()
			vim.cmd("redrawstatus")
		end,
	})

	-- Async git branch: invalidate cache on buffer/directory change (Issues 1, 2, 5)
	vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
		group = status_augroup,
		callback = function()
			cached_branch = nil
			branch_buf = ""
			fetch_git_branch()
		end,
	})

	-- Inactive window statusline (Issue 7)
	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		group = status_augroup,
		callback = function()
			vim.wo.statusline = "%#SlInactive# %f %l:%c %P"
		end,
	})

	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		group = status_augroup,
		callback = function()
			vim.wo.statusline = nil
		end,
	})

	-- Set statusline (static string, dynamic highlight via SlMode)
	-- Issue 1: module pattern via require('status-line')
	-- Issue 8: %L for total line count, %P for position percentage
	vim.opt.statusline = table.concat({
		-- Mode section (highlight updates dynamically via ModeChanged autocmd)
		"%#SlMode# %{v:lua.require('status-line').mode_label()} ",
		-- Git branch
		Sep.right,
		"%#SlGit#%{v:lua.require('status-line').git_branch()} ",
		-- File info
		Sep.right,
		"%#SlFile# %f %h%m%r",
		-- Right side
		"%= ",
		-- Diagnostics
		"%#SlDiagnostics#%{v:lua.require('status-line').lsp_diagnostics()} ",
		-- File type
		Sep.left,
		"%#SlType# %{v:lua.require('status-line').file_type()} %{v:lua.require('status-line').file_type_icon()} ",
		-- File size
		Sep.left,
		"%#SlSize# %{v:lua.require('status-line').file_size()} ",
		-- Position
		Sep.left,
		"%#SlPosition# %l:%c %L %P ",
	})
end

setup_dynamic_statusline()

-- Module exports (Issue 4: replace _G exports with module table)
local M = {}
M.mode_label = mode_label
M.git_branch = git_branch
M.file_type = file_type
M.file_type_icon = file_type_icon
M.file_size = file_size
M.lsp_diagnostics = lsp_diagnostics
return M
