return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>fm",
      function()
        require("conform").format({ async = true, timeout_ms = 3000 })
      end,
      desc = "󰉢 Format",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "biome", "prettier", stop_after_first = true },
      typescript = { "biome", "prettier", stop_after_first = true },
      javascriptreact = { "biome", "prettier", stop_after_first = true },
      typescriptreact = { "biome", "prettier", stop_after_first = true },
      json = { "biome", "prettier", stop_after_first = true },
      vue = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      markdown = { "prettier" },
      go = { "goimports", "gofumpt" },
      python = { "isort", "black" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      yaml = { "prettier" },
      toml = { "taplo" },
      -- Add more as needed
      -- graphql         = { "prettier" },
      -- csharp          = { "csharpier" },
    },
    format_on_save = {
      timeout_ms = 3000,
      lsp_format = "fallback",
    },
    formatters = {
      biome = {
        condition = function(_, ctx)
          return vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1]
        end,
      },
      prettier = {
        condition = function(_, ctx)
          local prettier_files = {
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.js",
            ".prettierrc.mjs",
            "prettier.config.js",
            "prettier.config.mjs",
            ".prettierrc.yaml",
            ".prettierrc.yml",
          }
          local has_prettier = vim.fs.find(prettier_files, { path = ctx.filename, upward = true })[1]
          local has_biome = vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1]
          return has_prettier or not has_biome
        end,
      },
      goimports = {
        prepend_args = { "-local", "github.com/your-org" },
      },
      gofumpt = {
        prepend_args = { "-extra" },
      },
      shfmt = {
        prepend_args = { "-i", "2", "-ci" },
      },
      black = {
        prepend_args = { "--fast" },
      },
      isort = {
        prepend_args = { "--profile", "black" },
      },
    },
  },
}
