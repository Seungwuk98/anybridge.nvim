-- anybridge.nvim main entry point
local M = {}

local options = require("anybridge.options")

function M.setup(opts)
  local config = options.get(opts)
  
  -- Create commands
  vim.api.nvim_create_user_command("ABOpen", function()
    M.open_float()
  end, { nargs = 0 })
  
  vim.api.nvim_create_user_command("ABToggle", function()
    M.toggle_float()
  end, { nargs = 0 })
  
  vim.api.nvim_create_user_command("ABClose", function()
    M.close_float()
  end, { nargs = 0 })
  
  -- Store config
  M.config = config
end

function M.get_float_window()
  -- Find existing float window relative to win (our AB float windows)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, config = pcall(vim.api.nvim_win_get_config, win)
    if ok and config and config.relative == "win" then
      return win
    end
  end
  return nil
end

function M.get_float_buf()
  -- Find existing float buffer
  local win = M.get_float_window()
  if win and vim.api.nvim_win_is_valid(win) then
    return vim.api.nvim_win_get_buf(win)
  end
  return nil
end

function M.close_float()
  local win = M.get_float_window()
  if win and vim.api.nvim_win_is_valid(win) then
    local current_win = vim.api.nvim_get_current_win()
    if win == current_win then
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if w ~= win then
          vim.api.nvim_set_current_win(w)
          break
        end
      end
    end
    vim.api.nvim_win_close(win, true)
  end
end

--- Check if terminal buffer is still running
function M.is_terminal_running(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
  if buftype ~= "terminal" then
    return false
  end
  
  -- Check if there's a running job in this buffer
  local job_id = vim.fn.getbufvar(buf, "job_id")
  if job_id and job_id ~= 0 and job_id ~= nil then
    -- Check if job is still running using jobwait with 0 timeout
    local ok, result = pcall(vim.fn.jobwait, {job_id}, 0)
    if ok and result and result[1] == -1 then
      return true  -- -1 means still running
    end
    -- If jobwait returns a number, the job has finished
    return false
  end
  
  -- No job_id means terminal hasn't started yet or is not running
  return false
end

--- Close and reopen float window with fresh terminal
function M.restart_float()
  local win = M.get_float_window()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  M.open_float()
end

function M.toggle_float()
  local win = M.get_float_window()
  local buf = M.get_float_buf()
  
  if win and vim.api.nvim_win_is_valid(win) then
    -- Window exists, check if terminal is running
    if M.is_terminal_running(buf) then
      -- Terminal is running, just switch to window
      vim.api.nvim_set_current_win(win)
    else
      -- Terminal is not running, restart the float window
      M.restart_float()
    end
  else
    -- No window, open new one
    M.open_float()
  end
end

function M.check_executable(config)
  local cmd = config.executable_path or config.command
  
  -- Check if executable exists using which command
  local handle = io.popen("which " .. cmd .. " 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= nil and result:match("%S+") ~= nil
  end
  return false
end

function M.show_install_prompt(config)
  local msg = {
    "AnyBridge is not installed.",
    "",
    "Install it by running:",
    "  " .. config.install_command,
    "",
    "Press Enter after installation, then try :ABOpen again.",
  }
  
  vim.api.nvim_echo(msg, true, {})
end

function M.open_float()
  local config = M.config or options.get({})
  
  -- Check if executable exists
  if not M.check_executable(config) then
    M.show_install_prompt(config)
    return
  end
  
  -- Get current window dimensions
  local current_win = vim.api.nvim_get_current_win()
  local win_width = vim.api.nvim_win_get_width(current_win)
  local win_height = vim.api.nvim_win_get_height(current_win)
  
  -- Calculate float window dimensions using config
  local width = math.floor(win_width * config.width_pct)
  local height = math.floor(win_height * config.height_pct)
  
  -- Calculate centered position
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)
  
  -- Create terminal buffer
  local buf = vim.api.nvim_create_buf(true, false)  -- terminal buffer
  
  -- Create floating window with terminal buffer
  local win_opts = {
    relative = "win",
    win = current_win,
    width = width,
    height = height,
    row = row,
    col = col,
    style = config.style,
    border = config.border,
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "filetype", "anybridge")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  
  -- Start terminal with anybridge command
  local cmd = config.command
  vim.fn.termopen(cmd, {
    on_exit = function(job_id, exit_code)
      -- Terminal exited, show message
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
        "",
        "AnyBridge exited with code: " .. exit_code,
        "Press 'r' to restart or close the window.",
      })
      vim.api.nvim_buf_set_option(buf, "modified", false)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
    end,
  })
end

return M
