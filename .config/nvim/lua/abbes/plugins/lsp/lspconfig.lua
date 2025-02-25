return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre", -- Load earlier for better responsiveness
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Set up capabilities
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      -- Disable file watcher for performance
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

        -- Set up keymaps
        km.set("n", "K", vim.lsp.buf.hover, opts)
        km.set("n", "gd", vim.lsp.buf.definition, opts)
        km.set("n", "gD", vim.lsp.buf.declaration, opts)
        km.set("n", "gi", vim.lsp.buf.implementation, opts)
        km.set("n", "go", vim.lsp.buf.type_definition, opts)
        km.set("n", "gr", vim.lsp.buf.references, opts)
        km.set("n", "gs", vim.lsp.buf.signature_help, opts)
        km.set("n", "<F2>", vim.lsp.buf.rename, opts)

        -- Use conform.nvim for formatting instead of LSP
        -- This avoids conflicts with your formatting config
        km.set({ "n", "x" }, "<F3>", function()
          require("conform").format({ async = true, lsp_fallback = true })
        end, opts)

        km.set("n", "<F4>", vim.lsp.buf.code_action, opts)

        -- Disable LSP formatting when using conform.nvim
        if client.name ~= "null-ls" then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end

      -- Configure LSP servers
      local lspconfig = require("lspconfig")

      -- Lua LSP with optimized settings
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
              -- Improve performance with max files
              maxPreload = 2000,
              preloadFileSize = 1000,
            },
            telemetry = { enable = false },
            -- Let conform.nvim handle formatting
            format = { enable = false },
          },
        },
      })

      -- TypeScript/JavaScript with optimized settings
      lspconfig.vtsls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = {
              completeFunctionCalls = true,
            },
            -- Performance optimizations
            disableAutomaticTypeAcquisition = true,
          },
          javascript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = {
              completeFunctionCalls = true,
            },
          },
          -- Let conform.nvim handle formatting
          documentFormatting = false,
          format = { enable = false },
        },
        -- Speed up startup
        init_options = {
          hostInfo = "neovim",
          maxTsServerMemory = 4096,
          disableAutomaticTypingAcquisition = true,
        },
      })

      -- Go with optimized settings
      lspconfig.gopls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          gopls = {
            gofumpt = false, -- Let conform.nvim handle this
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            -- Performance optimizations
            buildFlags = { "-tags=integration" },
            expandWorkspaceToModule = false,
            experimentalWorkspaceModule = false,
            allowImplicitNetworkAccess = false,
            allowModfileModifications = true,
            collectUsage = false, -- Reduce memory usage
            directoryFilters = { "-node_modules", "-vendor" },
          },
        },
      })

      -- Rust with optimized settings
      lspconfig.rust_analyzer.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              buildScripts = {
                enable = false, -- Improves performance
              },
              features = "all",
            },
            procMacro = {
              enable = true,
            },
            -- Performance optimizations
            checkOnSave = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            diagnostics = {
              disabled = { "unresolved-proc-macro" },
            },
          },
        },
      })

      -- Python with optimized settings
      lspconfig.pyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
              -- Performance optimizations
              typeCheckingMode = "basic",
              indexing = false,
              inlayHints = {
                variableTypes = false,
                functionReturnTypes = false,
              },
            },
          },
        },
      })

      -- Other LSPs with default config (avoid duplicates)
      local servers = {
        "clangd",
        "astro",
        "graphql",
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "vuels",
        "yamlls",
        "prismals",
      }

      for _, server in ipairs(servers) do
        if
          not (
            server == "lua_ls"
            or server == "vtsls"
            or server == "gopls"
            or server == "rust_analyzer"
            or server == "pyright"
          )
        then
          lspconfig[server].setup({
            on_attach = on_attach,
            capabilities = capabilities,
          })
        end
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

      -- Optimize LSP UI
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

      vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

      -- Performance optimization for LSP diagnostics
      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●" },
        severity_sort = true,
        update_in_insert = false, -- Improves performance while typing
        underline = true,
        float = { border = "rounded" },
      })
    end,
  },
}
