local u = require("abbes.config.utils")
--------------------------------------------------------------------------------

local defaultSources = {
  {
    name = "nvim_lsp",
  },
  { name = "luasnip" }, -- snippets
  { name = "buffer" },  -- text within current buffer
  { name = "path" },    -- file system paths
  {
    name = "nvim_lsp",
    entry_filter = function(entry, _)
      -- using cmp-buffer for that
      return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] ~= "Text"
    end,
  },
  {
    name = "buffer",
    option = {
      -- show completions from all buffers used within the last x minutes
      get_bufnrs = function()
        local usedWithinMins = 10 -- CONFIG
        local allBufs = vim.fn.getbufinfo({ buflisted = 1 })
        local recentBufs = vim.tbl_filter(function(buf)
          return os.time() - buf.lastused < usedWithinMins * 60
        end, allBufs)
        local bufnrs = vim.tbl_map(function(buf)
          return buf.bufnr
        end, recentBufs)
        return bufnrs
      end,
      max_indexed_line_length = 100, -- no long lines (e.g. base64-encoded things)
    },
    keyword_length = 3,
    max_item_count = 4, -- since searching all buffers results in many results
  },
  { name = "path" },
  { name = "emoji" },
}

local sourceIcons = {
  buffer = "󰽙",
  cmdline = "󰘳",
  emoji = "󰞅",
  luasnip = "",
  nvim_lsp = "󰒕",
  path = "",
}

--------------------------------------------------------------------------------

local function cmpconfig()
  local cmp = require("cmp")
  local compare = require("cmp.config.compare")
  require("vim-react-snippets").lazy_load()

  cmp.setup({
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },
    window = {
      completion = { border = vim.g.borderStyle, scrolloff = 2 },
      documentation = { border = vim.g.borderStyle, scrolloff = 2 },
    },
    sorting = {
      comparators = {
        -- Original order: https://github.com/hrsh7th/nvim-cmp/blob/538e37ba87284942c1d76ed38dd497e54e65b891/lua/cmp/config/default.lua#L65-L74
        -- Definitions of compare function https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/compare.lua
        compare.offset,
        compare.recently_used, -- higher
        compare.score,
        compare.exact,         -- lower
        compare.kind,          -- higher (prioritize snippets)
        compare.locality,
        compare.length,
        compare.order,
      },
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
      ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
      ["<C-e>"] = cmp.mapping.abort(),        -- close completion window
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
      ["<PageUp>"] = cmp.mapping.scroll_docs(-4),
      ["<PageDown>"] = cmp.mapping.scroll_docs(4),

      -- manually triggering to only include LSP, useful for typed yaml/json
      ["<D-c>"] = cmp.mapping.complete({
        config = { sources = cmp.config.sources({ { name = "nvim_lsp" } }) },
      }),

      -- Next item, or trigger completion, or insert normal tab
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end, { "i", "s" }),
      -- cmd+j: Jump to next location
      ["<D-j>"] = cmp.mapping(function(_)
        -- DOCS https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#api-2
        if require("luasnip").locally_jumpable(1) then
          require("luasnip").jump(1)
        else
          u.notify("Luasnip", "No more jumps.", "warn")
        end
      end, { "i", "s" }),
      -- cmd+shift+j: prev location
      ["<D-J>"] = cmp.mapping(function(_)
        if require("luasnip").locally_jumpable(-1) then
          require("luasnip").jump(-1)
        else
          u.notify("Luasnip", "No more jumps.", "warn")
        end
      end, { "i", "s" }),
    }),
    formatting = {
      fields = { "abbr", "menu", "kind" }, -- order of the fields
      format = function(entry, item)
        -- abbreviate length https://github.com/hrsh7th/nvim-cmp/discussions/609
        -- (height is controlled via pumheight option)
        local maxLength = 50
        if #item.abbr > maxLength then
          item.abbr = item.abbr:sub(1, maxLength) .. "…"
        end

        -- distinguish emmet snippets
        local ft = vim.bo[entry.context.bufnr].filetype
        local isEmmet = entry.source.name == "nvim_lsp" and item.kind == "Snippet" and ft == "css"

        -- set icons
        -- stylua: ignore
        local kindIcons = {
          Text = "",
          Method = "󰆧",
          Function = "󰊕",
          Constructor = "",
          Field = "󰇽",
          Variable = "󰂡",
          Class = "󰠱",
          Interface = "",
          Module = "",
          Property = "󰜢",
          Unit = "",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Snippet = "󰅱",
          Color = "󰏘",
          File = "󰈙",
          Reference = "",
          Folder = "󰉋",
          EnumMember = "",
          Constant = "󰏿",
          Struct = "",
          Event = "",
          Operator = "󰆕",
          TypeParameter = "󰅲"
        }
        item.kind = entry.source.name == "nvim_lsp" and kindIcons[item.kind] or ""
        item.menu = sourceIcons[entry.source.name]
        if isEmmet then
          item.menu = ""
          item.kind = ""
        end

        return item
      end,
    },
    sources = cmp.config.sources(defaultSources),
  })

  -----------------------------------------------------------------------------

  -- LUA: disable annoying `--#region` suggestions
  cmp.setup.filetype("lua", {
    enabled = function()
      local line = vim.api.nvim_get_current_line()
      return not (line:find("%s%-%-?$") or line:find("^%-%-?$"))
    end,
  })

  -- SHELL: disable `\[` suggestions at EoL
  cmp.setup.filetype("sh", {
    enabled = function()
      local col = vim.fn.col(".") - 1
      local charBefore = vim.api.nvim_get_current_line():sub(col, col)
      return charBefore ~= "\\"
    end,
  })

  -- COMMANDLINE
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" },
      { name = "cmdline" },
    }),
  })

  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer", max_item_count = 3, keyword_length = 2 },
    },
  })

  cmp.setup({
    sources = {
      { name = "codeium" }
    }
  })
end

--------------------------------------------------------------------------------

return {
  { -- Completion Engine + Sources
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    config = cmpconfig,
    dependencies = {
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-calc",
      "lukas-reineke/cmp-rg",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-emoji",
      "hrsh7th/cmp-nvim-lsp",         -- LSP input
      "L3MON4D3/LuaSnip",             -- snippet engine
      "saadparwaiz1/cmp_luasnip",     -- adapter for snippet engine
      "rafamadriz/friendly-snippets", -- useful snippets
      "mlaursen/vim-react-snippets",
    },
  },
  { -- Snippet Engine
    "L3MON4D3/LuaSnip",
    init = function()
      -- copy system clipboard to regular register, required for VSCode
      -- snippets with `$CLIPBOARD`
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          vim.fn.setreg('"', vim.fn.getreg("+"))
        end,
      })
    end,
    opts = {
      -- live updating of snippets
      update_events = { "TextChanged", "TextChangedI" },
      -- disable auto-reload, since already done by scissors
      fs_event_providers = { autocmd = false, libuv = false },
    },
    config = function(_, opts)
      require("luasnip").setup(opts)
      -- DOCS https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#vs-code
      require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    end,
  },
}
