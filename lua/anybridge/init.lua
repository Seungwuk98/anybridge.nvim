-- anybridge.nvim main entry point
local M = {}

local options = require("anybridge.options")

-- Module state: store float window ID and buffer
local float_win = nil
local float_buf = nil

function M.setup(opts)
  local config = options.get(opts)
  
  -- Create commands
  vim.api.nvim_create_user_command("ABOpen", function(opts)
    local selected_text = nil
    if opts.range > 0 then
      -- Line range selected
      local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
      selected_text = table.concat(lines, "\n")
    elseif vim.fn.mode() == "v" or vim.fn.mode() == "V" or vim.fn.mode() == "" then
      -- Visual mode selected
      selected_text = vim.fn.getreg(0)
    end
    M.open_float(selected_text)
  end, { nargs = 0, range = '%' })
  
  vim.api.nvim_create_user_command("ABToggle", function(opts)
    local selected_text = nil
    if opts.range > 0 then
      -- Line range selected
      local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
      selected_text = table.concat(lines, "\n")
    elseif vim.fn.mode() == "v" or vim.fn.mode() == "V" or vim.fn.mode() == "" then
      -- Visual mode selected
      selected_text = vim.fn.getreg(0)
    end
    M.toggle_float(selected_text)
  end, { nargs = 0, range = '%' })
  
  vim.api.nvim_create_user_command("ABClose", function()
    M.close_float()
  end, { nargs = 0 })
  
  vim.api.nvim_create_user_command("ABKill", function()
    M.kill_float()
  end, { nargs = 0 })
  
  -- Set up keymaps (normal and visual modes)
  if config.keymaps then
    if config.keymaps.toggle then
      vim.keymap.set("n", config.keymaps.toggle, "<cmd>ABToggle<cr>", { desc = "Toggle AnyBridge" })
      vim.keymap.set("v", config.keymaps.toggle, "<cmd>ABToggle<cr>", { desc = "Toggle AnyBridge" })
    end
    if config.keymaps.open then
      vim.keymap.set("n", config.keymaps.open, "<cmd>ABOpen<cr>", { desc = "Open AnyBridge" })
      vim.keymap.set("v", config.keymaps.open, "<cmd>ABOpen<cr>", { desc = "Open AnyBridge" })
    end
    if config.keymaps.close then
      vim.keymap.set("n", config.keymaps.close, "<cmd>ABClose<cr>", { desc = "Close AnyBridge" })
    end
    if config.keymaps.kill then
      vim.keymap.set("n", config.keymaps.kill, "<cmd>ABKill<cr>", { desc = "Kill AnyBridge" })
    end
  end
  
  -- Store config
  M.config = config
end

--- Get the float window if it exists and is valid
function M.get_float_window()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    return float_win
  end
  float_win = nil
  return nil
end

--- Get the float buffer if it exists and is valid
function M.get_float_buf()
  if float_buf and vim.api.nvim_buf_is_valid(float_buf) then
    return float_buf
  end
  return nil
end

function M.close_float()
  local win = M.get_float_window()
  if win then
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
    -- Clear window state but keep buffer (terminal keeps running)
    float_win = nil
  end
end

--- Kill the terminal and close the window
function M.kill_float()
  local win = M.get_float_window()
  local buf = M.get_float_buf()
  
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
  
  -- Kill the terminal job if it exists
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local job_id = vim.fn.getbufvar(buf, "job_id")
    if job_id and job_id ~= 0 then
      pcall(vim.fn.jobstop, job_id)
    end
    -- Delete the buffer
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
  
  -- Clear all state
  float_win = nil
  float_buf = nil
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
  M.kill_float()
  M.open_float()
end

function M.toggle_float(selected_text)
  local win = M.get_float_window()
  
  if win and vim.api.nvim_win_is_valid(win) then
    -- Window exists, close it (terminal keeps running)
    M.close_float()
  else
    -- No window, check if we have an existing buffer
    local buf = M.get_float_buf()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      -- Check if terminal is running
      if M.is_terminal_running(buf) then
        -- Terminal is running
        if selected_text and selected_text ~= "" then
          -- Send text to existing terminal
          vim.schedule(function()
            local chan_id = buf
            if chan_id and chan_id > 0 then
              vim.api.nvim_chan_send(chan_id, selected_text)
            end
          end)
        end
      end
      -- Open window with existing buffer (regardless of terminal state)
      M.open_float_with_buffer(buf)
    else
      -- No existing buffer, create new one
      M.open_float()
    end
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

--- Helper function to create window with existing buffer
function M.open_float_with_buffer(buf)
  local config = M.config or options.get({})
  
  -- Get editor dimensions (not current window)
  local win_width = vim.api.nvim_get_option("columns")
  local win_height = vim.api.nvim_get_option("lines")
  
  -- Calculate float window dimensions using config
  local width = math.floor(win_width * config.width_pct)
  local height = math.floor(win_height * config.height_pct)
  
  -- Calculate centered position
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)
  
  -- Create floating window with existing buffer (relative to editor)
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = config.style,
    border = config.border,
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Store window ID in module state (buffer already exists)
  float_win = win
end

function M.open_float(selected_text)
  local config = M.config or options.get({})
  
  -- Check if window is already open
  local existing_win = M.get_float_window()
  if existing_win and vim.api.nvim_win_is_valid(existing_win) then
    -- Window exists, switch to it
    vim.api.nvim_set_current_win(existing_win)
    
    -- Check if terminal is running
    local existing_buf = M.get_float_buf()
    if existing_buf and vim.api.nvim_buf_is_valid(existing_buf) and M.is_terminal_running(existing_buf) then
      -- Terminal is running
      if selected_text and selected_text ~= "" then
        -- Send text to existing terminal
        vim.schedule(function()
          local chan_id = existing_buf
          if chan_id and chan_id > 0 then
            vim.api.nvim_chan_send(chan_id, selected_text)
          end
        end)
      end
      -- Do nothing more
      return
    end
  end
  
  -- Check if we have an existing buffer (terminal may have exited)
  local existing_buf = M.get_float_buf()
  if existing_buf and vim.api.nvim_buf_is_valid(existing_buf) then
    -- Terminal exited, open window with existing buffer
    M.open_float_with_buffer(existing_buf)
    return
  end
  
  -- Check if executable exists
  if not M.check_executable(config) then
    M.show_install_prompt(config)
    return
  end
  
  -- Get editor dimensions (not current window)
  local win_width = vim.api.nvim_get_option("columns")
  local win_height = vim.api.nvim_get_option("lines")
  
  -- Calculate float window dimensions using config
  local width = math.floor(win_width * config.width_pct)
  local height = math.floor(win_height * config.height_pct)
  
  -- Calculate centered position
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)
  
  -- Create terminal buffer
  local buf = vim.api.nvim_create_buf(true, false)  -- terminal buffer
  
  -- Create floating window with terminal buffer (relative to editor)
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = config.style,
    border = config.border,
  }
  
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  
  -- Store window/buffer IDs in module state
  float_win = win
  float_buf = buf
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "filetype", "anybridge")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  
  -- Start terminal with anybridge command (ignore selected_text for new terminal)
  local cmd = config.command
  
  -- Helper function to safely update buffer on exit
  local function on_exit(job_id, exit_code)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    pcall(function()
      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
        "",
        "AnyBridge exited with code: " .. exit_code,
        "Press 'r' to restart or close the window.",
      })
      vim.api.nvim_buf_set_option(buf, "modified", false)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
    end)
  end
  
  vim.fn.termopen(cmd, { on_exit = on_exit })
end

return M
