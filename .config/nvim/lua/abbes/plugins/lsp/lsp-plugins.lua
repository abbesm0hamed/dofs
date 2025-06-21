return {
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
      event = "InsertEnter",
    },
    opts = {
      history = false,
      update_events = { "TextChanged", "TextChangedI" },
      fs_event_providers = { autocmd = false, libuv = false },
      delete_check_events = "InsertLeave",
    },
    config = function(_, opts)
      require("luasnip").setup(opts)
      require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    end,
  },
}
