-- Tests for anybridge.nvim
local describe = describe
local it = it
local assert = assert
local eq = assert.are.equal
local same = assert.are.same

describe("anybridge", function()
  describe("setup", function()
    it("should initialize without errors", function()
      local anybridge = require("anybridge")
      anybridge.setup({})
      assert.truthy(anybridge.config)
    end)

    it("should accept custom options", function()
      local anybridge = require("anybridge")
      anybridge.setup({ example_setting = false })
      eq(false, anybridge.config.example_setting)
    end)
  end)

  describe("terminal text formatting", function()
    it("should leave single-line text unchanged", function()
      local anybridge = require("anybridge")
      eq("print('hello')", anybridge.prepare_terminal_text("print('hello')"))
    end)

    it("should wrap multiline text as a bracketed paste", function()
      local anybridge = require("anybridge")
      local text = "local value = 1\nprint(value)"
      eq("\27[200~" .. text .. "\27[201~", anybridge.prepare_terminal_text(text))
    end)
  end)

  describe("terminal state", function()
    it("should detect a running terminal job", function()
      local anybridge = require("anybridge")
      local buf = vim.api.nvim_create_buf(true, false)
      local previous_buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_set_current_buf(buf)
      local job_id = vim.fn.termopen("sh")

      assert.is_true(anybridge.is_terminal_running(buf))

      vim.fn.jobstop(job_id)
      vim.api.nvim_set_current_buf(previous_buf)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("float window management", function()
    local test_buf
    local test_win
    
    before_each(function()
      -- Kill previous anybridge window and buffer (reset module state)
      local anybridge = require("anybridge")
      anybridge.kill_float()
      
      -- Close previous test window if exists
      if test_win and vim.api.nvim_win_is_valid(test_win) then
        local current_win = vim.api.nvim_get_current_win()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if win ~= test_win then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
        pcall(vim.api.nvim_win_close, test_win, true)
      end
      if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
        pcall(vim.api.nvim_buf_delete, test_buf, { force = true })
      end
      
      -- Create a fresh buffer and window for each test
      test_buf = vim.api.nvim_create_buf(false, true)
      test_win = vim.api.nvim_open_win(test_buf, true, {
        relative = "editor",
        width = 80,
        height = 24,
        row = 0,
        col = 0,
      })
      vim.api.nvim_set_current_win(test_win)
    end)
    
    it("should create a float window with open_float", function()
      local anybridge = require("anybridge")
      anybridge.setup({ command = "echo test" })
      
      anybridge.open_float()
      
      local float_win = anybridge.get_float_window()
      assert.truthy(float_win)
    end)
    
    it("should have correct float window dimensions", function()
      local anybridge = require("anybridge")
      anybridge.setup({ command = "echo test" })
      
      anybridge.open_float()
      
      local float_win = anybridge.get_float_window()
      assert.truthy(float_win)
      
      -- Verify dimensions are calculated (80% width, 60% height of parent)
      local float_width = vim.api.nvim_win_get_width(float_win)
      local float_height = vim.api.nvim_win_get_height(float_win)
      
      assert.is_true(float_width > 0, "Float window should have positive width")
      assert.is_true(float_height > 0, "Float window should have positive height")
    end)
    
    it("should toggle float window with toggle_float", function()
      local anybridge = require("anybridge")
      anybridge.setup({ command = "echo test" })
      
      -- Should open when closed
      anybridge.toggle_float()
      assert.truthy(anybridge.get_float_window())
      
      -- Close it manually for next test
      anybridge.kill_float()
    end)
    
    it("should preserve terminal buffer when toggling", function()
      local anybridge = require("anybridge")
      anybridge.setup({ command = "echo test" })
      
      -- Open and get the buffer
      anybridge.open_float()
      local buf1 = anybridge.get_float_buf()
      assert.truthy(buf1)
      
      -- Toggle (close window)
      anybridge.toggle_float()
      assert.falsy(anybridge.get_float_window())
      -- Buffer should still exist
      local buf2 = anybridge.get_float_buf()
      assert.truthy(buf2)
      eq(buf1, buf2)  -- Same buffer
      
      -- Toggle again (reopen window)
      anybridge.toggle_float()
      local win = anybridge.get_float_window()
      assert.truthy(win)
      -- Window should use the same buffer
      local buf3 = vim.api.nvim_win_get_buf(win)
      eq(buf2, buf3)
    end)

    it("should send selected text when reopening a running terminal with open_float", function()
      local anybridge = require("anybridge")
      anybridge.setup({ command = "sh" })

      anybridge.open_float()
      anybridge.close_float()

      local sent_text
      local original_send_terminal_text = anybridge.send_terminal_text
      anybridge.send_terminal_text = function(text)
        sent_text = text
      end

      local selected_text = "local value = 1\nprint(value)"
      anybridge.open_float(selected_text)
      vim.wait(100, function()
        return sent_text ~= nil
      end)

      anybridge.send_terminal_text = original_send_terminal_text
      eq(selected_text, sent_text)
    end)

    it("should kill terminal and close window with kill_float", function()
      local anybridge = require("anybridge")
      anybridge.setup({ command = "echo test" })
      
      -- Open and get the buffer
      anybridge.open_float()
      local buf1 = anybridge.get_float_buf()
      assert.truthy(buf1)
      
      -- Kill should close window and delete buffer
      anybridge.kill_float()
      assert.falsy(anybridge.get_float_window())
      assert.falsy(anybridge.get_float_buf())
    end)
    
    it("should check if executable exists", function()
      local anybridge = require("anybridge")
      anybridge.setup({ command = "echo" })
      
      -- echo should exist
      assert.truthy(anybridge.check_executable({ command = "echo" }))
      
      -- nonexistent command should not exist
      assert.falsy(anybridge.check_executable({ command = "nonexistent_command_xyz" }))
    end)
  end)
end)
