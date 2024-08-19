local telescope = vim.cmd.Telescope

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false, -- telescope did only one release, so use HEAD for now
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = vim.fn.executable("make") == 1 and "make"
            or
            "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
        enabled = vim.fn.executable("make") == 1 or vim.fn.executable("cmake") == 1,
      },
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      {
        "<leader>,",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "Switch Buffer",
      },
      { "<leader>:",  "<cmd>Telescope command_history<cr>",           desc = "Command History" },
      -- find
      { "<leader>ff", "<cmd>Telescope find_files<cr>",                desc = "Fuzzy find files in cwd" },
      { "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Fuzzy find in cb" },
      {
        "<leader>ft",
        "<cmd>Telescope current_buffer_tags<cr>",
        desc = "List all tags for currently open buffer",
      },
      { "<leader>fs", "<cmd>Telescope live_grep<cr>", desc = " Live-Grep" },
      {
        "<leader>fi",
        "<cmd>Telescope grep_string<cr>",
        desc = "Fuzzy string under cursor in cwd",
      },
      { "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
      { "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      -- git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Commits" },
      { "<leader>gb", "<cmd>Telescope git_branches<CR>", desc = " Branches" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Status" },
      { "<leader>gS", "<cmd>Telescope git_stash<CR>", desc = "Stash" },
      -- search
      { '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
      { "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "Auto Commands" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
      { "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics" },
      { "<leader>sD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
      { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Search Highlight Groups" },
      { "<leader>sK", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
      { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
      { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
      { "<leader>sR", "<cmd>Telescope resume<cr>", desc = "Resume" },
      -- treesitter
      { "<leader>T", "<cmd>Telescope treesitter<cr>", desc = "Telescope" },
      -- colorscheme
      {
        "<leader>Cs",
        function()
          -- HACK remove built-in colorschemes from selection
          -- stylua: ignore
          local builtins = {
            "zellner", "torte", "slate", "shine", "ron", "quiet", "peachpuff",
            "pablo", "murphy", "lunaperche", "koehler", "industry", "evening",
            "elflord", "desert", "delek", "default", "darkblue", "blue", "morning",
          }
          local original = vim.fn.getcompletion

          ---@diagnostic disable-next-line: duplicate-set-field
          vim.fn.getcompletion = function()
            return vim.tbl_filter(function(color)
              return not vim.tbl_contains(builtins, color)
            end, original("", "color"))
          end

          telescope("colorscheme")
        end,
        desc = " Colorschemes",
      },
    },
    opts = function()
      local actions = require("telescope.actions")

      local open_with_trouble = function(...)
        return require("trouble.providers.telescope").open_with_trouble(...)
      end
      local open_selected_with_trouble = function(...)
        return require("trouble.providers.telescope").open_selected_with_trouble(...)
      end

      return {
        pickers = {
          colorscheme = {
            enable_preview = true,
          },
        },
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          },
          entry_prefix = "  ",
          initial_mode = "insert",
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              height = { 0.95, min = 13 },
              width = 0.99,
              preview_cutoff = 70,
              preview_width = { 0.40, min = 30 },
            },
            vertical = {
              prompt_position = "top",
              mirror = true,
              height = 0.9,
              width = 0.7,
              preview_cutoff = 12,
              preview_height = { 0.7, min = 10 },
              anchor = "S",
            },
          },
          file_ignore_patterns = {},
          winblend = 0,
          border = {},
          borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          -- borderchars = { "═", "║", "═", "║", "╔", "╗", "╝", "╚" },
          -- borderchars =  { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          color_devicons = true,
          use_less = true,
          path_display = {},
          set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
          prompt_prefix = "▶ ",
          selection_caret = "▶ ",
          -- open files in the first window that is an actual file.
          -- use the current window if no other window is available.
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == "" then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ["<c-t>"] = open_with_trouble,
              ["<a-t>"] = open_selected_with_trouble,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-d>"] = actions.preview_scrolling_down,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-k>"] = actions.move_selection_previous, -- move to prev result
              ["<C-j>"] = actions.move_selection_next,     -- move to next result
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
            n = {
              ["q"] = actions.close,
            },
          },
        },
      }
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({
            }),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
  {
    "ziontee113/icon-picker.nvim",
    config = function()
      require("icon-picker").setup({ disable_legacy_commands = true })

      local opts = { noremap = true, silent = true }

      vim.keymap.set("n", "<Leader><Leader>i", "<cmd>IconPickerNormal<cr>", opts)
      vim.keymap.set("n", "<Leader><Leader>y", "<cmd>IconPickerYank<cr>", opts) --> Yank the selected icon into register
      vim.keymap.set("i", "<C-i>", "<cmd>IconPickerInsert<cr>", opts)
    end
  }
}
