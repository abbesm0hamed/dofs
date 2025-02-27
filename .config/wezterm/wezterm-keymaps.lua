-- Actions: https://wezfurlong.org/wezterm/config/lua/keyassignment/index.html#available-key-assignments
-- Key-Names: https://wezfurlong.org/wezterm/config/keys.html#configuring-key-assignments

local wt = require("wezterm")
local act = wt.action
local actFun = wt.action_callback
local theme = require("themes.theme-utils")

--------------------------------------------------------------------------------

local M = {}

M.keys = {
  { key = "q", mods = "ALT", action = act.QuitApplication },
  { key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "c", mods = "ALT", action = act.CopyTo("ClipboardAndPrimarySelection") },
  { key = "h", mods = "ALT", action = act.HideApplication }, -- only macOS
  { key = "+", mods = "ALT", action = act.IncreaseFontSize },
  { key = "-", mods = "ALT", action = act.DecreaseFontSize },
  { key = "0", mods = "ALT", action = act.ResetFontSize },
  { key = "p", mods = "ALT", action = act.ActivateCommandPalette },
  { key = "ö", mods = "ALT", action = act.CharSelect },
  { key = "v", mods = "ALT", action = act.PasteFrom("Clipboard") },

  -- using `ctrl-L` instead of wezterm's scrollback-clearing preserves the
  -- ability to scroll back
  { key = "k", mods = "ALT", action = act.SendKey { key = "l", mods = "CTRL" } },

  -- closes panes, then tabs, then windows
  { key = "w", mods = "ALT", action = act.CloseCurrentPane { confirm = false } },

  { -- cycles panes, then tabs, then windows
    key = "Enter",
    mods = "CTRL",
    action = wt.action_callback(function(win, pane)
      local paneCount = #pane:tab():panes()
      local tabCount = #win:mux_window():tabs()
      if paneCount > 1 then
        win:perform_action(act.ActivatePaneDirection("Next"), pane)
      elseif tabCount > 1 then
        win:perform_action(act.ActivateTabRelative(1), pane)
      else
        win:perform_action(act.ActivateTabRelative(1), pane)
      end
    end),
  },
  -- HACK close next pane/tab (CAVEAT: due to race condition, impossible to close all others)
  {
    key = "w",
    mods = "ALT|SHIFT",
    action = wt.action_callback(function(win, pane)
      local paneCount = #pane:tab():panes()
      local tabCount = #win:mux_window():tabs()
      if paneCount > 1 then
        win:perform_action(act.ActivatePaneDirection("Next"), pane)
        win:perform_action(act.CloseCurrentPane { confirm = false }, pane)
      end
      if tabCount > 1 then
        win:perform_action(act.ActivateTabRelative(1), pane)
        win:perform_action(act.CloseCurrentPane { confirm = false }, pane)
      end
    end),
  },
  {
    key = "PageUp",
    action = wt.action_callback(function(win, pane)
      -- if TUI (such as fullscreen fzf), send key to TUI,
      -- otherwise scroll by page https://github.com/wez/wezterm/discussions/4101
      if pane:is_alt_screen_active() then
        win:perform_action(act.SendKey { key = "PageUp" }, pane)
      else
        win:perform_action(act.ScrollByPage(-0.8), pane)
      end
    end),
  },
  {
    key = "PageDown",
    action = wt.action_callback(function(win, pane)
      if pane:is_alt_screen_active() then
        win:perform_action(act.SendKey { key = "PageDown" }, pane)
      else
        win:perform_action(act.ScrollByPage(0.8), pane)
      end
    end),
  },

  -- INFO using the mapping from the terminal_keybindings.zsh
  -- undo (ctrl-z set in terminal keybindings)
  { key = "z",     mods = "ALT", action = act.SendKey { key = "z", mods = "CTRL" } },
  { -- for adding inline code to a commit, hotkey consistent with GitHub
    key = "e",
    mods = "ALT",
    action = act.Multiple {
      act.SendString([[\`\`]]),
      act.SendKey { key = "LeftArrow" },
      act.SendKey { key = "LeftArrow" },
    },
  },
  -- Grappling-hook
  { key = "Enter", mods = "ALT", action = act.SendKey { key = "o", mods = "CTRL" } },

  { -- insert line-break https://unix.stackexchange.com/a/80820
    key = "Enter",
    mods = "SHIFT",
    action = act.Multiple {
      act.SendKey { key = "v", mods = "CTRL" },
      act.SendKey { key = "j", mods = "CTRL" },
    },
  },

  -- scroll-to-prompt, requires shell integration: https://wezfurlong.org/wezterm/config/lua/keyassignment/ScrollToPrompt.html
  { key = "k",          mods = "CTRL", action = act.ScrollToPrompt(-1) },
  { key = "j",          mods = "CTRL", action = act.ScrollToPrompt(1) },

  -- FIX works with `send_composed_key_when_right_alt_is_pressed = true`
  -- but expects another character, so this mapping fixes it
  { key = "n",          mods = "ALT",  action = act.SendString("~") },

  -- Emulates macOS' ALT-right & ALT-left
  { key = "LeftArrow",  mods = "ALT",  action = act.SendKey { key = "A", mods = "CTRL" } },
  { key = "RightArrow", mods = "ALT",  action = act.SendKey { key = "E", mods = "CTRL" } },

  key = "l",
  { -- ALT+l -> open current location in Finder
    mods = "ALT",
    action = actFun(function(_, pane)
      local cwd = pane:get_current_working_dir().file_path
      wt.open_with(cwd, "Finder")
    end),
  },
  -- Theme Cycler
  { key = "t",      mods = "ALT",  action = actFun(theme.cycle) },

  -----------------------------------------------------------------------------

  -- MODES
  -- Search
  { key = "f",      mods = "ALT",  action = act.Search("CurrentSelectionOrEmptyString") },

  -- Console / REPL
  { key = "Escape", mods = "CTRL", action = wt.action.ShowDebugOverlay },

  -- Copy Mode (= Caret Mode) -- https://wezfurlong.org/wezterm/copymode.html
  { key = "y",      mods = "ALT",  action = act.ActivateCopyMode },

  -- Quick Select (= Hint Mode) -- https://wezfurlong.org/wezterm/quickselect.html
  { key = "u",      mods = "ALT",  action = act.QuickSelect },

  { -- ALT+o -> copy [o]ption (e.g. from a man page)
    key = "o",
    mods = "ALT",
    action = act.QuickSelectArgs {
      patterns = { "--[\\w=-]+", "-\\w" }, -- long option, short option
      label = "Copy Shell Option",
    },
  },
  { -- ALT+, -> open the config file
    key = ",",
    mods = "ALT",
    action = actFun(function() wt.open_with(wt.config_file) end),
  },
  { -- ALT+shift+, -> open the keybindings file (this file)
    key = ";",
    mods = "ALT|SHIFT",
    action = actFun(function()
      local thisFile = wt.config_file:gsub("wezterm%.lua$", "wezterm-keymaps.lua")
      wt.open_with(thisFile)
    end),
  },
}

--------------------------------------------------------------------------------
-- COPYMODE
-- DOCS https://wezfurlong.org/wezterm/config/lua/wezterm.gui/default_key_tables.html
M.copymodeKeys = wt.gui.default_key_tables().copy_mode

-- HJKL like hjkl, but bigger distance
local myCopyModeKeys = {
  { key = "l", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
  { key = "h", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
  { key = "j", mods = "SHIFT", action = act.CopyMode { MoveByPage = 0.33 } },
  { key = "k", mods = "SHIFT", action = act.CopyMode { MoveByPage = -0.33 } },
}

for _, key in ipairs(myCopyModeKeys) do
  table.insert(M.copymodeKeys, key)
end

--------------------------------------------------------------------------------
return M
