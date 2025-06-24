return {
  {
    "stevearc/conform.nvim",
    event = "BufReadPre",
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
        markdown = { "prettier" },
        go = { "gofumpt" },
        python = { "black" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
      formatters = {
        biome = {
          condition = function(_, ctx)
            return vim.fs.find({ "biome.json" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        prettier = {
          condition = function(_, ctx)
            local has_prettier =
              vim.fs.find({ ".prettierrc", "prettier.config.js" }, { path = ctx.filename, upward = true })[1]
            local has_biome = vim.fs.find({ "biome.json" }, { path = ctx.filename, upward = true })[1]
            return has_prettier or not has_biome
          end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    opts = {
      linters_by_ft = {
        lua = { "luacheck" },
        python = { "flake8" },
        javascript = { "eslint" },
        typescript = { "eslint" },
        javascriptreact = { "eslint" },
        typescriptreact = { "eslint" },
        go = { "golangci_lint" },
        sh = { "shellcheck" },
      },
      linters = {
        eslint = {
          condition = function(ctx)
            return vim.fs.find({ ".eslintrc", "eslint.config.js" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft

      -- Apply linter configurations
      for name, linter in pairs(opts.linters) do
        if lint.linters[name] then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
        end
      end

      -- Simple debounced lint function
      local timer = vim.uv.new_timer()
      local function lint_file()
        timer:start(100, 0, function()
          timer:stop()
          vim.schedule(function()
            lint.try_lint()
          end)
        end)
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        callback = lint_file,
      })
    end,
  },
}
