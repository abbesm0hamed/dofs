-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

-- This file is automatically loaded by lazyvim.config.init.

-- Helper function to create autogroups
local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 }) -- Set a shorter timeout
  end,
})

-- Mason tool installer event handlers
local mason_group = augroup("mason_handlers")
vim.api.nvim_create_autocmd("User", {
  group = mason_group,
  pattern = "MasonToolsStartingInstall",
  callback = function()
    vim.schedule(function()
      print("mason-tool-installer is starting")
    end)
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = mason_group,
  pattern = "MasonToolsUpdateCompleted",
  callback = function(e)
    vim.schedule(function()
      -- Only print essential info to reduce output
      local installed = e.data and e.data.installed or {}
      print("Mason tools installation completed. Installed: " .. #installed .. " tools")
    end)
  end,
})

-- File change detection
local checktime_group = augroup("checktime")

-- Optimize file change detection events
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = checktime_group,
  callback = function()
    if vim.bo.buftype ~= "" then
      return -- Skip special buffers
    end
    vim.cmd("checktime")
  end,
  desc = "Check if buffers were changed externally",
})

-- Use a debounced version for CursorHold events
local cursorhold_group = augroup("cursorhold")
local cursorhold_timer = nil
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = cursorhold_group,
  callback = function()
    if cursorhold_timer then
      vim.fn.timer_stop(cursorhold_timer)
      cursorhold_timer = nil
    end
    cursorhold_timer = vim.fn.timer_start(1000, function()
      if vim.bo.buftype ~= "" then
        return -- Skip special buffers
      end
      vim.cmd("checktime")
    end)
  end,
  desc = "Debounced check for external file changes",
})
