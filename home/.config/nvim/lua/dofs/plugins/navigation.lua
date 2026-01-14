return {
  {
    "leath-dub/snipe.nvim",
    lazy = true,
    keys = {
      {
        "'",
        function()
          require("snipe").open_buffer_menu()
        end,
        desc = "Open Snipe buffer menu",
      },
    },
    opts = {},
    config = function()
      require("snipe").setup({
        ui = {
          max_height = -1, -- -1 means dynamic height
          -- Where to place the ui window
          -- Can be any of "topleft", "bottomleft", "topright", "bottomright", "center", "cursor" (sets under the current cursor pos)
          position = "topleft",
          -- Override options passed to `nvim_open_win`
          -- Be careful with this as snipe will not validate
          -- anything you override here. See `:h nvim_open_win`
          -- for config options
          open_win_override = {
            -- title = "My Window Title",
            border = "single", -- use "rounded" for rounded border
          },

          -- Preselect the currently open buffer
          preselect_current = true,

          -- Changes how the items are aligned: e.g. "<tag> foo    " vs "<tag>    foo"
          text_align = "left",
        },
        hints = {
          -- Charaters to use for hints (NOTE: make sure they don't collide with the navigation keymaps)
          dictionary = "sadflewcmpghio",
        },
        navigate = {
          -- When the list is too long it is split into pages
          -- `[next|prev]_page` options allow you to navigate
          -- this list
          next_page = "J",
          prev_page = "K",

          -- You can also just use normal navigation to go to the item you want
          -- this option just sets the keybind for selecting the item under the
          -- cursor
          under_cursor = "<cr>",

          -- In case you changed your mind, provide a keybind that lets you
          -- cancel the snipe and close the window.
          cancel_snipe = "<esc>",

          -- Close the buffer under the cursor
          -- Remove "j" and "k" from your dictionary to navigate easier to delete
          -- NOTE: Make sure you don't use the character below on your dictionary
          close_buffer = "D",

          -- Open buffer in vertical split
          open_vsplit = "V",

          -- Open buffer in split, based on `vim.opt.splitbelow`
          open_split = "H",

          -- Change tag manually
          change_tag = "C",
        },
        -- The default sort used for the buffers
        -- Can be any of "last", (sort buffers by last accessed) "default" (sort buffers by its number)
        sort = "default",
      })
    end,
  },
  -- {
  --   'EvWilson/spelunk.nvim',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',         -- For window drawing utilities
  --     'nvim-telescope/telescope.nvim', -- Optional: for fuzzy search capabilities
  --   },
  --   config = function()
  --     require('spelunk').setup({
  --       base_mappings = {
  --         -- Toggle the UI open/closed
  --         toggle = '<leader>bt',
  --         -- Add a bookmark to the current stack
  --         add = '<leader>ba',
  --         -- Move to the next bookmark in the stack
  --         next_bookmark = '<leader>bn',
  --         -- Move to the previous bookmark in the stack
  --         prev_bookmark = '<leader>bp',
  --         -- Fuzzy-find all bookmarks
  --         search_bookmarks = '<leader>bf',
  --         -- Fuzzy-find bookmarks in current stack
  --         search_current_bookmarks = '<leader>cb'
  --       },
  --       window_mappings = {
  --         -- Move the UI cursor down
  --         cursor_down = 'j',
  --         -- Move the UI cursor up
  --         cursor_up = 'k',
  --         -- Move the current bookmark down in the stack
  --         bookmark_down = '<C-j>',
  --         -- Move the current bookmark up in the stack
  --         bookmark_up = '<C-k',
  --         -- Jump to the selected bookmark
  --         goto_bookmark = '<CR>',
  --         -- Jump to the selected bookmark in a new vertical split
  --         goto_bookmark_hsplit = 'x',
  --         -- Jump to the selected bookmark in a new horizontal split
  --         goto_bookmark_vsplit = 'v',
  --         -- Delete the selected bookmark
  --         delete_bookmark = 'd',
  --         -- Navigate to the next stack
  --         next_stack = '<Tab>',
  --         -- Navigate to the previous stack
  --         previous_stack = '<S-Tab>',
  --         -- Create a new stack
  --         new_stack = 'n',
  --         -- Delete the current stack
  --         delete_stack = 'D',
  --         -- Rename the current stack
  --         edit_stack = 'E',
  --         -- Close the UI
  --         close = 'q',
  --         -- Open the help menu
  --         help = 'h', -- Not rebindable
  --       },
  --       -- Flag to enable directory-scoped bookmark persistence
  --       enable_persist = false,
  --       -- Prefix for the Lualine integration
  --       -- (Change this if your terminal emulator lacks emoji support)
  --       statusline_prefix = '🔖',
  --     })
  --   end
  -- },
  -- {
  --   "ThePrimeagen/harpoon",
  --   config = function()
  --     local harpoon = require("harpoon")
  --
  --     harpoon.setup({
  --       -- Global settings
  --       global_settings = {
  --         -- Set the max number of marks to keep in the buffer
  --         max_num_marks = 10,
  --         -- Rename or remap the toggle, add, and ui launch keys
  --         keymap = {
  --           toggle_quick_menu = "<C-a>",
  --           -- add_file = "<C-m>",
  --           -- ui_toggle = "<C-e>"
  --         },
  --       },
  --
  --       -- Mark-specific settings
  --       mark_specific_settings = {
  --         -- Set different commands for the marks
  --         ["1"] = { vim.cmd.edit, "edit" },
  --         ["2"] = { vim.cmd.vsplit, "vsplit" },
  --         ["3"] = { vim.cmd.split, "split" },
  --         ["4"] = { vim.cmd.tabedit, "tabedit" },
  --       },
  --     })
  --
  --     -- Example keymaps
  --     vim.keymap.set("n", "<C-e>", function() require("harpoon.ui").toggle_quick_menu() end)
  --     vim.keymap.set("n", "<C-h>", function() require("harpoon.mark").add_file() end)
  --     vim.keymap.set("n", "<C-j>", function() require("harpoon.ui").nav_file(1) end)
  --     vim.keymap.set("n", "<C-k>", function() require("harpoon.ui").nav_file(2) end)
  --     vim.keymap.set("n", "<C-l>", function() require("harpoon.ui").nav_file(3) end)
  --   end,
  -- }
}
