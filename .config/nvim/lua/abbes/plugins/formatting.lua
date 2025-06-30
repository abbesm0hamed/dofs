return {
  "stevearc/conform.nvim",
  -- Use "lazy" event instead of "BufReadPre" for better startup performance.
  -- The keybinding will load it when used, and format_on_save will also trigger it.
  keys = {
    {
      "<leader>fm",
      function()
        -- Consider making this a more robust format function that
        -- takes arguments for specific ranges or files if needed in the future.
        -- For now, async and timeout are good defaults.
        require("conform").format({ async = true, timeout_ms = 3000 })
      end,
      desc = "󰉢 Format",
    },
  },
  opts = {
    -- You can use a global `formatters` table and reference them here if you have
    -- complex configurations that are reused.
    formatters_by_ft = {
      lua = { "stylua" },
      -- biome should ideally be the primary formatter if a biome.json is present.
      -- If biome isn't found or doesn't apply, then prettier.
      -- The order here matters with stop_after_first.
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
      -- gofumpt is a stricter gofmt, good choice.
      go = { "gofumpt", "goimports" },
      -- isort first, then black. isort handles imports, black formats the rest.
      python = { "isort", "black" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      yaml = { "prettier" }, -- yamlfmt is another option if you prefer.
      toml = { "taplo" },
      -- Add more as needed, e.g., graphql = { "prettier" }, csharp = { "csharpier" }
    },
    format_on_save = {
      -- Set to true to enable format on save.
      -- This is a very common and convenient feature.
      enabled = true,
      -- timeout_ms should be reasonable. 1000ms is good for most cases.
      timeout_ms = 1000,
      -- fallback to LSP formatting if no conform formatter applies. Good.
      lsp_format = "fallback",
      -- This filter function is correct and effective.
      -- It prevents conform from running if an LSP client already handled formatting.
      filter = function(client)
        local formatters = require("conform").list_formatters_for_buffer()
        return #formatters == 0
      end,
    },
    -- Global formatter configurations.
    formatters = {
      -- Biome condition is well-defined, ensuring it only runs when a biome config is found.
      biome = {
        condition = function(_, ctx)
          return vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1]
        end,
      },
      -- Prettier condition: run if a prettier config is found OR if biome isn't present.
      -- This ensures prettier acts as a fallback for files that don't use biome.
      prettier = {
        condition = function(_, ctx)
          local prettier_files = {
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.js",
            ".prettierrc.mjs",
            "prettier.config.js",
            "prettier.config.mjs",
            -- Add .prettierrc.yaml, .prettierrc.yml if you use them.
            ".prettierrc.yaml",
            ".prettierrc.yml",
          }
          local has_prettier = vim.fs.find(prettier_files, { path = ctx.filename, upward = true })[1]
          local has_biome = vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1]
          -- Run prettier if it has a config or if biome doesn't have a config.
          -- This logic ensures prettier is a general fallback.
          return has_prettier or not has_biome
        end,
      },
      -- goimports configuration.
      goimports = {
        -- Prepend_args is good for adding common flags.
        -- Replace "github.com/your-org" with your actual organization's import path.
        prepend_args = { "-local", "github.com/your-org" },
      },
      -- shfmt configuration.
      shfmt = {
        -- -i 2 for 2-space indent, -ci for C-style indentation.
        prepend_args = { "-i", "2", "-ci" },
      },
      -- Example for black:
      black = {
        -- You might want to add a condition here if you have a pyproject.toml
        -- or black config specific to your project.
        -- condition = function(_, ctx)
        --   return vim.fs.find({ "pyproject.toml", "black.toml" }, { path = ctx.filename, upward = true })[1]
        -- end,
      },
      -- Example for isort:
      isort = {
        -- Same as black, a condition based on isort config files might be useful.
        -- condition = function(_, ctx)
        --   return vim.fs.find({ ".isort.cfg", "pyproject.toml", "setup.cfg" }, { path = ctx.filename, upward = true })[1]
        -- end,
      },
    },
  },
}
