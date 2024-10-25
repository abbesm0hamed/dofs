-- mainly using oil but left it in the config to
-- have a full overview on the project tree
--
return {
  {
    "nvim-tree/nvim-tree.lua",
    event = "VeryLazy",
    config = function()
      local nvimtree = require("nvim-tree")

      -- recommended settings from nvim-tree documentation
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- configure nvim-tree
      nvimtree.setup({
        view = {
          width = 35,
          relativenumber = true,
        },
        -- change folder arrow icons
        renderer = {
          indent_markers = {
            enable = true,
          },
          icons = {
            glyphs = {
              folder = {
                arrow_closed = "", -- arrow when folder is closed
                arrow_open = "",   -- arrow when folder is open
              },
            },
          },
        },
        -- disable window_picker for
        -- explorer to work well with
        -- window splits
        actions = {
          open_file = {
            window_picker = {
              enable = false,
            },
          },
        },
        filters = {
          custom = { ".DS_Store" },
        },
        git = {
          ignore = false,
        },
      })

      -- set keymaps
      local keymap = vim
          .keymap                                                                                                         -- for conciseness

      keymap.set("n", "<leader>fe", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })                         -- toggle file explorer
      keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }) -- toggle file explorer on current file
      keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" })                     -- collapse file explorer
      keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })                       -- refresh file explorer
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").set_icon({
        gql = { icon = "", color = "#e535ab", cterm_color = "199", name = "GraphQL" },
        js = { icon = "󰌞", color = "#f7df1e", name = "Javascript" },
        ts = { icon = "󰛦", color = "#007acc", name = "Typescript" },
        json = { icon = "󰎙", color = "#cbcb41", name = "Json" },
        php = { icon = "󰌟", color = "#8993be", name = "Php" },
        go = { icon = "󰟓", color = "#00add8", name = "Go" },
      })
    end,
  },
}
