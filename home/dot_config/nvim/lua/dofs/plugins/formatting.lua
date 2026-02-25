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
      desc = "Format",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "oxfmt", "prettier" },
      typescript = { "oxfmt", "prettier" },
      javascriptreact = { "oxfmt", "prettier" },
      typescriptreact = { "oxfmt", "prettier" },
      jsx = { "oxfmt", "prettier" },
      tsx = { "oxfmt", "prettier" },
      json = { "oxfmt", "prettier" },
      jsonc = { "oxfmt", "prettier" },
      vue = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      markdown = { "prettier" },
      go = { "goimports", "gofumpt" },
      python = { "isort", "black" },
      rust = { "rustfmt", lsp_format = "fallback" },
      sh = { "shfmt" },
      yaml = { "prettier" },
      toml = { "taplo" },
    },
    format_on_save = { timeout_ms = 3000, lsp_format = "fallback" },
    formatters = {
      oxfmt = {
        command = "oxfmt",
        args = { "--stdin-filepath", "$FILENAME" },
        stdin = true,
        condition = function(_, _)
          local out = vim.system({ "oxfmt", "--version" }, { stdin = "" }):wait()
          return out.code == 0
        end,
      },
      biome = {
        command = "biome",
        args = { "format", "--stdin-file-path", "$FILENAME" },
        stdin = true,
      },
      prettier = {
        condition = function(_, ctx)
          local p_files = {
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.js",
            ".prettierrc.mjs",
            "prettier.config.js",
            "prettier.config.mjs",
            ".prettierrc.yaml",
            ".prettierrc.yml",
          }
          local has_p = vim.fs.find(p_files, { path = ctx.filename, upward = true })[1]
          local has_b = vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1]
          return has_p or not has_b
        end,
      },
      stylua = { command = "stylua" },
      taplo = { command = "taplo" },
      shfmt = { command = "shfmt", prepend_args = { "-i", "2", "-ci" } },
      goimports = { command = "goimports", prepend_args = { "-local", "github.com/your-org" } },
      gofumpt = { command = "gofumpt", prepend_args = { "-extra" } },
      black = { command = "black", prepend_args = { "--fast" } },
      isort = { command = "isort", prepend_args = { "--profile", "black" } },
    },
  },
}
