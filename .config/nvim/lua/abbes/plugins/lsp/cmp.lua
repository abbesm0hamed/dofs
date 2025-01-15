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
  -- {
  --   'saghen/blink.cmp',
  --   -- optional: provides snippets for the snippet source
  --   dependencies = 'rafamadriz/friendly-snippets',
  --
  --   -- use a release tag to download pre-built binaries
  --   version = '*',
  --   -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  --   -- build = 'cargo build --release',
  --   -- If you use nix, you can build from source using latest nightly rust with:
  --   -- build = 'nix run .#build-plugin',
  --
  --   ---@module 'blink.cmp'
  --   ---@type blink.cmp.Config
  --   opts = {
  --     -- 'default' for mappings similar to built-in completion
  --     -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
  --     -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
  --     -- See the full "keymap" documentation for information on defining your own keymap.
  --     keymap = { preset = 'default' },
  --
  --     appearance = {
  --       -- Sets the fallback highlight groups to nvim-cmp's highlight groups
  --       -- Useful for when your theme doesn't support blink.cmp
  --       -- Will be removed in a future release
  --       use_nvim_cmp_as_default = true,
  --       -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
  --       -- Adjusts spacing to ensure icons are aligned
  --       nerd_font_variant = 'mono'
  --     },
  --
  --     -- Default list of enabled providers defined so that you can extend it
  --     -- elsewhere in your config, without redefining it, due to `opts_extend`
  --     sources = {
  --       default = { 'lsp', 'path', 'snippets', 'buffer' },
  --     },
  --   },
  --   opts_extend = { "sources.default" }
  -- }
}
