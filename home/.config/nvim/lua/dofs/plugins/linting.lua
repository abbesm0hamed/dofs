return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  opts = function()
    local function get_go_linters()
      local linters = {}
      if vim.fn.executable("golangcilint") == 1 then
        table.insert(linters, "golangci_lint")
      elseif vim.fn.executable("staticcheck") == 1 then
        table.insert(linters, "staticcheck")
      end
      return linters
    end

    local function has_config_file(ctx, filenames)
      return vim.fs.find(filenames, { path = ctx.filename, upward = true })[1]
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
            return has_config_file(ctx, eslint_files)
          end,
        },
        golangci_lint = {
          cmd = "golangci-lint",
          args = function()
            return {
              "run",
              "--out-format=json",
              "--issues-exit-code=1",
              "--print-issued-lines=false",
              "--print-linter-name=false",
              "--timeout=5m",
              vim.api.nvim_buf_get_name(0),
            }
          end,
          stream = "stdout",
          ignore_exitcode = true,
          timeout = 30000,
        },
        luacheck = {
          condition = function(ctx)
            return has_config_file(ctx, { ".luacheckrc" })
          end,
        },
        mypy = {
          condition = function(ctx)
            return has_config_file(ctx, { "mypy.ini", ".mypy.ini", "pyproject.toml", "setup.cfg" })
          end,
        },
        ruff = {
          condition = function(ctx)
            return has_config_file(ctx, { "pyproject.toml", ".ruff.toml" })
          end,
        },
        yamllint = {
          condition = function(ctx)
            return has_config_file(ctx, { ".yamllint", ".yamllint.yaml", ".yamllint.yml" })
          end,
        },
        jsonlint = {},
        hadolint = {},
        shellcheck = {},
      },
    }
  end,
  config = function(_, opts)
    local lint = require("lint")
    local resolved_opts = type(opts) == "function" and opts() or opts

    lint.linters_by_ft = resolved_opts.linters_by_ft or {}

    for name, config in pairs(resolved_opts.linters or {}) do
      lint.linters[name] = lint.linters[name] and vim.tbl_deep_extend("force", lint.linters[name], config) or config
    end

    local timer = vim.uv.new_timer()
    local lint_in_progress = false

    local function lint_file()
      if lint_in_progress or not vim.api.nvim_buf_is_valid(0) or vim.bo.buftype ~= "" then
        return
      end

      timer:stop()

      timer:start(200, 0, function()
        vim.schedule(function()
          lint_in_progress = true
          local ok, err = pcall(lint.try_lint)

          if not ok then
            local filetype = vim.bo.filetype
            local msg = tostring(err)
            if msg:match("timeout") then
              vim.notify("Linting timeout: " .. msg, vim.log.levels.WARN)
            elseif msg:match("golangci%-lint") then
              vim.notify("golangci-lint error: " .. msg, vim.log.levels.WARN)
            else
              vim.notify("Lint error for " .. filetype .. ": " .. msg, vim.log.levels.ERROR)
            end
          end
          lint_in_progress = false
        end)
      end)
    end

    local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = group,
      callback = lint_file,
    })

    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group,
      callback = function()
        if vim.bo.modified then
          lint_file()
        end
      end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = function()
        if timer then
          timer:stop()
          timer:close()
          timer = nil
        end
      end,
    })
  end,
}
