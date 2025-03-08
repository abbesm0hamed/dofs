return {
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
      {
        "<leader>sw",
        function()
          local grug = require("grug-far")
          local word = vim.fn.expand("<cword>")
          grug.open({
            transient = true,
            prefills = {
              searchPattern = word,
            },
          })
        end,
        desc = "Search current word",
      },
      {
        "<leader>sw",
        function()
          local grug = require("grug-far")
          local selected_text = vim.fn.expand("<cword>")
          grug.open({
            transient = true,
            prefills = {
              searchPattern = selected_text,
            },
          })
        end,
        mode = "v",
        desc = "Search selected text",
      },
      {
        "<leader>sf",
        function()
          local grug = require("grug-far")
          local current_file = vim.fn.expand("%:p")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = current_file,
            },
          })
        end,
        desc = "Search in current file",
      },
      {
        "<leader>sW",
        function()
          local grug = require("grug-far")
          local word = vim.fn.expand("<cword>")
          grug.open({
            transient = true,
            prefills = {
              searchPattern = word,
              replacePattern = "",
            },
          })
        end,
        desc = "Replace current word",
      },
      {
        "<leader>sW",
        function()
          local grug = require("grug-far")
          local selected_text = vim.fn.expand("<cword>")
          grug.open({
            transient = true,
            prefills = {
              searchPattern = selected_text,
              replacePattern = "",
            },
          })
        end,
        mode = "v",
        desc = "Replace selected text",
      },
    },
  },
  -- {
  --   "nvim-pack/nvim-spectre",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --   },
  --   keys = {
  --     {
  --       "<leader>rp",
  --       function()
  --         require("spectre").toggle()
  --       end,
  --       desc = "Toggle search and replace",
  --     },
  --     {
  --       "<leader>rw",
  --       function()
  --         require("spectre").open_visual({ select_word = true })
  --       end,
  --       desc = "Search current word",
  --     },
  --     {
  --       "<leader>rw",
  --       mode = "v",
  --       function()
  --         require("spectre").open_visual()
  --       end,
  --       desc = "Search current word",
  --     },
  --     {
  --       "<leader>rf",
  --       function()
  --         require("spectre").open_file_search({ select_word = true })
  --       end,
  --       desc = "Search in current file",
  --     },
  --   },
  -- },
}
