return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Configure linters by filetype
    lint.linters_by_ft = {
      -- Python
      python = { "pylint", "mypy" },
      
      -- Go
      go = { "golangcilint" },
      
      -- JavaScript/TypeScript (using Biome)
      javascript = { "biome" },
      typescript = { "biome" },
      javascriptreact = { "biome" },
      typescriptreact = { "biome" },
      
      -- Web technologies
      html = { "htmlhint" },
      css = { "stylelint" },
      scss = { "stylelint" },
      json = { "jsonlint" },
      yaml = { "yamllint" },
      
      -- Shell
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      fish = { "fish" },
      
      -- Lua
      lua = { "luacheck" },
      
      -- Other languages
      rust = { "clippy" },
      c = { "cppcheck" },
      cpp = { "cppcheck" },
      dockerfile = { "hadolint" },
      sql = { "sqlfluff" },
      
      -- Markdown
      markdown = { "markdownlint" },
      
      -- Use the "*" filetype to run linters on all filetypes
      -- ["*"] = { "codespell" }, -- Disabled - install codespell if needed
    }

    -- Custom linter configurations
    local function get_python_path()
      -- Try to get python path from virtual environment
      local venv = os.getenv("VIRTUAL_ENV")
      if venv then
        return venv .. "/bin/python"
      end
      return "python3"
    end

    -- Configure specific linters
    lint.linters.pylint.cmd = get_python_path()
    lint.linters.mypy.cmd = get_python_path()
    
    -- Configure golangci-lint
    lint.linters.golangcilint = {
      cmd = "golangci-lint",
      stdin = false,
      args = {
        "run",
        "--out-format",
        "json",
        "--issues-exit-code=1",
        "--path-prefix",
        function()
          return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
        end,
      },
      stream = "stdout",
      ignore_exitcode = true,
      parser = function(output, bufnr)
        local decoded = vim.json.decode(output)
        local diagnostics = {}
        
        if decoded and decoded.Issues then
          for _, issue in ipairs(decoded.Issues) do
            table.insert(diagnostics, {
              lnum = issue.Pos.Line - 1,
              col = issue.Pos.Column - 1,
              end_lnum = issue.Pos.Line - 1,
              end_col = issue.Pos.Column,
              severity = vim.diagnostic.severity.WARN,
              message = issue.Text,
              source = "golangci-lint",
              code = issue.FromLinter,
            })
          end
        end
        
        return diagnostics
      end,
    }
    
    -- Configure ESLint to use project-specific config
    lint.linters.eslint_d.args = {
      "--no-warn-ignored",
      "--format",
      "json",
      "--stdin",
      "--stdin-filename",
      function()
        return vim.api.nvim_buf_get_name(0)
      end,
    }

    -- Debounced lint function for better performance
    local function debounce(ms, fn)
      local timer = vim.uv.new_timer()
      return function(...)
        local argv = { ... }
        timer:start(ms, 0, function()
          timer:stop()
          vim.schedule_wrap(fn)(unpack(argv))
        end)
      end
    end

    -- Smart lint function that respects project configuration
    local function lint_buffer()
      local ft = vim.bo.filetype
      local filename = vim.api.nvim_buf_get_name(0)
      
      -- Skip linting for certain conditions
      if filename == "" or vim.bo.buftype ~= "" then
        return
      end
      
      -- Get linters for current filetype
      local names = lint._resolve_linter_by_ft(ft)
      
      -- Add fallback linters if no specific ones found
      if #names == 0 then
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
      end
      
      -- Add global linters
      vim.list_extend(names, lint.linters_by_ft["*"] or {})
      
      -- Filter linters based on availability and conditions
      local ctx = { filename = filename, dirname = vim.fn.fnamemodify(filename, ":h") }
      
      names = vim.tbl_filter(function(name)
        local linter = lint.linters[name]
        if not linter then
          return false
        end
        
        -- Check if linter has a condition function
        if type(linter) == "table" and linter.condition then
          return linter.condition(ctx)
        end
        
        return true
      end, names)
      
      -- Run linters
      if #names > 0 then
        lint.try_lint(names)
      end
    end

    -- Create autocommand group for linting
    local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

    -- Set up autocommands with debouncing for better performance
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = debounce(100, lint_buffer),
    })

    -- Additional autocommand for text changes (with longer debounce)
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = lint_augroup,
      callback = debounce(500, lint_buffer),
    })

    -- Create user commands
    vim.api.nvim_create_user_command("Lint", lint_buffer, {
      desc = "Trigger linting for current buffer",
    })
    
    vim.api.nvim_create_user_command("LintInfo", function()
      local ft = vim.bo.filetype
      local linters = lint.linters_by_ft[ft] or {}
      if #linters == 0 then
        vim.notify("No linters configured for filetype: " .. ft, vim.log.levels.INFO)
      else
        vim.notify("Linters for " .. ft .. ": " .. table.concat(linters, ", "), vim.log.levels.INFO)
      end
    end, {
      desc = "Show configured linters for current filetype",
    })
  end,
}
