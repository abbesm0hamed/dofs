return {
  {
    "williamboman/mason.nvim",
    config = function()
      -- import mason
      local mason = require("mason")

      opts = {
        keys = {
          { "<leader>mn", vim.cmd.Mason, desc = " Mason" },
        },
      }
      -- enable mason and configure icons
      mason.setup({
        ui = {
          border = vim.g.borderStyle,
          height = 0.85,
          width = 0.8,
          icons = {
            package_installed = "✓",
            package_pending = "󰔟",
            package_uninstalled = "✗",
          },
          keymaps = { -- consistent with keymaps for lazy.nvim
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
    opts = {
      auto_install = true,
    },
    config = function()
      local lsp_zero = require("lsp-zero")

      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        -- list of servers for mason to install
        ensure_installed = {
          "ts_ls",
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
        -- auto-install configured servers (with lspconfig)
        automatic_installation = true, -- not the same as ensure_installed
        handlers = {
          lsp_zero.default_setup,
          ts_ls = function()
            require("lspconfig").ts_ls.setup({
              single_file_support = false,
            })
          end,
        },
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      local mason_tool_installer = require("mason-tool-installer")
      mason_tool_installer.setup({
        ensure_installed = {
          "lua-language-server",
          "vim-language-server",
          "gopls",
          "stylua",
          "shellcheck",
          "editorconfig-checker",
          "gofumpt",
          "golines",
          "gomodifytags",
          "gotests",
          "impl",
          "json-to-struct",
          "misspell",
          "revive",
          "shellcheck",
          "shfmt",
          "staticcheck",
          "vint",
          "golangci-lint",
          "prettier", -- prettier formatter
          "stylua",   -- lua formatter
          "eslint_d", -- js linter
          "bash-language-server",
        },
      })
    end,
  },
}
