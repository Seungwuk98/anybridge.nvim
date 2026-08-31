-- Default options for anybridge.nvim
local defaults = {
	-- Float window dimensions (percentage of parent window)
	width_pct = 0.8,
	height_pct = 0.6,

	-- Float window border style
	border = "rounded", -- "single", "double", "rounded", "solid", "shadow", or table

	-- Additional float window options
	style = "minimal",

	-- Content
	title = "AnyBridge",

	-- Terminal command to run
	command = "anybridge",

	-- AnyBridge executable path (null to search PATH)
	executable_path = nil,

	-- Installation command (if executable not found)
	install_command = "curl -fsSL https://code.anybridge.ai/install.sh | bash",

	-- Keymaps (set to false to disable specific ones, or nil to disable all)
	keymaps = nil,
}

local M = {}

function M.get(opts)
	return vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return M
