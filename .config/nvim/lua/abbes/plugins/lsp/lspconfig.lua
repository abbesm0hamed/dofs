return {
  {
    "VonHeikemen/lsp-zero.nvim",
    event = "VeryLazy",
    cmd = "Mason",
    branch = "v4.x",
    dependencies = {
      -- LSP Support
      { 
        "neovim/nvim-lspconfig",
        event = "VeryLazy",
        config = function()
          -- Set up capabilities properly
          local capabilities = vim.lsp.protocol.make_client_capabilities()
          capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
          
          -- Disable file watcher
          capabilities.workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = false
            }
          }
          
          -- Make capabilities available globally
          vim.g.lsp_capabilities = capabilities
        end,
      },
      { 
        "williamboman/mason.nvim",
        cmd = "Mason",
        opts = {
          ui = { border = "rounded" },
          max_concurrent_installers = 4,
        },
      },
      { 
        "williamboman/mason-lspconfig.nvim",
        event = "VeryLazy",
      },
      -- Autocompletion
      { 
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
          { "hrsh7th/cmp-buffer", event = "InsertEnter" },
          { "hrsh7th/cmp-path", event = "InsertEnter" },
          { "saadparwaiz1/cmp_luasnip", event = "InsertEnter" },
          { "hrsh7th/cmp-nvim-lsp", event = "InsertEnter" },
          { "hrsh7th/cmp-nvim-lua", ft = "lua" },
        },
        opts = {
          preselect = "none",
          completion = {
            completeopt = "menu,menuone,noinsert,noselect"
          },
        },
      },
      -- Snippets
      { 
        "L3MON4D3/LuaSnip",
        event = "InsertEnter",
        dependencies = {
          { "rafamadriz/friendly-snippets", event = "InsertEnter" },
        },
        config = function()
          require("luasnip").setup({
            history = false,
            update_events = "TextChanged,TextChangedI",
          })
        end,
      },
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
        capabilities = vim.g.lsp_capabilities,
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
          eslint = function()
            require("lspconfig").eslint.setup({
              on_attach = lsp_attach,
              capabilities = vim.g.lsp_capabilities,
              filetypes = {
                "javascript",
                "javascriptreact",
                "javascript.jsx",
                "typescript",
                "typescriptreact",
                "typescript.tsx",
                "vue",
                "svelte",
                "astro"
              },
            })
          end,
        },
      })

      local cmp = require("cmp")
      local cmp_select = lsp_zero.cmp_action()
      local winhighlight = {
        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel",
      }

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        sources = {
          { name = "path" },
          { name = "nvim_lsp" },
          { name = "nvim_lua" },
          { name = "luasnip", keyword_length = 2 },
          { name = "buffer",  keyword_length = 3 },
        },
        window = {
          --   completion = cmp.config.window.bordered({
          --     winhighlight = winhighlight.winhighlight,
          --     border = "single",
          --     side_padding = 0,
          --   }),
          --   documentation = cmp.config.window.bordered({
          --     winhighlight = winhighlight.winhighlight,
          --     border = "single",
          --     side_padding = 1,
          --   }),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
          ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<Tab>"] = cmp_select.luasnip_supertab(),
          ["<S-Tab>"] = cmp_select.luasnip_shift_supertab(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),

          ["<C-j>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_next_item({ behavior = "insert" })
            else
              cmp.complete()
            end
          end),
          ["<C-k>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_prev_item({ behavior = "insert" })
            else
              cmp.complete()
            end
          end),
        }),
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
      })

      lsp_zero.setup()
      -- Setup individual language servers
      local lspconfig = require("lspconfig")

      lspconfig.vtsls.setup({})
      lspconfig.gopls.setup({})
      lspconfig.rust_analyzer.setup({})
      lspconfig.astro.setup({})
      lspconfig.graphql.setup({})
      lspconfig.emmet_ls.setup({
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

      -- Format on save
      lsp_zero.format_on_save({
        format_opts = {
          async = false,
          timeout_ms = 10000,
        },
        servers = {
          ["lua_ls"] = { "lua" },
          ["vtsls"] = {
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
            "astro",
            "svelte",
            "vue",
          },
        },
      })

      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
