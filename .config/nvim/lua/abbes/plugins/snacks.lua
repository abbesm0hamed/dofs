return {
  {
    "folke/snacks.nvim",
    event = "VimEnter",
    cmd = "Snacks",
    priority = 1000,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      dashboard = {
        formats = {
          key = function(item)
            return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
          end,
        },
        sections = {
          {
            header = [[


███╗   ███╗███████╗ ██████╗ ██╗   ██╗██╗ ██████╗
████╗ ████║██╔════╝██╔═══██╗██║   ██║██║██╔════╝
 ██╔████╔██║█████╗  ██║   ██║██║   ██║██║██║  ███╗
 ██║╚██╔╝██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║   ██║
 ██║ ╚═╝ ██║███████╗╚██████╔╝ ╚████╔╝ ██║╚██████╔╝
 ╚═╝     ╚═╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝ ╚═════╝

            ]],
          },
          -- { section = "startup" },
          { title = "MRU", padding = 1 },
          { section = "recent_files", limit = 3, padding = 1 },
          { title = "MRU CWD ", file = vim.fn.fnamemodify(".", ":~"), padding = 1 },
          { section = "recent_files", cwd = true, limit = 3, padding = 1 },
          { title = "Sessions", padding = 1 },
          { section = "projects", padding = 1 },
          { title = "Bookmarks", padding = 1 },
          -- { section = "keys", limit = 3 },
        },
      },
      scroll = { enabled = false },
      bigfile = {
        notify = true, -- show notification when big file detected
        size = 1.5 * 1024 * 1024, -- 1.5MB
        -- Enable or disable features when big file detected
        ---@param ctx {buf: number, ft:string}
        setup = function(ctx)
          vim.cmd([[NoMatchParen]])
          Snacks.util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
          vim.b.minianimate_disable = true
          vim.schedule(function()
            vim.bo[ctx.buf].syntax = ctx.ft
          end)
        end,
      },
      statuscolumn = {
        enabled = false,
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = {
          open = true,
          git_hl = false,
        },
        git = {
          patterns = { "GitSign", "MiniDiffSign" },
        },
        refresh = 50,
      },
      indent = {
        enabled = true,
        indent = {
          char = "▎",
        },
        scope = {
          char = "▎",
          only_current = true,
        },
        animate = {
          enabled = false,
        },
      },
      input = { enabled = false },
      quickfile = {
        enabled = true,
        exclude = { "latex" },
      },
      lazygit = {
        configure = true,
        -- extra configuration for lazygit that will be merged with the default
        -- snacks does NOT have a full yaml parser, so if you need `"test"` to appear with the quotes
        -- you need to double quote it: `"\"test\""`
        config = {
          os = { editPreset = "nvim-remote" },
          gui = {
            -- set to an empty string "" to disable icons
            nerdFontsVersion = "3",
          },
        },
        theme_path = vim.fs.normalize(vim.fn.stdpath("cache") .. "/lazygit-theme.yml"),
        -- Theme for lazygit
        theme = {
          [241] = { fg = "Special" },
          activeBorderColor = { fg = "MatchParen", bold = true },
          cherryPickedCommitBgColor = { fg = "Identifier" },
          cherryPickedCommitFgColor = { fg = "Function" },
          defaultFgColor = { fg = "Normal" },
          inactiveBorderColor = { fg = "FloatBorder" },
          optionsTextColor = { fg = "Function" },
          searchingActiveBorderColor = { fg = "MatchParen", bold = true },
          selectedLineBgColor = { bg = "Visual" }, -- set to `default` to have no background colour
          unstagedChangesColor = { fg = "DiagnosticError" },
        },
        win = {
          style = "lazygit",
        },
      },
      notifier = {
        enabled = true,
        timeout = 3000,
        sort = { "added" }, -- sort only by time
        width = { min = 12, max = 0.5 },
        height = { min = 1, max = 0.5 },
        icons = { error = "󰅚", warn = "", info = "󰋽", debug = "󰃤", trace = "󰓗" },
        top_down = false,
      },
      dim = {
        ---@type snacks.scope.Config
        scope = {
          min_size = 5,
          max_size = 20,
          siblings = true,
        },
        -- animate scopes. Enabled by default for Neovim >= 0.10
        -- Works on older versions but has to trigger redraws during animation.
        ---@type snacks.animate.Config|{enabled?: boolean}
        animate = {
          enabled = vim.fn.has("nvim-0.10") == 1,
          easing = "outQuad",
          duration = {
            step = 20, -- ms per step
            total = 300, -- maximum duration
          },
        },
        -- what buffers to dim
        filter = function(buf)
          return vim.g.snacks_dim ~= false and vim.b[buf].snacks_dim ~= false and vim.bo[buf].buftype == ""
        end,
      },
      words = {
        enabled = false,
        highlight = {
          whole = true,
          partial = false,
          hl = "Search",
        },
        throttle = 200,
        min_length = 3,
        max_highlight = 100,
        filter = function(buf)
          return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "markdown"
        end,
      },
      explorer = {
        enabled = true,
        replace_netrw = true,
        win = {
          position = "right",
          size = 30,
          relative = "editor",
        },
      },
      picker = {
        prompt = " ",
        sources = {},
        layout = {
          cycle = true,
          --- Use the default layout or vertical if the window is too narrow
          preset = function()
            return vim.o.columns >= 120 and "default" or "vertical"
          end,
        },
        ui_select = true, -- replace `vim.ui.select` with the snacks picker
        live_filter = {
          enabled = true,
          min_chars = 0,
          update_delay = 0,
        },
        previewers = {
          file = {
            max_size = 1024 * 1024, -- 1MB
            max_line_length = 500,
          },
        },
        win = {
          -- input window
          input = {
            keys = {
              -- ["<Esc>"] = "close",
              -- to close the picker on ESC instead of going to normal mode,
              -- add the following keymap to your config
              ["<Esc>"] = { "close", mode = { "n", "i" } },
              ["<CR>"] = { "confirm", mode = { "i", "n" } },
              ["G"] = "list_bottom",
              ["gg"] = "list_top",
              ["j"] = "list_down",
              ["k"] = "list_up",
              ["/"] = "toggle_focus",
              ["q"] = "close",
              ["?"] = "toggle_help",
              ["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
              ["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
              ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
              ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
              ["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
              ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
              ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
              ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
              ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
              ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
              ["<Down>"] = { "list_down", mode = { "i", "n" } },
              ["<Up>"] = { "list_up", mode = { "i", "n" } },
              ["<c-j>"] = { "list_down", mode = { "i", "n" } },
              ["<c-k>"] = { "list_up", mode = { "i", "n" } },
              -- ["<c-n>"] = { "list_down", mode = { "i", "n" } },
              -- ["<c-p>"] = { "list_up", mode = { "i", "n" } },
              ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
              ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
              ["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
              ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
              ["<ScrollWheelDown>"] = { "list_scroll_wheel_down", mode = { "i", "n" } },
              ["<ScrollWheelUp>"] = { "list_scroll_wheel_up", mode = { "i", "n" } },

              ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
              ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
              ["<c-q>"] = { "qflist", mode = { "i", "n" } },
            },
            b = {
              minipairs_disable = true,
            },
          },
          -- result list window
          list = {
            keys = {
              ["<CR>"] = "confirm",
              ["gg"] = "list_top",
              ["G"] = "list_bottom",
              ["i"] = "focus_input",
              ["j"] = "list_down",
              ["k"] = "list_up",
              ["q"] = "close",
              ["<Tab>"] = "select_and_next",
              ["<S-Tab>"] = "select_and_prev",
              ["<Down>"] = "list_down",
              ["<Up>"] = "list_up",
              ["<c-d>"] = "list_scroll_down",
              ["<c-u>"] = "list_scroll_up",
              ["zt"] = "list_scroll_top",
              ["zb"] = "list_scroll_bottom",
              ["zz"] = "list_scroll_center",
              ["/"] = "toggle_focus",
              ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
              ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
              ["<c-f>"] = "preview_scroll_down",
              ["<c-b>"] = "preview_scroll_up",
              ["<c-v>"] = "edit_vsplit",
              ["<c-s>"] = "edit_split",
              ["<c-j>"] = "list_down",
              ["<c-k>"] = "list_up",
              ["<c-n>"] = "list_down",
              ["<c-p>"] = "list_up",
              ["<a-w>"] = "cycle_win",
              ["<Esc>"] = "close",
            },
          },
          -- preview window
          preview = {
            minimal = false,
            wo = {
              cursorline = false,
              colorcolumn = "",
            },
            keys = {
              ["<Esc>"] = "close",
              ["q"] = "close",
              ["i"] = "focus_input",
              ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
              ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
              ["<a-w>"] = "cycle_win",
            },
          },
        },
        ---@class snacks.picker.icons
        icons = {
          indent = {
            vertical = "│ ",
            middle = "├╴",
            last = "└╴",
          },
          ui = {
            live = "󰐰 ",
            selected = "● ",
            -- selected = " ",
          },
          git = {
            commit = "󰜘 ",
          },
          diagnostics = {
            Error = " ",
            Warn = " ",
            Hint = " ",
            Info = " ",
          },
          kinds = {
            Array = " ",
            Boolean = "󰨙 ",
            Class = " ",
            Color = " ",
            Control = " ",
            Collapsed = " ",
            Constant = "󰏿 ",
            Constructor = " ",
            Copilot = " ",
            Enum = " ",
            EnumMember = " ",
            Event = " ",
            Field = " ",
            File = " ",
            Folder = " ",
            Function = "󰊕 ",
            Interface = " ",
            Key = " ",
            Keyword = " ",
            Method = "󰊕 ",
            Module = " ",
            Namespace = "󰦮 ",
            Null = " ",
            Number = "󰎠 ",
            Object = " ",
            Operator = " ",
            Package = " ",
            Property = " ",
            Reference = " ",
            Snippet = "󱄽 ",
            String = " ",
            Struct = "󰆼 ",
            Text = " ",
            TypeParameter = " ",
            Unit = " ",
            Uknown = " ",
            Value = " ",
            Variable = "󰀫 ",
          },
        },
      },
      bufdelete = { enabled = true },
      zen = {
        -- Set to false to disable zen mode
        enabled = true,

        -- Zen mode window settings
        window = {
          backdrop = 0.95, -- shade the backdrop of the zen window
          width = 0.85, -- width of the zen window
          height = 0.85, -- height of the zen window
          options = {
            signcolumn = "no", -- disable signcolumn
            number = false, -- disable number column
            relativenumber = false, -- disable relative numbers
            cursorline = false, -- disable cursorline
            cursorcolumn = false, -- disable cursor column
            foldcolumn = "0", -- disable fold column
            list = false, -- disable whitespace characters
          },
        },

        -- Zen mode plugins
        plugins = {
          -- disable tmux status
          tmux = { enabled = true },

          -- disable status and tab lines
          gitsigns = { enabled = true },
          diagnostics = { enabled = false },
          statusline = { enabled = false, hidden = true },
          tabline = { enabled = false, hidden = true },

          -- smooth scrolling options
          smooth_scroll = { enabled = true },
        },

        -- Key mappings for zen mode
        keys = {
          { "<leader>tz", "<cmd>lua require('snacks.zen').toggle()<CR>", desc = "Toggle Zen Mode" },
        },

        -- Zen mode hooks
        on_open = function(win)
          -- custom logic to run when entering zen mode
        end,

        on_close = function()
          -- custom logic to run when exiting zen mode
        end,
      },
    },
    keys = {
      -- explorer
      {
        "<leader>fe",
        function()
          require("snacks").explorer({})
        end,
        desc = "Open File Explorer",
      },
      -- lazygit
      {
        "<leader>lg",
        function()
          require("snacks").lazygit({
            win = {
              style = "float",
              size = { height = 0.9, width = 0.9 },
              border = "rounded",
            },
          })
        end,
        desc = "LazyGit (Floating)",
      },
      -- picker
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      -- find
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent",
      },
      -- git
      {
        "<leader>gc",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      -- Grep
      {
        "<leader>sb",
        function()
          Snacks.picker.lines()
        end,
        desc = "Buffer Lines",
      },
      {
        "<leader>sB",
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = "Grep Open Buffers",
      },
      {
        "<leader>fs",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Visual selection or word",
        mode = { "n", "x" },
      },
      -- search
      {
        '<leader>s"',
        function()
          Snacks.picker.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>sa",
        function()
          Snacks.picker.autocmds()
        end,
        desc = "Autocmds",
      },
      {
        "<leader>sc",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>sC",
        function()
          Snacks.picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sH",
        function()
          Snacks.picker.highlights()
        end,
        desc = "Highlights",
      },
      {
        "<leader>sj",
        function()
          Snacks.picker.jumps()
        end,
        desc = "Jumps",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sl",
        function()
          Snacks.picker.loclist()
        end,
        desc = "Location List",
      },
      {
        "<leader>sM",
        function()
          Snacks.picker.man()
        end,
        desc = "Man Pages",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sR",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume",
      },
      {
        "<leader>sq",
        function()
          Snacks.picker.qflist()
        end,
        desc = "Quickfix List",
      },
      {
        "<leader>uS",
        function()
          Snacks.picker.colorschemes()
        end,
        desc = "Colorschemes",
      },
      {
        "<leader>qp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Projects",
      },
      -- LSP
      {
        "gd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "gr",
        function()
          Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
      },
      {
        "gI",
        function()
          Snacks.picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
      },
      {
        "gy",
        function()
          Snacks.picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "<leader>sS",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
      },

      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
      },
      {
        "<leader>S",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select Scratch Buffer",
      },
      -- bufdelete
      {
        "<leader>bd",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
      },
      {
        "<leader>bD",
        function()
          Snacks.bufdelete.all()
        end,
        desc = "Delete Buffer (Force)",
      },
      {
        "<leader>bo",
        function()
          Snacks.bufdelete.other()
        end,
        desc = "Delete Other Buffers",
      },
    },
  },
}
