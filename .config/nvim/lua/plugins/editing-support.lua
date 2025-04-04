return {
  -- { -- automatically set correct indent for file
  --   "nmac427/guess-indent.nvim",
  --   event = { "BufReadPre", "BufNewFile" },
  --   config = function()
  --     require("guess-indent").setup({})
  --   end,
  -- },
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
    lazy = true,
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
        python = { string_content = gww }, -- python docstrings
        rst = { paragraph = gww }, -- python docstrings (when rsg is injected)
        comment = { source = gww, element = gww }, -- comments in any language
        jsdoc = { source = gww, description = gww },
        javascript = curleyLessIfStatementJoin,
        typescript = curleyLessIfStatementJoin,
      }
      require("treesj").setup(opts)
    end,
  },
  {
    "gbprod/yanky.nvim",
    dependencies = { "ibhagwan/fzf-lua" },
    opts = {
      ring = {
        history_length = 100,
        storage = "memory",
        sync_with_numbered_registers = true,
        cancel_event = "update",
      },
      picker = {
        select = {
          action = nil, -- nil to use default put action
        },
        telescope = nil, -- disable telescope
      },
      system_clipboard = {
        sync_with_ring = true,
      },
    },
    keys = {
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after cursor" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before cursor" },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
      { "<c-n>", "<Plug>(YankyCycleForward)", desc = "Cycle forward through yank history" },
      { "<c-p>", "<Plug>(YankyCycleBackward)", desc = "Cycle backward through yank history" },
      { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
      { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
      { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after cursor (linewise)" },
      { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before cursor (linewise)" },
      { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and indent right" },
      { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and indent left" },
      { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before and indent right" },
      { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before and indent left" },
      {
        "<leader>p",
        function()
          require("fzf-lua").yanky()
        end,
        desc = "Paste from Yanky",
      },
    },
  },
  {
    "kkharji/sqlite.lua",
    lazy = true,
    event = "VeryLazy",
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    -- @type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S",     mode = { "n", "o", "x" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      -- { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
    },
  },
  -- Lorem Ipsum generator for Neovim
  {
    "derektata/lorem.nvim",
    cmd = { "Lorem", "LoremSentence", "LoremParagraph", "LoremWord" },
    keys = {
      { "<leader>il", "<cmd>Lorem<cr>", desc = "Insert Lorem text" },
      { "<leader>is", "<cmd>LoremSentence<cr>", desc = "Insert Lorem sentence" },
      { "<leader>ip", "<cmd>LoremParagraph<cr>", desc = "Insert Lorem paragraph" },
      { "<leader>iw", "<cmd>LoremWord<cr>", desc = "Insert Lorem word" },
    },
    opts = {
      sentenceLength = "mixed", -- mixed gives more variety
      comma_chance = 0.3, -- slightly higher chance for commas
      max_commas_per_sentence = 3,
      word_list = nil, -- use default word list
    },
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
  -- },
  --
  -- {
  --   "folke/which-key.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     plugins = {
  --       marks = true,
  --       registers = true,
  --       spelling = {
  --         enabled = true,
  --         suggestions = 20,
  --       },
  --       presets = {
  --         operators = false,
  --         motions = false,
  --         text_objects = false,
  --         windows = true,
  --         nav = true,
  --         z = true,
  --         g = true,
  --       },
  --     },
  --     icons = {
  --       breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
  --       separator = "➜", -- symbol used between a key and it's label
  --       group = "+", -- symbol prepended to a group
  --     },
  --     popup_mappings = {
  --       scroll_down = "<PageDown>",
  --       scroll_up = "<PageUp>",
  --     },
  --     window = {
  --       border = "single",        -- none, single, double, shadow
  --       position = "bottom",      -- bottom, top
  --       margin = { 1, 0, 1, 0 },  -- extra window margin [top, right, bottom, left]
  --       padding = { 1, 2, 1, 2 }, -- extra window padding [top, right, bottom, left]
  --       winblend = 0,
  --     },
  --     layout = {
  --       height = { min = 4, max = 25 }, -- min and max height of the columns
  --       width = { min = 20, max = 50 }, -- min and max width of the columns
  --       spacing = 3,                    -- spacing between columns
  --       align = "left",                 -- align columns left, center or right
  --     },
  --     hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
  --     ignore_missing = false, -- enable this to hide mappings for which you didn't specify a label
  --     show_help = true,       -- show help message on the command line when the popup is visible
  --     triggers = "auto",      -- automatically setup triggers
  --     -- triggers = {"<leader>"} -- or specify a list manually
  --     triggers_blacklist = {
  --       -- list of mode / prefixes that should never be hooked by WhichKey
  --       -- this is mostly relevant for key maps that start with a native binding
  --       -- most people should not need to change this
  --       i = { "j", "k" },
  --       v = { "j", "k" },
  --     },
  --   },
  --   config = function(_, opts)
  --     local wk = require("which-key")
  --     wk.setup(opts)
  --
  --     wk.register({
  --       ["<leader>"] = {
  --         u = { name = "󰕌 Undo" },
  --         o = { name = " Options" },
  --         p = { name = "󰏗 Packages" },
  --         i = { name = "󱡴 Inspect" },
  --         c = { name = " Code Action", mode = { "n", "v" } },
  --         f = { name = "󱗘 Refactor", mode = { "n", "v" } },
  --         g = { name = "󰊢 Git", mode = { "n", "v" } },
  --         d = { name = "  Debugger", mode = { "n", "x" } },
  --         t = {
  --           name = "Toggle",
  --           g = { "<cmd>Neogit<CR>", "Neogit" },
  --         },
  --         x = {
  --           name = "Trouble/Quickfix",
  --           x = { "<cmd>!chmod +x %<CR>", "Make executable" },
  --           T = { "<cmd>TroubleToggle todo<CR>", "Todo/Fix/Fixme (Trouble)" },
  --           l = { "<cmd>TroubleToggle loclist<CR>", "Location List" },
  --           t = { "<cmd>TroubleToggle<CR>", "Trouble" },
  --           q = { "<cmd>TroubleToggle quickfix<CR>", "Quickfix List" },
  --         },
  --         l = {
  --           name = "Lazy",
  --           s = { "<cmd>SessionRestore<CR>", "Restore session for current directory" },
  --         },
  --       },
  --       g = {
  --         r = { name = "References" },
  --         c = { name = "Comment" },
  --       },
  --     })
  --
  --     -- Prevent unnecessary keymaps from interfering with which-key
  --     vim.keymap.set("o", "<LeftMouse>", "<Nop>")
  --   end,
  -- },
}
