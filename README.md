# anybridge.nvim

AnyBridge Neovim plugin.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "seungwuk98/anybridge.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- your configuration
  },
}
```

## Usage

### Commands

- `:ABOpen` - Open the AnyBridge floating terminal window
- `:ABToggle` - Toggle the AnyBridge floating terminal window (hides window, keeps terminal running)
- `:ABClose` - Close the AnyBridge floating terminal window (terminal keeps running in background)
- `:ABKill` - Kill the terminal and close the window

### Example

```vim
:ABOpen
```

Or set up a keybinding in your config:

```lua
vim.keymap.set("n", "<leader>ab", "<cmd>ABToggle<cr>", { desc = "Toggle AnyBridge" })
```

## Configuration

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `width_pct` | number | `0.8` | Float window width as percentage of parent window |
| `height_pct` | number | `0.6` | Float window height as percentage of parent window |
| `border` | string | `"rounded"` | Border style: `"single"`, `"double"`, `"rounded"`, `"solid"`, `"shadow"`, or table |
| `style` | string | `"minimal"` | Window style |
| `title` | string | `"AnyBridge"` | Title text displayed in the float window |
| `command` | string | `"anybridge"` | Shell command to run in the terminal |
| `executable_path` | string or nil | `nil` | Path to anybridge executable (null to search PATH) |
| `install_command` | string | `"pip install anybridge"` | Command shown to install anybridge if not found |

### Example

```lua
require("anybridge").setup({
  width_pct = 0.9,           -- 90% of parent window width
  height_pct = 0.7,          -- 70% of parent window height
  border = "double",         -- Double border style
  command = "anybridge",     -- Command to run
  install_command = "pip install anybridge",  -- Shown if anybridge not found
})
```

## Features

- **Toggle behavior**: `:ABToggle` hides the window but keeps the terminal running; toggling again restores the same terminal session
- **Close behavior**: `:ABClose` closes the window but keeps the terminal running in background
- **Kill behavior**: `:ABKill` terminates the terminal and closes the window
- **Auto-restart**: After `:ABKill`, next `:ABOpen` starts a fresh session
- **Executable check**: Shows installation prompt if `anybridge` is not found in PATH (does not auto-install)
- **Configurable**: Customize window size, border style, and command
- **Visual mode support**: Pass selected text to the terminal via heredoc

### Visual Mode

Select text in visual mode and run `:ABOpen` to pass the selected content to the terminal wrapped in a heredoc:

```vim
" Select text visually and run:
:'<,'>ABOpen

" Or select a range:
:10,20ABOpen
```

The selected text is passed to the terminal using Python heredoc syntax:

```python
python3 << 'PYEOF'
text = '''
selected text content
'''
print(text)
PYEOF
```

## Command Comparison

| Command | Window | Terminal |
|---------|--------|----------|
| `:ABOpen` | Opens | Starts new session |
| `:ABToggle` | Hides/Shows | Keeps running |
| `:ABClose` | Closes | Keeps running (background) |
| `:ABKill` | Closes | Terminates |

## Requirements

- `anybridge` executable must be installed and available in PATH
- If not found, a message will show the installation command (manual installation required)

## Testing

Run tests with:

```bash
make test
```

## Development

1. Clone this repository
2. Add to your Lazy.nvim config:

```lua
{
  "user/anybridge.nvim",
  dir = "/path/to/anybridge.nvim",
  lazy = false,
  opts = {},
}
```

## License

MIT
