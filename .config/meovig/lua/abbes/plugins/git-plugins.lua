return {
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    config = function()
      local diffview_ok, diffview = pcall(require, "diffview")
      if not diffview_ok then
        vim.notify("Diffview plugin failed to load.", vim.log.levels.ERROR)
        return
      end
      local actions = require("diffview.actions")
      diffview.setup({
        enhanced_diff_hl = true,
        use_icons = true,
        icons = {
          folder_closed = "",
          folder_open = "",
        },
        signs = {
          fold_closed = "",
          fold_open = "",
          done = "✓",
        },
        view = {
          default = {
            layout = "diff2_horizontal",
            winbar_info = true,
          },
          merge_tool = {
            layout = "diff3_horizontal",
            disable_diagnostics = true,
          },
          file_history = {
            layout = "diff2_horizontal",
          },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = {
            flatten_dirs = true,
            folder_statuses = "only_folded",
          },
          win_config = {
            position = "left",
            width = 35,
          },
        },
        keymaps = {
          view = {
            -- Preserve your existing keymaps
            ["<leader>q"] = "<cmd>DiffviewClose<CR>",
            ["<leader>ch"] = actions.conflict_choose("ours"),
            ["<leader>cl"] = actions.conflict_choose("theirs"),
            ["<leader>cb"] = actions.conflict_choose("base"),
            ["<leader>ca"] = actions.conflict_choose("all"),
            ["<leader>cx"] = actions.conflict_choose("none"),
            ["do"] = "<cmd>diffget<cr>",
            ["dp"] = "<cmd>diffput<cr>",

            -- Enhanced navigation
            ["<C-u>"] = actions.scroll_view(-0.25),
            ["<C-d>"] = actions.scroll_view(0.25),
            ["<tab>"] = actions.next_entry,
            ["<S-tab>"] = actions.prev_entry,
            ["<C-/>"] = actions.toggle_files,
          },
          file_panel = {
            ["j"] = "NextEntry",
            ["k"] = "PrevEntry",
            ["<cr>"] = "SelectEntry",
            ["<2-LeftMouse>"] = "SelectEntry",
            ["<space>"] = "ToggleStage",
            ["-"] = "ToggleStage",
            ["S"] = "StageAll",
            ["U"] = "UnstageAll",
            ["X"] = "RestoreEntry",
            ["L"] = "ToggleAll",
            ["zh"] = "ToggleFold",
            ["R"] = "RefreshFiles",
          },
          file_history_panel = {
            ["g!"] = "Options",
            ["<C-A-d>"] = "OpenInDiffview",
            ["zR"] = "ExpandAll",
            ["zM"] = "CollapseAll",
            ["<C-b>"] = actions.scroll_view(-0.25),
            ["<C-f>"] = actions.scroll_view(0.25),
          },
        },
      })
      -- Preserve your existing key mappings
      vim.keymap.set("n", "<leader>gdo", "<cmd>DiffviewOpen<CR>", { desc = "Open Git diff view" })
      vim.keymap.set("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Close Git diff view" })
      vim.keymap.set("n", "<leader>gdr", "<cmd>DiffviewRefresh<CR>", { desc = "Refresh Git diff view" })
      vim.keymap.set("n", "<leader>gdf", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle Git diff file panel" })
      vim.keymap.set("n", "<leader>gdh", "<cmd>DiffviewFileHistory<CR>", { desc = "Open Git diff file history" })
    end,
  },
  -- lazy git can be executed inside toggleterm with <leader>gg
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵", show_count = true },
        topdelete = { text = "‾", show_count = true },
        changedelete = { text = "~", show_count = true },
      },
      max_file_length = 12000,
      attach_to_untracked = true,
      current_line_blame = false,
      preview_config = {
        border = "rounded",
      },
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Stage operations
        map("n", "ga", gitsigns.stage_hunk)
        map("v", "ga", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end)
        map("n", "gA", gitsigns.stage_buffer)

        -- View operations
        map("n", "<leader>gv", gitsigns.toggle_deleted)
        map("n", "gp", gitsigns.preview_hunk_inline)

        -- Undo/Reset operations
        map("n", "<leader>uh", gitsigns.reset_hunk)
        map("n", "<leader>ub", gitsigns.reset_buffer)

        -- Blame
        map("n", "<leader>ob", gitsigns.toggle_current_line_blame)

        -- Navigation
        map("n", "gh", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end)
        map("n", "gH", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end)

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
      end,
    },
  },
  -- {
  --   "akinsho/git-conflict.nvim",
  --   version = "*",
  --   config = function()
  --     require("git-conflict").setup({
  --       -- co - Choose Ours (current changes)
  --       -- ct - Choose Theirs (incoming changes)
  --       -- cb - Choose Both
  --       -- c0 - Choose None
  --       -- ]x - Move to next conflict
  --       -- [x - Move to previous conflict
  --       --
  --       -- Default highlights
  --       highlights = {
  --         incoming = "DiffText",
  --         current = "DiffAdd",
  --       },
  --
  --       -- Default character markers
  --       default_mappings = true, -- Enables default keymaps
  --       default_commands = true, -- Enables default commands
  --
  --       -- Customize the conflict marker symbols
  --       list_opener = "o", -- Key to open the conflict list
  --       disable_diagnostics = false, -- Enable conflict diagnostics
  --     })
  --   end,
  -- },
  -- {
  --   "tanvirtin/vgit.nvim",
  --   branch = "v1.0.x",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   keys = {
  --     { "<leader>gj", "<cmd>VGitHunkDown<CR>", desc = "Next Hunk" },
  --     { "<leader>gk", "<cmd>VGitHunkUp<CR>", desc = "Previous Hunk" },
  --
  --     -- Buffer operations
  --     { "<leader>gp", "<cmd>VGitBufferHunkPreview<CR>", desc = "Preview Hunk" },
  --     { "<leader>gd", "<cmd>VGitBufferDiffPreview<CR>", desc = "Buffer Diff" },
  --     { "<leader>gb", "<cmd>VGitBufferBlamePreview<CR>", desc = "Buffer Blame" },
  --     { "<leader>gh", "<cmd>VGitBufferHistoryPreview<CR>", desc = "Buffer History" },
  --
  --     -- Staging
  --     { "<leader>gsh", "<cmd>VGitBufferHunkStage<CR>", desc = "Stage Hunk" },
  --     { "<leader>gsb", "<cmd>VGitBufferStage<CR>", desc = "Stage Buffer" },
  --
  --     -- Reset
  --     { "<leader>grh", "<cmd>VGitBufferHunkReset<CR>", desc = "Reset Hunk" },
  --     { "<leader>grb", "<cmd>VGitBufferReset<CR>", desc = "Reset Buffer" },
  --
  --     -- Project-wide operations
  --     { "<leader>gPd", "<cmd>VGitProjectDiffPreview<CR>", desc = "Project Diff" },
  --     { "<leader>gPl", "<cmd>VGitProjectLogsPreview<CR>", desc = "Project Logs" },
  --     { "<leader>gPc", "<cmd>VGitProjectCommitPreview<CR>", desc = "New Commit" },
  --     { "<leader>gPh", "<cmd>VGitProjectCommitsPreview<CR>", desc = "Commit History" },
  --     { "<leader>gPs", "<cmd>VGitProjectStashPreview<CR>", desc = "Stash Preview" },
  --
  --     -- Conflict resolution
  --     { "<leader>gcb", "<cmd>VGitBufferConflictAcceptBoth<CR>", desc = "Accept Both" },
  --     { "<leader>gcc", "<cmd>VGitBufferConflictAcceptCurrent<CR>", desc = "Accept Current" },
  --     { "<leader>gci", "<cmd>VGitBufferConflictAcceptIncoming<CR>", desc = "Accept Incoming" },
  --
  --     -- Toggles
  --     { "<leader>gtd", "<cmd>VGitToggleDiffPreference<CR>", desc = "Toggle Diff Preference" },
  --     { "<leader>gtg", "<cmd>VGitToggleLiveGutter<CR>", desc = "Toggle Live Gutter" },
  --     { "<leader>gtb", "<cmd>VGitToggleLiveBlame<CR>", desc = "Toggle Live Blame" },
  --     { "<leader>gtt", "<cmd>VGitToggleTracing<CR>", desc = "Toggle Tracing" },
  --   },
  --   event = "VeryLazy",
  --   config = function()
  --     require("vgit").setup({
  --       -- Appearance settings
  --       signs = {
  --         add = "│",
  --         change = "│",
  --         delete = "_",
  --       },
  --
  --       -- Preview window settings
  --       preview = {
  --         kind = "split", -- or "floating"
  --         signs = {
  --           -- { CLOSED, OPENED }
  --           section = { "▶ ", "▼ " },
  --           item = { "▶ ", "▼ " },
  --           hunk = { "", "" },
  --         },
  --       },
  --
  --       -- Diff settings
  --       diff = {
  --         preference = "split", -- or "unified"
  --         signs = {
  --           fold = { "─", "╭", "╮", "╰", "╯" },
  --         },
  --       },
  --
  --       -- Live features
  --       live_gutter = true,
  --       live_blame = false,
  --
  --       -- Project settings
  --       project = {
  --         logs = {
  --           max_entries = 100,
  --         },
  --         commits = {
  --           max_entries = 100,
  --         },
  --         stash = {
  --           max_entries = 100,
  --         },
  --       },
  --
  --       -- System settings
  --       debug = false,
  --       auto_refresh = true,
  --       disable_builtin_notifications = false,
  --
  --       -- Buffer settings
  --       buffer = {
  --         preview = {
  --           height = 0.4, -- 40% of window height
  --           width = 0.8, -- 80% of window width
  --         },
  --       },
  --     })
  --   end,
  -- },
}
