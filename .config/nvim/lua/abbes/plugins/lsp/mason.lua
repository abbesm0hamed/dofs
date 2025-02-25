return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        -- LSP servers
        "lua-language-server",
        "vtsls",
        "gopls",
        "rust-analyzer",
        "pyright",
        "emmet-ls",
        "tailwindcss-language-server",
        "html-lsp",
        "css-lsp",

        -- Formatters
        "stylua",
        "biome",
        "prettier",
        "gofumpt",
        "goimports",
        "shfmt",
        "isort",
        "black",

        -- Linters
        "luacheck",
        "eslint_d",
        "golangci-lint",
        "shellcheck",
        "flake8",
      },
      ui = {
        border = "rounded",
        width = 0.8,
        height = 0.8,
      },
      install_root_dir = vim.fn.stdpath("data") .. "/mason",
    },
    config = function(_, opts)
      require("mason").setup(opts)

      local registry = require("mason-registry")
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = registry.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end

      if registry.refresh then
        registry.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
  -- Mason-LSPConfig integration
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      automatic_installation = true,
    },
  },
}
