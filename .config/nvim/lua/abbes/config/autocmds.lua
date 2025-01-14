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

-- Auto-reload files when changed externally
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = augroup("checktime"),
  command = "if !bufexists('[Command Line]') | checktime | endif",
  desc = "Check if any buffers were changed outside of Vim",
})

-- Trigger `checktime` when changing buffers or after writing
vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave" }, {
  group = augroup("refresh_file"),
  command = "checktime",
  desc = "Refresh file content after writing or leaving buffer",
})
