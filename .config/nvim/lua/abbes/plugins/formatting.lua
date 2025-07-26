return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>fm",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
    {
      "<leader>fM",
      function()
        require("conform").format({ formatters = { "injected" }, async = true })
      end,
      mode = { "n", "v" },
      desc = "Format injected languages",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      go = { "goimports", "gofmt" },
      javascript = { "biome" },
      typescript = { "biome" },
      javascriptreact = { "biome" },
      typescriptreact = { "biome" },
      html = { { "prettierd", "prettier" } },
      css = { { "prettierd", "prettier" } },
      scss = { { "prettierd", "prettier" } },
      json = { "biome" },
      jsonc = { "biome" },
      yaml = { { "prettierd", "prettier" } },
      markdown = { { "prettierd", "prettier" } },
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
      fish = { "fish_indent" },
      rust = { "rustfmt" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      java = { "google-java-format" },
      xml = { "xmlformat" },
      sql = { "sqlfluff" },
      ["_"] = { "trim_whitespace" },
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return {
        timeout_ms = 1000,
        lsp_fallback = true,
        async = false,
      }
    end,
    formatters = {
      shfmt = {
        prepend_args = { "-i", "2" },
      },
      black = {
        prepend_args = { "--line-length", "88" },
      },
      isort = {
        prepend_args = { "--profile", "black" },
      },
      prettier = {
        prepend_args = { "--tab-width", "2" },
      },
      prettierd = {
        prepend_args = { "--tab-width", "2" },
      },
      goimports = {
        prepend_args = { "-local", "github.com" },
      },
    },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, {
      desc = "Disable autoformat-on-save",
      bang = true,
    })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = "Re-enable autoformat-on-save",
    })
  end,
  config = function(_, opts)
    local conform = require("conform")

    conform.setup(opts)

    vim.api.nvim_create_user_command("Format", function(args)
      local range = nil
      if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = {
          start = { args.line1, 0 },
          ["end"] = { args.line2, #end_line },
        }
      end
      conform.format({
        async = true,
        lsp_fallback = true,
        range = range,
        timeout_ms = 3000,
      })
    end, { range = true, desc = "Format code" })

    vim.api.nvim_create_user_command("ConformInfo", function()
      local formatters = conform.list_formatters()
      if #formatters == 0 then
        vim.notify("No formatters available for this buffer", vim.log.levels.INFO)
        return
      end
      local lines = { "Available formatters:" }
      for _, formatter in ipairs(formatters) do
        table.insert(
          lines,
          string.format("  • %s (%s)", formatter.name, formatter.available and "available" or "not available")
        )
      end
      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Conform Info" })
    end, { desc = "Show conform formatter info" })
  end,
}
