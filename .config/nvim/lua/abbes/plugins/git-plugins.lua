-- local u = require("abbes.config.utils")
------------------------------------------------------------------------------
--
-- some comment here
return {
  -- lazy git can be executed inside toggleterm with <leader>gg
  { -- git sign gutter & hunk actions
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    keys = {
      { "ga", "<cmd>Gitsigns stage_hunk<CR>", desc = "󰊢 Stage Hunk" },
      { "ga", ":Gitsigns stage_hunk<CR>", mode = "x", silent = true, desc = "󰊢 Stage Sel" },
      -- stylua: ignore start
      { "gA", function() require("gitsigns").stage_buffer() end, desc = "󰊢 Add Buffer" },
      { "<leader>gv", function() require("gitsigns").toggle_deleted() end, desc = "󰊢 View Deletions Inline" },
      { "<leader>ua", function() require("gitsigns").undo_stage_hunk() end, desc = "󰊢 Unstage Last Stage" },
      { "<leader>uh", function() require("gitsigns").reset_hunk() end, desc = "󰊢 Reset Hunk" },
      { "<leader>ub", function() require("gitsigns").reset_buffer() end, desc = "󰊢 Reset Buffer" },
      { "<leader>ob", function() require("gitsigns").toggle_current_line_blame() end, desc = "󰊢 Git Blame" },
      { "gh", function() require("gitsigns").next_hunk { foldopen = true } end, desc = "󰊢 Next Hunk" },
      { "gH", function() require("gitsigns").prev_hunk { foldopen = true } end, desc = "󰊢 Previous Hunk" },
      { "gh", function() require("gitsigns").select_hunk() end, mode = { "o", "x" }, desc = "󱡔 󰊢 Hunk textobj" }, -- stylua: ignore end
      -- stylua: ignore end
    },
    opts = {
      max_file_length = 12000, -- lines
      -- deletions greater than one line will show a count to assess the size
      -- (digits are actually nerdfont numbers to achieve smaller size)
      -- stylua: ignore
      -- count_chars = { "", "󰬻", "󰬼", "󰬽", "󰬾", "󰬿", "󰭀", "󰭁", "󰭂", ["+"] = "󰿮" },
      signs = {
        delete = { show_count = true },
        topdelete = { show_count = true },
        changedelete = { show_count = true },
      },
      attach_to_untracked = true,
    },
  },
  { "akinsho/git-conflict.nvim", version = "*", config = true },
  {
    "neogitorg/neogit",
    event = "VeryLazy",
    config = function()
      -- local wk = require("which-key")
      -- wk.register({
      --   ["<leader>tg"] = { "<cmd>Neogit<CR>", "Neogit" },
      -- })

      require("neogit").setup({
        auto_refresh = true,
        disable_builtin_notifications = false,
        use_magit_keybindings = false,
        -- Change the default way of opening neogit
        kind = "tab",
        -- Change the default way of opening the commit popup
        commit_popup = {
          kind = "split",
        },
        -- Change the default way of opening popups
        popup = {
          kind = "split",
        },
        -- customize displayed signs
        signs = {
          -- { CLOSED, OPENED }
          section = { "▶ ", "▼ " },
          item = { "▶ ", "▼ " },
          hunk = { "", "" },
        },
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    config = function()
      local diffview_ok, diffview = pcall(require, "diffview")
      if not diffview_ok then
        vim.notify("Diffview plugin failed to load.", vim.log.levels.ERROR)
        return
      end

      diffview.setup({
        enhanced_diff_hl = true, -- Highlight word-level changes
        keymaps = {
          view = {
            ["<leader>q"] = "<cmd>DiffviewClose<CR>", -- Close with leader + q
          },
          file_panel = {
            ["j"] = "NextEntry",      -- Down
            ["k"] = "PrevEntry",      -- Up
            ["<cr>"] = "SelectEntry", -- Open the diff for the selected entry
          },
          file_history_panel = {
            ["g!"] = "Options",
            ["<C-A-d>"] = "OpenInDiffview", -- Open selected commit in diffview
            ["zR"] = "ExpandAll",           -- Expand all folders
          },
        },
      })

      -- Key mappings
      vim.keymap.set("n", "<leader>gdo", "<cmd>DiffviewOpen<CR>", { desc = "Open Git diff view" })
      vim.keymap.set("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Close Git diff view" })
      vim.keymap.set("n", "<leader>gdr", "<cmd>DiffviewRefresh<CR>", { desc = "Refresh Git diff view" })
      vim.keymap.set("n", "<leader>gdf", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle Git diff file panel" })
      vim.keymap.set("n", "<leader>gdh", "<cmd>DiffviewFileHistory<CR>", { desc = "Open Git diff file history" })
    end,
  }
}
