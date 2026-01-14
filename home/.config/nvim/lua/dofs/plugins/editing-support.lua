return {
  {
    "ziontee113/icon-picker.nvim",
    dependencies = { "stevearc/dressing.nvim" },
    keys = {
      { "<Leader><Leader>i", "<cmd>IconPickerNormal<cr>", desc = "Pick icon" },
      { "<Leader><Leader>y", "<cmd>IconPickerYank<cr>", desc = "Yank icon" },
      { "<C-i>", "<cmd>IconPickerInsert<cr>", mode = "i", desc = "Insert icon" },
    },
    opts = { disable_legacy_commands = true },
  },
  {
    "nmac427/guess-indent.nvim",
    event = "BufReadPre",
    opts = {
      override_editorconfig = false,
      filetype_exclude = {
        "netrw",
        "tutor",
      },
    },
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
  {
    "mbbill/undotree",
    keys = {
      { "<leader>ut", vim.cmd.UndotreeToggle, desc = "󰕌 Undotree" },
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
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local npairs = require("nvim-autopairs")
      npairs.setup({
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
          typescript = { "string", "template_string" },
        },
        disable_filetype = { "TelescopePrompt", "vim" },
        fast_wrap = {
          map = "<M-e>",
          chars = { "{", "[", "(", '"', "'" },
          pattern = [=[[%'%"%>%]%)%}%,]]=],
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "Search",
          highlight_grey = "Comment",
        },
      })

      -- CMP integration
      local ok, cmp = pcall(require, "cmp")
      if ok then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end

      -- Custom rules
      local rule = require("nvim-autopairs.rule")
      local isNodeType = require("nvim-autopairs.ts-conds").is_ts_node
      local isNotNodeType = require("nvim-autopairs.ts-conds").is_not_ts_node
      local negLookahead = require("nvim-autopairs.conds").not_after_regex

      npairs.add_rules({
        -- HTML/XML tags
        rule("<", ">", { "html", "xml" }),
        rule("<", ">", "lua"):with_pair(isNodeType({ "string", "string_content" })),

        -- CSS trailing semicolon
        rule(":", ";", "css"):with_pair(negLookahead(".", 1)),

        -- Auto-add trailing comma
        rule([[^%s*[:=%w]$]], ",", { "javascript", "typescript", "lua", "python", "go" })
          :use_regex(true)
          :with_pair(negLookahead(".+"))
          :with_pair(isNodeType({ "table_constructor", "field", "object", "dictionary" }))
          :with_del(function()
            return false
          end)
          :with_move(function(opts)
            return opts.char == ","
          end),

        -- Git commit scope
        rule("^%a+%(%)", ": ", "gitcommit")
          :use_regex(true)
          :with_pair(negLookahead(".+"))
          :with_pair(isNotNodeType("message"))
          :with_move(function(opts)
            return opts.char == ":"
          end),

        -- JavaScript/TypeScript if statements
        rule("^%s*if $", "()", { "javascript", "typescript" })
          :use_regex(true)
          :with_del(function()
            return false
          end)
          :set_end_pair_length(1),
        rule("^%s*else if $", "()", { "javascript", "typescript" })
          :use_regex(true)
          :with_del(function()
            return false
          end)
          :set_end_pair_length(1),

        -- Python if/else colons
        rule("^%s*e?l?if$", ":", "python")
          :use_regex(true)
          :with_del(function()
            return false
          end)
          :with_pair(isNotNodeType("string_content")),
        rule("^%s*else$", ":", "python")
          :use_regex(true)
          :with_del(function()
            return false
          end)
          :with_pair(isNotNodeType("string_content")),

        -- Python colon movement
        rule("", ":", "python")
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
  {
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
        python = { string_content = gww },
        rst = { paragraph = gww },
        comment = { source = gww, element = gww },
        jsdoc = { source = gww, description = gww },
        javascript = curleyLessIfStatementJoin,
        typescript = curleyLessIfStatementJoin,
      }

      require("treesj").setup(opts)
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
    },
  },
  {
    "derektata/lorem.nvim",
    cmd = { "LoremIpsum" },
    keys = {
      { "<leader>tl", "<cmd>LoremIpsum<cr>", desc = "Generate Lorem Ipsum" },
    },
    opts = {
      sentenceLength = "medium",
      comma_chance = 0.2,
      max_commas_per_sentence = 2,
    },
  },
  {
    "kkharji/sqlite.lua",
    lazy = true,
  },
}
