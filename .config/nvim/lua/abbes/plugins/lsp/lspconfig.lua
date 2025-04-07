return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
      vim.g.lsp_capabilities = capabilities

      -- LSP attach function
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr }
        local km = vim.keymap

        km.set("n", "K", vim.lsp.buf.hover, opts)
        km.set("n", "gd", vim.lsp.buf.definition, opts)
        km.set("n", "gD", vim.lsp.buf.declaration, opts)
        km.set("n", "gi", vim.lsp.buf.implementation, opts)
        km.set("n", "go", vim.lsp.buf.type_definition, opts)
        km.set("n", "gr", vim.lsp.buf.references, opts)
        km.set("n", "gs", vim.lsp.buf.signature_help, opts)
        km.set("n", "<F2>", vim.lsp.buf.rename, opts)
        km.set({ "n", "x" }, "<F3>", function()
          require("conform").format({ async = true, lsp_fallback = true })
        end, opts)
        km.set("n", "<F4>", vim.lsp.buf.code_action, opts)

        if client.name ~= "null-ls" then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end

      -- Configure LSP servers
      local lspconfig = require("lspconfig")

      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
              maxPreload = 2000,
              preloadFileSize = 1000,
            },
            telemetry = { enable = false },
            format = { enable = false },
          },
        },
      })

      lspconfig.vtsls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            disableAutomaticTypeAcquisition = true,
          },
          javascript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
          },
          documentFormatting = false,
          format = { enable = false },
        },
        init_options = {
          hostInfo = "neovim",
          maxTsServerMemory = 4096,
          disableAutomaticTypingAcquisition = true,
        },
      })

      lspconfig.gopls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          gopls = {
            gofumpt = false,
            analyses = { unusedparams = true },
            staticcheck = true,
            buildFlags = { "-tags=integration" },
            expandWorkspaceToModule = false,
            experimentalWorkspaceModule = false,
            allowImplicitNetworkAccess = false,
            allowModfileModifications = true,
            collectUsage = false,
            directoryFilters = { "-node_modules", "-vendor" },
          },
        },
      })

      lspconfig.rust_analyzer.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              buildScripts = { enable = false },
              features = "all",
            },
            procMacro = { enable = true },
            checkOnSave = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            diagnostics = { disabled = { "unresolved-proc-macro" } },
          },
        },
      })

      lspconfig.pyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
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
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

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
          html = { options = { ["bem.enabled"] = true } },
        },
      })

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●" },
        severity_sort = true,
        update_in_insert = false,
        underline = true,
        float = { border = "rounded" },
      })
    end,
  },
}