return {
  "CRAG666/betterTerm.nvim",
  keys = {
    {
      mode = { "n", "t" },
      "<A-.>",
      function()
        require("betterTerm").open()
      end,
      desc = "Open BetterTerm 0",
    },
    {
      mode = { "n", "t" },
      "<A-/>",
      function()
        require("betterTerm").open(1)
      end,
      desc = "Open BetterTerm 1",
    },
    {
      mode = { "n", "t" },
      "<A-,>",
      function()
        require("betterTerm").open(2)
      end,
      desc = "Open BetterTerm 1",
    },
    {
      "<leader>bt",
      function()
        require("betterTerm").select()
      end,
      desc = "Select terminal",
    },
  },
  opts = {
    position = "bot",
    size = 20,
    jump_tab_mapping = "<A-$tab>",
  },
}
