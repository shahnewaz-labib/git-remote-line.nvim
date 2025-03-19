# Git Remote Line

Generate and share GitHub permalinks for code selections directly from Neovim.

## Prerequisites

- [gh](https://cli.github.com/) needs to be set up

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "shahnewaz-labib/git-remote-line",
  config = function()
    require("git-remote-line").setup()
    vim.keymap.set("n", "<leader>grl", ":GRL copy<CR>", { desc = "Copy GitHub permalink" })
    vim.keymap.set("n", "<leader>gro", ":GRL open<CR>", { desc = "Open GitHub permalink in browser" })

    vim.keymap.set("v", "<leader>grl", ":GRL copy<CR>", { desc = "Copy GitHub permalink for selection" })
    vim.keymap.set("v", "<leader>gro", ":GRL open<CR>", { desc = "Open GitHub permalink for selection" })
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
}
```

## Usage

Git Remote Line provides the :GRL command with the following options:

| Command     | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `:GRL copy` | Generate a github permalink and copy it to the clipboard        |
| `:GRL open` | Generate a github permalink and open it in your default browser |

When running the command:

1. If there are multiple git remotes, a selection menu will appear
2. Select the remote you want to use
3. The URL will be generated and either copied or opened based on your command
