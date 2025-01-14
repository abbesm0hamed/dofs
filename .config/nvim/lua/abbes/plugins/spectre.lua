return {
  "nvim-pack/nvim-spectre",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    {
      "<leader>rp",
      function()
        require("spectre").toggle()
      end,
      desc = "Toggle search and replace",
    },
    {
      "<leader>rw",
      function()
        require("spectre").open_visual({ select_word = true })
      end,
      desc = "Search current word",
    },
    {
      "<leader>rw",
      mode = "v",
      function()
        require("spectre").open_visual()
      end,
      desc = "Search current word",
    },
    {
      "<leader>rf",
      function()
        require("spectre").open_file_search({ select_word = true })
      end,
      desc = "Search in current file",
    },
  },
}
