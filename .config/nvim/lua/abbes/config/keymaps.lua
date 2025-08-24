-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps -------------------

-- delete single character without copying into register
-- keymap.set("n", "x", '"_x')
--
keymap.set("i", ";;", "<Esc>")

-- Mason
keymap.set("n", "<leader>mn", "<cmd>Mason<CR>", { desc = " Mason" })

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- layout - Fixed typo
keymap.set("n", "<A-z>", ":lua vim.wo.wrap = not vim.wo.wrap<CR>", { desc = "Wrap text" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- window management
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>dw", "<cmd>close<CR>", { desc = "Close current split" })
keymap.set("n", "<C-Up>", ":resize +4<CR>", { desc = "Increase window height" })
keymap.set("n", "<C-Down>", ":resize -4<CR>", { desc = "Decrease window height" })
keymap.set("n", "<C-Right>", ":vertical resize +4<CR>", { desc = "Increase window width" })
keymap.set("n", "<C-Left>", ":vertical resize -4<CR>", { desc = "Decrease window width" })
keymap.set("n", "<C-k>", "<C-W>k", { desc = "Jump to Previous Horizontal Tab", remap = true })
keymap.set("n", "<C-j>", "<C-W>j", { desc = "Jump to Next Horizontal Tab", remap = true })

-- tab management (consolidated and optimized)
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

-- buffers
keymap.set("n", "[b", "<cmd>bprev<CR>", { desc = "Jump to previous buffer", silent = true })
keymap.set("n", "]b", "<cmd>bnext<CR>", { desc = "Jump to next buffer", silent = true })

-- save file (optimized - no unnecessary escape)
keymap.set("n", "<C-s>", "<cmd>w<cr>", { desc = "Save File" })
keymap.set("i", "<C-s>", "<cmd>w<cr>", { desc = "Save File" })
keymap.set("x", "<C-s>", "<cmd>w<cr>", { desc = "Save File" })
keymap.set("s", "<C-s>", "<cmd>w<cr>", { desc = "Save File" })

-- select and copy from file
keymap.set("n", "<leader>vv", "ggVG", { desc = "Select All" })
keymap.set("n", "<leader>ca", 'ggVG"+y', { desc = "Copy All to Clipboard" })

-- Move Lines
keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Clear search ONLY in normal mode (performance optimized)
keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear hlsearch" })

-- Alternative clear search mapping that doesn't interfere with insert mode
keymap.set("n", "<leader>/", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Clear search, diff update and redraw
keymap.set(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- keywordprg
keymap.set("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
keymap.set("v", "<", "<gv")
keymap.set("v", ">", ">gv")

-- lazy
keymap.set("n", "<leader>la", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- new file
keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- lists
keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
keymap.set("n", "<leader>fl", "<cmd>copen<cr>", { desc = "Quickfix list" })

-- quickfix navigation
keymap.set("n", "[q", "<cmd>cprev<cr>", { desc = "Previous Quickfix" })
keymap.set("n", "]q", "<cmd>cnext<cr>", { desc = "Next Quickfix" })

-- quit
keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- highlights under cursor
keymap.set("n", "<leader>ui", vim.show_pos, { desc = "Inspect pos" })

-- Terminal mappings (optimized for smooth operation)
-- Use Alt c in terminal mode for consistency
keymap.set("t", "<A-c>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })

-- Window navigation from terminal
keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

-- Terminal close (using Ctrl+q for less conflict)
keymap.set("t", "<C-q>", "<cmd>close<cr>", { desc = "Close Terminal" })

-- windows (consistent leader-based approach)
keymap.set("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
keymap.set("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
keymap.set("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Quick splits (no leader for speed)
keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })

-- Macro recording (direct mapping for performance)
keymap.set("n", "Q", "q", { desc = "Record Macro" })

-- augment code ai
keymap.set("i", "<A-y>", "<cmd>call augment#Accept()<cr>", { silent = true })

-- keymap.set("n", "<leader>tf", function()
--   vim.g.format_on_save = not vim.g.format_on_save
--   local status = vim.g.format_on_save and "enabled" or "disabled"
--   vim.notify("Format on save " .. status, vim.log.levels.INFO)
-- end, { desc = "Toggle Format on Save" })
--
-- Format on save toggle
-- if vim.g.format_on_save == nil then
--   vim.g.format_on_save = true
-- end

-- Additional performance-oriented mappings

-- Fast file operations
keymap.set("n", "<leader>fw", "<cmd>w<cr>", { desc = "Save File" })
keymap.set("n", "<leader>fq", "<cmd>wq<cr>", { desc = "Save and Quit" })

-- Quick yank to system clipboard
keymap.set("n", "<leader>y", '"+y', { desc = "Yank to Clipboard" })
keymap.set("v", "<leader>y", '"+y', { desc = "Yank to Clipboard" })
keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank Line to Clipboard" })

-- Quick paste from system clipboard
keymap.set("n", "<leader>p", '"+p', { desc = "Paste from Clipboard" })
keymap.set("v", "<leader>p", '"+p', { desc = "Paste from Clipboard" })

-- Better search navigation
keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

-- Join lines and keep cursor position
keymap.set("n", "J", "mzJ`z", { desc = "Join lines" })

-- Undo break points for better undo granularity
keymap.set("i", ",", ",<c-g>u")
keymap.set("i", ".", ".<c-g>u")
keymap.set("i", "!", "!<c-g>u")
keymap.set("i", "?", "?<c-g>u")

-- Better page up/down
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Location and quickfix list navigation
keymap.set("n", "[l", "<cmd>lprev<cr>", { desc = "Previous Location" })
keymap.set("n", "]l", "<cmd>lnext<cr>", { desc = "Next Location" })

-- Buffer management improvements
keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete Buffer" })
keymap.set("n", "<leader>ba", "<cmd>bufdo bdelete<cr>", { desc = "Delete All Buffers" })

-- Improved substitute
keymap.set(
  "n",
  "<leader>s",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Substitute word under cursor" }
)

-- Text objects for entire buffer
keymap.set("o", "ae", ":<C-u>normal! ggVG<cr>", { desc = "Entire buffer" })
keymap.set("x", "ae", ":<C-u>normal! ggVG<cr>", { desc = "Entire buffer" })

-- Diagnostic navigation
keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })

-- Toggle options quickly
keymap.set("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify("Wrap " .. (vim.wo.wrap and "enabled" or "disabled"))
end, { desc = "Toggle Wrap" })

keymap.set("n", "<leader>ts", function()
  vim.o.spell = not vim.o.spell
  vim.notify("Spell " .. (vim.o.spell and "enabled" or "disabled"))
end, { desc = "Toggle Spell" })

keymap.set("n", "<leader>tr", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
  vim.notify("Relative numbers " .. (vim.wo.relativenumber and "enabled" or "disabled"))
end, { desc = "Toggle Relative Numbers" })
