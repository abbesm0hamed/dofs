local opt = vim.opt -- for conciseness

-- status line config
opt.laststatus = 2 -- Always show statusline
opt.showmode = false -- Don't show mode in command line

-- Set up highlight group for mode text
vim.cmd([[
  highlight StatusLineMode guifg=#87af87
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

-- Function to get current mode with custom names
local function get_mode()
  local mode_map = {
    ["n"] = "NORMAL",
    ["no"] = "PENDING",
    ["v"] = "VISUAL",
    ["V"] = "V-LINE",
    ["\22"] = "V-BLOCK", -- Ctrl-V
    ["s"] = "SELECT",
    ["S"] = "S-LINE",
    ["\19"] = "S-BLOCK", -- Ctrl-S
    ["i"] = "INSERT",
    ["ic"] = "INSERT",
    ["R"] = "REPLACE",
    ["Rv"] = "V-REPLACE",
    ["c"] = "COMMAND",
    ["cv"] = "VIM EX",
    ["ce"] = "EX",
    ["r"] = "PROMPT",
    ["rm"] = "MOREPROMPT",
    ["r?"] = "CONFIRM",
    ["!"] = "SHELL",
    ["t"] = "TERMINAL",
  }
  local current_mode = vim.api.nvim_get_mode().mode
  return mode_map[current_mode] or current_mode
end

-- Set custom statusline
opt.statusline = table.concat({
  "%#StatusLineMode#", -- Start mode color
  " %{%v:lua.get_mode()%} ", -- Current mode
  "%#StatusLine#", -- Reset color to default
  -- "%{%v:lua.require'nvim-web-devicons'.get_icon(expand('%:t'))%} ", -- File icon
  "%{%v:lua.relative_path()%}", -- Relative path
  "%m", -- Modified flag
  "%r", -- Readonly flag
  "%h", -- Help file flag
  "%=", -- Right align
  "%y", -- File type
  " %p%%", -- Percentage through file
  " %l:%c ", -- Line and column
})

-- Make the functions available to statusline
_G.relative_path = relative_path
_G.get_mode = get_mode
