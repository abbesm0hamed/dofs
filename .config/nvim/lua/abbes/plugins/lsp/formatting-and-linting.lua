local u = require("abbes.config.utils")
vim.g.mapleader = " "

-- use formatting from conform.nvim
local ftToFormatter = {
  applescript = { "trim_whitespace", "trim_newlines", "squeeze_blanks" },
  lua = { "stylua" },
  markdown = { "markdown-toc", "markdownlint", "injected" },
  sh = { "shfmt" },
  bib = { "bibtex-tidy" },
  css = { "squeeze_blanks" }, -- since the css formatter does not support that
  go = { "goimports", "gofumpt" },
  html = { "emmet-ls" },
}
-- use formatting from the LSP
local lspFormatFt = {
  "javascript",
  "typescript",
  "json",
  "jsonc",
  "toml",
  "yaml",
  "html",
  "python",
  "css",
  "go",
  "rs",
  "cpp",
}

local autoIndentFt = {
  "query",
  "applescript",
}

local function flatten(tbl)
  local result = {}
  for _, v in ipairs(tbl) do
    if type(v) == "table" then
      for _, inner in ipairs(flatten(v)) do
        table.insert(result, inner)
      end
    else
      table.insert(result, v)
    end
  end
  return result
end

local function listConformFormatters(formattersByFt)
  local notClis = { "trim_whitespace", "trim_newlines", "squeeze_blanks", "injected" }
  local formatters = flatten(vim.tbl_values(formattersByFt))
  formatters = vim.tbl_filter(function(f)
    return not vim.tbl_contains(notClis, f)
  end, formatters)
  table.sort(formatters)
  return vim.fn.uniq(formatters)
end

local conformOpts = {
  formatters_by_ft = ftToFormatter,
  format_on_save = {
    lsp_fallback = true,
    async = false,
    timeout_ms = 2000,
  },
  formatters = {
    ["bibtex-tidy"] = {
      prepend_args = {
        "--tab",
        "--curly",
        "--no-align",
        "--no-wrap",
        "--drop-all-caps",
        "--numeric",
        "--trailing-commas",
        "--no-escape",
        "--duplicates",
        "--sort-fields",
        "--remove-empty-fields",
        "--omit=month,issn,abstract",
      },
    },
  },
}

local function formattingFunc(bufnr)
  if not bufnr then
    bufnr = 0
  end
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if vim.bo[bufnr].buftype ~= "" or not vim.loop.fs_stat(bufname) or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local ft = vim.bo[bufnr].filetype
  local useLsp = vim.tbl_contains(lspFormatFt, ft) and "always" or false

  if string.match(bufname, "%.env$") then
    return
  end
  if vim.tbl_contains(autoIndentFt, ft) then
    u.normal("gg=G``")
  end

  if ft == "typescript" then
    local actions = {
      "source.fixAll.ts",
      "source.addMissingImports.ts",
      "source.removeUnusedImports.ts",
      "source.organizeImports.biome",
    }
    for i = 0, #actions do
      vim.defer_fn(function()
        if i < #actions then
          vim.lsp.buf.code_action({ context = { only = { actions[i] } }, apply = true })
        else
          require("conform").format({ lsp_fallback = useLsp })
        end
      end, i * 60)
    end
    return
  end

  require("conform").format({ lsp_fallback = useLsp }, function()
    if ft == "python" then
      vim.lsp.buf.code_action({ context = { only = { "source.fixAll.ruff" } }, apply = true })
    end
  end)
end

return {
  {
    "stevearc/conform.nvim",
    -- event = { "BufWritePre" },
    cmd = "ConformInfo",
    mason_dependencies = listConformFormatters(ftToFormatter),
    config = function()
      local conform = require("conform")
      require("conform.formatters.injected").options.ignore_errors = true
      conform.setup(conformOpts)
      vim.api.nvim_create_autocmd("FocusLost", {
        callback = function(ctx)
          formattingFunc(ctx.buf)
        end,
      })
    end,
    keys = {
      { "<leader>mp", formattingFunc, desc = "󰒕 Format & Save", mode = { "n", "v", "x" } },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    lazy = true,
    dependencies = { "jay-babu/mason-null-ls.nvim" },
    config = function()
      local mason_null_ls = require("mason-null-ls")
      local null_ls = require("null-ls")
      local null_ls_utils = require("null-ls.utils")

      mason_null_ls.setup({
        ensure_installed = {
          "prettier",
          "stylua",
          "eslint_d",
        },
        automatic_installation = true,
      })

      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics

      null_ls.setup({
        root_dir = null_ls_utils.root_pattern(".null-ls-root", "Makefile", ".git", "package.json"),
        sources = {
          formatting.prettier.with({
            extra_filetypes = {
              "svelte",
              "typescript",
              "typescriptreact",
            },
            extra_args = {
              "--single-quote",
              "--jsx-single-quote",
            },
          }),
          formatting.stylua,
          formatting.black,
          diagnostics.pylint,
          diagnostics.eslint_d.with({
            condition = function(utils)
              return utils.root_has_file({
                ".eslintrc.js",
                ".eslintrc.cjs",
              })
            end,
          }),
        },
      })
    end,
  },
}
