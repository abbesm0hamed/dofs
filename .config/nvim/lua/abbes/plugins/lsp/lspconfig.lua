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
    branch = "v3.x",
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
      local lsp = require("lsp-zero").preset({})
      vim.g.mapleader = " "

      lsp.on_attach(function(client, bufnr)
        lsp.default_keymaps({ buffer = bufnr })
        vim.keymap.set({ "n", "v" }, "<space>ca", "<cmd>vim.lsp.buf.code_action<cr>", { buffer = bufnr })
        lsp.buffer_autoformat()
      end)

      require("lspconfig").lua_ls.setup({})
      require("lspconfig").tsserver.setup({})
      require("lspconfig").rust_analyzer.setup({})

      lsp.setup()

      local cmp = require("cmp")

      require("luasnip.loaders.from_vscode").lazy_load()

      lsp.format_on_save({
        format_opts = {
          async = false,
          timeout_ms = 10000,
        },
        servers = {
          ["tsserver"] = { "javascript", "typescript" },
          ["rust_analyzer"] = { "rust" },
          ["gopls"] = { "go" },
        },
      })

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
        },
        mapping = {
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-j>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_next_item({ behavior = 'insert' })
            else
              cmp.complete()
            end
          end),
          ["<C-k>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.select_prev_item({ behavior = 'insert' })
            else
              cmp.complete()
            end
          end),
        },
        -- window = {
        --   completion = cmp.config.window.bordered(),
        --   documentation = cmp.config.window.bordered(),
        -- },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
      })
    end,
  },
}
