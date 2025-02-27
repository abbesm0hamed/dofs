-- local u = require("abbes.config.utils")
---------------------------------------

return {
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
  -- { -- display inlay hints from LSP
  --   "lvimuser/lsp-inlayhints.nvim",
  --   init = function()
  --     vim.api.nvim_create_autocmd("LspAttach", {
  --       callback = function(args)
  --         if not (args.data and args.data.client_id) then
  --           return
  --         end
  --         local bufnr = args.buf
  --         local client = vim.lsp.get_client_by_id(args.data.client_id)
  --         require("lsp-inlayhints").on_attach(client, bufnr)
  --       end,
  --     })
  --   end,
  --   opts = {
  --     inlay_hints = {
  --       labels_separator = "",
  --       parameter_hints = {
  --         prefix = " 󰁍 ",
  --         remove_colon_start = true,
  --         remove_colon_end = true,
  --       },
  --       type_hints = {
  --         remove_colon_start = true,
  --         remove_colon_end = true,
  --       },
  --     },
  --   },
  -- },
  -- { -- CodeLens, but also for languages not supporting it
  --   "Wansmer/symbol-usage.nvim",
  --   event = "BufReadPre",
  --   opts = {
  --     hl = { link = "Comment" },
  --     vt_position = "end_of_line",
  --     request_pending_text = false, -- no "Loading…" PENDING https://github.com/Wansmer/symbol-usage.nvim/issues/24
  --     references = { enabled = true, include_declaration = false },
  --     definition = { enabled = false },
  --     implementation = { enabled = true },
  --     text_format = function(symbol)
  --       local refs = (symbol.references and symbol.references > 0) and (" 󰈿 %s"):format(symbol.references) or ""
  --       return refs
  --     end,
  --     disable = {
  --       filetypes = { "css", "scss" },
  --     },
  --     -- available kinds: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#symbolKind
  --     kinds = {
  --       vim.lsp.protocol.SymbolKind.Module,
  --       vim.lsp.protocol.SymbolKind.Package,
  --       vim.lsp.protocol.SymbolKind.Function,
  --       vim.lsp.protocol.SymbolKind.Class,
  --       vim.lsp.protocol.SymbolKind.Constructor,
  --       vim.lsp.protocol.SymbolKind.Method,
  --       vim.lsp.protocol.SymbolKind.Interface,
  --       vim.lsp.protocol.SymbolKind.Object,
  --       vim.lsp.protocol.SymbolKind.Key,
  --     },
  --   },
  -- },
  -- { -- lsp definitions & references count in the status line
  --   "chrisgrieser/nvim-dr-lsp",
  --   event = "LspAttach",
  --   config = function()
  --     u.addToLuaLine("sections", "lualine_x", require("dr-lsp").lspProgress)
  --     u.addToLuaLine("sections", "lualine_c", {
  --       require("dr-lsp").lspCount,
  --       fmt = function(str)
  --         return str:gsub("R", ""):gsub("D", " 󰄾"):gsub("LSP:", "󰈿")
  --       end,
  --     })
  --   end,
  -- },
  -- { -- signature hints
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufReadPre",
  --   keys = {
  --     { -- better signature view
  --       "<A-g>",
  --       function()
  --         require("lsp_signature").toggle_float_win()
  --       end,
  --       mode = { "i", "n", "v" },
  --       desc = "󰏪 LSP Signature",
  --     },
  --   },
  --   opts = {
  --     noice = false,
  --     hint_prefix = "󰏪 ",
  --     hint_scheme = "@variable.parameter",
  --     hint_inline = function()
  --       return false -- Disable inline hints
  --     end,
  --     floating_window = false,
  --     always_trigger = true,
  --     bind = true,
  --     handler_opts = { border = vim.g.borderStyle },
  --
  --     -- Add these settings to disable automatic triggering
  --     toggle_key = nil,                 -- Disable default toggle key
  --     toggle_key_flip_floatwin = nil,   -- Disable default float window toggle
  --     auto_close_after = nil,           -- Disable auto-close
  --     check_completion_visible = false, -- Disable checks for completion window
  --     trigger_on_newline = false,       -- Disable trigger on newline
  --     doc_lines = 0,                    -- Disable doc lines
  --   },
  -- },
  -- { -- add ignore-comments & lookup rules
  --   "chrisgrieser/nvim-rulebook",
  --   keys = {
  --     {
  --       "<leader>rl",
  --       function()
  --         require("rulebook").lookupRule()
  --       end,
  --       desc = " Lookup Rule",
  --     },
  --     {
  --       "<leader>ri",
  --       function()
  --         require("rulebook").ignoreRule()
  --       end,
  --       desc = "󰅜 Ignore Rule",
  --     },
  --     {
  --       "<leader>ry",
  --       function()
  --         require("rulebook").yankDiagnosticCode()
  --       end,
  --       desc = "󰅍 Yank Diagnostic Code",
  --     },
  --   },
  -- },
}
