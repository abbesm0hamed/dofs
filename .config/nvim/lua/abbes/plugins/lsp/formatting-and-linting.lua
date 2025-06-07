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
      lint_delay = 100,
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
      format_on_save = function(bufnr)
        if vim.g.format_on_save == false then
          return
        end
        return {
          timeout_ms = 500,
          lsp_fallback = true,
          stop_after_first = true,
        }
      end,
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
          condition = (function()
            local prettier_cache = {}
            return function(ctx)
              local file_path = ctx.filename
              local root_dir = vim.fn.fnamemodify(file_path, ":h")

              if prettier_cache[root_dir] ~= nil then
                return prettier_cache[root_dir]
              end

              local has_prettier = vim.fn.findfile(".prettierrc", root_dir .. ";") ~= ""
                or vim.fn.findfile(".prettierrc.js", root_dir .. ";") ~= ""
                or vim.fn.findfile(".prettierrc.json", root_dir .. ";") ~= ""
                or vim.fn.findfile(".prettierrc.yml", root_dir .. ";") ~= ""
                or vim.fn.findfile("prettier.config.js", root_dir .. ";") ~= ""
                or vim.fn.glob(root_dir .. "/package.json") ~= ""

              prettier_cache[root_dir] = has_prettier
              return has_prettier
            end
          end)(),
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
      linters_by_ft = {
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
      },
      linters = {
        shellcheck = { args = { "--severity=warning" } },
      },
    },
    config = function(_, opts) -- Changed from *_*, *opts* to _, opts
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft
      for name, linter in pairs(opts.linters) do
        lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
      end
      local function lint_buffer()
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)
        if #names > 0 then
          lint.try_lint(names)
        end
      end
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("lint", { clear = true }),
        callback = function()
          vim.defer_fn(lint_buffer, 100)
        end,
      })
    end,
  },
}
