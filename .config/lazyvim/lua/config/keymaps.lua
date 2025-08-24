-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps -------------------

-- Fix Enter key in insert mode
keymap.set("i", "<CR>", "<CR>", { desc = "Return to new line" })

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- delete single character without copying into register
-- keymap.set("n", "x", '"_x')

-- Mason
keymap.set("n", "<leader>mn", "<cmd>Mason<CR>", { desc = " Mason" })

-- layout
keymap.set("n", "<A>-z", ":lua vim.wo.wrap = not vim.wo.wrap<CR>", { desc = "Wrap text" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sc", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window
keymap.set("n", "<C-Up>", ":resize +4<CR>", { desc = "Increase window height" }) -- increase window height
keymap.set("n", "<C-Down>", ":resize -4<CR>", { desc = "Decrease window height" }) -- decrease window height
keymap.set("n", "<C-Right>", ":vertical resize +4<CR>", { desc = "Increase window width" }) -- increase window width
keymap.set("n", "<C-Left>", ":vertical resize -4<CR>", { desc = "Decrease window width" }) -- decrease window width
keymap.set("n", "<C-k>", "<C-W>k", { desc = "Jump to Previous Horizontal Tab", remap = true })
keymap.set("n", "<C-j>", "<C-W>j", { desc = "Jump to Next Horizontal Tab", remap = true })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- buffers
keymap.set("n", "[b", ":bprev<CR>", { desc = "Jump to previous buffer", noremap = true, silent = true }) --  go to previous tab
keymap.set("n", "]b", ":bnext<CR>", { desc = "Jump to next buffer", noremap = true, silent = true }) --  move current buffer to new tab

-- save file
keymap.set({ "n" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- select and copy from file
keymap.set("n", "<leader>vv", "ggVG", { desc = "Select All" })
keymap.set("n", "<leader>vc", 'ggVG"+y', { desc = "Copy All to Clipboard", remap = false })

-- Move Lines
keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Clear search with <esc>
keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
keymap.set(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

--keywordprg
keymap.set("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
keymap.set("v", "<", "<gv")
keymap.set("v", ">", ">gv")

-- lazy
keymap.set("n", "<leader>la", "<CMD>Lazy<cr>", { desc = "Lazy" })

-- new file
keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
keymap.set("n", "<leader>fl", "<cmd>copen<cr>", { desc = "Quickfix list" })

keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- quit
keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- highlights under cursor
keymap.set("n", "<leader>ui", vim.show_pos, { desc = "inspect pos" })

-- Terminal keymap.setpings
keymap.set("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })
-- keymap.set("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
keymap.set("t", "<c-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })

-- windows
keymap.set("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
keymap.set("n", "<leader>dw", "<C-W>c", { desc = "Delete Window", remap = true })
keymap.set("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
keymap.set("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })

-- tabs
keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- disable recording using q key
-- keymap.set("n", "q", "<Nop>", { noremap = true, silent = true })
-- record macros
keymap.set("n", "Q", "q", { noremap = true, silent = true })

-- save a mark
keymap.set("n", "M", "m", { noremap = true, silent = true })
