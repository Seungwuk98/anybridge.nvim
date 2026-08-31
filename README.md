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
| `install_command` | string | `"curl -fsSL https://code.anybridge.ai/install.sh \\| bash"` | Command shown to install anybridge if not found |
| `keymaps` | table or nil | `nil` | Keymap configuration (see example below) |

### Example

```lua
require("anybridge").setup({
  width_pct = 0.9,           -- 90% of parent window width
  height_pct = 0.7,          -- 70% of parent window height
  border = "double",         -- Double border style
  command = "anybridge",     -- Command to run
  install_command = "curl -fsSL https://code.anybridge.ai/install.sh | bash",
  keymaps = {
    toggle = "<leader>ab",   -- Toggle AnyBridge (normal + visual)
    open = "<leader>aO",     -- Open new session (normal + visual)
    close = "<leader>ac",    -- Close window (normal only)
    kill = "<leader>ax",     -- Kill terminal and close (normal only)
  },
})
```

To disable all keymaps (default):

```lua
require("anybridge").setup({
  -- keymaps defaults to nil, no keybindings registered
})
```

To disable specific keymaps:

```lua
require("anybridge").setup({
  keymaps = {
    toggle = false,  -- Disable toggle keymap
  },
})
```

## Features

- **Toggle behavior**: `:ABToggle` hides the window but keeps the terminal running; toggling again restores the same terminal session
- **Close behavior**: `:ABClose` closes the window but keeps the terminal running in background
- **Kill behavior**: `:ABKill` terminates the terminal and closes the window
- **Auto-restart**: After `:ABKill`, next `:ABOpen` starts a fresh session
- **Configurable keymaps**: Set custom keybindings in setup (disabled by default)
  - `toggle` and `open` work in both normal and visual modes
  - `close` and `kill` work in normal mode only
- **Executable check**: Shows installation prompt if `anybridge` is not found in PATH (does not auto-install)
- **Configurable**: Customize window size, border style, and command
- **Visual mode support**: Send selected text to a running AnyBridge terminal
- **Multiline code blocks**: Wrap multiline selections in Markdown code fences and send them as a bracketed paste
- **Terminal input mode**: Focus the terminal and enter Terminal mode after sending selected text
- **Single window**: `:ABOpen` always reuses the existing terminal session

### Visual Mode

Select text in visual mode and run `:ABOpen` or `:ABToggle` to send the selected content to an existing, running AnyBridge terminal:

```vim
" Select text visually and run:
:'<,'>ABOpen
:'<,'>ABToggle

" Or select a range:
:10,20ABOpen
:10,20ABToggle

" Or use keymap (if configured):
vmap <leader>aO  # visual mode + keymap sends selection to terminal
```

Multiline selections are wrapped in Markdown code fences and delivered as one bracketed paste. A trailing newline is included after the closing fence:

````text
```
<selected text>
```
````

After sending, the floating terminal receives focus and enters Terminal mode so you can continue typing immediately.

Selected text is intentionally not sent when the terminal is created for the first time. Open AnyBridge first, then send the selection with `:ABOpen`; or hide the running terminal and reopen it with `:ABToggle` while text is selected.

`ABToggle` sends a selection only while restoring a hidden terminal. If the terminal window is already visible, `ABToggle` hides it without sending the selection.

Single-line selections are sent unchanged:

```vim
:'<,'>ABOpen
```

### ABOpen Behavior

| Window State | Terminal State | Selected Text | Result |
|--------------|----------------|---------------|--------|
| Open | Running | Yes | Send text, focus terminal, enter Terminal mode |
| Open | Running | No | Switch to window |
| Open | Exited | Any | Switch to window |
| Closed | Running | Yes | Open window, send text, enter Terminal mode |
| Closed | Running | No | Open window |
| Closed | Exited | Any | Open exited terminal buffer without sending |
| Not created | — | Any | Start terminal without sending selected text |

### ABToggle Behavior

| Window State | Terminal State | Selected Text | Result |
|--------------|----------------|---------------|--------|
| Open | Any | Any | Close window |
| Closed | Running | Yes | Open window, send text, enter Terminal mode |
| Closed | Running | No | Open window |
| Closed | Exited | Any | Open window |
| Not created | — | Any | Start terminal without sending selected text |

## Command Comparison

| Command | Window | Terminal |
|---------|--------|----------|
| `:ABOpen` | Opens/Shows | Starts new or reuses |
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
