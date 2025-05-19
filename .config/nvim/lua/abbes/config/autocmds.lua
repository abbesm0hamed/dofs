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
    if not vim.bo.buftype == "" then
      return -- Skip special buffers
    end
    vim.cmd("checktime")
  end,
  desc = "Check if buffers were changed externally",
})

-- Use a debounced version for CursorHold events
local cursorhold_timer
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = checktime_group,
  callback = function()
    if cursorhold_timer then
      vim.fn.timer_stop(cursorhold_timer)
    end
    cursorhold_timer = vim.fn.timer_start(1000, function()
      if not vim.bo.buftype == "" then
        return -- Skip special buffers
      end
      vim.cmd("checktime")
    end)
  end,
  desc = "Debounced check for external file changes",
})

-- Optimize buffer refresh
vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave" }, {
  group = augroup("refresh_file"),
  callback = function()
    if not vim.bo.buftype == "" then
      return -- Skip special buffers
    end
    vim.cmd("checktime")
  end,
  desc = "Refresh file content after writing or leaving buffer",
})

-- git-conflict plugin autocmd
-- When a conflict is detected by this plugin a User autocommand is fired called GitConflictDetected.
-- When this is resolved another command is fired called GitConflictResolved.
vim.api.nvim_create_autocmd("User", {
  pattern = "GitConflictDetected",
  callback = function()
    vim.notify("Conflict detected in " .. vim.fn.expand("<afile>"))
    vim.keymap.set("n", "cww", function()
      engage.conflict_buster()
      create_buffer_local_mappings()
    end)
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    require("conform").format({
      bufnr = args.buf,
      async = false,
      lsp_fallback = true,
    })
  end,
})
