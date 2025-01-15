return {
  {
    "folke/edgy.nvim",
    ---@module 'edgy'
    ---@param opts Edgy.Config
    opts = function(_, opts)
      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = "snacks_terminal",
          size = { height = 0.4 },
          title = "%{b:snacks_terminal.id}: %{b:term_title}",
          filter = function(_buf, win)
            return vim.w[win].snacks_win
              and vim.w[win].snacks_win.position == pos
              and vim.w[win].snacks_win.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        })
      end
    end,
  },
  {
    "szw/vim-maximizer",
    event = "VeryLazy",
    keys = {
      { "<leader>mx", "<cmd>MaximizerToggle<CR>", desc = "Maximize/minimize a split" },
    },
  },
  { -- fixes scrolloff at end of file
    "Aasim-A/scrollEOF.nvim",
    event = "CursorMoved",
    opts = true,
  },
  {
    "tzachar/highlight-undo.nvim",
    keys = { "u", "<A-u>" }, -- Alt+r for redo
    opts = {
      duration = 400,
      undo = {
        lhs = "u",
        map = "silent! undo", -- ensure 'undo' is executed silently
        opts = { desc = "󰕌 Undo" },
      },
      redo = {
        lhs = "<A-u>",
        map = "silent! redo", -- ensure 'redo' is executed silently
        opts = { desc = "󰑎 Redo" },
      },
    },
    config = function(_, opts)
      local highlight_undo = require("highlight-undo")
      highlight_undo.setup(opts)
      -- Custom mapping for Alt + r to redo if not automatically set
      vim.keymap.set("n", "<A-u>", "<cmd>redo<CR>", { desc = "󰑎 Redo" })
    end,
  },
  { -- indentation guides
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    main = "ibl",
    opts = {
      scope = {
        highlight = "Comment",
        enabled = false,
        show_start = false,
        show_end = false,
        show_exact_scope = true,
      },
      indent = { char = "│", tab_char = "│" },
      exclude = {
        filetypes = {
          "undotree",
          "help",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
        },
      },
    },
  },
  { -- scrollbar with information
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    opts = {
      winblend = 10, -- little transparency, hard to see in many themes otherwise
      handlers = {
        cursor = { enable = false },
        marks = { enable = false }, -- FIX mark-related error message
        quickfix = { enable = true, signs = { "·", ":", "󰇙" } },
      },
    },
  },
  { -- when searching, search count is shown next to the cursor
    "kevinhwang91/nvim-hlslens",
    event = "VeryLazy",
    opts = {
      nearest_only = true,
      override_lens = function(render, posList, nearest, idx, _)
        -- formats virtual text as a bubble
        local lnum, col = unpack(posList[idx])
        local text = ("%d/%d"):format(idx, #posList)
        local chunks = {
          { " ", "Padding-Ignore" },
          { "", "HLSearchReversed" },
          { text, "HlSearchLensNear" },
          { "", "HLSearchReversed" },
        }
        render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
      end,
    },
  },
  { -- rainbow brackets
    "hiphish/rainbow-delimiters.nvim",
    event = "BufReadPost", -- later does not load on first buffer
    lazy = true,
    dependencies = "nvim-treesitter/nvim-treesitter",
    main = "rainbow-delimiters.setup",
  },
  { -- emphasized headers & code blocks in markdown
    "lukas-reineke/headlines.nvim",
    lazy = true,
    event = "VeryLazy",
    ft = "markdown",
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = {
      markdown = {
        fat_headlines = false,
        bullets = false,
        dash_string = "_",
      },
    },
  },
  { -- color previews & color picker
    "uga-rosa/ccc.nvim",
    lazy = true,
    keys = {
      { "g#", vim.cmd.CccPick, desc = " Color Picker" },
    },
    ft = { "css", "scss", "sh", "lua" },
    config = function()
      vim.opt.termguicolors = true
      local ccc = require("ccc")
      ccc.setup({
        win_opts = { border = vim.g.borderStyle },
        highlighter = {
          auto_enable = true,
          max_byte = 1.5 * 1024 * 1024, -- 1.5 Mb
          lsp = true,
          filetypes = { "css", "scss", "sh", "lua" },
        },
        pickers = {
          ccc.picker.hex,
          ccc.picker.css_rgb,
          ccc.picker.css_hsl,
          ccc.picker.ansi_escape({ meaning1 = "bright" }),
        },
        alpha_show = "hide", -- needed when highlighter.lsp is set to true
        recognize = { output = true }, -- automatically recognize color format under cursor
        inputs = { ccc.input.hsl },
        outputs = {
          ccc.output.css_hsl,
          ccc.output.css_rgb,
          ccc.output.hex,
        },
        mappings = {
          ["<Esc>"] = ccc.mapping.quit,
          ["q"] = ccc.mapping.quit,
          ["L"] = ccc.mapping.increase10,
          ["H"] = ccc.mapping.decrease10,
          ["o"] = ccc.mapping.toggle_output_mode, -- = convert color
        },
      })
    end,
  },
  --
  -- plugin to create custom colorscheme
  -- {
  --   'rktjmp/lush.nvim',
  --   lazy = false,
  --   priority = 1001,
  -- },
}
