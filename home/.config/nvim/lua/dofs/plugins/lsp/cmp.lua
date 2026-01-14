return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "moyiz/blink-emoji.nvim",
      "rafamadriz/friendly-snippets",
      {
        "saghen/blink.compat",
        optional = true,
        opts = {},
        version = "*",
      },
    },
    version = "*",
    opts = {
      sources = {
        default = { "lsp", "snippets", "buffer", "path", "emoji" },
        providers = {
          lsp = {
            name = "lsp",
            enabled = true,
          },
          snippets = {
            name = "snippets",
            enabled = true,
          },
          buffer = {
            name = "buffer",
            enabled = true,
          },
          path = {
            name = "path",
            enabled = true,
          },
          emoji = {
            module = "blink-emoji",
            name = "emoji",
            enabled = true,
          },
        },
      },
      completion = {
        menu = {
          border = "none",
        },
        documentation = {
          auto_show = true,
          window = {
            border = "none",
          },
        },
      },
      snippets = {
        preset = "luasnip",
      },
      keymap = {
        preset = "default",
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<S-k>"] = { "scroll_documentation_up", "fallback" },
        ["<S-j>"] = { "scroll_documentation_down", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
      },
    },
  },
}
