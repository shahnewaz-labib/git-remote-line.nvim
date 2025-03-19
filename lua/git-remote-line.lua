local Menu = require("nui.menu")

--@return number
local get_cursor_line_number = function()
	local line_no, _ = unpack(vim.api.nvim_win_get_cursor(0))
	return line_no
end

--@return number, number
local get_cursor_line_range = function()
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

-- Extract remote name and URL from the selected item text
local function extract_remote_info(text)
    return text:match("^(%S+)%s+(%S+)")
end

-- Convert git URL to GitHub web URL
local function get_http_repo_url(git_url)
    return git_url:gsub("git@github.com:", "https://github.com/"):gsub("%.git$", "")
end

-- Get current branch name
local function get_current_branch()
    return vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("%s+", "")
end

-- Get commit hash, trying remote first and falling back to local
local function get_commit_hash(remote_name, branch)
    local remote_branch_cmd = string.format("git ls-remote %s %s", 
        vim.fn.shellescape(remote_name), 
        vim.fn.shellescape(branch))
    local remote_hash = vim.fn.system(remote_branch_cmd):match("^(%w+)")

    if remote_hash and remote_hash ~= "" then
        return remote_hash
    else
        print("Warning: Using local HEAD, couldn't find commit on remote")
        return vim.fn.system("git rev-parse HEAD"):gsub("%s+", "")
    end
end

-- Get file's path relative to git repo root
local function get_file_relative_path()
    local file_path = vim.fn.expand("%:p")
    return vim.fn.system("git ls-files --full-name " .. 
        vim.fn.shellescape(file_path)):gsub("%s+", "")
end

-- Build GitHub URL with line numbers
local function build_url_with_lines(repo_url, commit_hash, relative_path, start_line, end_line)
    if end_line and end_line ~= start_line then
        return string.format("%s/blob/%s/%s#L%d-L%d", 
            repo_url, commit_hash, relative_path, start_line, end_line)
    else
        return string.format("%s/blob/%s/%s#L%d", 
            repo_url, commit_hash, relative_path, start_line)
    end
end

--@param start_line number
--@param end_line number
local build_github_url = function(start_line, end_line, callback)
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
			local remote_name, remote_url = extract_remote_info(item.text)
			
			if remote_name then
				local repo_url = get_http_repo_url(remote_url)
				local branch = get_current_branch()
				local commit_hash = get_commit_hash(remote_name, branch)
				local relative_path = get_file_relative_path()
				local url = build_url_with_lines(repo_url, commit_hash, relative_path, start_line, end_line)
				
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
local main = function(mode)
    local start_line, end_line = get_cursor_line_range()
	if mode == "copy" then
		build_github_url(start_line, end_line, copy_to_clipboard)
	elseif mode == "open" then
		build_github_url(start_line, end_line, open_in_browser)
	end
end

local M = {}

M.setup = function()
	vim.api.nvim_create_user_command("GRL", function(opts)
        local mode = opts.args
        if mode ~= "copy" and mode ~= "open" then
            print("Invalid mode. Usage: GRL copy|open")
            return
        end
        main(mode)
    end, {
        nargs = 1,
        desc = "GitHub Remote Line - Generate GitHub URL for current line(s)",
        complete = function()
            return {"copy", "open"}
        end
    })
end

return M
