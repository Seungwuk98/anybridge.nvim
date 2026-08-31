-- Test setup for anybridge.nvim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if vim.fn.isdirectory(lazypath) == 0 then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end

vim.opt.runtimepath:prepend(lazypath)

-- Load lazy with plenary
require("lazy").setup({
  spec = {
    { "nvim-lua/plenary.nvim" },
  },
  root = vim.fn.stdpath("data") .. "/lazy",
})

-- Add current project to runtimepath
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Load our plugin
require("anybridge").setup({})

-- Find and run all test files
local test_dir = "tests/spec"
local handle = vim.loop.fs_scandir(test_dir)
if handle then
  while true do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then break end
    
    if t == "file" and name:match("_spec%.lua$") then
      local file_path = test_dir .. "/" .. name
      require("plenary.busted").run(file_path)
    end
  end
end
