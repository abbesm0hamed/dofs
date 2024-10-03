return {
  {
    "chrisgrieser/nvim-origami",
    event = "BufReadPost",
    opts = true,
  },
  {
    "anuvyklack/pretty-fold.nvim",
    event = "VeryLazy",
    dependencies = "kevinhwang91/promise-async",
    config = function()
      require("pretty-fold").setup {
        keep_indentation = false,
        fill_char = "━",
        sections = {
          left = {
            "━ ", function() return string.rep("*", vim.v.foldlevel) end, " ━┫", "content", "┣"
          },
          right = {
            "┫ ", "number_of_folded_lines", ": ", "percentage", " ┣━━",
          }
        },
        ft_ignore = { "neorg" },
      }

      -- Set up explicit keymaps
      local function close_all_folds() vim.cmd("normal! zM") end
      local function open_all_folds() vim.cmd("normal! zR") end
      local function open_all_regular_folds() vim.cmd("normal! zr") end
      local function close_folds_level(level) return function() vim.cmd("normal! z" .. level) end end

      vim.keymap.set("n", "zM", close_all_folds, { desc = "Close All Folds" })
      vim.keymap.set("n", "zR", open_all_folds, { desc = "Open All Folds" })
      vim.keymap.set("n", "zr", open_all_regular_folds, { desc = "Open All Regular Folds" })
      vim.keymap.set("n", "zm", close_folds_level("1"), { desc = "Close L1 Folds" })
      vim.keymap.set("n", "zM", close_folds_level("2"), { desc = "Close L2 Folds" })
      vim.keymap.set("n", "zM", close_folds_level("3"), { desc = "Close L3 Folds" })
      vim.keymap.set("n", "zM", close_folds_level("4"), { desc = "Close L4 Folds" })
    end,
  },
  {
    "anuvyklack/fold-preview.nvim",
    dependencies = "anuvyklack/keymap-amend.nvim",
    event = "VeryLazy",
    config = true,
  },
}
