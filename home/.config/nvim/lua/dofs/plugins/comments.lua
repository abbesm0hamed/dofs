return {
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    cmd = { "TodoTrouble", "TodoTelescope" },
    config = true,
    -- optional = true,
    -- stylua: ignore
    keys = {
      { "<leader>st", function() Snacks.picker.todo_comments() end,                                          desc = "Todo" },
      { "<leader>sT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
    },
  },
  { -- comment
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      -- import comment plugin safely
      local comment = require("Comment")

      local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

      -- enable comment
      comment.setup({
        -- for commenting tsx and jsx files
        pre_hook = ts_context_commentstring.create_pre_hook(),
      })
    end,
    opts = {
      opleader = { line = "gcc", block = "<Nop>" },
      toggler = { line = "gcc", block = "<Nop>" },
      extra = { eol = "Q", above = "qO", below = "qo" },
    },
  },
  -- {
  --   "LudoPinelli/comment-box.nvim",
  --   config = function()
  --     local cb = require("comment-box")
  --
  --     -- General setup for comment-box
  --     cb.setup({
  --       doc_width = 80, -- Set max width for comment boxes
  --       box_width = 60, -- Set width of boxes for text
  --       borders = { -- Custom border characters
  --         top = "─",
  --         bottom = "─",
  --         left = "│",
  --         right = "│",
  --         top_left = "┌",
  --         top_right = "┐",
  --         bottom_left = "└",
  --         bottom_right = "┘",
  --       },
  --       line_width = 70, -- Width of divider lines
  --       inner_padding = 1, -- Padding inside boxes
  --       outer_padding = 1, -- Space outside boxes
  --       outer_blank_lines_above = false, -- insert a blank line above the box
  --       outer_blank_lines_below = false, -- insert a blank line below the box
  --       inner_blank_lines = false, -- insert a blank line above and below the text
  --       line_blank_line_above = false, -- insert a blank line above the line
  --       line_blank_line_below = false, -- insert a blank line below the line
  --     })
  --
  --     -- Define key mappings for different types of aligned lines
  --     -- lines
  --     vim.api.nvim_set_keymap("n", "<leader>lL", ":CBllline<CR>", { noremap = true, silent = true }) -- Left aligned line with left text
  --     vim.api.nvim_set_keymap("n", "<leader>lc", ":CBlcline<CR>", { noremap = true, silent = true }) -- Left aligned line with centered text
  --     -- vim.api.nvim_set_keymap("n", "<leader>lr", ":CBlrline<CR>", { noremap = true, silent = true }) -- Left aligned line with right text
  --     -- vim.api.nvim_set_keymap("n", "<leader>cl", ":CBclline<CR>", { noremap = true, silent = true }) -- Centered title line with left text
  --     -- vim.api.nvim_set_keymap("n", "<leader>cc", ":CBccline<CR>", { noremap = true, silent = true }) -- Centered title line with centered text
  --     -- vim.api.nvim_set_keymap("n", "<leader>cr", ":CBcrline<CR>", { noremap = true, silent = true }) -- Centered title line with right text
  --     -- vim.api.nvim_set_keymap("n", "<leader>rl", ":CBrlline<CR>", { noremap = true, silent = true }) -- Right aligned title line with left text
  --     -- vim.api.nvim_set_keymap("n", "<leader>rc", ":CBrcline<CR>", { noremap = true, silent = true }) -- Right aligned title line with centered text
  --     -- vim.api.nvim_set_keymap("n", "<leader>clr", ":CBrrline<CR>", { noremap = true, silent = true }) -- Right aligned title line with right text
  --     --
  --     -- boxes
  --     vim.api.nvim_set_keymap("n", "<leader>bc", ":CBccbox<CR>", { noremap = true, silent = true }) -- Centered box with centered text
  --     vim.api.nvim_set_keymap("n", "<leader>bl", ":CBlcbox<CR>", { noremap = true, silent = true }) -- Right-aligned box with centered text
  --   end,
  -- },
}
