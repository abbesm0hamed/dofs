return {
  {
    "stevearc/conform.nvim",   -- Fast formatter
    event = { "BufWritePre" }, -- Load only before saving
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "󰉢 Format",
      },
    },
    opts = {
      -- Define formatters per filetype
      formatters_by_ft = {
        lua = { "stylua" },
        -- Frontend
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
        vue = { "prettierd" },
        html = { "prettierd" },
        css = { "prettierd" },
        scss = { "prettierd" },
        markdown = { "prettierd" },
        yaml = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        -- Go
        go = { "gofumpt", "goimports" },
        -- Shell
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      },
      -- Use faster formatters where possible
      formatters = {
        prettierd = {
          env = {
            PRETTIERD_DEFAULT_CONFIG = vim.fn.expand("~/.config/nvim/utils/linting-and-formatting/.prettierrc.json"),
          },
          -- Fallback to prettier if prettierd fails
          condition = function(ctx)
            return vim.fn.executable("prettierd") == 1
          end,
        },
        prettier = {
          -- Only use prettier as fallback
          condition = function(ctx)
            return vim.fn.executable("prettierd") == 0
          end,
        },
        shfmt = {
          args = { "-i", "2", "-ci" },
        },
      },
      -- Format on save (synchronous)
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      -- Async formatting after save
      format_after_save = {
        lsp_fallback = true,
        async = true,
      },
      -- Don't log formatting
      notify_on_error = false,
      -- Cache formatters for better performance
      cache_disabled = false,
    },
  },
  {
    "mfussenegger/nvim-lint", -- Async linter
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      -- Use built-in linters
      lint.linters_by_ft = {
        javascript = { "eslint" },
        typescript = { "eslint" },
        javascriptreact = { "eslint" },
        typescriptreact = { "eslint" },
        vue = { "eslint" },
        go = { "staticcheck" }, -- Use staticcheck instead of golangci-lint
        sh = { "shellcheck" },
        lua = { "luacheck" },
      }

      -- Create autocommand for linting
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
