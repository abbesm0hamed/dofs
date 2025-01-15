return {
  {

    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
      },
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)
  
      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      auto_install = true,
    },
    config = function()
      local lsp_zero = require("lsp-zero")

      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        -- list of servers for mason to install
        ensure_installed = {
          "vtsls",
          "emmet_ls",
          "html",
          "cssls",
          "tailwindcss",
          "svelte",
          "lua_ls",
          "graphql",
          "gopls",
          "vuels",
          "yamlls",
          "prismals",
          "pyright",
        },
        -- auto-install configured servers (with lspconfig)
        automatic_installation = true, -- not the same as ensure_installed
        handlers = {
          lsp_zero.default_setup,
          vtsls = function()
            local lspconfig = require("lspconfig")

            lspconfig.vtsls.setup({
              single_file_support = false,
              settings = {
                documentFormatting = true, -- Ensure formatting is enabled
                format = {
                  enable = true,
                },
              },
            })
          end,
        }
      })
    end,
  },
}
