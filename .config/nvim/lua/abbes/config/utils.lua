local M = {}
--------------------------------------------------------------------------------

---runs :normal with bang
---@param cmdStr string
function M.normal(cmdStr)
  vim.cmd.normal({ cmdStr, bang = true })
end

---@param msg string
---@param title string
---@param level? "info"|"trace"|"debug"|"warn"|"error"
function M.notify(msg, title, level)
  if not level then
    level = "info"
  end
  vim.notify(msg, vim.log.levels[level:upper()], { title = title })
end

function M.ftAbbr(lhs, rhs)
  -- TODO update on nvim 0.10
  -- vim.keymap.set("ia", lhs, rhs, { buffer = true })
  vim.cmd.inoreabbrev(("<buffer> %s %s"):format(lhs, rhs))
end

---https://www.reddit.com/r/neovim/comments/oxddk9/comment/h7maerh/
---@param name string name of highlight group
---@param key "fg"|"bg"
---@nodiscard
---@return string|nil the value, or nil if hlgroup or key is not available
function M.getHighlightValue(name, key)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
  if not ok or not hl then
    return nil
  end

  local value = hl[key]
  if not value then
    return nil
  end
  return ("#%06x"):format(value)
end

--------------------------------------------------------------------------------

---Creates autocommand triggered by Colorscheme change, that modifies a
---highlight group. Mostly useful for setting up colorscheme modifications
---specific to plugins, that should persist across colorscheme changes triggered
---by switching between dark and light mode.
---@param hlgroup string
---@param modification table
function M.colorschemeMod(hlgroup, modification)
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      vim.api.nvim_set_hl(0, hlgroup, modification)
    end,
  })
end

---@alias vimMode "n"|"v"|"x"|"i"|"o"|"c"|"t"

-- Cache for which-key to avoid repeated checks
local whichkey_available = nil
local pending_subkeys = {}

---set up subkey for the <leader> key (if whichkey is loaded)
---@param key string
---@param label string
---@param modes? vimMode|vimMode[]
function M.leaderSubkey(key, label, modes)
  -- Cache the which-key availability check
  if whichkey_available == nil then
    local ok, _ = pcall(require, "which-key")
    whichkey_available = ok
  end

  if not whichkey_available then
    return
  end

  -- Store subkey registration for batch processing
  table.insert(pending_subkeys, { key = key, label = label, modes = modes })

  -- Use a shorter, more reasonable delay and batch process
  vim.defer_fn(function()
    if #pending_subkeys == 0 then
      return
    end

    local ok, whichkey = pcall(require, "which-key")
    if not ok then
      return
    end

    -- Batch register all pending subkeys
    local registrations = {}
    for _, subkey in ipairs(pending_subkeys) do
      registrations[subkey.key] = { name = " " .. subkey.label }
    end

    -- Single registration call for all subkeys
    whichkey.register(registrations, { prefix = "<leader>", mode = modes or "n" })

    -- Clear pending subkeys
    pending_subkeys = {}
  end, 100) -- Much shorter delay - 100ms instead of 2000ms
end

-- Cache for lualine to avoid repeated setup calls
local lualine_components = {}
local lualine_setup_pending = false

---Adds a component to the lualine after lualine was already set up. Useful for
---lazyloading. This version batches updates to avoid multiple setup calls.
---@param bar "tabline"|"winbar"|"inactive_winbar"|"sections"
---@param section "lualine_a"|"lualine_b"|"lualine_c"|"lualine_x"|"lualine_y"|"lualine_z"
---@param component function|table the component forming the lualine
---@param whereInComponent? "before"|"after"
function M.addToLuaLine(bar, section, component, whereInComponent)
  local ok, lualine = pcall(require, "lualine")
  if not ok then
    return
  end

  -- Initialize section if it doesn't exist
  if not lualine_components[bar] then
    lualine_components[bar] = {}
  end
  if not lualine_components[bar][section] then
    lualine_components[bar][section] = lualine.get_config()[bar][section] or {}
  end

  local componentObj = type(component) == "table" and component or { component }

  if whereInComponent == "before" then
    table.insert(lualine_components[bar][section], 1, componentObj)
  else
    table.insert(lualine_components[bar][section], componentObj)
  end

  -- Batch the lualine setup to avoid multiple calls
  if not lualine_setup_pending then
    lualine_setup_pending = true
    vim.defer_fn(function()
      -- Apply all accumulated changes at once
      local config_update = {}
      for bar_name, sections in pairs(lualine_components) do
        config_update[bar_name] = sections
      end

      lualine.setup(config_update)
      lualine_setup_pending = false

      -- Theming needs to be re-applied, since the lualine-styling can change
      -- require("abbes.config.theme-customization").reloadTheming()
    end, 50) -- Short delay to batch multiple calls
  end
end

---ensures unique keymaps https://www.reddit.com/r/neovim/comments/16h2lla/can_you_make_neovim_warn_you_if_your_config_maps/
---@param modes vimMode|vimMode[]
---@param lhs string
---@param rhs string|function
---@param opts? { unique: boolean, desc: string, buffer: boolean|number, nowait: boolean, remap: boolean }
function M.uniqueKeymap(modes, lhs, rhs, opts)
  opts = opts or {}
  if opts.unique == nil then
    opts.unique = true
  end

  -- Add error handling for keymap conflicts
  local ok, err = pcall(vim.keymap.set, modes, lhs, rhs, opts)
  if not ok and opts.unique then
    vim.notify(
      string.format("Keymap conflict for '%s': %s", lhs, err),
      vim.log.levels.WARN,
      { title = "Keymap Warning" }
    )
  end
end

-- Performance: Make this a constant instead of recreating the table
M.textobjRemaps = {
  c = "}", -- [c]urly brace
  r = "]", -- [r]ectangular bracket
  m = "W", -- [m]assive word
  q = '"', -- [q]uote
  z = "'", -- [z]ingle quote
  e = "`", -- t[e]mplate string / inline cod[e]
}

-- Additional utility functions for better performance

---Debounced function executor to avoid rapid successive calls
---@param fn function
---@param delay number
---@return function
function M.debounce(fn, delay)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
    end
    timer = vim.defer_fn(function()
      fn(unpack(args))
    end, delay)
  end
end

---Safe require with error handling
---@param module string
---@return boolean, any
function M.safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify(
      string.format("Failed to load module '%s': %s", module, result),
      vim.log.levels.ERROR,
      { title = "Module Load Error" }
    )
    return false, nil
  end
  return true, result
end

---Check if a plugin is available
---@param plugin string
---@return boolean
function M.has_plugin(plugin)
  return pcall(require, plugin)
end

--------------------------------------------------------------------------------
return M
