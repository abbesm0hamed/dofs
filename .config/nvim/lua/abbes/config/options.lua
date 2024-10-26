local opt = vim.opt -- for conciseness

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true         -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 2       -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2    -- 2 spaces for indent width
opt.expandtab = true  -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- line wrapping
opt.wrap = false -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true  -- if you include mixed case in your search, assumes you want case-sensitive

-- cursor line
opt.cursorline = true -- highlight the current cursor line
opt.guicursor = 'n-v-c-sm:block,i-ci-ve:blinkon1'

-- appearance

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
-- opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false


-- status line config
opt.laststatus = 2   -- Always show statusline
opt.showmode = false -- Don't show mode in command line
-- Function to get relative file path
local function relative_path()
  local full_path = vim.fn.expand('%:p')
  local cwd = vim.fn.getcwd()
  local rel_path = vim.fn.fnamemodify(full_path, ':~:.')
  if rel_path == '' then
    return '[No Name]'
  end
  return rel_path
end
-- Set custom statusline
opt.statusline = table.concat({
  " %{%v:lua.require'nvim-web-devicons'.get_icon(expand('%:t'))%} ", -- File icon (if you have nvim-web-devicons)
  "%{%v:lua.relative_path()%}",                                      -- Relative path
  "%m",                                                              -- Modified flag
  "%r",                                                              -- Readonly flag
  "%h",                                                              -- Help file flag
  "%=",                                                              -- Right align
  "%y",                                                              -- File type
  " %{&fileencoding?&fileencoding:&encoding}",                       -- File encoding
  " [%{&fileformat}]",                                               -- File format
  " %p%%",                                                           -- Percentage through file
  " %l:%c ",                                                         -- Line and column
})
-- Make the relative_path function available to statusline
_G.relative_path = relative_path
