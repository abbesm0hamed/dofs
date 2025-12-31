return {
  {
    -- The most comprehensive and performant Git plugin for Neovim
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signs_staged = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      -- Performance optimizations
      max_file_length = 40000,
      attach_to_untracked = true,
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
      },
      preview_config = {
        border = "rounded",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
      -- Advanced diff options
      diff_opts = {
        internal = true,
        algorithm = "myers",
        indent_heuristic = true,
        vertical = false,
      },
      -- Word diff for better granularity
      word_diff = false,
      -- Better performance for large repos
      watch_gitdir = {
        follow_files = true,
      },
      auto_attach = true,
      -- Sign priority
      sign_priority = 6,
      -- Update debounce
      update_debounce = 100,
      -- Status formatter
      status_formatter = nil,
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, { desc = "Next hunk" })

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, { desc = "Previous hunk" })

        map("n", "]H", function()
          gitsigns.nav_hunk("last")
        end, { desc = "Last hunk" })
        map("n", "[H", function()
          gitsigns.nav_hunk("first")
        end, { desc = "First hunk" })

        -- Staging operations
        map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Stage hunk" })
        map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset hunk" })
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Stage hunk" })
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Reset hunk" })

        -- Buffer operations
        map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Stage buffer" })
        map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Reset buffer" })
        map("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "Undo stage hunk" })

        -- Preview and diff
        map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Preview hunk" })
        map("n", "<leader>hd", gitsigns.diffthis, { desc = "Diff this" })
        map("n", "<leader>hD", function()
          gitsigns.diffthis("~")
        end, { desc = "Diff this ~" })

        -- Blame
        map("n", "<leader>hb", function()
          gitsigns.blame_line({ full = true })
        end, { desc = "Blame line" })
        map("n", "<leader>hB", gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })

        -- Toggles
        map("n", "<leader>td", gitsigns.toggle_deleted, { desc = "Toggle deleted" })
        map("n", "<leader>tw", gitsigns.toggle_word_diff, { desc = "Toggle word diff" })

        -- Text objects
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })

        -- Advanced operations
        map("n", "<leader>hl", function()
          gitsigns.setloclist(0)
        end, { desc = "List hunks" })

        map("n", "<leader>hq", function()
          gitsigns.setqflist("all")
        end, { desc = "Quickfix all hunks" })
      end,
    },
  },
  {
    -- Essential conflict resolution - lightweight and focused
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
    opts = {
      default_mappings = {
        ours = "co",
        theirs = "ct",
        none = "c0",
        both = "cb",
        next = "]x",
        prev = "[x",
      },
      default_commands = true,
      disable_diagnostics = false,
      list_opener = "copen",
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
        ancestor = "DiffChange",
      },
    },
    keys = {
      { "<leader>co", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose ours" },
      { "<leader>ct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose theirs" },
      { "<leader>cb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose both" },
      { "<leader>c0", "<cmd>GitConflictChooseNone<cr>", desc = "Choose none" },
      { "<leader>cl", "<cmd>GitConflictListQf<cr>", desc = "List conflicts" },
    },
  },
}
