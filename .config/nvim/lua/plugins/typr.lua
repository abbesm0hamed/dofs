return {
  {
    "nvzone/typr",
    event = "VeryLazy",
    dependencies = "nvzone/volt",
    opts = {}, -- Plugin-specific options (if any)
    cmd = { "Typr", "TyprStats" }, -- Commands provided by the plugin
    keys = { -- Keybindings for the commands
      { "<Leader>ty", "<Cmd>Typr<CR>", desc = "Start Typr" }, -- Start Typr
      { "<Leader>ts", "<Cmd>TyprStats<CR>", desc = "Show Typr Stats" }, -- Show Typr Stats
    },
    config = function(_, opts)
      -- Plugin setup (if required)
      require("typr").setup(opts)
    end,
  },
}
