return {
  {
    "echasnovski/mini.icons",
    lazy = true,
    specs = {
      { "nvim-tree/nvim-web-devicons", enabled = false, optional = true },
    },
    opts = {
      file = {
        [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
        [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
        [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
        ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
      },
    },
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
  {
    "echasnovski/mini.surround",
    lazy = true,
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local plugin = require("lazy.core.config").spec.plugins["mini.surround"]
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      local mappings = {
        { opts.mappings.add, desc = "Add surrounding", mode = { "n", "v" } },
        { opts.mappings.delete, desc = "Delete surrounding" },
        { opts.mappings.find, desc = "Find right surrounding" },
        { opts.mappings.find_left, desc = "Find left surrounding" },
        { opts.mappings.highlight, desc = "Highlight surrounding" },
        { opts.mappings.Replace, desc = "Replace surrounding" },
        { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
      }
      mappings = vim.tbl_filter(function(m)
        return m[1] and #m[1] > 0
      end, mappings)
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      mappings = {
        add = "gsa", -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (to the right)
        find_left = "gsF", -- Find surrounding (to the left)
        highlight = "gsh", -- Highlight surrounding
        Replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`
      },
    },
  },
  {
    "echasnovski/mini.ai",
    version = "*", -- Use latest stable version
    event = "VeryLazy",
    opts = {
      -- Custom textobjects
      custom_textobjects = {
        -- Brackets and quotes
        ["("] = { "%b()", "^.().*().$" },
        ["["] = { "%b[]", "^.().*().$" },
        ["{"] = { "%b{}", "^.().*().$" },
        ['"'] = { '%b""', "^.().*().$" },
        ["'"] = { "%b''", "^.().*().$" },
        ["`"] = { "%b``", "^.().*().$" },

        -- Common programming patterns
        o = { -- Around function calls
          { "%b()", "^.-%s*().*()$" },
        },
        f = { -- Around function definitions
          { "^%s*function%s*[^%s(]+%s*%b()%s*{", "}" },
          { "^%s*local%s+function%s*[^%s(]+%s*%b()%s*{", "}" },
          { "^%s*[^%s(]+%s*=%s*function%s*%b()%s*{", "}" }, -- For variable functions
        },
        c = { -- Around class/module definitions
          { "^%s*class%s+[^%s{]+%s*{", "}" },
          { "^%s*module%s+[^%s{]+%s*{", "}" },
        },
        m = { -- Around methods
          { "^%s*[^%s(]+%s*%b()%s*{", "}" },
        },
      },

      -- Specify search method
      search_method = "cover_or_next",

      -- Define n_lines to search
      n_lines = 50,

      -- Highlight configuration
      highlight = {
        enable = true,
        duration = 500,
      },

      -- Mappings for built-in textobjects
      mappings = {
        -- Main textobject prefixes
        around = "a",
        inside = "i",

        -- Next/last textobjects
        around_next = "an",
        inside_next = "in",
        around_last = "al",
        inside_last = "il",

        -- Move cursor to corresponding edge of `a` textobject
        goto_left = "g[",
        goto_right = "g]",
      },

      silent = true,
    },
    config = function(_, opts)
      require("mini.ai").setup(opts)

      -- Additional key mappings if needed
      local map = vim.keymap.set

      -- Function text objects
      map({ "o", "x" }, "af", [[<cmd>lua MiniAi.select_textobject('f')<CR>]])
      map({ "o", "x" }, "if", [[<cmd>lua MiniAi.select_textobject('f')<CR>]])

      -- Method text objects
      map({ "o", "x" }, "am", [[<cmd>lua MiniAi.select_textobject('m')<CR>]])
      map({ "o", "x" }, "im", [[<cmd>lua MiniAi.select_textobject('m')<CR>]])
    end,
  },
}
