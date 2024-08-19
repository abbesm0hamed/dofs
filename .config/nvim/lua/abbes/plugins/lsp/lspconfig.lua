local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

-- Auto-install lazy.nvim if not present
if not vim.uv.fs_stat(lazypath) then
  print('Installing lazy.nvim....')
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

return {
  {
    "folke/neodev.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local neodev_status_ok, neodev = pcall(require, "neodev")

      if not neodev_status_ok then
        return
      end

      neodev.setup()
    end,
  },
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
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "saadparwaiz1/cmp_luasnip" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      -- Snippets
      { "L3MON4D3/LuaSnip" },
      { "rafamadriz/friendly-snippets" },
    },
    config = function()
      vim.g.mapleader = " "

      local lsp_zero = require('lsp-zero')
      local lsp_attach = function(client, bufnr)
        local opts = { buffer = bufnr }

        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
      end

      lsp_zero.extend_lspconfig({
        sign_text = true,
        lsp_attach = lsp_attach,
        float_border = 'rounded',
        capabilities = require('cmp_nvim_lsp').default_capabilities()
      })

      require('mason').setup({})
      require('mason-lspconfig').setup({
        ensure_installed = {},
        handlers = {
          lsp_zero.default_setup,
          lua_ls = function()
            local lua_opts = lsp_zero.nvim_lua_ls()
            require('lspconfig').lua_ls.setup(vim.tbl_deep_extend('force', lua_opts, {
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { 'vim' }
                  },
                  workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false
                  },
                  telemetry = {
                    enable = false,
                  },
                  format = {
                    enable = true,
                    defaultConfig = {
                      indent_style = "space",
                      indent_size = "2",
                    }
                  }
                }
              }
            }))
          end,
        }
      })

      local cmp = require('cmp')
      local cmp_select = lsp_zero.cmp_action()
      local winhighlight = {
        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel",
      }

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        sources = {
          { name = 'path' },
          { name = 'nvim_lsp' },
          { name = 'nvim_lua' },
          { name = 'luasnip', keyword_length = 2 },
          { name = 'buffer',  keyword_length = 3 },
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
          ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
          ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-u>'] = cmp.mapping.scroll_docs(-4),
          ['<C-d>'] = cmp.mapping.scroll_docs(4),
          ['<Tab>'] = cmp_select.luasnip_supertab(),
          ['<S-Tab>'] = cmp_select.luasnip_shift_supertab(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),
          ['<CR>'] = cmp.mapping.confirm({ select = false }),

          ['<C-j>'] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_next_item({ behavior = 'insert' })
            else
              cmp.complete()
            end
          end),
          ['<C-k>'] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_prev_item({ behavior = 'insert' })
            else
              cmp.complete()
            end
          end),
        }),
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
      })

      lsp_zero.setup()
      -- Setup individual language servers
      local lspconfig = require('lspconfig')
      lspconfig.tsserver.setup({})
      lspconfig.gopls.setup({})
      lspconfig.rust_analyzer.setup({})
      lspconfig.astro.setup({})
      lspconfig.graphql.setup({})

      -- Format on save
      lsp_zero.format_on_save({
        format_opts = {
          async = false,
          timeout_ms = 10000,
        },
        servers = {
          ['lua_ls'] = { 'lua' },
          ['tsserver'] = { 'javascript', 'typescript' },
          ['rust_analyzer'] = { 'rust' },
          ['gopls'] = { 'go' },
        }
      })

      -- Load snippets
      require('luasnip.loaders.from_vscode').lazy_load()
    end,
  },
}
