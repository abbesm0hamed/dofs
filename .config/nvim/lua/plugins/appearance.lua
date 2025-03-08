return {
  {
    "wurli/visimatch.nvim",
    opts = {},
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
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
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
  --
  -- {
  --   "folke/edgy.nvim",
  --   event = "VeryLazy",
  --   keys = {
  --     {
  --       "<leader>ue",
  --       function()
  --         require("edgy").toggle()
  --       end,
  --       desc = "Edgy Toggle",
  --     },
  --     -- stylua: ignore
  --     { "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
  --   },
  --   opts = function()
  --     local opts = {
  --       animate = {
  --         enabled = false,
  --         fps = 100, -- frames per second
  --         cps = 120, -- cells per second
  --         on_begin = function()
  --           vim.g.minianimate_disable = true
  --         end,
  --         on_end = function()
  --           vim.g.minianimate_disable = false
  --         end,
  --         -- Spinner for pinned views that are loading.
  --         -- if you have noice.nvim installed, you can use any spinner from it, like:
  --         -- spinner = require("noice.util.spinners").spinners.circleFull,
  --         spinner = {
  --           frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
  --           interval = 80,
  --         },
  --       },
  --       bottom = {
  --         {
  --           ft = "toggleterm",
  --           size = { height = 0.4 },
  --           filter = function(_win)
  --             return vim.api.nvim_win_get_config(_win).relative == ""
  --           end,
  --         },
  --         "Trouble",
  --         { ft = "qf", title = "QuickFix" },
  --         {
  --           ft = "help",
  --           size = { height = 20 },
  --           -- don't open help files in edgy that we're editing
  --           filter = function(_)
  --             return vim.bo[vim.api.nvim_get_current_buf()].buftype == "help"
  --           end,
  --         },
  --         { title = "Spectre", ft = "spectre_panel", size = { height = 0.4 } },
  --         { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
  --       },
  --       left = {
  --         { title = "Neotest Summary", ft = "neotest-summary" },
  --         -- "neo-tree",
  --       },
  --       right = {
  --         { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
  --       },
  --       keys = {
  --         -- increase width
  --         ["<c-Right>"] = function(win)
  --           win:resize("width", 2)
  --         end,
  --         -- decrease width
  --         ["<c-Left>"] = function(win)
  --           win:resize("width", -2)
  --         end,
  --         -- increase height
  --         ["<c-Up>"] = function(win)
  --           win:resize("height", 2)
  --         end,
  --         -- decrease height
  --         ["<c-Down>"] = function(win)
  --           win:resize("height", -2)
  --         end,
  --       },
  --     }
  --
  --     if LazyVim.has("neo-tree.nvim") then
  --       local pos = {
  --         filesystem = "left",
  --         buffers = "top",
  --         git_status = "right",
  --         document_symbols = "bottom",
  --         diagnostics = "bottom",
  --       }
  --       local sources = LazyVim.opts("neo-tree.nvim").sources or {}
  --       for i, v in ipairs(sources) do
  --         table.insert(opts.left, i, {
  --           title = "Neo-Tree " .. v:gsub("_", " "):gsub("^%l", string.upper),
  --           ft = "neo-tree",
  --           filter = function(buf)
  --             return vim.b[buf].neo_tree_source == v
  --           end,
  --           pinned = true,
  --           open = function()
  --             vim.cmd(("Neotree show position=%s %s dir=%s"):format(pos[v] or "bottom", v, LazyVim.root()))
  --           end,
  --         })
  --       end
  --     end
  --
  --     -- trouble
  --     for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
  --       opts[pos] = opts[pos] or {}
  --       table.insert(opts[pos], {
  --         ft = "trouble",
  --         filter = function(_, win)
  --           return vim.w[win].trouble
  --             and vim.w[win].trouble.position == pos
  --             and vim.w[win].trouble.type == "split"
  --             and vim.w[win].trouble.relative == "editor"
  --             and not vim.w[win].trouble_preview
  --         end,
  --       })
  --     end
  --
  --     -- snacks terminal
  --     for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
  --       opts[pos] = opts[pos] or {}
  --       table.insert(opts[pos], {
  --         ft = "snacks_terminal",
  --         size = { height = 0.4 },
  --         title = "%{b:snacks_terminal.id}: %{b:term_title}",
  --         filter = function(_, win)
  --           return vim.w[win].snacks_win
  --             and vim.w[win].snacks_win.position == pos
  --             and vim.w[win].snacks_win.relative == "editor"
  --             and not vim.w[win].trouble_preview
  --         end,
  --       })
  --     end
  --     return opts
  --   end,
  -- },
  --
  -- {
  --   "Bekaboo/dropbar.nvim",
  --   -- optional, but required for fuzzy finder support
  --   dependencies = {
  --     "ibhagwan/fzf-lua",
  --   },
  --   config = function()
  --     require("dropbar").setup({
  --       menu = {
  --         -- Use fzf-lua for fuzzy finding
  --         select = function(menu)
  --           local selected = menu.items[menu.selected]
  --           if not selected then
  --             return
  --           end
  --           menu:close()
  --           selected.handler(selected)
  --         end,
  --         -- Use fzf for fuzzy search
  --         fuzzy_finder = function(menu)
  --           local items = menu.items
  --           local selections = require("fzf-lua").fzf({
  --             source = vim.tbl_map(function(item)
  --               return item.text
  --             end, items),
  --           })
  --           if selections then
  --             for _, selection in ipairs(selections) do
  --               for _, item in ipairs(items) do
  --                 if item.text == selection then
  --                   item.handler(item)
  --                   break
  --                 end
  --               end
  --             end
  --           end
  --           menu:close()
  --         end,
  --       },
  --     })
  --     local dropbar_api = require("dropbar.api")
  --     vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
  --     vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
  --     vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
  --   end,
  -- },
}
