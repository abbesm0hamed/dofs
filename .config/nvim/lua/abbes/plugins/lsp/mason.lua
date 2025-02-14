return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = {
      { "<leader>cm", "<cmd>Mason<cr>", desc = " Mason" },
    },
    build = ":MasonUpdate",
    event = "VeryLazy",
    config = function()
      require("mason").setup({
        ui = {
          border = vim.g.borderStyle,
          height = 0.85,
          width = 0.8,
          icons = {
            package_installed = "✓",
            package_pending = "󰔟",
            package_uninstalled = "✗",
          },
          keymaps = {
            uninstall_package = "x",
            toggle_help = "?",
            toggle_package_expand = "<Tab>",
          },
        },
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      local lsp_zero = require("lsp-zero")
      require("mason-lspconfig").setup({
        ensure_installed = {
          "vtsls",
          "emmet_ls",
          "html",
          "cssls",
          "tailwindcss",
          "svelte",
          "lua_ls",
          "graphql",
          "gopls",
          "vuels",
          "yamlls",
          "prismals",
          "pyright",
        },
        automatic_installation = true,
        handlers = {
          lsp_zero.default_setup,
          vtsls = function()
            require("lspconfig").vtsls.setup({
              single_file_support = false,
              settings = {
                documentFormatting = true,
                format = {
                  enable = true,
                },
              },
            })
          end,
        },
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = "williamboman/mason.nvim",
    event = "VeryLazy",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- Formatters
          "stylua",
          "prettier",
          "gofumpt",
          "golines",
          -- Linters
          "eslint_d",
          "golangci-lint",
          "shellcheck",
          "editorconfig-checker",
          "vint",
          -- Go tools
          "gomodifytags",
          "gotests",
          "impl",
          "json-to-struct",
          "revive",
          "staticcheck",
          -- Shell
          "shfmt",
        },
        auto_update = true,
        run_on_start = true,
      })
    end,
  },
}
