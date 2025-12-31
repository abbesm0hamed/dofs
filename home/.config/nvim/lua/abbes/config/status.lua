local opt = vim.opt -- for conciseness

-- status line config
opt.laststatus = 2 -- Always show statusline
opt.showmode = false -- Don't show mode in command line

-- Set up highlight groups for status line
vim.cmd([[
  highlight StatusLineMode_Normal guibg=#7E9CD8 guifg=#232324
  highlight StatusLineMode_Insert guibg=#a8e6cf guifg=#232324
  highlight StatusLineMode_Visual guibg=#ffd3b6 guifg=#232324
  highlight StatusLineMode_Command guibg=#D27E99 guifg=#232324
  highlight StatusLineMode_Replace guibg=#ffb37e guifg=#232324
  highlight StatusLinePath guibg=#363646 guifg=#ffffff
  highlight StatusLineInfo guibg=#2A2A37 guifg=#ffffff
]])

-- Function to get relative file path
local function relative_path()
  local full_path = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()
  local rel_path = vim.fn.fnamemodify(full_path, ":~:.")
  if rel_path == "" then
    return "[No Name]"
  end
  return rel_path
end

-- Mode highlight group mapping
local mode_hl_map = {
  ["n"] = "StatusLineMode_Normal",
  ["i"] = "StatusLineMode_Insert",
  ["v"] = "StatusLineMode_Visual",
  ["V"] = "StatusLineMode_Visual",
  ["\22"] = "StatusLineMode_Visual",
  ["c"] = "StatusLineMode_Command",
  ["R"] = "StatusLineMode_Replace",
}

-- Function to get current mode with highlight group
local function get_mode()
  local mode_map = {
    ["n"] = "N",
    ["no"] = "P",
    ["v"] = "V",
    ["V"] = "V-L",
    ["\22"] = "V-B", -- Ctrl-V
    ["s"] = "SE",
    ["S"] = "S-L",
    ["\19"] = "S-B", -- Ctrl-S
    ["i"] = "I",
    ["ic"] = "IN",
    ["R"] = "R",
    ["Rv"] = "V-R",
    ["c"] = "C",
    ["cv"] = "VE",
    ["ce"] = "EX",
    ["r"] = "P",
    ["rm"] = "MO",
    ["r?"] = "CM",
    ["!"] = "SHL",
    ["t"] = "T",
  }
  local current_mode = vim.api.nvim_get_mode().mode
  return mode_map[current_mode] or current_mode
end

-- Set custom statusline
opt.statusline = table.concat({
  "%{%v:lua.get_mode_hl()%}", -- Mode highlight group
  " %{%v:lua.get_mode()%} ", -- Current mode
  "%#StatusLinePath#", -- Path section color
  " %{%v:lua.relative_path()%}", -- Relative path
  "%m", -- Modified flag
  "%r", -- Readonly flag
  "%h", -- Help file flag
  "%#StatusLineInfo#", -- Info section color
  "%=", -- Right align
  "%y", -- File type
  " %p%%", -- Percentage through file
  " %l:%c ", -- Line and column
})

-- Function to get current mode highlight group
local function get_mode_hl()
  local mode = vim.api.nvim_get_mode().mode
  return "%#" .. (mode_hl_map[mode] or "StatusLineMode_Normal") .. "#"
end

-- Make the functions available to statusline
_G.relative_path = relative_path
_G.get_mode = get_mode
_G.get_mode_hl = get_mode_hl
