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
        scss = { "prettier" },
        markdown = { "prettier" },
        go = { "gofumpt", "goimports" },
        python = { "black", "isort" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        yaml = { "prettier" },
        toml = { "taplo" },
      },
      format_on_save = {
        timeout_ms = 1000,
        lsp_format = "fallback",
        filter = function(client)
          local formatters = require("conform").list_formatters_for_buffer()
          return #formatters == 0
        end,
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
            }
            local has_prettier = vim.fs.find(prettier_files, { path = ctx.filename, upward = true })[1]
            local has_biome = vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1]
            return has_prettier or not has_biome
          end,
        },
        goimports = {
          prepend_args = { "-local", "github.com/your-org" },
        },
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    opts = function()
      local function get_go_linters()
        local linters = {}

        if vim.fn.executable("golangci-lint") == 1 then
          table.insert(linters, "golangci_lint")
        elseif vim.fn.executable("staticcheck") == 1 then
          table.insert(linters, "staticcheck")
        end

        return linters
      end

      return {
        linters_by_ft = {
          lua = { "luacheck" },
          python = { "ruff", "mypy" },
          javascript = { "eslint_d" },
          typescript = { "eslint_d" },
          javascriptreact = { "eslint_d" },
          typescriptreact = { "eslint_d" },
          go = get_go_linters(),
          sh = { "shellcheck" },
          dockerfile = { "hadolint" },
          yaml = { "yamllint" },
          json = { "jsonlint" },
        },
        linters = {
          eslint_d = {
            condition = function(ctx)
              local eslint_files = {
                ".eslintrc",
                ".eslintrc.js",
                ".eslintrc.json",
                ".eslintrc.yaml",
                ".eslintrc.yml",
                "eslint.config.js",
                "eslint.config.mjs",
              }
              return vim.fs.find(eslint_files, { path = ctx.filename, upward = true })[1]
            end,
          },
          golangci_lint = {

            args = {
              "run",
              "--out-format=json",
              "--issues-exit-code=1",
              "--print-issued-lines=false",
              "--print-linter-name=false",
              "--timeout=5m",
              function()
                return vim.api.nvim_buf_get_name(0)
              end,
            },
            timeout = 30000,
            ignore_exitcode = true,
          },
          luacheck = {
            condition = function(ctx)
              return vim.fs.find({ ".luacheckrc" }, { path = ctx.filename, upward = true })[1]
            end,
          },
          mypy = {
            condition = function(ctx)
              local mypy_files = { "mypy.ini", ".mypy.ini", "pyproject.toml", "setup.cfg" }
              return vim.fs.find(mypy_files, { path = ctx.filename, upward = true })[1]
            end,
          },
        },
      }
    end,
    config = function(_, opts)
      local lint = require("lint")

      local resolved_opts = type(opts) == "function" and opts() or opts
      lint.linters_by_ft = resolved_opts.linters_by_ft

      for name, config in pairs(resolved_opts.linters or {}) do
        if lint.linters[name] then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], config)
        end
      end

      local timer = vim.uv.new_timer()
      local lint_in_progress = false

      local function lint_file()
        if lint_in_progress then
          return
        end

        timer:start(200, 0, function()
          timer:stop()
          vim.schedule(function()
            lint_in_progress = true

            local bufnr = vim.api.nvim_get_current_buf()
            local filetype = vim.bo[bufnr].filetype

            if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
              lint_in_progress = false
              return
            end

            local ok, err = pcall(function()
              if filetype == "go" then
                local old_timeout = vim.g.lint_timeout
                vim.g.lint_timeout = 30000
                lint.try_lint()
                vim.g.lint_timeout = old_timeout
              else
                lint.try_lint()
              end
            end)

            if not ok then
              local error_msg = tostring(err)
              if error_msg:match("timeout") then
                vim.notify("Linting timeout for " .. filetype, vim.log.levels.WARN)
              elseif error_msg:match("golangci%-lint") then
                vim.notify("golangci-lint error - check your config", vim.log.levels.WARN)
              else
                vim.notify("Linting error: " .. error_msg, vim.log.levels.DEBUG)
              end
            end

            lint_in_progress = false
          end)
        end)
      end

      local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = lint_augroup,
        callback = lint_file,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
        group = lint_augroup,
        callback = function()
          if vim.bo.modified then
            lint_file()
          end
        end,
      })

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = lint_augroup,
        callback = function()
          if timer then
            timer:stop()
            timer:close()
          end
        end,
      })
    end,
  },
}
