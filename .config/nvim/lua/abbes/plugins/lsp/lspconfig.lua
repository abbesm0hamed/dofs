local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- Auto-install lazy.nvim if not present
if vim.fn.empty(vim.fn.glob(lazypath)) > 0 then
  print("Installing lazy.nvim....")
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

return {
  -- {
  --   "folke/neodev.nvim",
  --   event = { "BufReadPre", "BufNewFile" },
  --   config = function()
  --     local neodev_status_ok, neodev = pcall(require, "neodev")
  --
  --     if not neodev_status_ok then
  --       return
  --     end
  --
  --     neodev.setup()
  --   end,
  -- },
  {
    "VonHeikemen/lsp-zero.nvim",
    event = {
      "BufReadPre",
      "BufNewFile",
    },
    cmd = "Mason",
    branch = "v4.x",
    dependencies = {
      -- LSP Support
      { "neovim/nvim-lspconfig" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      -- Autocompletion
      { "saghen/blink.cmp" },
      -- { "hrsh7th/nvim-cmp" },
      -- { "hrsh7th/cmp-buffer" },
      -- { "hrsh7th/cmp-path" },
      -- { "saadparwaiz1/cmp_luasnip" },
      -- { "hrsh7th/cmp-nvim-lsp" },
      -- { "hrsh7th/cmp-nvim-lua" },
      -- Snippets
      { "L3MON4D3/LuaSnip" },
      { "rafamadriz/friendly-snippets" },
    },
    config = function()
      vim.g.mapleader = " "

      local lsp_zero = require("lsp-zero")
      local lsp_attach = function(client, bufnr)
        local opts = { buffer = bufnr }

        vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
        vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
        vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
        vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
        vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
        vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
        vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
        vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
        vim.keymap.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
        vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
      end

      lsp_zero.extend_lspconfig({
        sign_text = true,
        lsp_attach = lsp_attach,
        float_border = "rounded",
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        -- capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      require("mason").setup({})
      require("mason-lspconfig").setup({
        ensure_installed = {},
        handlers = {
          lsp_zero.default_setup,
          lua_ls = function()
            local lua_opts = lsp_zero.nvim_lua_ls()
            require("lspconfig").lua_ls.setup(vim.tbl_deep_extend("force", lua_opts, {
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { "vim" },
                  },
                  workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                  },
                  telemetry = {
                    enable = false,
                  },
                  format = {
                    enable = true,
                    defaultConfig = {
                      indent_style = "space",
                      indent_size = "4",
                    },
                  },
                },
              },
            }))
          end,
        },
      })

      -- local cmp = require("cmp")
      local cmp = require("cmp")
      local blink_cmp = require("blink.cmp")

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "path" },
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer", keyword_length = 3 },
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        capabilities = blink_cmp.get_lsp_capabilities(), -- Use blink's LSP capabilities
      })

      lsp_zero.setup()
      require("luasnip.loaders.from_vscode").lazy_load()
      -- Language server setup
      local lspconfig = require("lspconfig")

      lspconfig.ts_ls.setup({})
      lspconfig.gopls.setup({})
      lspconfig.rust_analyzer.setup({})
      lspconfig.astro.setup({})
      lspconfig.graphql.setup({})
      lspconfig.emmet_ls.setup({
        filetypes = {
          "html",
          "typescriptreact",
          "javascriptreact",
          "typescript",
          "javascript",
          "css",
          "astro",
          "sass",
          "scss",
          "less",
          "svelte",
          "vue",
        },
        init_options = {
          html = {
            options = {
              ["bem.enabled"] = true,
            },
          },
        },
      })

      lsp_zero.format_on_save({
        format_opts = {
          async = false,
          timeout_ms = 10000,
        },
        servers = {
          ["lua_ls"] = { "lua" },
          ["ts_ls"] = {
            "javascript",
            "typescript",
            "typescriptreact",
            "javascriptreact",
          },
          ["rust_analyzer"] = { "rust" },
          ["gopls"] = { "go" },
          ["emmet_ls"] = {
            "html",
            "typescriptreact",
            "javascriptreact",
            "typescript",
            "javascript",
            "css",
            "astro",
            "sass",
            "scss",
            "less",
            "svelte",
            "vue",
          },
        },
      })

      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
