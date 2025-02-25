return {
  {
    "stevearc/conform.nvim",
    event = "BufReadPre",
    lazy = true,
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          local conform = require("conform")
          -- Save cursor position
          local cursor = vim.api.nvim_win_get_cursor(0)
          conform.format({ async = true, lsp_fallback = true })
          -- Restore cursor position after format
          vim.schedule(function()
            pcall(vim.api.nvim_win_set_cursor, 0, cursor)
          end)
        end,
        desc = "󰉢 Format",
      },
    },
    opts = {
      -- Define formatters per filetype
      formatters_by_ft = {
        lua = { "stylua" },
        -- Frontend - Using the new syntax with stop_after_first option
        javascript = { "biome", "prettier" },
        typescript = { "biome", "prettier" },
        javascriptreact = { "biome", "prettier" },
        typescriptreact = { "biome", "prettier" },
        json = { "biome", "prettier" },
        jsonc = { "biome", "prettier" },
        -- Prettier-only formats
        vue = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        yaml = { "prettier" },
        -- Go
        go = { "gofumpt", "goimports" },
        -- Shell
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        -- Python
        python = { "isort", "black" },
        -- Rust
        rust = { "rustfmt" },
      },
      -- NEW: This option allows nvim to stop after the first successful formatter
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
        stop_after_first = true, -- This will make conform try biome first, then prettier
      },
      formatters = {
        biome = {
          condition = (function()
            local biome_cache = {}
            return function(ctx)
              local file_path = ctx.filename
              local root_dir = vim.fn.fnamemodify(file_path, ":h")

              if biome_cache[root_dir] ~= nil then
                return biome_cache[root_dir]
              end

              -- Check for biome config files
              local has_biome = vim.fn.findfile("biome.json", root_dir .. ";") ~= ""
                or vim.fn.findfile("biome.jsonc", root_dir .. ";") ~= ""

              -- Fallback to executable check if no config found
              if not has_biome then
                has_biome = vim.fn.executable("biome") == 1
              end

              biome_cache[root_dir] = has_biome
              return has_biome
            end
          end)(),
        },
        prettier = {
          condition = function(ctx)
            local file_path = ctx.filename
            local root_dir = vim.fn.fnamemodify(file_path, ":h")

            return vim.fn.findfile(".prettierrc", root_dir .. ";") ~= ""
              or vim.fn.findfile(".prettierrc.js", root_dir .. ";") ~= ""
              or vim.fn.findfile(".prettierrc.json", root_dir .. ";") ~= ""
              or vim.fn.findfile(".prettierrc.yml", root_dir .. ";") ~= ""
              or vim.fn.findfile("prettier.config.js", root_dir .. ";") ~= ""
              or vim.fn.glob(root_dir .. "/package.json") ~= "" -- might have prettier config
          end,
        },
        shfmt = {
          args = { "-i", "2", "-ci" },
        },
        black = {
          args = { "--fast" },
        },
      },
      notify_on_error = false,
      cache_disabled = false,
    },
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    opts = {
      events = { "BufWritePost", "InsertLeave" },
      linters_by_ft = {
        fish = { "fish" },
        lua = { "luacheck" },
        python = { "flake8" },
        javascript = { "eslint" },
        typescript = { "eslint" },
        javascriptreact = { "eslint" },
        typescriptreact = { "eslint" },
        go = { "golangci_lint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
        markdown = { "markdownlint" },
        -- Use the "*" filetype to run linters on all filetypes.
        -- ['*'] = { 'global linter' },
        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        -- ['_'] = { 'fallback linter' },
        -- ["*"] = { "typos" }, -- Uncomment if you want typo checking everywhere
      },
      -- LazyVim extension to easily override linter options
      -- or add custom linters.
      ---@type table<string,table>
      linters = {
        -- More efficient ESLint configuration
        eslint = {
          condition = function(ctx)
            -- First check if eslint is installed
            if vim.fn.executable("eslint") == 0 then
              return false
            end

            -- Then check for config files
            return vim.fs.find({
              ".eslintrc.js",
              ".eslintrc.json",
              ".eslintrc.yml",
              ".eslintrc",
              ".eslintrc.cjs",
              "eslint.config.js", -- For new flat config format
            }, { path = ctx.filename, upward = true })[1] ~= nil or             
            -- Check for eslint config in package.json
            (function()
              local package_json = vim.fs.find("package.json", { path = ctx.filename, upward = true })[1]
              if package_json then
                local content = vim.fn.readfile(package_json)
                local json_content = table.concat(content, "\n")
                return json_content:find('"eslintConfig"') ~= nil
              end
              return false
            end)()
          end,
        },
        luacheck = {
          condition = function(ctx)
            return vim.fs.find({
              ".luacheckrc",
            }, { path = ctx.filename, upward = true })[1] ~= nil
          end,
        },
        shellcheck = {
          args = { "--shell=bash", "--severity=warning" },
        },
      },
    },
    config = function(_, opts)
      local M = {}

      local lint = require("lint")
      for name, linter in pairs(opts.linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
          if type(linter.prepend_args) == "table" then
            lint.linters[name].args = lint.linters[name].args or {}
            vim.list_extend(lint.linters[name].args, linter.prepend_args)
          end
        else
          lint.linters[name] = linter
        end
      end
      lint.linters_by_ft = opts.linters_by_ft

      -- Improved debouncing with variable timeout based on event
      function M.debounce(ms, fn)
        local timer = vim.loop.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(function()
              fn(unpack(argv))
            end)()
          end)
        end
      end

      function M.lint()
        -- Use nvim-lint's logic first:
        -- * checks if linters exist for the full filetype first
        -- * otherwise will split filetype by "." and add all those linters
        -- * this differs from conform.nvim which only uses the first filetype that has a formatter
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)

        -- Create a copy of the names table to avoid modifying the original.
        names = vim.list_extend({}, names)

        -- Add fallback linters.
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft["_"] or {})
        end

        -- Add global linters.
        vim.list_extend(names, lint.linters_by_ft["*"] or {})

        -- Filter out linters that don't exist or don't match the condition.
        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            -- Reduced notification verbosity for performance
            if not vim.g.suppress_lint_warnings then
              vim.notify("Linter not found: " .. name, vim.log.levels.WARN, {
                title = "nvim-lint",
              })
            end
            return false
          end
          return not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
        end, names)

        -- Run linters.
        if #names > 0 then
          lint.try_lint(names)
        end
      end

      -- Variable debounce times based on event type
      local event_debounce = {
        BufWritePost = 50, -- Quick response after saving
        InsertLeave = 300, -- More delay for better performance while typing
      }

      -- Create autocmds with variable debounce times
      for _, event in ipairs(opts.events) do
        vim.api.nvim_create_autocmd(event, {
          group = vim.api.nvim_create_augroup("nvim-lint-" .. event, { clear = true }),
          callback = M.debounce(event_debounce[event] or 100, M.lint),
        })
      end
    end,
  },
}
