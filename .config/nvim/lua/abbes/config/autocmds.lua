-- This file is automatically loaded by lazyvim.config.init.

-- Helper function to create autogroups
local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Mason tool installer event handlers
vim.api.nvim_create_autocmd("User", {
  pattern = "MasonToolsStartingInstall",
  callback = function()
    vim.schedule(function()
      print("mason-tool-installer is starting")
    end)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MasonToolsUpdateCompleted",
  callback = function(e)
    vim.schedule(function()
      print(vim.inspect(e.data)) -- print the table that lists the programs that were installed
    end)
  end,
})

-- Disable folding for specific file types
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yml", "yaml", "neo-tree" },
  callback = function()
    local ufo = require("ufo")
    if ufo then
      ufo.detach()
    end
    vim.opt_local.foldenable = false
  end
})

-- Disable folding for .env files
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*.env",
  callback = function()
    local ufo = require("ufo")
    if ufo then
      ufo.detach()
    end
    vim.opt_local.foldenable = false
  end
})
