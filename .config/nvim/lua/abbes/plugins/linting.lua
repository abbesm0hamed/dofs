return {
  "mfussenegger/nvim-lint",
  opts = function()
    -- Helper function to determine Go linters based on executables. Good practice.
    local function get_go_linters()
      local linters = {}
      if vim.fn.executable("golangci-lint") == 1 then
        table.insert(linters, "golangci_lint")
      elseif vim.fn.executable("staticcheck") == 1 then
        table.insert(linters, "staticcheck")
        -- You might also want to include 'go vet' as a very basic linter.
        -- table.insert(linters, "govet")
      end
      return linters
    end

    -- Centralized definition of common condition checks.
    local function has_config_file(ctx, filenames)
      return vim.fs.find(filenames, { path = ctx.filename, upward = true })[1]
    end

    return {
      linters_by_ft = {
        lua = { "luacheck" },
        python = { "ruff", "mypy" },
        -- eslint_d should be sufficient for JS/TS/JSX.
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        go = get_go_linters(),
        sh = { "shellcheck" },
        dockerfile = { "hadolint" },
        yaml = { "yamllint" },
        json = { "jsonlint" },
        -- Add other filetypes as needed, e.g., markdown = { "markdownlint" }
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
              -- Add more if your project uses them, e.g., package.json for eslint config in root.
            }
            return has_config_file(ctx, eslint_files)
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
            -- The function for the filename is correct here.
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
          },
          timeout = 30000, -- 30 seconds, quite generous. Adjust if too slow.
          ignore_exitcode = true,
          -- Add a condition for golangci-lint if you have a specific config file for it.
          -- condition = function(ctx)
          --   return has_config_file(ctx, { ".golangci.yml", ".golangci.yaml" })
          -- end,
        },
        luacheck = {
          condition = function(ctx)
            return has_config_file(ctx, { ".luacheckrc" })
          end,
        },
        mypy = {
          condition = function(ctx)
            local mypy_files = { "mypy.ini", ".mypy.ini", "pyproject.toml", "setup.cfg" }
            return has_config_file(ctx, mypy_files)
          end,
        },
        ruff = {
          -- Ruff often uses pyproject.toml or .ruff.toml.
          condition = function(ctx)
            return has_config_file(ctx, { "pyproject.toml", ".ruff.toml" })
          end,
        },
        -- Add a general 'jsonlint' configuration if it needs specific args or conditions.
        jsonlint = {
          -- args = { "--compact" }, -- Example argument
        },
        -- Add 'yamllint' configuration.
        yamllint = {
          -- args = { "-f", "parsable" }, -- Example for parsable output
          condition = function(ctx)
            return has_config_file(ctx, { ".yamllint" }) -- Common yamllint config file
          end,
        },
        -- Add 'hadolint' configuration if you need specific args.
        hadolint = {
          -- args = { "--no-color" }, -- Example
        },
        -- Add 'shellcheck' configuration if needed.
        shellcheck = {
          -- args = { "-f", "json" }, -- Example for JSON output
        },
      },
    }
  end,
  -- Configuration function. This is where you set up autocmds and apply options.
  config = function(_, opts)
    local lint = require("lint")
    local resolved_opts = type(opts) == "function" and opts() or opts

    -- Apply linters_by_ft.
    lint.linters_by_ft = resolved_opts.linters_by_ft

    -- Merge linter configurations. This is correctly done.
    for name, config in pairs(resolved_opts.linters or {}) do
      if lint.linters[name] then
        lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], config)
      else
        -- If a linter is defined in your opts.linters but not in lint.linters,
        -- it means it's a custom linter or a linter not shipped by default.
        -- You should define it fully in your config or ensure it's a recognized linter.
        lint.linters[name] = config
      end
    end

    -- Use a single timer instance managed by the plugin's config scope.
    local timer = vim.uv.new_timer()
    local lint_in_progress = false

    local function lint_file()
      if lint_in_progress or not vim.api.nvim_buf_is_valid(0) or vim.bo.buftype ~= "" then
        return
      end

      -- Stop any pending timers to avoid multiple lint runs.
      timer:stop()

      -- Start a new timer to debounce linting calls.
      timer:start(200, 0, function()
        vim.schedule(function()
          lint_in_progress = true
          local bufnr = vim.api.nvim_get_current_buf()
          local filetype = vim.bo[bufnr].filetype

          local ok, err = pcall(function()
            -- Directly call lint.try_lint(). The timeout handling for golangci-lint
            -- should be part of its linter definition's `timeout` option,
            -- not a global `vim.g.lint_timeout` which isn't standard `nvim-lint` API.
            -- The `timeout` in the `golangci_lint` linter definition is the correct way.
            lint.try_lint()
          end)

          if not ok then
            local error_msg = tostring(err)
            -- More specific error messages for better user feedback.
            if error_msg:match("timeout") then
              vim.notify("Linting timeout for " .. filetype .. ": " .. error_msg, vim.log.levels.WARN)
            elseif error_msg:match("golangci%-lint") then
              vim.notify("golangci-lint error for " .. filetype .. ": " .. error_msg, vim.log.levels.WARN)
            else
              vim.notify("Linting error for " .. filetype .. ": " .. error_msg, vim.log.levels.ERROR)
            end
          end
          lint_in_progress = false
        end)
      end)
    end

    -- Create an autocmd group for nvim-lint related autocmds.
    local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

    -- Trigger linting on buffer read and write.
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = lint_augroup,
      callback = lint_file,
    })

    -- Trigger linting when leaving insert mode if the buffer is modified.
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = lint_augroup,
      callback = function()
        if vim.bo.modified then
          lint_file()
        end
      end,
    })

    -- Ensure the timer is closed when Neovim exits.
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = lint_augroup,
      callback = function()
        if timer then
          timer:stop()
          timer:close()
          timer = nil -- Nil out the reference to prevent use-after-free
        end
      end,
    })

    -- Initial lint on BufRead for the current buffer if it's already loaded
    -- when the plugin loads (e.g., if you opened Neovim with a file).
    -- This needs to be outside the `config` function if `event = "LazyFile"` is used
    -- because `LazyFile` means the plugin is loaded *when a file is opened*,
    -- so the `BufReadPost` will already have fired for the initial file.
    -- However, if `LazyFile` loads it *later* (e.g., first write), then this
    -- might be useful for existing buffers.
    -- For consistency, relying on `BufReadPost` autocmd is generally sufficient.
  end,
}
