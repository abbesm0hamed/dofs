local defaultSources = {
  { name = "nvim_lsp" },
  { name = "luasnip" },
  { name = "buffer" },
  { name = "path" },
  { name = "emmet_ls" },
}

local sourceIcons = {
  buffer = "󰽙",
  cmdline = "󰘳",
  emoji = "󰞅",
  luasnip = "",
  nvim_lsp = "󰒕",
  path = "",
  emmet_ls = "󰌝",
}

local function cmpconfig()
  local cmp = require("cmp")
  local compare = require("cmp.config.compare")

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
        compare.offset,
        compare.exact,
        compare.score,
        compare.recently_used,
        compare.kind,
        compare.length,
        compare.order,
      },
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-k>"] = cmp.mapping.select_prev_item(),
      ["<C-j>"] = cmp.mapping.select_next_item(),
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
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
    }),
    formatting = {
      fields = { "abbr", "menu", "kind" },
      format = function(entry, item)
        local maxLength = 50
        if #item.abbr > maxLength then
          item.abbr = item.abbr:sub(1, maxLength) .. "…"
        end

        item.kind = entry.source.name == "nvim_lsp" and sourceIcons[entry.source.name] or ""
        item.menu = sourceIcons[entry.source.name] or ""

        return item
      end,
    },
    sources = cmp.config.sources(defaultSources),
    performance = {
      debounce = 60,
      throttle = 30,
      fetching_timeout = 500,
    },
  })

  cmp.setup.filetype("lua", {
    enabled = function()
      local line = vim.api.nvim_get_current_line()
      return not (line:find("%s%-%-?$") or line:find("^%-%-?$"))
    end,
  })

  cmp.setup.filetype("sh", {
    enabled = function()
      local col = vim.fn.col(".") - 1
      local charBefore = vim.api.nvim_get_current_line():sub(col, col)
      return charBefore ~= "\\"
    end,
  })

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
end

return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    config = cmpconfig,
    dependencies = {
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
  },
  {
    "L3MON4D3/LuaSnip",
    opts = {
      update_events = { "TextChanged", "TextChangedI" },
      fs_event_providers = { autocmd = false, libuv = false },
    },
    config = function(_, opts)
      require("luasnip").setup(opts)
      require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")
      npairs.setup({
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
        },
      })

      -- Make autopairs and completion work together
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
}
