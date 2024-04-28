local u = require("abbes.config.utils")
--------------------------------------------------------------------------------

return {
  { -- automatically set correct indent for file
    "nmac427/guess-indent.nvim",
    event = "BufReadPre",
    opts = { override_editorconfig = false },
  },
  { -- comment
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      -- import comment plugin safely
      local comment = require("Comment")

      local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

      -- enable comment
      comment.setup({
        -- for commenting tsx and jsx files
        pre_hook = ts_context_commentstring.create_pre_hook(),
      })
    end,
    opts = {
      opleader = { line = "gcc", block = "<Nop>" },
      toggler = { line = "gcc", block = "<Nop>" },
      extra = { eol = "Q", above = "qO", below = "qo" },
    },
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
  { -- undo history
    "mbbill/undotree",
    event = "VeryLazy",
    keys = {
      { "<leader>ut", vim.cmd.UndotreeToggle, desc = " Undotree" },
    },
    init = function()
      vim.g.undotree_WindowLayout = 3
      vim.g.undotree_DiffpanelHeight = 10
      vim.g.undotree_ShortIndicators = 1
      vim.g.undotree_SplitWidth = 30
      vim.g.undotree_DiffAutoOpen = 0
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_HelpLine = 1

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "undotree",
        callback = function()
          vim.defer_fn(function()
            vim.keymap.set("n", "J", "6j", { buffer = true })
            vim.keymap.set("n", "K", "6k", { buffer = true })
          end, 1)
        end,
      })
    end,
  },
  { -- autopair brackets/quotes
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      -- add brackets to cmp completions, e.g. "function" -> "function()"
      local ok, cmp = pcall(require, "cmp")
      if ok then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end

      -- CUSTOM RULES
      -- DOCS https://github.com/windwp/nvim-autopairs/wiki/Rules-API
      require("nvim-autopairs").setup({ check_ts = true }) -- use treesitter for custom rules

      local rule = require("nvim-autopairs.rule")
      local isNodeType = require("nvim-autopairs.ts-conds").is_ts_node
      local isNotNodeType = require("nvim-autopairs.ts-conds").is_not_ts_node
      local negLookahead = require("nvim-autopairs.conds").not_after_regex

      require("nvim-autopairs").add_rules({
        rule("<", ">", "lua"):with_pair(isNodeType({ "string", "string_content" })),
        rule("<", ">", { "vim", "html", "xml" }), -- keymaps & tags

        -- css: auto-add trailing semicolon, but only for declarations
        -- (which are at the end of the line and have no text afterwards)
        rule(":", ";", "css"):with_pair(negLookahead(".", 1)),

        -- auto-add trailing comma inside objects/arrays
        rule([[^%s*[:=%w]$]], ",", { "javascript", "typescript", "lua", "python", "go" })
            :use_regex(true)
            :with_pair(negLookahead(".+")) -- neg. cond has to come first
            :with_pair(isNodeType({ "table_constructor", "field", "object", "dictionary" }))
            :with_del(function()
              return false
            end)
            :with_move(function(opts)
              return opts.char == ","
            end),

        -- git commit with scope auto-append `(` to `(): `
        rule("^%a+%(%)", ": ", "gitcommit")
            :use_regex(true)
            :with_pair(negLookahead(".+"))
            :with_pair(isNotNodeType("message"))
            :with_move(function(opts)
              return opts.char == ":"
            end),

        -- add brackets to if/else in js/ts
        rule("^%s*if $", "()", { "javascript", "typescript" })
            :use_regex(true)
            :with_del(function()
              return false
            end)
            :set_end_pair_length(1), -- only move one char to the side
        rule("^%s*else if $", "()", { "javascript", "typescript" })
            :use_regex(true)
            :with_del(function()
              return false
            end)
            :set_end_pair_length(1),
        rule("^%s*} ?else if $", "() {", { "javascript", "typescript" })
            :use_regex(true)
            :with_del(function()
              return false
            end)
            :set_end_pair_length(3),

        -- add colon to if/else in python
        rule("^%s*e?l?if$", ":", "python")
            :use_regex(true)
            :with_del(function()
              return false
            end)
            :with_pair(isNotNodeType("string_content")), -- no docstrings
        rule("^%s*else$", ":", "python")
            :use_regex(true)
            :with_del(function()
              return false
            end)
            :with_pair(isNotNodeType("string_content")), -- no docstrings
        rule("", ":", "python")                          -- automatically move past colons
            :with_move(function(opts)
              return opts.char == ":"
            end)
            :with_pair(function()
              return false
            end)
            :with_del(function()
              return false
            end)
            :with_cr(function()
              return false
            end)
            :use_key(":"),
      })
    end,
  },
  { -- auto-convert string and f/template string -- for eg : for js/ts when typing "${}" it becomes `${}` automatically
    "chrisgrieser/nvim-puppeteer",
    ft = { "python", "javascript", "typescript", "lua", "go" },
    cmd = "PuppeteerToggle",
    init = function()
      vim.g.puppeteer_disable_filetypes = {}
    end,
    keys = {
      { "<leader>tp", vim.cmd.PuppeteerToggle, desc = "󰅳 Puppeteer" },
    },
  },
  { -- split-join lines
    "Wansmer/treesj",
    keys = {
      {
        "<leader>tj",
        function()
          require("treesj").toggle()
        end,
        desc = "󰗈 Split-join lines",
      },
      {
        "<leader>tJ",
        "gww",
        ft = { "markdown", "applescript" },
        desc = "󰗈 Split line",
      },
    },
    opts = {
      use_default_keymaps = false,
      cursor_behavior = "start",
      max_join_length = 160,
    },
    config = function(_, opts)
      local gww = {
        both = {
          fallback = function()
            vim.cmd("normal! gww")
          end,
        },
      }
      local curleyLessIfStatementJoin = {
        -- remove curly brackets in js when joining if statements https://github.com/Wansmer/treesj/issues/150
        statement_block = {
          join = {
            format_tree = function(tsj)
              if tsj:tsnode():parent():type() == "if_statement" then
                tsj:remove_child({ "{", "}" })
              else
                require("treesj.langs.javascript").statement_block.join.format_tree(tsj)
              end
            end,
          },
        },
        -- one-line-if-statement can be split into multi-line https://github.com/Wansmer/treesj/issues/150
        expression_statement = {
          join = { enable = false },
          split = {
            enable = function(tsn)
              return tsn:parent():type() == "if_statement"
            end,
            format_tree = function(tsj)
              tsj:wrap({ left = "{", right = "}" })
            end,
          },
        },
      }
      opts.langs = {
        python = { string_content = gww },         -- python docstrings
        rst = { paragraph = gww },                 -- python docstrings (when rsg is injected)
        comment = { source = gww, element = gww }, -- comments in any language
        jsdoc = { source = gww, description = gww },
        javascript = curleyLessIfStatementJoin,
        typescript = curleyLessIfStatementJoin,
      }
      require("treesj").setup(opts)
    end,
  },
  { -- which-key
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- FIX very weird bug where insert mode undo points (<C-g>u),
      -- as well as vim-matchup's `<C-G>%` binding insert extra `1`s
      -- after wrapping to the next line in insert mode. The `G` needs
      -- to be uppercased to affect the right mapping.
      triggers_blacklist = { i = { "<C-G>" } },

      plugins = {
        presets = { motions = false, g = false, z = false },
        spelling = { enabled = false },
      },
      hidden = { "<Plug>", "^:lua ", "<cmd>" },
      key_labels = {
        ["<CR>"] = "↵",
        ["<BS>"] = "⌫",
        ["<space>"] = "󱁐",
        ["<Tab>"] = "󰌒",
        ["<Esc>"] = "⎋",
      },
      window = {
        border = { "", "─", "", "" }, -- only horizontal border to save space
        padding = { 0, 0, 0, 0 },
        margin = { 0, 0, 0, 0 },
      },
      popup_mappings = {
        scroll_down = "<PageDown>",
        scroll_up = "<PageUp>",
      },
      layout = { -- of the columns
        height = { min = 5, max = 15 },
        width = { min = 31, max = 34 },
        spacing = 1,
        align = "center",
      },
    },
    config = function(_, opts)
      local whichkey = require("which-key")
      whichkey.setup(opts)

      -- leader prefixes normal mode
      whichkey.register({
        u = { name = " 󰕌 Undo" },
        o = { name = "  Options" },
        p = { name = " 󰏗 Packages" },
        i = { name = " 󱡴 Inspect" },
      }, { prefix = "<leader>" })

      -- leader prefixes normal+visual mode
      whichkey.register({
        c = { name = "  Code Action" },
        f = { name = " 󱗘 Refactor" },
        g = { name = " 󰊢 Git" },
      }, { prefix = "<leader>", mode = { "x", "n" } })

      -- set by some plugins and unnecessarily clobbers whichkey
      vim.keymap.set("o", "<LeftMouse>", "<Nop>")
    end,
  },
  { "kkharji/sqlite.lua" },
  {
    "gbprod/yanky.nvim",
    dependencies = { "kkharji/sqlite.lua" },
    opts = {
      highlight = { timer = 250 },
      ring = { storage = "shada" or "sqlite" },
    },
    keys = {
      -- stylua: ignore
      { "<leader>p", function() require("telescope").extensions.yank_history.yank_history({}) end, desc = "Open Yank History" },
      {
        "y",
        "<Plug>(YankyYank)",
        mode = { "n", "x" },
        desc = "Yank Text",
      },
      {
        "p",
        "<Plug>(YankyPutAfter)",
        mode = { "n", "x" },
        desc = "Put Yanked Text After Cursor",
      },
      {
        "P",
        "<Plug>(YankyPutBefore)",
        mode = { "n", "x" },
        desc = "Put Yanked Text Before Cursor",
      },
      {
        "gp",
        "<Plug>(YankyGPutAfter)",
        mode = { "n", "x" },
        desc = "Put Yanked Text After Selection",
      },
      {
        "gP",
        "<Plug>(YankyGPutBefore)",
        mode = { "n", "x" },
        desc = "Put Yanked Text Before Selection",
      },
      {
        "[y",
        "<Plug>(YankyCycleForward)",
        desc = "Cycle Forward Through Yank History",
      },
      {
        "]y",
        "<Plug>(YankyCycleBackward)",
        desc = "Cycle Backward Through Yank History",
      },
      {
        "]p",
        "<Plug>(YankyPutIndentAfterLinewise)",
        desc = "Put Indented After Cursor (Linewise)",
      },
      {
        "[p",
        "<Plug>(YankyPutIndentBeforeLinewise)",
        desc = "Put Indented Before Cursor (Linewise)",
      },
      {
        "]P",
        "<Plug>(YankyPutIndentAfterLinewise)",
        desc = "Put Indented After Cursor (Linewise)",
      },
      {
        "[P",
        "<Plug>(YankyPutIndentBeforeLinewise)",
        desc = "Put Indented Before Cursor (Linewise)",
      },
      {
        ">p",
        "<Plug>(YankyPutIndentAfterShiftRight)",
        desc = "Put and Indent Right",
      },
      {
        "<p",
        "<Plug>(YankyPutIndentAfterShiftLeft)",
        desc = "Put and Indent Left",
      },
      {
        ">P",
        "<Plug>(YankyPutIndentBeforeShiftRight)",
        desc = "Put Before and Indent Right",
      },
      {
        "<P",
        "<Plug>(YankyPutIndentBeforeShiftLeft)",
        desc = "Put Before and Indent Left",
      },
      {
        "=p",
        "<Plug>(YankyPutAfterFilter)",
        desc = "Put After Applying a Filter",
      },
      {
        "=P",
        "<Plug>(YankyPutBeforeFilter)",
        desc = "Put Before Applying a Filter",
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    -- @type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      -- { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      -- { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {},
    config = function()
      require("barbecue").setup({
        create_autocmd = false, -- prevent barbecue from updating itself automatically
      })

      vim.api.nvim_create_autocmd({
        "WinScrolled", -- or WinResized on NVIM-v0.9 and higher
        "BufWinEnter",
        "CursorHold",
        "InsertLeave",
        -- include this if you have set `show_modified` to `true`
        -- "BufModifiedSet",
      }, {
        group = vim.api.nvim_create_augroup("barbecue.updater", {}),
        callback = function()
          require("barbecue.ui").update()
        end,
      })
    end,
  },
  -- Lorem Ipsum generator for Neovim
  {
    "derektata/lorem.nvim",
    enabled = false,
    config = function()
      local lorem = require("lorem")
      lorem.setup({
        sentenceLength = "mixedShort",
        comma = 1,
      })
    end,
  },
  -- { -- Multi Cursor
  --   "mg979/vim-visual-multi",
  --   keys = {
  --     { "<D-j>", mode = { "n", "x" }, desc = "󰆿 Multi-Cursor (Cursor Word)" },
  --     { "<D-a>", mode = { "n", "x" }, desc = "󰆿 Multi-Cursor (All)" },
  --   },
  --   init = function()
  --     vim.g.VM_set_statusline = 0 -- using my version via lualine component
  --     vim.g.VM_show_warnings = 0
  --     vim.g.VM_silent_exit = 1
  --     vim.g.VM_quit_after_leaving_insert_mode = 1 -- can use "reselect last" to restore
  --     -- DOCS https://github.com/mg979/vim-visual-multi/blob/master/doc/vm-mappings.txt
  --     vim.g.VM_maps = {
  --       -- Enter Visual-Multi-Mode
  --       ["Find Under"] = "<D-j>", -- select word under cursor
  --       ["Visual Add"] = "<D-j>",
  --       ["Reselect Last"] = "gV",
  --       ["Select All"] = "<D-a>",
  --       ["Visual All"] = "<D-a>",
  --
  --       -- Visual-Multi-Mode Mappings
  --       ["Find Next"] = "<D-j>",
  --       ["Find Prev"] = "<D-J>",
  --       ["Skip Region"] = "n", -- [n]o & find next
  --       ["Remove Region"] = "N", -- [N]o & goto prev
  --       ["Find Operator"] = "s", -- operator, selects all regions found in textobj
  --
  --       ["Motion $"] = "L", -- consistent with my mappings
  --       ["Motion ^"] = "H",
  --     }
  --   end,
  --   config = function()
  --     u.addToLuaLine("sections", "lualine_z", function()
  --       if not vim.b["VM_Selection"] or not vim.b["VM_Selection"].Regions then
  --         return ""
  --       end
  --       return ("󰇀 %s"):format(#vim.b.VM_Selection.Regions)
  --     end)
  --   end,
  -- },
}
