local popup = require("nui.popup")
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

M.git_remote_list = function()
	local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree"):gsub("%s+", "")
	if is_git_repo ~= "true" then
		print("Not a git repo")
		return nil
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
				local commit_hash = vim.fn.system("git rev-parse HEAD"):gsub("%s+", "")

				local file_path = vim.fn.expand("%:p")
				local relative_path =
					vim.fn.system("git ls-files --full-name " .. vim.fn.shellescape(file_path)):gsub("%s+", "")

				local url = string.format("%s/blob/%s/%s#L%d", repo_url, commit_hash, relative_path, line_no)


				if vim.fn.has("mac") == 1 then
					vim.fn.system("open " .. vim.fn.shellescape(url))
				elseif vim.fn.has("unix") == 1 then
					vim.fn.system("xdg-open " .. vim.fn.shellescape(url))
				elseif vim.fn.has("win32") == 1 then
					vim.fn.system("start " .. vim.fn.shellescape(url))
				end

				print("Opening: " .. url)
			else
				print("No remote name found")
			end
		end,
	})

	menu:mount()

	return nil
end

return M
