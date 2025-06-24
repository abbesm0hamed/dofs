return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities() or {}
      )

      capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
      capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
      capabilities.textDocument.colorProvider = { dynamicRegistration = false }

      vim.g.lsp_capabilities = capabilities

      local on_attach = function(client, bufnr)
        -- Performance: disable semantic tokens for large files
        if vim.api.nvim_buf_line_count(bufnr) > 1000 then
          client.server_capabilities.semanticTokensProvider = nil
        end

        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
        map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
        map("n", "go", vim.lsp.buf.type_definition, "Go to Type Definition")
        map("n", "gr", vim.lsp.buf.references, "Go to References")
        map("n", "gs", vim.lsp.buf.signature_help, "Signature Help")
        map("n", "<F2>", vim.lsp.buf.rename, "Rename Symbol")
        map("n", "<F4>", vim.lsp.buf.code_action, "Code Action")

        -- Format with conform fallback
        map({ "n", "v" }, "<F3>", function()
          local ok, conform = pcall(require, "conform")
          if ok then
            conform.format({ async = true, lsp_fallback = true })
          else
            vim.lsp.buf.format({ async = true })
          end
        end, "Format")

        if client.name ~= "null-ls" and client.name ~= "efm" then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end

        if vim.api.nvim_buf_line_count(bufnr) > 1000 then
          vim.lsp.codelens.refresh = function() end
        end
      end

      local lspconfig = require("lspconfig")

      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = {
              globals = { "vim" },
              disable = { "missing-fields" }, -- Reduce noise
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
              maxPreload = 1000, -- Reduced for performance
              preloadFileSize = 500, -- Reduced for performance
            },
            telemetry = { enable = false },
            format = { enable = false },
            completion = { callSnippet = "Replace" },
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
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
            },
          },
          javascript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
          },
        },
        init_options = {
          hostInfo = "neovim",
          maxTsServerMemory = 8192,
          preferences = {
            disableSuggestions = false,
            quotePreference = "auto",
          },
        },
      })

      lspconfig.gopls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          gopls = {
            gofumpt = true, -- Enable gofumpt for better formatting
            analyses = {
              unusedparams = true,
              shadow = true,
              fieldalignment = false, -- Can be noisy
            },
            staticcheck = true,
            buildFlags = { "-tags=integration" },
            expandWorkspaceToModule = false,
            usePlaceholders = true,
            completeUnimported = true,
            directoryFilters = {
              "-node_modules",
              "-vendor",
              "-.git",
              "-.vscode",
              "-.idea",
            },
            semanticTokens = true,
            codelenses = {
              gc_details = false, -- Disable for performance
              generate = true,
              regenerate_cgo = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
          },
        },
      })

      -- Rust Analyzer with performance optimizations
      lspconfig.rust_analyzer.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              buildScripts = { enable = true },
              features = "all",
              loadOutDirsFromCheck = true,
            },
            procMacro = {
              enable = true,
              attributes = { enable = true },
            },
            checkOnSave = {
              command = "clippy",
              extraArgs = { "--no-deps", "--target-dir", "/tmp/rust-analyzer-check" },
            },
            diagnostics = {
              disabled = { "unresolved-proc-macro" },
              experimental = { enable = false }, -- Disable for performance
            },
            completion = {
              addCallParenthesis = true,
              addCallArgumentSnippets = true,
            },
            inlayHints = {
              bindingModeHints = { enable = false },
              chainingHints = { enable = true },
              closingBraceHints = { enable = true, minLines = 25 },
              closureReturnTypeHints = { enable = "never" },
              lifetimeElisionHints = { enable = "never" },
              maxLength = 25,
              parameterHints = { enable = true },
              reborrowHints = { enable = "never" },
              renderColons = true,
              typeHints = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
            },
          },
        },
      })

      -- Python with Pyright
      lspconfig.pyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly", -- Better performance
              useLibraryCodeForTypes = true,
              typeCheckingMode = "basic",
              stubPath = vim.fn.stdpath("data") .. "/lazy/python-type-stubs",
            },
          },
        },
      })

      -- Batch setup for simple servers
      local simple_servers = {
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

      for _, server in ipairs(simple_servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end

      -- Emmet with expanded filetypes
      lspconfig.emmet_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        filetypes = {
          "html",
          "typescriptreact",
          "javascriptreact",
          "css",
          "sass",
          "scss",
          "less",
          "astro",
          "svelte",
          "vue",
          "templ",
        },
        init_options = {
          html = {
            options = {
              ["bem.enabled"] = true,
              ["output.selfClosingStyle"] = "html",
            },
          },
        },
      })

      -- Enhanced UI configuration
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
        max_width = 80,
        max_height = 20,
      })

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
        focusable = false,
        relative = "cursor",
      })

      -- Optimized diagnostic configuration
      vim.diagnostic.config({
        virtual_text = {
          spacing = 4,
          prefix = function(diagnostic)
            local icons = { "󰅚 ", "󰀪 ", "󰌶 ", "󰌵 " }
            return icons[diagnostic.severity] or "●"
          end,
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅚",
            [vim.diagnostic.severity.WARN] = "󰀪",
            [vim.diagnostic.severity.INFO] = "󰌶",
            [vim.diagnostic.severity.HINT] = "󰌵",
          },
        },
        severity_sort = true,
        update_in_insert = false,
        underline = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
          focusable = false,
        },
      })

      -- Performance: debounce LSP requests
      vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
        },
      })

      -- Auto-command for LSP optimization
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client then
            -- Disable hover in insert mode for better performance
            vim.api.nvim_create_autocmd("InsertEnter", {
              buffer = ev.buf,
              callback = function()
                vim.lsp.handlers["textDocument/hover"] = function() end
              end,
            })

            vim.api.nvim_create_autocmd("InsertLeave", {
              buffer = ev.buf,
              callback = function()
                vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
                  border = "rounded",
                })
              end,
            })
          end
        end,
      })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
      event = "InsertEnter",
    },
    opts = {
      history = false,
      update_events = { "TextChanged", "TextChangedI" },
      fs_event_providers = { autocmd = false, libuv = false },
      delete_check_events = "InsertLeave",
    },
    config = function(_, opts)
      require("luasnip").setup(opts)
      require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    end,
  },
}
