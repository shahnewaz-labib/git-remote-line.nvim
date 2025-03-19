local Menu = require("nui.menu")

local M = {}

M.setup = function()
	-- nothing
end

--@return number
local get_cursor_line_number = function()
	local line_no, _ = unpack(vim.api.nvim_win_get_cursor(0))
	return line_no
end

--@param url string
--@return nil
local function open_in_browser(url)
	if vim.fn.has("mac") == 1 then
		vim.fn.system("open " .. vim.fn.shellescape(url))
	elseif vim.fn.has("unix") == 1 then
		vim.fn.system("xdg-open " .. vim.fn.shellescape(url))
	elseif vim.fn.has("win32") == 1 then
		vim.fn.system("start " .. vim.fn.shellescape(url))
	end
	print("Opening in browser: " .. url)
end

--@param url string
--@return nil
local function copy_to_clipboard(url)
	vim.fn.setreg("+", url)
	vim.fn.setreg('"', url)
	print("URL Copied to clipboard: " .. url)
end

--@param start_line number
--@param end_line number
M.build_github_url = function(start_line, end_line, callback)
	local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree"):gsub("%s+", "")
	if is_git_repo ~= "true" then
		print("Not a git repo")
		if callback then
			callback(nil)
		end
		return
	end

	local line_no = get_cursor_line_number()
	local git_remote = vim.fn.systemlist("git remote -v")

	local menu_items = {}
	for _, remote in ipairs(git_remote) do
		table.insert(menu_items, Menu.item(remote))
	end

	local menu = Menu({
		position = "50%",
		size = {
			width = 80,
			height = 10,
		},
		border = {
			style = "single",
			text = {
				top = "Select a Git Remote",
				top_align = "center",
			},
		},
	}, {
		lines = menu_items,
		max_width = 80,
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "q" },
			submit = { "<CR>", "<Space>" },
		},
		on_submit = function(item)
			local remote_name, remote_url = item.text:match("^(%S+)%s+(%S+)")
			
			if remote_name then
				local repo_url = remote_url:gsub("git@github.com:", "https://github.com/"):gsub("%.git$", "")

				local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("%s+", "")
				
				local commit_hash
				local remote_branch_cmd = string.format("git ls-remote %s %s", vim.fn.shellescape(remote_name), vim.fn.shellescape(branch))
				local remote_hash = vim.fn.system(remote_branch_cmd):match("^(%w+)")

				if remote_hash and remote_hash ~= "" then
					commit_hash = remote_hash
				else
					commit_hash = vim.fn.system("git rev-parse HEAD"):gsub("%s+", "")
					print("Warning: Using local HEAD, couldn't find commit on remote")
				end

				local file_path = vim.fn.expand("%:p")
				local relative_path =
					vim.fn.system("git ls-files --full-name " .. vim.fn.shellescape(file_path)):gsub("%s+", "")
				local url
				if end_line and end_line ~= start_line then
					url = string.format("%s/blob/%s/%s#L%d-L%d", repo_url, commit_hash, relative_path, start_line, end_line)
				else
					url = string.format("%s/blob/%s/%s#L%d", repo_url, commit_hash, relative_path, start_line)
				end

				print("URL: " .. url)
				if callback then
					callback(url)
				end
			else
				print("No remote name found")
				if callback then
					callback(nil)
				end
			end
		end
	})

	menu:mount()
end

--@param mode string
--@return nil
M.main = function(mode)
    local start_line, end_line = M.get_cursor_line_range()
	if mode == "copy" then
		M.build_github_url(start_line, end_line, copy_to_clipboard)
	elseif mode == "open" then
		M.build_github_url(start_line, end_line, open_in_browser)
	end
end

M.get_cursor_line_range = function()
	local start_line = get_cursor_line_number()
	local end_line = start_line

	if vim.fn.exists('*nvim_buf_get_mark') == 1 then
		local visual_start = vim.api.nvim_buf_get_mark(0, '<')
		local visual_end = vim.api.nvim_buf_get_mark(0, '>')

		if visual_start[1] ~= 0 and visual_end[1] ~= 0 then
			start_line = visual_start[1]
			end_line = visual_end[1]
		end
	end

	return start_line, end_line
end

return M
