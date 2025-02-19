return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Set up capabilities
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Disable file watcher
      capabilities.workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = false,
        },
      }

      -- Make capabilities available globally
      vim.g.lsp_capabilities = capabilities

      -- LSP attach function
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr }
        local km = vim.keymap

        km.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
        km.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
        km.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
        km.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
        km.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
        km.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
        km.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
        km.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
        km.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
        km.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)

        -- Set up formatting on save
        if client.server_capabilities.documentFormattingProvider then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false, timeout_ms = 10000 })
            end,
          })
        end
      end

      -- Configure LSP servers
      local lspconfig = require("lspconfig")

      -- Lua LSP
      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
            format = {
              enable = true,
              defaultConfig = {
                indent_style = "space",
                indent_size = "4",
              },
            },
          },
        },
      })

      -- TypeScript/JavaScript
      lspconfig.vtsls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          documentFormatting = true,
          format = { enable = true },
        },
      })

      -- Other LSPs with default config
      local servers = {
        "gopls",
        "lua_ls",
        "vtsls",
        "clangd",
        "rust_analyzer",
        "astro",
        "graphql",
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "vuels",
        "yamlls",
        "prismals",
        "pyright",
      }

      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

      -- Special setup for emmet_ls
      lspconfig.emmet_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        filetypes = {
          "html",
          "typescriptreact",
          "javascriptreact",
          "astro",
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
    end,
  },
}

